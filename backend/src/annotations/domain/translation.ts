import { createHash } from 'crypto';

// Quy tắc thuần cho dịch nghĩa: khoá cache, prompt, kiểm tra JSON của model, đọc kết quả từ điển.

/** Schema JSON ép model trả về (Gemini `generationConfig.responseJsonSchema`). Chuỗi rỗng nghĩa là "không có". */
export const TRANSLATION_SCHEMA = {
  type: 'object',
  properties: {
    meaning: { type: 'string' },
    partOfSpeech: { type: 'string' },
    sentenceTranslation: { type: 'string' },
  },
  required: ['meaning', 'partOfSpeech', 'sentenceTranslation'],
  additionalProperties: false,
};

const SCHEMA_KEYS = ['meaning', 'partOfSpeech', 'sentenceTranslation'];

export interface ModelTranslation {
  meaning: string;
  partOfSpeech: string | null;
  sentenceTranslation: string | null;
}

/** Kết quả trả FE và lưu cache. */
export interface TranslationPayload extends ModelTranslation {
  text: string;
  ipa: string | null;
}

export interface DictionaryInfo {
  ipa: string | null;
  /** Từ loại tiếng Anh (noun, verb…) của nghĩa đầu tiên. */
  partOfSpeech: string | null;
}

/** sha1(lower(trim(text)) + '|' + lower(trim(sentence ?? ''))). */
export function translationKey(
  text: string,
  sentence: string | null | undefined,
): string {
  const norm = (s: string) => s.trim().toLowerCase();
  return createHash('sha1')
    .update(`${norm(text)}|${norm(sentence ?? '')}`)
    .digest('hex');
}

export function wordCount(text: string): number {
  const t = text.trim();
  return t ? t.split(/\s+/).length : 0;
}

/** System prompt cố định (không chèn chữ của người dùng); bản cho một từ đơn gọi là "TỪ", còn lại "CỤM". */
export function translationSystemPrompt(singleWord: boolean): string {
  const unit = singleWord ? 'TỪ' : 'CỤM';
  return [
    'Bạn là từ điển Anh–Việt cho người học IELTS.',
    'Trả về JSON đúng schema: {"meaning": string, "partOfSpeech": string, "sentenceTranslation": string}',
    `- meaning: nghĩa tiếng Việt ngắn gọn (≤ 12 từ) của ${unit} cần dịch theo ngữ cảnh câu.`,
    '- partOfSpeech: "danh từ" | "động từ" | "tính từ" | "trạng từ" | "cụm danh từ" | "cụm động từ" | "thành ngữ" | ... hoặc chuỗi rỗng nếu không rõ.',
    `- sentenceTranslation: dịch tự nhiên cả câu chứa ${unit.toLowerCase()} sang tiếng Việt; chuỗi rỗng nếu không có câu.`,
    'Không thêm giải thích, không markdown.',
  ].join('\n');
}

export function translationUserMessage(
  text: string,
  sentence: string | null,
  singleWord: boolean,
): string {
  const unit = singleWord ? 'Từ' : 'Cụm';
  return `${unit} cần dịch: ${text}\nCâu chứa ${unit.toLowerCase()}: ${sentence ?? '(không có)'}`;
}

/**
 * Đọc JSON model trả về theo đúng schema. Sai kiểu, thừa / thiếu khoá, nghĩa rỗng → null (gọi lại).
 * Chuỗi rỗng ở `partOfSpeech` / `sentenceTranslation` thành null.
 */
export function parseModelTranslation(
  raw: string | null | undefined,
): ModelTranslation | null {
  if (!raw) return null;
  let value: unknown;
  try {
    value = JSON.parse(raw);
  } catch {
    return null;
  }
  if (typeof value !== 'object' || value === null || Array.isArray(value))
    return null;
  const obj = value as Record<string, unknown>;
  const keys = Object.keys(obj);
  if (
    keys.length !== SCHEMA_KEYS.length ||
    !SCHEMA_KEYS.every((k) => typeof obj[k] === 'string')
  )
    return null;
  const meaning = (obj.meaning as string).trim();
  if (!meaning) return null;
  const orNull = (s: unknown) => (s as string).trim() || null;
  return {
    meaning,
    partOfSpeech: orNull(obj.partOfSpeech),
    sentenceTranslation: orNull(obj.sentenceTranslation),
  };
}

const VI_POS: Record<string, string> = {
  noun: 'danh từ',
  verb: 'động từ',
  adjective: 'tính từ',
  adverb: 'trạng từ',
  pronoun: 'đại từ',
  preposition: 'giới từ',
  conjunction: 'liên từ',
  interjection: 'thán từ',
  determiner: 'từ hạn định',
};

/** Từ loại tiếng Anh của từ điển → nhãn tiếng Việt (dùng khi model để trống). */
export function vietnamesePos(
  english: string | null | undefined,
): string | null {
  return english ? (VI_POS[english.toLowerCase()] ?? null) : null;
}

interface FreeDictPhonetic {
  text?: unknown;
  audio?: unknown;
}

/**
 * Kết quả của api.dictionaryapi.dev: ưu tiên phiên âm có audio giọng Anh (`-uk`),
 * không có thì lấy phiên âm đầu tiên khác rỗng.
 */
export function pickDictionaryInfo(body: unknown): DictionaryInfo | null {
  if (!Array.isArray(body) || !body.length) return null;
  const entries = body.filter(
    (e): e is Record<string, unknown> => typeof e === 'object' && e !== null,
  );
  const phonetics: FreeDictPhonetic[] = entries.flatMap((e) =>
    Array.isArray(e.phonetics) ? (e.phonetics as FreeDictPhonetic[]) : [],
  );
  const textOf = (p: FreeDictPhonetic) =>
    typeof p?.text === 'string' ? p.text.trim() : '';
  const uk = phonetics.find(
    (p) => textOf(p) && typeof p.audio === 'string' && p.audio.includes('-uk'),
  );
  const first = phonetics.find((p) => textOf(p));
  const fallback = entries
    .map((e) => (typeof e.phonetic === 'string' ? e.phonetic.trim() : ''))
    .find(Boolean);
  const ipa = (uk ? textOf(uk) : first ? textOf(first) : fallback) || null;

  const meanings = entries.flatMap((e) =>
    Array.isArray(e.meanings)
      ? (e.meanings as { partOfSpeech?: unknown }[])
      : [],
  );
  const pos = meanings.find((m) => typeof m?.partOfSpeech === 'string')
    ?.partOfSpeech as string | undefined;

  return { ipa: ipa ? ipa.slice(0, 80) : null, partOfSpeech: pos ?? null };
}
