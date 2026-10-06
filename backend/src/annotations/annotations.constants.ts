// Hằng số của module ghi chú cá nhân trên tài liệu (highlight, vẽ trên slide), Sổ từ, dịch nghĩa.

export const HIGHLIGHT_COLORS = ['yellow', 'green', 'blue', 'pink'] as const;
export type HighlightColor = (typeof HIGHLIGHT_COLORS)[number];

/** Ngữ cảnh trước / sau đoạn highlight: lưu tối đa 32 ký tự (prefix giữ 32 ký tự cuối, suffix 32 ký tự đầu). */
export const HIGHLIGHT_CONTEXT_CHARS = 32;
export const HIGHLIGHT_QUOTE_MAX = 300;

export const SLIDE_KEY_PATTERN = /^[A-Za-z0-9_-]{1,40}$/;
/** Dữ liệu vẽ của một slide, tính theo JSON UTF-8. */
export const MAX_SLIDE_ANNOTATION_BYTES = 256 * 1024;
/** Body của `/api/me/docs/*`: dư cho phần bọc ngoài `data` 256 KB. */
export const ANNOTATION_BODY_LIMIT = '320kb';
export const ANNOTATION_DOC_PATH = '/api/me/docs';

export const VOCAB_LIST_CAP = 2000;

/** Dịch nghĩa (POST /translate) bằng Gemini; đổi model bằng biến môi trường `GEMINI_MODEL`. */
export const DEFAULT_GEMINI_MODEL = 'gemini-3.5-flash-lite';
export const GEMINI_API_URL =
  'https://generativelanguage.googleapis.com/v1beta/models/';
export const TRANSLATE_MAX_TOKENS = 4096;
export const DEFAULT_TRANSLATE_DEADLINE_MS = 6000;
export const DEFAULT_TRANSLATE_RATE_LIMIT = 60;
export const TRANSLATE_RATE_WINDOW_MS = 60 * 60 * 1000;
/** Tra IPA ở từ điển miễn phí không chờ quá mức này (vẫn trong hạn chung). */
export const DICTIONARY_TIMEOUT_MS = 3000;
export const DICTIONARY_URL =
  'https://api.dictionaryapi.dev/api/v2/entries/en/';
