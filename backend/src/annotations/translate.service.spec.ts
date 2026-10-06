import { HttpException } from '@nestjs/common';
import type { ConfigService } from '@nestjs/config';
import type { Repository } from 'typeorm';
import { DictionaryLookup } from './dictionary';
import type { DictionaryInfo, TranslationPayload } from './domain/translation';
import { TranslationCache } from './entities/translation-cache.entity';
import { TranslateService } from './translate.service';
import {
  type LlmReply,
  type LlmTranslateInput,
  LlmFailedError,
  TranslatorLlm,
} from './translator-llm';

const VALID =
  '{"meaning":"kiên cường","partOfSpeech":"tính từ","sentenceTranslation":"Cô ấy rất kiên cường."}';

/** Model giả: trả lần lượt theo `replies` (hàm thì gọi để lấy kết quả). */
class FakeLlm extends TranslatorLlm {
  calls: LlmTranslateInput[] = [];
  ok = true;
  constructor(public replies: (LlmReply | (() => Promise<LlmReply>))[] = []) {
    super();
  }
  available() {
    return this.ok;
  }
  complete(input: LlmTranslateInput): Promise<LlmReply> {
    this.calls.push(input);
    const next = this.replies.shift() ?? { kind: 'text', text: VALID };
    return typeof next === 'function' ? next() : Promise.resolve(next);
  }
}

class FakeDictionary extends DictionaryLookup {
  terms: string[] = [];
  constructor(private info: DictionaryInfo | null = null) {
    super();
  }
  lookup(term: string) {
    this.terms.push(term);
    return Promise.resolve(this.info);
  }
}

function fakeCache() {
  const rows = new Map<string, TranslationPayload>();
  const repo = {
    findOneBy: ({ key }: { key: string }) =>
      Promise.resolve(rows.has(key) ? { key, payload: rows.get(key) } : null),
    upsert: (v: { key: string; payload: TranslationPayload }) => {
      rows.set(v.key, v.payload);
      return Promise.resolve();
    },
  };
  return { rows, repo: repo as unknown as Repository<TranslationCache> };
}

function setup(opts: {
  llm?: FakeLlm;
  dict?: FakeDictionary;
  env?: Record<string, string>;
}) {
  const llm = opts.llm ?? new FakeLlm();
  const dict = opts.dict ?? new FakeDictionary();
  const cache = fakeCache();
  const config = {
    get: (k: string) => opts.env?.[k],
  } as unknown as ConfigService;
  const service = new TranslateService(cache.repo, llm, dict, config);
  return { service, llm, dict, cache };
}

async function errorOf(p: Promise<unknown>) {
  try {
    await p;
  } catch (e) {
    if (e instanceof HttpException)
      return {
        status: e.getStatus(),
        code: (e.getResponse() as { code: string }).code,
      };
    throw e;
  }
  throw new Error('Không có lỗi');
}

describe('TranslateService', () => {
  it('gọi model + từ điển, ghép kết quả, lưu cache; lần sau lấy từ cache', async () => {
    const { service, llm, dict, cache } = setup({
      dict: new FakeDictionary({
        ipa: '/rɪˈzɪlɪənt/',
        partOfSpeech: 'adjective',
      }),
    });
    const first = await service.translate('u1', {
      text: ' resilient ',
      sentence: 'She is resilient.',
    });
    expect(first).toEqual({
      text: 'resilient',
      meaning: 'kiên cường',
      ipa: '/rɪˈzɪlɪənt/',
      partOfSpeech: 'tính từ',
      sentenceTranslation: 'Cô ấy rất kiên cường.',
    });
    expect(llm.calls).toEqual([
      { text: 'resilient', sentence: 'She is resilient.', singleWord: true },
    ]);
    expect(dict.terms).toEqual(['resilient']);
    expect(cache.rows.size).toBe(1);

    const again = await service.translate('u2', {
      text: 'Resilient',
      sentence: ' she is RESILIENT. ',
    });
    expect(again).toEqual({ ...first, text: 'Resilient' });
    expect(llm.calls).toHaveLength(1);
  });

  it('không có câu thì sentenceTranslation = null; cụm > 3 từ không tra từ điển', async () => {
    const { service, dict } = setup({});
    const res = await service.translate('u1', {
      text: 'a piece of cake indeed',
    });
    expect(res.sentenceTranslation).toBeNull();
    expect(dict.terms).toEqual([]);
  });

  it('model để trống từ loại → lấy từ loại của từ điển', async () => {
    const { service } = setup({
      llm: new FakeLlm([
        {
          kind: 'text',
          text: '{"meaning":"chạy","partOfSpeech":"","sentenceTranslation":""}',
        },
      ]),
      dict: new FakeDictionary({ ipa: null, partOfSpeech: 'verb' }),
    });
    const res = await service.translate('u1', { text: 'run' });
    expect(res).toMatchObject({ partOfSpeech: 'động từ', ipa: null });
  });

  it('JSON sai schema: gọi lại một lần rồi thành công', async () => {
    const { service, llm } = setup({
      llm: new FakeLlm([{ kind: 'text', text: '{"meaning":"x"}' }]),
    });
    const res = await service.translate('u1', { text: 'resilient' });
    expect(res.meaning).toBe('kiên cường');
    expect(llm.calls).toHaveLength(2);
  });

  it('JSON sai schema hai lần → 502 TRANSLATE_FAILED, không lưu cache', async () => {
    const { service, llm, cache } = setup({
      llm: new FakeLlm([
        { kind: 'text', text: 'oops' },
        { kind: 'text', text: '{}' },
      ]),
    });
    expect(await errorOf(service.translate('u1', { text: 'x' }))).toEqual({
      status: 502,
      code: 'TRANSLATE_FAILED',
    });
    expect(llm.calls).toHaveLength(2);
    expect(cache.rows.size).toBe(0);
  });

  it('model từ chối → 502, không gọi lại', async () => {
    const { service, llm } = setup({
      llm: new FakeLlm([{ kind: 'refusal' }]),
    });
    expect(await errorOf(service.translate('u1', { text: 'x' }))).toEqual({
      status: 502,
      code: 'TRANSLATE_FAILED',
    });
    expect(llm.calls).toHaveLength(1);
  });

  it('lỗi gọi API → 502', async () => {
    const { service } = setup({
      llm: new FakeLlm([() => Promise.reject(new LlmFailedError('api_500'))]),
    });
    expect((await errorOf(service.translate('u1', { text: 'x' }))).code).toBe(
      'TRANSLATE_FAILED',
    );
  });

  it('quá hạn chung → 504 TRANSLATE_TIMEOUT (kể cả khi model không trả lời)', async () => {
    const { service } = setup({
      env: { TRANSLATE_DEADLINE_MS: '50' },
      llm: new FakeLlm([() => new Promise<LlmReply>(() => undefined)]),
    });
    const started = Date.now();
    expect(await errorOf(service.translate('u1', { text: 'x' }))).toEqual({
      status: 504,
      code: 'TRANSLATE_TIMEOUT',
    });
    expect(Date.now() - started).toBeLessThan(2000);
  });

  it('từ điển treo không làm chậm quá hạn chung', async () => {
    const dict = new FakeDictionary();
    dict.lookup = () => new Promise<DictionaryInfo | null>(() => undefined);
    const { service } = setup({ env: { TRANSLATE_DEADLINE_MS: '80' }, dict });
    const res = await service.translate('u1', { text: 'resilient' });
    expect(res).toMatchObject({ meaning: 'kiên cường', ipa: null });
  });

  it('chưa cấu hình khoá → 503 TRANSLATE_UNAVAILABLE; cache vẫn dùng được', async () => {
    const { service, llm } = setup({});
    await service.translate('u1', { text: 'resilient' });
    llm.ok = false;
    expect(await errorOf(service.translate('u1', { text: 'other' }))).toEqual({
      status: 503,
      code: 'TRANSLATE_UNAVAILABLE',
    });
    expect((await service.translate('u1', { text: 'resilient' })).meaning).toBe(
      'kiên cường',
    );
  });

  it('giới hạn lượt gọi model mỗi người / giờ; cache không tính lượt', async () => {
    const { service } = setup({ env: { TRANSLATE_RATE_LIMIT_PER_HOUR: '2' } });
    await service.translate('u1', { text: 'one' });
    await service.translate('u1', { text: 'two' });
    await service.translate('u1', { text: 'one' }); // cache
    expect(await errorOf(service.translate('u1', { text: 'three' }))).toEqual({
      status: 429,
      code: 'TRANSLATE_RATE_LIMIT',
    });
    await service.translate('u2', { text: 'three' }); // người khác vẫn được
  });
});
