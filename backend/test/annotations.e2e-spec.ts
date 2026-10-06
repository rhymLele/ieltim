// Integration test ghi chú trên tài liệu, Sổ từ, dịch nghĩa — chạy với Postgres thật.
// Chỉ chạy trên DB tên kết thúc bằng `_test` (test xoá sạch các bảng weekly và ghi chú), ví dụ:
//   DB_HOST=localhost DB_PORT=5432 DB_NAME=weekly_test WEEKLY_SCHEDULER=off npm run test:e2e -- annotations
// Model dịch và từ điển được thay bằng bản giả: test không gọi API ngoài.
import { INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { DataSource } from 'typeorm';
import { DictionaryLookup } from '../src/annotations/dictionary';
import type { DictionaryInfo } from '../src/annotations/domain/translation';
import {
  type LlmReply,
  type LlmTranslateInput,
  TranslatorLlm,
} from '../src/annotations/translator-llm';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';
import { WeeklySeedService } from '../src/weekly-docs/weekly-seed.service';

jest.setTimeout(60_000);
process.env.WEEKLY_WEEKS_AHEAD = '1';
process.env.TRANSLATE_RATE_LIMIT_PER_HOUR = '3';

const VALID =
  '{"meaning":"kiên cường","partOfSpeech":"tính từ","sentenceTranslation":"Cô ấy rất kiên cường."}';

class FakeLlm extends TranslatorLlm {
  calls: LlmTranslateInput[] = [];
  replies: LlmReply[] = [];
  ok = true;
  available() {
    return this.ok;
  }
  complete(input: LlmTranslateInput): Promise<LlmReply> {
    this.calls.push(input);
    return Promise.resolve(
      this.replies.shift() ?? { kind: 'text', text: VALID },
    );
  }
}

class FakeDictionary extends DictionaryLookup {
  terms: string[] = [];
  lookup(term: string): Promise<DictionaryInfo | null> {
    this.terms.push(term);
    return Promise.resolve({ ipa: '/rɪˈzɪlɪənt/', partOfSpeech: 'adjective' });
  }
}

describe('Ghi chú trên tài liệu, Sổ từ, dịch nghĩa (e2e)', () => {
  let app: INestApplication;
  let db: DataSource;
  const llm = new FakeLlm();
  const dict = new FakeDictionary();
  // a, b, r: ACTIVE; off: DISABLED; ghost: không có trong bảng users.
  const users = {
    a: randomUUID(),
    b: randomUUID(),
    r: randomUUID(),
    off: randomUUID(),
    ghost: randomUUID(),
  };
  type U = keyof typeof users;
  const tokens = {} as Record<U, string>;

  const http = () => request(app.getHttpServer());
  const as = (u: U, r: request.Test) =>
    r.set('Authorization', `Bearer ${tokens[u]}`);
  const doc = (u: U, docId = 'w12-doc1') => ({
    get: () => as(u, http().get(`/api/me/docs/${docId}/annotations`)),
    putHl: (id: string, body: object) =>
      as(u, http().put(`/api/me/docs/${docId}/highlights/${id}`)).send(body),
    delHl: (id: string) =>
      as(u, http().delete(`/api/me/docs/${docId}/highlights/${id}`)),
    putSlide: (key: string, body: object) =>
      as(u, http().put(`/api/me/docs/${docId}/slides/${key}/annotations`)).send(
        body,
      ),
  });
  const vocab = (u: U) => ({
    get: (p = '') => as(u, http().get(`/api/me/vocab${p}`)),
    post: (body: object) => as(u, http().post('/api/me/vocab')).send(body),
    patch: (id: string, body: object) =>
      as(u, http().patch(`/api/me/vocab/${id}`)).send(body),
    del: (id: string) => as(u, http().delete(`/api/me/vocab/${id}`)),
  });
  const translate = (u: U, body: object) =>
    as(u, http().post('/api/translate')).send(body);

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    })
      .overrideProvider(TranslatorLlm)
      .useValue(llm)
      .overrideProvider(DictionaryLookup)
      .useValue(dict)
      .compile();
    app = moduleRef.createNestApplication({ bodyParser: false });
    configureApp(app);
    await app.init();
    db = app.get(DataSource);
    const [{ name }] = await db.query('SELECT current_database() AS name');
    if (!String(name).endsWith('_test'))
      throw new Error(
        `Từ chối chạy test trên DB "${name}" (cần tên kết thúc bằng _test).`,
      );
    await db.query(
      'TRUNCATE text_highlights, slide_annotations, translation_cache, vocab_entries, weekly_documents, weekly_document_revisions, document_audit_logs, user_document_progress, learning_activities, weeks CASCADE',
    );
    await app.get(WeeklySeedService).seed();
    for (const [k, status] of [
      ['a', 'ACTIVE'],
      ['b', 'ACTIVE'],
      ['r', 'ACTIVE'],
      ['off', 'DISABLED'],
    ] as const)
      await db.query(
        `INSERT INTO users (id, display_name, role, status) VALUES ($1, $2, 'USER', $3)`,
        [users[k], `User ${k}`, status],
      );
    const jwt = app.get(JwtService, { strict: false });
    for (const [k, id] of Object.entries(users))
      tokens[k as U] = jwt.sign({ sub: id, role: 'USER', displayName: k });
  });

  afterAll(async () => {
    await db?.query('DELETE FROM users WHERE id = ANY($1)', [
      Object.values(users),
    ]);
    await app?.close();
  });

  describe('Quyền', () => {
    it('chưa đăng nhập → 401', async () => {
      await http().get('/api/me/docs/w12-doc1/annotations').expect(401);
    });

    it('tài khoản DISABLED hoặc không có trong users → 403 USER_INACTIVE', async () => {
      for (const u of ['off', 'ghost'] as const) {
        for (const res of [
          await doc(u).get(),
          await vocab(u).get(),
          await translate(u, { text: 'resilient' }),
        ]) {
          expect(res.status).toBe(403);
          expect(res.body.error).toBe('USER_INACTIVE');
        }
      }
    });

    it('tài liệu nháp / không tồn tại → 403 DOC_FORBIDDEN', async () => {
      for (const res of [
        await doc('a', 'w12-doc2').get(),
        await doc('a', 'w99-doc9').get(),
        await doc('a', 'w12-doc2').putHl(randomUUID(), {}),
        await doc('a', 'w12-doc2').putSlide('s1', {}),
      ]) {
        expect(res.status).toBe(403);
        expect(res.body.error).toBe('DOC_FORBIDDEN');
      }
    });
  });

  describe('Highlight', () => {
    const id = randomUUID();
    const body = {
      id: 'bỏ qua',
      blockKey: 's0-b1',
      quote: 'resilient',
      prefix: 'x'.repeat(10) + 'a'.repeat(32),
      suffix: 'b'.repeat(32) + 'y'.repeat(10),
      color: 'yellow',
      start: 4,
      end: 13,
      docVersion: 1,
    };
    let createdAt: string;

    it('ban đầu trống', async () => {
      const res = await doc('a').get().expect(200);
      expect(res.body.data).toEqual({ highlights: [], slides: {} });
    });

    it('PUT tạo mới; prefix giữ 32 ký tự cuối, suffix 32 ký tự đầu; id trong body bị bỏ qua', async () => {
      const res = await doc('a').putHl(id, body).expect(200);
      expect(res.body.data).toEqual({
        id,
        blockKey: 's0-b1',
        quote: 'resilient',
        prefix: 'a'.repeat(32),
        suffix: 'b'.repeat(32),
        color: 'yellow',
        start: 4,
        end: 13,
        docVersion: 1,
        createdAt: expect.any(String),
        updatedAt: expect.any(String),
      });
      createdAt = res.body.data.createdAt;
    });

    it('PUT lần nữa ghi đè (start / end bỏ trống thành null), giữ createdAt', async () => {
      const res = await doc('a')
        .putHl(id, {
          blockKey: 's0-b1',
          quote: 'resilient',
          color: 'pink',
          docVersion: 2,
        })
        .expect(200);
      expect(res.body.data).toMatchObject({
        color: 'pink',
        start: null,
        end: null,
        prefix: '',
        docVersion: 2,
        createdAt,
      });
      const list = await doc('a').get().expect(200);
      expect(list.body.data.highlights).toHaveLength(1);
      expect(list.body.data.highlights[0]).toMatchObject({ id, color: 'pink' });
    });

    it('dữ liệu sai → 400', async () => {
      expect(
        (await doc('a').putHl('khong-phai-uuid', body).expect(400)).body.error,
      ).toBe('HIGHLIGHT_ID_INVALID');
      await doc('a')
        .putHl(randomUUID(), { ...body, color: 'red' })
        .expect(400);
      await doc('a')
        .putHl(randomUUID(), { ...body, quote: 'q'.repeat(301) })
        .expect(400);
      await doc('a')
        .putHl(randomUUID(), { ...body, quote: '' })
        .expect(400);
      await doc('a')
        .putHl(randomUUID(), { ...body, docVersion: undefined })
        .expect(400);
      await doc('a').delHl('khong-phai-uuid').expect(400);
    });

    it('người khác không thấy, không sửa / xoá được highlight của tôi', async () => {
      expect((await doc('b').get().expect(200)).body.data.highlights).toEqual(
        [],
      );
      expect((await doc('b').putHl(id, body).expect(404)).body.error).toBe(
        'HIGHLIGHT_NOT_FOUND',
      );
      await doc('b').delHl(id).expect(204);
      expect(
        (await doc('a').get().expect(200)).body.data.highlights,
      ).toHaveLength(1);
    });

    it('DELETE xoá mềm, idempotent; PUT lại khôi phục', async () => {
      await doc('a').delHl(id).expect(204);
      await doc('a').delHl(id).expect(204);
      await doc('a').delHl(randomUUID()).expect(204);
      expect((await doc('a').get().expect(200)).body.data.highlights).toEqual(
        [],
      );
      const [row] = await db.query(
        'SELECT deleted_at FROM text_highlights WHERE id = $1',
        [id],
      );
      expect(row.deleted_at).not.toBeNull();
      const res = await doc('a').putHl(id, body).expect(200);
      expect(res.body.data.createdAt).toBe(createdAt);
      expect(
        (await doc('a').get().expect(200)).body.data.highlights,
      ).toHaveLength(1);
    });
  });

  describe('Nét vẽ trên slide', () => {
    const item = (n: number) => ({ type: 'pen', points: [n, n + 1] });

    it('rev: 0 → 1 → 2; sai rev → 409 kèm bản hiện tại', async () => {
      expect(
        (
          await doc('a')
            .putSlide('0-1', {
              data: { items: [item(1)] },
              rev: 0,
              docVersion: 1,
            })
            .expect(200)
        ).body.data,
      ).toEqual({ rev: 1 });
      expect(
        (
          await doc('a')
            .putSlide('0-1', {
              data: { items: [item(1), item(2)] },
              rev: 1,
              docVersion: 1,
            })
            .expect(200)
        ).body.data,
      ).toEqual({ rev: 2 });
      for (const rev of [1, 0, 5]) {
        const res = await doc('a')
          .putSlide('0-1', { data: { items: [] }, rev, docVersion: 1 })
          .expect(409);
        expect(res.body.error).toBe('ANNOTATION_CONFLICT');
        expect(res.body.data).toEqual({
          data: { items: [item(1), item(2)] },
          rev: 2,
        });
      }
    });

    it('slide chưa có gì mà gửi rev > 0 → 409 với rev 0', async () => {
      const res = await doc('a')
        .putSlide('s3', { data: { items: [] }, rev: 2, docVersion: 1 })
        .expect(409);
      expect(res.body.data).toEqual({ data: null, rev: 0 });
    });

    it('hai lần lưu song song cùng rev: chỉ một lần thành công', async () => {
      const save = (n: number) =>
        doc('a').putSlide('0-1', {
          data: { items: [item(n)] },
          rev: 2,
          docVersion: 1,
        });
      const results = await Promise.all([save(10), save(20)]);
      expect(results.map((r) => r.status).sort()).toEqual([200, 409]);
      const ok = results.find((r) => r.status === 200)!;
      expect(ok.body.data).toEqual({ rev: 3 });
    });

    it('xoá hết ({ items: [] }) vẫn giữ dòng, rev tăng; GET trả theo slideKey', async () => {
      await doc('a')
        .putSlide('0-1', { data: { items: [] }, rev: 3, docVersion: 2 })
        .expect(200);
      await doc('a')
        .putSlide('doc', { data: { items: [item(7)] }, rev: 0, docVersion: 2 })
        .expect(200);
      const res = await doc('a').get().expect(200);
      expect(res.body.data.slides).toEqual({
        '0-1': { data: { items: [] }, rev: 4, docVersion: 2 },
        doc: { data: { items: [item(7)] }, rev: 1, docVersion: 2 },
      });
      expect((await doc('b').get().expect(200)).body.data.slides).toEqual({});
    });

    it('mã slide / dữ liệu sai → 400', async () => {
      expect(
        (
          await doc('a')
            .putSlide('a.b', { data: { items: [] }, rev: 0, docVersion: 1 })
            .expect(400)
        ).body.error,
      ).toBe('SLIDE_KEY_INVALID');
      expect(
        (
          await doc('a')
            .putSlide('s9', { data: { lines: [] }, rev: 0, docVersion: 1 })
            .expect(400)
        ).body.error,
      ).toBe('ANNOTATION_INVALID');
      await doc('a')
        .putSlide('s9', { data: { items: [] }, rev: -1, docVersion: 1 })
        .expect(400);
    });

    it('dữ liệu > 256 KB → 413 ANNOTATION_TOO_LARGE; body > 320 KB → 413', async () => {
      const big = { items: ['x'.repeat(270 * 1024)] };
      const res = await doc('a')
        .putSlide('s9', { data: big, rev: 0, docVersion: 1 })
        .expect(413);
      expect(res.body.error).toBe('ANNOTATION_TOO_LARGE');
      const huge = { items: ['x'.repeat(400 * 1024)] };
      expect(
        (
          await doc('a')
            .putSlide('s9', { data: huge, rev: 0, docVersion: 1 })
            .expect(413)
        ).body.error,
      ).toBe('PAYLOAD_TOO_LARGE');
      // 200 KB vẫn lưu được (lớn hơn giới hạn 100 KB mặc định của Express).
      await doc('a')
        .putSlide('s9', {
          data: { items: ['x'.repeat(200 * 1024)] },
          rev: 0,
          docVersion: 1,
        })
        .expect(200);
    });
  });

  describe('Sổ từ', () => {
    let first: { id: string };
    let second: { id: string };

    it('thêm từ (mặc định Sổ chung); trùng trong cùng sổ → 409 VOCAB_EXISTS kèm bản đã có', async () => {
      const res = await vocab('a')
        .post({
          text: '  Resilient ',
          meaning: 'kiên cường',
          ipa: '/rɪˈzɪlɪənt/',
          partOfSpeech: 'tính từ',
          sourceDocId: 'w12-doc1',
          sourceBlockKey: 's0-b1',
        })
        .expect(201);
      expect(res.body.data).toEqual({
        id: expect.any(String),
        text: 'Resilient',
        meaning: 'kiên cường',
        ipa: '/rɪˈzɪlɪənt/',
        example: null,
        partOfSpeech: 'tính từ',
        deck: 'Sổ chung',
        sourceDocId: 'w12-doc1',
        sourceBlockKey: 's0-b1',
        createdAt: expect.any(String),
      });
      first = res.body.data;
      const dup = await vocab('a')
        .post({ text: 'resilient ', meaning: 'khác' })
        .expect(409);
      expect(dup.body.error).toBe('VOCAB_EXISTS');
      expect(dup.body.data).toEqual(first);
    });

    it('cùng từ ở sổ khác thì được; dữ liệu sai → 400', async () => {
      const res = await vocab('a')
        .post({ text: 'resilient', deck: ' IELTS  Writing ' })
        .expect(201);
      expect(res.body.data).toMatchObject({
        deck: 'IELTS Writing',
        meaning: '',
      });
      second = res.body.data;
      await vocab('a').post({ text: '   ' }).expect(400);
      await vocab('a')
        .post({ text: 'w'.repeat(121) })
        .expect(400);
      await vocab('a')
        .post({ text: 'ok', meaning: 'm'.repeat(501) })
        .expect(400);
    });

    it('danh sách mới nhất trước, lọc theo sổ / từ khoá', async () => {
      const all = await vocab('a').get().expect(200);
      expect(all.body.data.map((v: { id: string }) => v.id)).toEqual([
        second.id,
        first.id,
      ]);
      expect(all.body.count).toBe(2);
      const byDeck = await vocab('a')
        .get(`?deck=${encodeURIComponent('IELTS Writing')}`)
        .expect(200);
      expect(byDeck.body.data.map((v: { id: string }) => v.id)).toEqual([
        second.id,
      ]);
      const byMeaning = await vocab('a')
        .get(`?q=${encodeURIComponent('kiên')}`)
        .expect(200);
      expect(byMeaning.body.data.map((v: { id: string }) => v.id)).toEqual([
        first.id,
      ]);
      expect(
        (await vocab('a').get('?q=RESIL').expect(200)).body.data,
      ).toHaveLength(2);
      expect((await vocab('a').get('?q=%25').expect(200)).body.data).toEqual(
        [],
      );
      expect((await vocab('b').get().expect(200)).body.data).toEqual([]);
    });

    it('exists (mọi sổ) và danh sách sổ (dùng gần nhất trước, luôn có Sổ chung)', async () => {
      expect(
        (await vocab('a').get('/exists?text=%20RESILIENT%20').expect(200)).body
          .data,
      ).toBe(true);
      expect(
        (await vocab('a').get('/exists?text=nope').expect(200)).body.data,
      ).toBe(false);
      expect((await vocab('a').get('/exists').expect(200)).body.data).toBe(
        false,
      );
      expect((await vocab('a').get('/decks').expect(200)).body.data).toEqual([
        'IELTS Writing',
        'Sổ chung',
      ]);
      expect((await vocab('b').get('/decks').expect(200)).body.data).toEqual([
        'Sổ chung',
      ]);
    });

    it('"Lưu từ vựng của tài liệu" (weekly) vẫn chạy, ghi vào Sổ chung', async () => {
      const save = () =>
        as('a', http().post('/api/weekly/vocab/from-document')).send({
          documentId: 'w12-doc1',
        });
      const res = await save().expect(201);
      expect(res.body.data.added).toBe(3);
      expect((await save().expect(201)).body.data.added).toBe(0);
      const [{ n }] = await db.query(
        `SELECT COUNT(*)::int AS n FROM vocab_entries WHERE user_id = $1 AND deck = 'Sổ chung'`,
        [users.a],
      );
      expect(n).toBe(4);
      expect((await vocab('a').get('/decks').expect(200)).body.data).toEqual([
        'Sổ chung',
        'IELTS Writing',
      ]);
    });

    it('sửa: trùng từ trong sổ đích → 409 kèm bản kia; của người khác → 404', async () => {
      const dup = await vocab('a')
        .patch(first.id, { deck: 'IELTS Writing' })
        .expect(409);
      expect(dup.body.error).toBe('VOCAB_EXISTS');
      expect(dup.body.data.id).toBe(second.id);
      expect(
        (await vocab('b').patch(first.id, { meaning: 'x' }).expect(404)).body
          .error,
      ).toBe('VOCAB_NOT_FOUND');
      await vocab('a').patch('abc', { meaning: 'x' }).expect(404);
      const res = await vocab('a')
        .patch(first.id, {
          text: 'Resilience',
          meaning: 'sự kiên cường',
          example: 'Her resilience is admirable.',
        })
        .expect(200);
      expect(res.body.data).toMatchObject({
        id: first.id,
        text: 'Resilience',
        meaning: 'sự kiên cường',
        example: 'Her resilience is admirable.',
        deck: 'Sổ chung',
        ipa: '/rɪˈzɪlɪənt/',
      });
      expect(
        (await vocab('a').get('/exists?text=resilience').expect(200)).body.data,
      ).toBe(true);
      const cleared = await vocab('a')
        .patch(first.id, { example: null })
        .expect(200);
      expect(cleared.body.data.example).toBeNull();
      // Màn Sổ từ dùng từ loại làm tag: sửa được, null để xoá.
      const tagged = await vocab('a')
        .patch(first.id, { partOfSpeech: 'idiom' })
        .expect(200);
      expect(tagged.body.data.partOfSpeech).toBe('idiom');
      expect(
        (await vocab('a').patch(first.id, { partOfSpeech: null }).expect(200))
          .body.data.partOfSpeech,
      ).toBeNull();
    });

    it('xoá: của người khác → 404, của tôi → 204, xoá lại → 404', async () => {
      await vocab('b').del(first.id).expect(404);
      await vocab('a').del(first.id).expect(204);
      expect((await vocab('a').del(first.id).expect(404)).body.error).toBe(
        'VOCAB_NOT_FOUND',
      );
    });
  });

  describe('Dịch nghĩa', () => {
    it('gọi model + từ điển; hỏi lại (khác hoa thường) lấy từ cache', async () => {
      const res = await translate('a', {
        text: 'resilient',
        sentence: 'She is resilient.',
      }).expect(200);
      expect(res.body.data).toEqual({
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
      const again = await translate('b', {
        text: ' Resilient ',
        sentence: 'she is RESILIENT.',
      }).expect(200);
      expect(again.body.data).toEqual({ ...res.body.data, text: 'Resilient' });
      expect(llm.calls).toHaveLength(1);
    });

    it('JSON sai schema hai lần → 502 TRANSLATE_FAILED', async () => {
      llm.replies = [
        { kind: 'text', text: 'không phải json' },
        { kind: 'text', text: '{"meaning":"x"}' },
      ];
      const before = llm.calls.length;
      const res = await translate('a', { text: 'take part' }).expect(502);
      expect(res.body.error).toBe('TRANSLATE_FAILED');
      expect(llm.calls.length - before).toBe(2);
    });

    it('chưa cấu hình khoá → 503 TRANSLATE_UNAVAILABLE', async () => {
      llm.ok = false;
      try {
        const res = await translate('a', { text: 'other' }).expect(503);
        expect(res.body).toMatchObject({
          error: 'TRANSLATE_UNAVAILABLE',
          message: 'Chưa cấu hình dịch nghĩa.',
        });
      } finally {
        llm.ok = true;
      }
    });

    it('quá giới hạn lượt / giờ → 429 TRANSLATE_RATE_LIMIT; cache vẫn trả', async () => {
      for (const text of ['one', 'two', 'three'])
        await translate('r', { text }).expect(200);
      expect(
        (await translate('r', { text: 'four' }).expect(429)).body.error,
      ).toBe('TRANSLATE_RATE_LIMIT');
      await translate('r', { text: 'one' }).expect(200);
    });

    it('dữ liệu sai → 400', async () => {
      await translate('a', { text: '  ' }).expect(400);
      await translate('a', { text: 'x'.repeat(301) }).expect(400);
      await translate('a', { text: 'x', sentence: 's'.repeat(601) }).expect(
        400,
      );
      await translate('a', { text: 'x', from: 'fr' }).expect(400);
    });
  });
});
