import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import {
  DEFAULT_GEMINI_MODEL,
  GEMINI_API_URL,
  TRANSLATE_MAX_TOKENS,
} from './annotations.constants';
import {
  TRANSLATION_SCHEMA,
  translationSystemPrompt,
  translationUserMessage,
} from './domain/translation';

export interface LlmTranslateInput {
  text: string;
  sentence: string | null;
  singleWord: boolean;
}

/** `text`: chuỗi JSON model trả (chưa kiểm tra); `refusal`: model từ chối. */
export type LlmReply = { kind: 'text'; text: string } | { kind: 'refusal' };

/** Hết hạn chờ (timeout / bị huỷ). */
export class LlmTimeoutError extends Error {
  constructor() {
    super('llm_timeout');
  }
}

/** Lỗi gọi model; `category` chỉ là loại lỗi để ghi log, không chứa nội dung người dùng. */
export class LlmFailedError extends Error {
  constructor(public readonly category: string) {
    super(`llm_failed:${category}`);
  }
}

/** Cổng gọi model dịch nghĩa. Test e2e / unit thay bằng bản giả, không gọi API thật. */
export abstract class TranslatorLlm {
  /** Đã cấu hình khoá API chưa. */
  abstract available(): boolean;

  abstract complete(
    input: LlmTranslateInput,
    opts: { timeoutMs: number; signal: AbortSignal },
  ): Promise<LlmReply>;
}

/** Lý do kết thúc / chặn của Gemini coi như model từ chối trả lời. */
const BLOCKED_REASONS = new Set([
  'SAFETY',
  'RECITATION',
  'BLOCKLIST',
  'PROHIBITED_CONTENT',
  'SPII',
  'IMAGE_SAFETY',
  'OTHER',
]);

interface GeminiResponse {
  promptFeedback?: { blockReason?: string };
  candidates?: {
    finishReason?: string;
    content?: { parts?: { text?: string; thought?: boolean }[] };
  }[];
  error?: { status?: string };
}

/**
 * Gọi Gemini qua REST `models/{model}:generateContent` (fetch có sẵn của Node, không thêm package).
 * Khoá `GEMINI_API_KEY`, model `GEMINI_MODEL` (mặc định [DEFAULT_GEMINI_MODEL]). Không tự retry (hạn chung 6 giây).
 */
@Injectable()
export class GeminiTranslatorLlm extends TranslatorLlm {
  constructor(private config: ConfigService) {
    super();
  }

  private get apiKey(): string {
    return this.config.get<string>('GEMINI_API_KEY')?.trim() ?? '';
  }

  private get model(): string {
    return (
      this.config.get<string>('GEMINI_MODEL')?.trim() || DEFAULT_GEMINI_MODEL
    );
  }

  available(): boolean {
    return !!this.apiKey;
  }

  async complete(
    input: LlmTranslateInput,
    opts: { timeoutMs: number; signal: AbortSignal },
  ): Promise<LlmReply> {
    const url = `${GEMINI_API_URL}${encodeURIComponent(this.model)}:generateContent`;
    let res: Response;
    try {
      res = await fetch(url, {
        method: 'POST',
        headers: {
          'content-type': 'application/json',
          // Khoá đặt ở header, không nằm trên URL (tránh lọt vào log của proxy).
          'x-goog-api-key': this.apiKey,
        },
        body: JSON.stringify({
          systemInstruction: {
            parts: [{ text: translationSystemPrompt(input.singleWord) }],
          },
          contents: [
            {
              role: 'user',
              parts: [
                {
                  text: translationUserMessage(
                    input.text,
                    input.sentence,
                    input.singleWord,
                  ),
                },
              ],
            },
          ],
          generationConfig: {
            maxOutputTokens: TRANSLATE_MAX_TOKENS,
            responseMimeType: 'application/json',
            responseJsonSchema: TRANSLATION_SCHEMA,
          },
        }),
        signal: AbortSignal.any([
          opts.signal,
          AbortSignal.timeout(Math.max(1, Math.floor(opts.timeoutMs))),
        ]),
      });
    } catch (e) {
      const name = (e as Error)?.name;
      if (name === 'AbortError' || name === 'TimeoutError')
        throw new LlmTimeoutError();
      throw new LlmFailedError('connection');
    }

    let body: GeminiResponse;
    try {
      body = (await res.json()) as GeminiResponse;
    } catch (e) {
      const name = (e as Error)?.name;
      if (name === 'AbortError' || name === 'TimeoutError')
        throw new LlmTimeoutError();
      throw new LlmFailedError(res.ok ? 'invalid_body' : `api_${res.status}`);
    }
    if (!res.ok) throw new LlmFailedError(errorCategory(res.status));

    if (body.promptFeedback?.blockReason) return { kind: 'refusal' };
    const candidate = body.candidates?.[0];
    if (!candidate) return { kind: 'refusal' };
    if (candidate.finishReason && BLOCKED_REASONS.has(candidate.finishReason))
      return { kind: 'refusal' };
    const text = (candidate.content?.parts ?? [])
      .filter((p) => !p.thought && typeof p.text === 'string')
      .map((p) => p.text)
      .join('');
    return { kind: 'text', text };
  }
}

/** Mã HTTP của Gemini → loại lỗi để ghi log (không chứa nội dung người dùng). */
function errorCategory(status: number): string {
  if (status === 401 || status === 403) return 'auth';
  if (status === 429) return 'rate_limited';
  if (status === 404) return 'model_not_found';
  if (status === 400) return 'bad_request';
  return `api_${status}`;
}
