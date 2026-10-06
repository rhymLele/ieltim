import type { ConfigService } from '@nestjs/config';
import { DEFAULT_GEMINI_MODEL } from './annotations.constants';
import { TRANSLATION_SCHEMA } from './domain/translation';
import {
  GeminiTranslatorLlm,
  LlmFailedError,
  LlmTimeoutError,
} from './translator-llm';

const INPUT = {
  text: 'resilient',
  sentence: 'She is remarkably resilient.',
  singleWord: true,
};
const JSON_REPLY =
  '{"meaning":"kiên cường","partOfSpeech":"tính từ","sentenceTranslation":"Cô ấy kiên cường lạ thường."}';

function config(env: Record<string, string | undefined>): ConfigService {
  return { get: (key: string) => env[key] } as unknown as ConfigService;
}

interface Call {
  url: string;
  init: RequestInit;
}

/** Body gửi Gemini (chỉ các trường test đọc). */
interface SentBody {
  systemInstruction: unknown;
  contents: { parts: { text: string }[] }[];
  generationConfig: Record<string, unknown>;
}

/** Thay `fetch` toàn cục: ghi lại request, trả [respond]; không gọi mạng. */
function stubFetch(respond: (call: Call) => Promise<Response> | Response) {
  const calls: Call[] = [];
  globalThis.fetch = (url: string, init: RequestInit) => {
    const call = { url, init };
    calls.push(call);
    return Promise.resolve(respond(call));
  };
  return calls;
}

const json = (body: unknown, status = 200) =>
  new Response(JSON.stringify(body), {
    status,
    headers: { 'content-type': 'application/json' },
  });

const reply = (text: string, finishReason = 'STOP') =>
  json({
    candidates: [
      { finishReason, content: { role: 'model', parts: [{ text }] } },
    ],
  });

describe('GeminiTranslatorLlm', () => {
  const realFetch = globalThis.fetch;
  afterEach(() => {
    globalThis.fetch = realFetch;
  });

  const llm = (env: Record<string, string | undefined> = {}) =>
    new GeminiTranslatorLlm(config({ GEMINI_API_KEY: 'test-key', ...env }));
  const opts = () => ({
    timeoutMs: 5000,
    signal: new AbortController().signal,
  });

  it('chưa có GEMINI_API_KEY → không khả dụng', () => {
    expect(llm({ GEMINI_API_KEY: undefined }).available()).toBe(false);
    expect(llm({ GEMINI_API_KEY: '  ' }).available()).toBe(false);
    expect(llm().available()).toBe(true);
  });

  it('gửi generateContent: khoá ở header, prompt cố định, JSON theo schema', async () => {
    const calls = stubFetch(() => reply(JSON_REPLY));
    await expect(llm().complete(INPUT, opts())).resolves.toEqual({
      kind: 'text',
      text: JSON_REPLY,
    });
    const [call] = calls;
    expect(call.url).toBe(
      `https://generativelanguage.googleapis.com/v1beta/models/${DEFAULT_GEMINI_MODEL}:generateContent`,
    );
    expect(call.url).not.toContain('test-key');
    const headers = call.init.headers as Record<string, string>;
    expect(headers['x-goog-api-key']).toBe('test-key');
    const body = JSON.parse(call.init.body as string) as SentBody;
    expect(body.generationConfig).toMatchObject({
      responseMimeType: 'application/json',
      responseJsonSchema: TRANSLATION_SCHEMA,
    });
    // Chữ người dùng chỉ nằm trong tin nhắn user, không nằm trong system prompt.
    expect(JSON.stringify(body.systemInstruction)).not.toContain('resilient');
    expect(body.contents[0].parts[0].text).toContain('resilient');
    expect(body.contents[0].parts[0].text).toContain(INPUT.sentence);
  });

  it('GEMINI_MODEL đổi model', async () => {
    const calls = stubFetch(() => reply(JSON_REPLY));
    await llm({ GEMINI_MODEL: 'gemini-3.8-flash' }).complete(INPUT, opts());
    expect(calls[0].url).toContain('/models/gemini-3.8-flash:generateContent');
  });

  it('bỏ phần suy nghĩ (thought), nối các phần chữ', async () => {
    stubFetch(() =>
      json({
        candidates: [
          {
            finishReason: 'STOP',
            content: {
              parts: [
                { text: 'đang nghĩ…', thought: true },
                { text: JSON_REPLY.slice(0, 10) },
                { text: JSON_REPLY.slice(10) },
              ],
            },
          },
        ],
      }),
    );
    await expect(llm().complete(INPUT, opts())).resolves.toEqual({
      kind: 'text',
      text: JSON_REPLY,
    });
  });

  it.each([
    ['prompt bị chặn', json({ promptFeedback: { blockReason: 'SAFETY' } })],
    ['không có candidate', json({ candidates: [] })],
    ['dừng vì an toàn', reply('', 'SAFETY')],
    ['dừng vì nội dung cấm', reply('', 'PROHIBITED_CONTENT')],
  ])('%s → từ chối', async (_, res) => {
    stubFetch(() => res);
    await expect(llm().complete(INPUT, opts())).resolves.toEqual({
      kind: 'refusal',
    });
  });

  it.each([
    [400, 'bad_request'],
    [403, 'auth'],
    [404, 'model_not_found'],
    [429, 'rate_limited'],
    [503, 'api_503'],
  ])('HTTP %i → LlmFailedError(%s)', async (status, category) => {
    stubFetch(() =>
      json({ error: { code: status, status: 'X', message: 'm' } }, status),
    );
    const err = await llm()
      .complete(INPUT, opts())
      .catch((e: unknown) => e);
    expect(err).toBeInstanceOf(LlmFailedError);
    expect((err as LlmFailedError).category).toBe(category);
  });

  it('lỗi mạng → LlmFailedError(connection)', async () => {
    stubFetch(() => Promise.reject(new TypeError('fetch failed')));
    const err = await llm()
      .complete(INPUT, opts())
      .catch((e: unknown) => e);
    expect((err as LlmFailedError).category).toBe('connection');
  });

  it('hết hạn / bị huỷ → LlmTimeoutError', async () => {
    // fetch giả tôn trọng signal như fetch thật.
    stubFetch(
      ({ init }) =>
        new Promise<Response>((_, reject) =>
          init.signal?.addEventListener('abort', () =>
            reject(init.signal?.reason as Error),
          ),
        ),
    );
    await expect(
      llm().complete(INPUT, {
        timeoutMs: 20,
        signal: new AbortController().signal,
      }),
    ).rejects.toBeInstanceOf(LlmTimeoutError);

    const ctrl = new AbortController();
    const pending = llm().complete(INPUT, {
      timeoutMs: 5000,
      signal: ctrl.signal,
    });
    ctrl.abort();
    await expect(pending).rejects.toBeInstanceOf(LlmTimeoutError);
  });
});
