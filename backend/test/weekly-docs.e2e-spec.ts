// Integration test Tài liệu theo tuần, chạy với Postgres thật.
// Chỉ chạy trên DB tên kết thúc bằng `_test` (test xoá sạch các bảng weekly), ví dụ:
//   DB_HOST=localhost DB_PORT=5432 DB_NAME=weekly_test npx jest --config test/jest-e2e.json weekly-docs --runInBand
import { INestApplication } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { Test } from '@nestjs/testing';
import { randomUUID } from 'crypto';
import request from 'supertest';
import { DataSource } from 'typeorm';
import { AppModule } from '../src/app.module';
import { configureApp } from '../src/app.setup';
import { addDays, vnCalendarWeek } from '../src/weekly-docs/domain/vn-time';
import { LearnerService } from '../src/weekly-docs/learner.service';
import { PublishSchedulerService } from '../src/weekly-docs/publish-scheduler.service';
import { WeeklySeedService } from '../src/weekly-docs/weekly-seed.service';

jest.setTimeout(60_000);

describe('Tài liệu theo tuần (e2e)', () => {
  let app: INestApplication;
  let db: DataSource;
  let adminToken: string;
  const users = { a: randomUUID(), b: randomUUID(), c: randomUUID() };
  const tokens: Record<string, string> = {};

  const http = () => request(app.getHttpServer());
  const asAdmin = (r: request.Test) =>
    r.set('Authorization', `Bearer ${adminToken}`);
  const as = (u: keyof typeof users, r: request.Test) =>
    r.set('Authorization', `Bearer ${tokens[u]}`);
  const admin = {
    get: (p: string) => asAdmin(http().get(`/api/admin/weekly${p}`)),
    post: (p: string, body?: object) =>
      asAdmin(http().post(`/api/admin/weekly${p}`)).send(body ?? {}),
    put: (p: string, body: object) =>
      asAdmin(http().put(`/api/admin/weekly${p}`)).send(body),
    patch: (p: string, body: object) =>
      asAdmin(http().patch(`/api/admin/weekly${p}`)).send(body),
    del: (p: string) => asAdmin(http().delete(`/api/admin/weekly${p}`)),
  };
  const user = (u: keyof typeof users) => ({
    get: (p: string) => as(u, http().get(`/api/weekly${p}`)),
    post: (p: string, body?: object) =>
      as(u, http().post(`/api/weekly${p}`)).send(body ?? {}),
    put: (p: string, body: object) =>
      as(u, http().put(`/api/weekly${p}`)).send(body),
  });

  beforeAll(async () => {
    const moduleRef = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
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
      'TRUNCATE weekly_documents, weekly_document_revisions, document_audit_logs, user_document_progress, learning_activities, vocab_entries, weeks CASCADE',
    );
    await app.get(WeeklySeedService).seed();
    const jwt = app.get(JwtService, { strict: false });
    adminToken = jwt.sign({
      sub: randomUUID(),
      role: 'ADMIN',
      displayName: 'Minh',
    });
    for (const [k, id] of Object.entries(users))
      tokens[k] = jwt.sign({ sub: id, role: 'USER', displayName: `User ${k}` });
  });

  afterAll(async () => {
    await app?.close();
  });

  describe('Tuần', () => {
    it('seed: Tuần 10–13, 13 còn khoá; gợi ý tuần tiếp theo', async () => {
      const res = await admin.get('/weeks').expect(200);
      expect(
        res.body.data.data.map((w: { number: number; state: string }) => [
          w.number,
          w.state,
        ]),
      ).toEqual([
        [10, 'open'],
        [11, 'open'],
        [12, 'open'],
        [13, 'locked'],
      ]);
      expect(res.body.data.suggestion.number).toBe(14);
    });

    it('tạo tuần: phải là thứ Hai, không trùng số, không chồng ngày', async () => {
      const monday14 = addDays(vnCalendarWeek().monday, 14);
      expect(
        (
          await admin
            .post('/weeks', { number: 14, startDate: addDays(monday14, 1) })
            .expect(400)
        ).body.error,
      ).toBe('WEEK_START_NOT_MONDAY');
      expect(
        (
          await admin
            .post('/weeks', { number: 12, startDate: addDays(monday14, 7) })
            .expect(409)
        ).body.error,
      ).toBe('WEEK_NUMBER_TAKEN');
      expect(
        (
          await admin
            .post('/weeks', { number: 99, startDate: vnCalendarWeek().monday })
            .expect(409)
        ).body.error,
      ).toBe('WEEK_OVERLAP');
      const created = await admin
        .post('/weeks', { number: 14, startDate: monday14, stageGoal: 3 })
        .expect(201);
      expect(created.body.data).toMatchObject({
        number: 14,
        endDate: addDays(monday14, 6),
        stageGoal: 3,
        state: 'locked',
      });
      expect((await admin.del('/weeks/12').expect(409)).body.error).toBe(
        'WEEK_NOT_EMPTY',
      );
      await admin.del('/weeks/14').expect(200);
    });

    it('người dùng: tuần khoá trả 403', async () => {
      expect(
        (await user('a').get('/weeks/13/documents').expect(403)).body.error,
      ).toBe('WEEK_LOCKED');
    });
  });

  describe('Luồng admin: template → lưu → kiểm tra → xuất bản → người dùng thấy', () => {
    let version: number;

    it('7 lựa chọn template (5 khung + JSON + HTML)', async () => {
      const res = await admin.get('/templates').expect(200);
      expect(res.body.data.map((t: { id: string }) => t.id)).toEqual([
        'reading-lesson',
        'writing-task2',
        'vocab-set',
        'speaking-part2',
        'blank',
        'import',
        'html',
      ]);
    });

    it('tạo nháp từ template: order = lớn nhất + 1, trùng order → 409', async () => {
      const res = await admin
        .post('/documents', {
          week: 12,
          title: 'Reading: True/False/Not Given',
          template: 'reading-lesson',
        })
        .expect(201);
      expect(res.body.data).toMatchObject({
        id: 'w12-doc3',
        order: 3,
        status: 'draft',
        version: 1,
        sectionCount: 4,
        skill: 'reading',
      });
      expect(res.body.data.validation.valid).toBe(true);
      expect(res.body.data.validation.warnings.length).toBeGreaterThan(0); // còn chỗ trống [ … ]
      const taken = await admin
        .post('/documents', {
          week: 12,
          order: 3,
          title: 'Trùng số',
          template: 'blank',
        })
        .expect(409);
      expect(taken.body).toMatchObject({
        error: 'DOC_ORDER_TAKEN',
        message: 'Tuần 12 đã có Tài liệu 3.',
      });
      expect(taken.body.data.suggestion).toBe(4);
      version = res.body.data.version;
    });

    it('lưu nháp tăng version; id / week / order trong content bị ghi đè theo bản ghi', async () => {
      const cur = (await admin.get('/documents/w12-doc3').expect(200)).body
        .data;
      const content = {
        ...cur.content,
        id: 'sai',
        week: 99,
        title: 'Reading: TFNG',
      };
      const res = await admin
        .put('/documents/w12-doc3', { content, version })
        .expect(200);
      expect(res.body.data).toMatchObject({
        title: 'Reading: TFNG',
        version: version + 1,
      });
      expect(res.body.data.content).toMatchObject({
        id: 'w12-doc3',
        week: 12,
        order: 3,
      });
      version = res.body.data.version;
    });

    it('lưu với version cũ → 409 kèm bản hiện tại và tên người sửa', async () => {
      const res = await admin
        .put('/documents/w12-doc3', {
          content: { title: 'x' },
          version: version - 1,
        })
        .expect(409);
      expect(res.body.error).toBe('DOC_VERSION_CONFLICT');
      expect(res.body.message).toMatch(
        /^Minh vừa sửa tài liệu này lúc \d\d:\d\d\.$/,
      );
      expect(res.body.data.current).toMatchObject({
        id: 'w12-doc3',
        version,
        title: 'Reading: TFNG',
      });
    });

    it('validate chạy thử không lưu', async () => {
      const res = await admin
        .post('/documents/validate', { content: '{"title": ' })
        .expect(201);
      expect(res.body.data.valid).toBe(false);
      expect(res.body.data.errors[0].message).toMatch(/^Lỗi cú pháp JSON/);
    });

    it('xuất bản khi còn lỗi → 422 kèm danh sách lỗi', async () => {
      const draft = (
        await admin
          .post('/documents', { week: 12, title: 'Còn lỗi', template: 'blank' })
          .expect(201)
      ).body.data;
      const content = {
        ...draft.content,
        sections: [
          {
            title: 'S',
            blocks: [
              { type: 'quiz', question: 'Q', options: ['a', 'b'], answer: 5 },
            ],
          },
        ],
      };
      await admin
        .put(`/documents/${draft.id}`, { content, version: draft.version })
        .expect(200);
      const res = await admin
        .post(`/documents/${draft.id}/publish`)
        .expect(422);
      expect(res.body).toMatchObject({
        error: 'DOC_INVALID_CONTENT',
        message: 'Tài liệu còn 1 lỗi cần sửa trước khi xuất bản.',
      });
      expect(res.body.data.errors).toEqual([
        { path: 'sections[0].blocks[0].answer', message: 'phải nằm trong 0…1' },
      ]);
      await admin.del(`/documents/${draft.id}`).expect(200);
    });

    it('xuất bản → người dùng thấy trong tuần; nháp và tài liệu chưa xuất bản thì không', async () => {
      const res = await admin.post('/documents/w12-doc3/publish').expect(201);
      expect(res.body.data).toMatchObject({
        status: 'published',
        everPublished: true,
      });
      const list = await user('a').get('/weeks/12/documents').expect(200);
      expect(list.body.data.map((d: { id: string }) => d.id)).toEqual([
        'w12-doc1',
        'w12-doc3',
      ]);
      expect(list.body.data[0]).not.toHaveProperty('content');
      expect(
        (await user('a').get('/documents/w12-doc2').expect(404)).body.error,
      ).toBe('DOC_NOT_FOUND');
    });

    it('sửa tài liệu đã xuất bản: vào bản nháp sửa đổi, người dùng chỉ thấy sau "Cập nhật bản phát hành"', async () => {
      const cur = (await admin.get('/documents/w12-doc3').expect(200)).body
        .data;
      const content = {
        ...cur.content,
        title: 'Reading: TFNG (v2)',
        sections: cur.content.sections.slice(0, 3),
      };
      const saved = await admin
        .put('/documents/w12-doc3', { content, version: cur.version })
        .expect(200);
      expect(saved.body.data).toMatchObject({
        hasRevisionDraft: true,
        source: 'draft',
        title: 'Reading: TFNG',
        draftSectionCount: 3,
      });
      expect(
        (await user('a').get('/documents/w12-doc3').expect(200)).body.data
          .title,
      ).toBe('Reading: TFNG');
      const released = await admin
        .post('/documents/w12-doc3/release')
        .expect(201);
      expect(released.body.data).toMatchObject({
        hasRevisionDraft: false,
        title: 'Reading: TFNG (v2)',
        sectionCount: 3,
        version: saved.body.data.version + 1,
      });
      expect(
        (await user('a').get('/documents/w12-doc3').expect(200)).body.data
          .title,
      ).toBe('Reading: TFNG (v2)');
      const audit = await admin.get('/documents/w12-doc3/audit').expect(200);
      expect(audit.body.data.map((a: { action: string }) => a.action)).toEqual(
        expect.arrayContaining(['create', 'update', 'publish', 'release']),
      );
    });

    it('lịch sử phiên bản: khôi phục phiên bản cũ vào bản nháp', async () => {
      const revs = (
        await admin.get('/documents/w12-doc3/revisions').expect(200)
      ).body.data;
      const created = revs.find((r: { note: string }) => r.note === 'create');
      const res = await admin
        .post(`/documents/w12-doc3/revisions/${created.id}/restore`)
        .expect(201);
      expect(res.body.data).toMatchObject({
        hasRevisionDraft: true,
        source: 'draft',
      });
      expect(res.body.data.content.title).toBe('Reading: True/False/Not Given');
      await admin.del('/documents/w12-doc3/revision-draft').expect(200);
    });

    it('export rồi import lại cho ra nội dung y hệt', async () => {
      const exported = await admin
        .get('/documents/w12-doc1/export')
        .expect(200);
      expect(exported.headers['content-disposition']).toBe(
        'attachment; filename="w12-doc1.json"',
      );
      const json = JSON.parse(exported.text);
      const imported = await asAdmin(
        http().post('/api/admin/weekly/documents/import'),
      )
        .field('week', '11')
        .attach('file', Buffer.from(exported.text), 'w12-doc1.json')
        .expect(201);
      const doc = imported.body.data.document;
      expect(doc.id).toBe('w11-doc1'); // theo `order` trong file
      expect({ ...doc.content, id: 0, week: 0, order: 0 }).toEqual({
        ...json,
        id: 0,
        week: 0,
        order: 0,
      });
      const bad = await asAdmin(
        http().post('/api/admin/weekly/documents/import'),
      )
        .field('week', '11')
        .attach('file', Buffer.from('{ khong phai json'), 'x.json')
        .expect(422);
      expect(bad.body.error).toBe('IMPORT_PARSE_ERROR');
    });
  });

  describe('Vòng đời: hẹn giờ, gỡ, khôi phục, xoá, nhân bản, sắp xếp', () => {
    it('hẹn giờ: < 5 phút → 422; tới giờ job xuất bản; còn lỗi thì về nháp + nhật ký', async () => {
      const ok = (
        await admin
          .post('/documents', { week: 12, title: 'Hẹn giờ', template: 'blank' })
          .expect(201)
      ).body.data;
      const fixed = {
        ...ok.content,
        sections: [
          { title: 'S', blocks: [{ type: 'heading', text: 'Xin chào' }] },
        ],
      };
      await admin
        .put(`/documents/${ok.id}`, { content: fixed, version: ok.version })
        .expect(200);
      const soon = new Date(Date.now() + 60_000).toISOString();
      expect(
        (
          await admin
            .post(`/documents/${ok.id}/publish`, { publishAt: soon })
            .expect(422)
        ).body.error,
      ).toBe('DOC_SCHEDULE_PAST');
      const later = new Date(Date.now() + 3_600_000).toISOString();
      expect(
        (
          await admin
            .post(`/documents/${ok.id}/publish`, { publishAt: later })
            .expect(201)
        ).body.data.status,
      ).toBe('scheduled');

      const bad = (
        await admin
          .post('/documents', {
            week: 12,
            title: 'Hẹn giờ lỗi',
            template: 'blank',
          })
          .expect(201)
      ).body.data;
      await admin
        .put(`/documents/${bad.id}`, { content: fixed, version: bad.version })
        .expect(200);
      await admin
        .post(`/documents/${bad.id}/schedule`, { publishAt: later })
        .expect(201);
      // Sửa tài liệu đã hẹn: sửa trực tiếp, giữ lịch — lần này làm hỏng nội dung.
      const cur = (await admin.get(`/documents/${bad.id}`).expect(200)).body
        .data;
      await admin
        .put(`/documents/${bad.id}`, {
          content: { ...cur.content, sections: [] },
          version: cur.version,
        })
        .expect(200);

      await db.query(
        `UPDATE weekly_documents SET publish_at = now() - interval '1 minute' WHERE id IN ($1, $2)`,
        [ok.id, bad.id],
      );
      await app.get(PublishSchedulerService).tick();
      expect((await admin.get(`/documents/${ok.id}`)).body.data.status).toBe(
        'published',
      );
      expect((await admin.get(`/documents/${bad.id}`)).body.data.status).toBe(
        'draft',
      );
      const audit = (await admin.get(`/documents/${bad.id}/audit`)).body.data;
      expect(audit[0]).toMatchObject({
        action: 'schedule_failed',
        fromStatus: 'scheduled',
        toStatus: 'draft',
      });
      expect(audit[0].note).toMatch(/vì còn 1 lỗi$/);
      // Chạy lại job không đổi gì (idempotent).
      await app.get(PublishSchedulerService).tick();
      expect((await admin.get(`/documents/${ok.id}`)).body.data.status).toBe(
        'published',
      );
    });

    it('không xoá được tài liệu đã xuất bản; gỡ → người dùng không thấy, tiến độ còn; khôi phục → nháp', async () => {
      await user('c')
        .put('/documents/w12-doc1/progress', { sectionIndex: 1 })
        .expect(200);
      expect(
        (await admin.del('/documents/w12-doc1').expect(409)).body.error,
      ).toBe('DOC_DELETE_NOT_ALLOWED');
      await admin
        .post('/documents/w12-doc1/unpublish', { reason: 'Sửa lỗi chính tả' })
        .expect(201);
      const gone = await user('c')
        .put('/documents/w12-doc1/progress', { sectionIndex: 2 })
        .expect(404);
      expect(gone.body).toMatchObject({
        error: 'DOC_UNPUBLISHED',
        message: 'Tài liệu này đã được gỡ.',
      });
      expect(
        (
          await admin
            .put('/documents/w12-doc1', { content: {}, version: 1 })
            .expect(409)
        ).body.error,
      ).toBe('DOC_EDIT_ARCHIVED');
      expect(
        (await admin.post('/documents/w12-doc1/restore').expect(201)).body.data
          .status,
      ).toBe('draft');
      await admin.post('/documents/w12-doc1/publish').expect(201);
      expect(
        (await user('c').get('/documents/w12-doc1').expect(200)).body.data
          .progress.seenSections,
      ).toEqual([1]);
    });

    it('xoá nháp (xoá mềm) và hoàn tác', async () => {
      const d = (
        await admin
          .post('/documents', { week: 12, title: 'Sẽ xoá', template: 'blank' })
          .expect(201)
      ).body.data;
      await admin.del(`/documents/${d.id}`).expect(200);
      await admin.get(`/documents/${d.id}`).expect(404);
      expect(
        (await admin.post(`/documents/${d.id}/undelete`).expect(201)).body.data
          .id,
      ).toBe(d.id);
      await admin.del(`/documents/${d.id}`).expect(200);
    });

    it('nhân bản sang tuần khác: id mới, tiêu đề "(bản sao)", là nháp', async () => {
      const res = await admin
        .post('/documents/w12-doc1/duplicate', { targetWeek: 13 })
        .expect(201);
      expect(res.body.data).toMatchObject({
        id: 'w13-doc1',
        week: 13,
        status: 'draft',
        title: 'Reading: Matching Headings (bản sao)',
      });
    });

    it('sắp xếp lại: đổi số = đổi id; tài liệu đã xuất bản thì khoá', async () => {
      await admin
        .post('/documents', { week: 13, title: 'Thứ hai', template: 'blank' })
        .expect(201);
      const res = await admin.put('/weeks/13/documents/order', [
        { id: 'w13-doc1', order: 2 },
        { id: 'w13-doc2', order: 1 },
      ]);
      expect(res.status).toBe(200);
      expect(
        res.body.data.map((d: { id: string; title: string }) => [
          d.id,
          d.title,
        ]),
      ).toEqual([
        ['w13-doc1', 'Thứ hai'],
        ['w13-doc2', 'Reading: Matching Headings (bản sao)'],
      ]);
      expect(
        (await admin.get('/documents/w13-doc2')).body.data.content,
      ).toMatchObject({ id: 'w13-doc2', order: 2 });
      const locked = await admin
        .put('/weeks/12/documents/order', [{ id: 'w12-doc1', order: 9 }])
        .expect(409);
      expect(locked.body.error).toBe('DOC_MOVE_PUBLISHED');
    });
  });

  describe('Người dùng: đọc, trắc nghiệm, hoàn thành, chặng Vũ Môn, streak, Sổ từ', () => {
    it('đọc tài liệu: content + progress, ETag → 304', async () => {
      const res = await user('a').get('/documents/w12-doc1').expect(200);
      expect(res.body.data).toMatchObject({
        id: 'w12-doc1',
        sectionCount: 4,
        progress: { lastSection: 0, seenCount: 0, completed: false },
      });
      expect(res.body.data.content.sections).toHaveLength(4);
      const etag = res.headers.etag;
      await user('a')
        .get('/documents/w12-doc1')
        .set('If-None-Match', etag)
        .expect(304);
      await user('a')
        .put('/documents/w12-doc1/progress', { sectionIndex: 0 })
        .expect(200);
      await user('a')
        .get('/documents/w12-doc1')
        .set('If-None-Match', etag)
        .expect(200); // tiến độ đổi → ETag đổi
    });

    it('tiến độ: idempotent, section ngoài phạm vi → 422', async () => {
      await user('a')
        .put('/documents/w12-doc1/progress', {
          sectionIndex: 1,
          viewMode: 'doc',
        })
        .expect(200);
      const res = await user('a')
        .put('/documents/w12-doc1/progress', { sectionIndex: 1 })
        .expect(200);
      expect(res.body.data).toMatchObject({
        lastSection: 1,
        seenCount: 2,
        seenSections: [0, 1],
        viewMode: 'doc',
      });
      expect(
        (
          await user('a')
            .put('/documents/w12-doc1/progress', { sectionIndex: 4 })
            .expect(422)
        ).body.error,
      ).toBe('SECTION_OUT_OF_RANGE');
    });

    it('trắc nghiệm: trả đúng/sai + giải thích, giữ firstCorrect của lần đầu', async () => {
      const wrong = await user('a')
        .post('/documents/w12-doc1/quiz-answers', {
          blockKey: '2-1',
          option: 0,
        })
        .expect(201);
      expect(wrong.body.data).toMatchObject({ correct: false, answer: 1 });
      expect(wrong.body.data.explain).toMatch(/^Đoạn văn nêu/);
      await user('a')
        .post('/documents/w12-doc1/quiz-answers', {
          blockKey: '2-1',
          option: 1,
        })
        .expect(201);
      const doc = await user('a').get('/documents/w12-doc1').expect(200);
      expect(doc.body.data.progress.quizAnswers).toEqual({
        '2-1': { option: 1, firstCorrect: false },
      });
      await user('a')
        .post('/documents/w12-doc1/quiz-answers', {
          blockKey: '0-0',
          option: 0,
        })
        .expect(404);
    });

    it('hoàn thành: idempotent; justPassedGate chỉ ở lần chạm mục tiêu đầu tiên', async () => {
      await admin.patch('/weeks/12', { stageGoal: 2 }).expect(200);
      const first = await user('b')
        .post('/documents/w12-doc1/complete')
        .expect(201);
      expect(first.body.data).toEqual({
        completedNow: true,
        weekStage: {
          done: 1,
          goal: 2,
          passedGate: false,
          justPassedGate: false,
        },
        streak: 1,
      });
      const second = await user('b')
        .post('/documents/w12-doc3/complete')
        .expect(201);
      expect(second.body.data.weekStage).toEqual({
        done: 2,
        goal: 2,
        passedGate: true,
        justPassedGate: true,
      });
      const again = await user('b')
        .post('/documents/w12-doc3/complete')
        .expect(201);
      expect(again.body.data).toMatchObject({
        completedNow: false,
        weekStage: { done: 2, passedGate: true, justPassedGate: false },
      });
      const weeks = await user('b').get('/weeks').expect(200);
      expect(
        weeks.body.data.data.find((w: { number: number }) => w.number === 12),
      ).toMatchObject({ docDone: 2, state: 'open' });
      await admin.patch('/weeks/12', { stageGoal: 5 }).expect(200);
    });

    it('lưu từ vựng: bỏ trùng theo word_norm', async () => {
      const first = await user('a')
        .post('/vocab/from-document', { documentId: 'w12-doc1' })
        .expect(201);
      expect(first.body.data).toEqual({ added: 3, existed: 0, total: 3 });
      const again = await user('a')
        .post('/vocab/from-document', { documentId: 'w12-doc1' })
        .expect(201);
      expect(again.body.data).toEqual({ added: 0, existed: 3, total: 3 });
      const summary = await user('a').get('/me/summary').expect(200);
      expect(summary.body.data).toMatchObject({
        savedWords: 3,
        wordsLearnedThisWeek: 3,
        weekStage: { done: 0, goal: 5 },
      });
    });

    it('streak qua mốc nửa đêm giờ Việt Nam', async () => {
      const learner = app.get(LearnerService);
      const uid = randomUUID();
      const add = (iso: string) =>
        db.query(
          `INSERT INTO learning_activities (user_id, type, occurred_at) VALUES ($1, 'quiz_answer', $2)`,
          [uid, iso],
        );
      await add('2026-10-03T17:30:00Z'); // 04/10 00:30 VN
      await add('2026-10-04T16:59:00Z'); // 04/10 23:59 VN — cùng ngày
      expect(await learner.streak(uid, new Date('2026-10-04T20:00:00Z'))).toBe(
        1,
      ); // 05/10 03:00 VN, hôm nay chưa học
      await add('2026-10-04T17:01:00Z'); // 05/10 00:01 VN
      expect(await learner.streak(uid, new Date('2026-10-04T20:00:00Z'))).toBe(
        2,
      );
      expect(await learner.streak(uid, new Date('2026-10-06T18:00:00Z'))).toBe(
        0,
      ); // 07/10: bỏ ngày 06/10
    });
  });

  describe('Tài liệu HTML (file 9)', () => {
    const html = (bytes: number) =>
      `<!doctype html><html><head><title>Mẫu</title></head><body><p>${'a'.repeat(bytes)}</p></body></html>`;
    let id: string;

    it('tạo với body lớn (≈ 4,5 MB) qua API admin; danh sách không trả html, chi tiết thì có', async () => {
      const res = await admin
        .post('/documents', {
          week: 12,
          title: 'Collocations chủ đề Môi trường',
          template: 'html',
          skill: 'vocabulary',
          html: html(4_500_000),
          htmlFileName: 'mau.html',
        })
        .expect(201);
      id = res.body.data.id;
      expect(res.body.data).toMatchObject({
        week: 12,
        isHtml: true,
        sectionCount: 0,
        htmlFileName: 'mau.html',
        status: 'draft',
      });
      expect(res.body.data.htmlSize).toBeGreaterThan(4_500_000);
      expect(res.body.data.content.html.length).toBeGreaterThan(4_500_000);
      expect(res.body.data.content.sections).toEqual([]);
      expect(res.body.data.validation).toEqual({
        valid: true,
        errors: [],
        warnings: [],
      });

      const list = await admin.get('/documents?week=12').expect(200);
      const row = list.body.data.data.find((d: { id: string }) => d.id === id);
      expect(row).toMatchObject({ isHtml: true, htmlFileName: 'mau.html' });
      expect(row).not.toHaveProperty('content');
      expect(JSON.stringify(list.body).length).toBeLessThan(100_000);
    });

    it('html quá 5 MB → 413; API người dùng vẫn giữ giới hạn body 100 KB', async () => {
      const big = await admin
        .put(`/documents/${id}`, {
          content: { template: 'html', title: 'x' },
          html: html(5 * 1024 * 1024),
          version: 1,
        })
        .expect(413);
      expect(big.body).toMatchObject({
        error: 'HTML_TOO_LARGE',
        message:
          'File lớn hơn 5 MB. Hãy nén ảnh hoặc dùng link ảnh thay vì nhúng base64.',
      });
      const tooBig = await user('a')
        .put('/documents/w12-doc1/progress', {
          sectionIndex: 0,
          pad: 'x'.repeat(200_000),
        })
        .expect(413);
      expect(tooBig.body.error).toBe('PAYLOAD_TOO_LARGE');
    });

    it('chưa tải file → xuất bản báo đúng một lỗi "Chưa tải file HTML"', async () => {
      const d = (
        await admin
          .post('/documents', {
            week: 12,
            title: 'HTML chưa có file',
            template: 'html',
          })
          .expect(201)
      ).body.data;
      const res = await admin.post(`/documents/${d.id}/publish`).expect(422);
      expect(res.body.data.errors).toEqual([
        { path: '', message: 'Chưa tải file HTML' },
      ]);
    });

    it('đổi file (lưu nháp), xuất bản; người dùng nhận nguyên file và hoàn thành được', async () => {
      const cur = (await admin.get(`/documents/${id}`).expect(200)).body.data;
      const small = '<!doctype html><title>Mới</title><p>Slide 1</p>';
      const saved = await admin
        .put(`/documents/${id}`, {
          content: { ...cur.content, html: small, htmlFileName: 'moi.html' },
          version: cur.version,
        })
        .expect(200);
      expect(saved.body.data).toMatchObject({
        htmlFileName: 'moi.html',
        htmlSize: Buffer.byteLength(small),
      });
      await admin.post(`/documents/${id}/publish`).expect(201);

      const list = await user('a').get('/weeks/12/documents').expect(200);
      expect(
        list.body.data.find((d: { id: string }) => d.id === id),
      ).toMatchObject({
        isHtml: true,
        sectionCount: 0,
        progress: { completed: false },
      });
      const doc = await user('a').get(`/documents/${id}`).expect(200);
      expect(doc.body.data.content).toMatchObject({
        template: 'html',
        html: small,
        htmlFileName: 'moi.html',
        sections: [],
      });
      const done = await user('a')
        .post(`/documents/${id}/complete`)
        .expect(201);
      expect(done.body.data.completedNow).toBe(true);
      expect(
        (await user('a').get('/weeks/12/documents')).body.data.find(
          (d: { id: string }) => d.id === id,
        ).progress.completed,
      ).toBe(true);
    });
  });
});
