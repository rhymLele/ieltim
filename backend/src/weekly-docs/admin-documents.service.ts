import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectDataSource, InjectRepository } from '@nestjs/typeorm';
import {
  DataSource,
  EntityManager,
  In,
  LessThan,
  QueryFailedError,
  Repository,
} from 'typeorm';
import {
  DocJson,
  NormalizedDoc,
  categoryLabel,
  categoryOf,
  docCode,
  isPlainObject,
  mergeHtml,
  normalizeDoc,
  regenerateBlockIds,
} from './domain/doc-content';
import {
  ValidateOptions,
  ValidationResult,
  validateDocJson,
  validateDocText,
} from './domain/doc-validator';
import {
  DOC_TEMPLATES,
  buildDocFromTemplate,
  templateById,
} from './domain/templates';
import { vnHm } from './domain/vn-time';
import {
  CreateDocumentDto,
  ImportDocumentDto,
  ListDocumentsQueryDto,
  ReorderItemDto,
  SaveDocumentDto,
} from './dto/document.dto';
import { DocumentAuditLog } from './entities/document-audit-log.entity';
import { WeeklyDocumentRevision } from './entities/weekly-document-revision.entity';
import { WeeklyDocument } from './entities/weekly-document.entity';
import {
  AuditAction,
  DocCategory,
  DocStatus,
  RevisionNote,
} from './enums/weekly-docs.enums';
import { WeeksService } from './weeks.service';
import {
  AUTOSAVE_SESSION_MS,
  IMPORT_MAX_BYTES,
  MAX_HTML_BYTES,
  MIN_SCHEDULE_LEAD_MS,
  SOFT_DELETE_RETENTION_DAYS,
} from './weekly-docs.constants';
import { Actor, weeklyError } from './weekly-errors';

/** Phần nội dung của một bản (phát hành hoặc nháp sửa đổi). */
interface DocPart {
  content: DocJson;
  html: string | null;
  htmlFileName: string | null;
}

export interface UploadedJsonFile {
  originalname: string;
  size: number;
  buffer: Buffer;
}

const SYSTEM: Actor = { id: '', role: 'SYSTEM', displayName: 'Hệ thống' };
const HTML_TOO_LARGE =
  'File lớn hơn 5 MB. Hãy nén ảnh hoặc dùng link ảnh thay vì nhúng base64.';

/**
 * Admin quản lý tài liệu theo tuần (file nghiệp vụ 1 mục 4, file 7, file 9).
 * Khoá lạc quan bằng `version`: mọi lần ghi nội dung là UPDATE … WHERE version = :v.
 */
@Injectable()
export class AdminDocumentsService {
  constructor(
    @InjectRepository(WeeklyDocument) private docs: Repository<WeeklyDocument>,
    @InjectRepository(WeeklyDocumentRevision)
    private revisions: Repository<WeeklyDocumentRevision>,
    @InjectRepository(DocumentAuditLog)
    private audits: Repository<DocumentAuditLog>,
    @InjectDataSource() private dataSource: DataSource,
    private weeks: WeeksService,
    private config: ConfigService,
  ) {}

  // ───────────────────────────── Template, kiểm tra ─────────────────────────────

  templates() {
    return DOC_TEMPLATES.map(
      ({ id, name, skill, description, kind, sections }) => ({
        id,
        name,
        skill,
        description,
        kind,
        outline:
          kind === 'html'
            ? ['<!doctype html>', '<html>…</html>', 'Tự lo trình chiếu']
            : sections.map((s) => s.title as string),
      }),
    );
  }

  template(id: string) {
    const t = templateById(id);
    if (!t)
      throw weeklyError(404, 'TEMPLATE_NOT_FOUND', 'Không có template này.');
    return {
      ...t,
      content: buildDocFromTemplate(t, {
        week: 0,
        order: 0,
        title: '',
        skill: t.skill,
      }),
    };
  }

  validateOptions(): ValidateOptions {
    const hosts = (this.config.get<string>('WEEKLY_IMAGE_HOSTS') ?? '')
      .split(',')
      .map((h) => h.trim())
      .filter(Boolean);
    return { allowedImageHosts: hosts };
  }

  validate(content: unknown): ValidationResult {
    return typeof content === 'string'
      ? validateDocText(content, this.validateOptions())
      : validateDocJson(content, this.validateOptions());
  }

  // ───────────────────────────── Đọc ─────────────────────────────

  async list(q: ListDocumentsQueryDto) {
    const qb = this.docs.createQueryBuilder('d');
    if (q.week) qb.andWhere('d.week = :week', { week: q.week });
    const statuses = (q.status ?? '')
      .split(',')
      .map((s) => s.trim())
      .filter(Boolean);
    if (statuses.length)
      qb.andWhere('d.status IN (:...statuses)', { statuses });
    if (q.skill) qb.andWhere('d.skill = :skill', { skill: q.skill });
    if (q.category)
      qb.andWhere('d.category = :category', { category: q.category });
    qb.orderBy('d.week', 'DESC')
      .addOrderBy('d.category', 'DESC') // lesson trước homework
      .addOrderBy('d.order', 'ASC');
    let rows = await qb.getMany();
    if (q.q?.trim()) {
      const needle = fold(q.q);
      rows = rows.filter((d) => fold(d.title).includes(needle));
    }
    const total = rows.length;
    // Lọc theo một tuần thì trả hết; xem "Tất cả tuần" thì 20 hàng/trang (UC-D01).
    const pageSize = q.week ? Math.max(total, 1) : (q.pageSize ?? 20);
    const page = q.week ? 1 : (q.page ?? 1);
    const data = rows
      .slice((page - 1) * pageSize, page * pageSize)
      .map((d) => this.toSummary(d));
    return {
      data,
      pagination: {
        page,
        pageSize,
        total,
        totalPages: Math.ceil(total / pageSize),
      },
    };
  }

  async detail(id: string, source: 'working' | 'live' = 'working') {
    return this.toDetail(await this.findFull(id), source);
  }

  /** Nội dung như người dùng sẽ thấy, không ghi tiến độ (UC-D04). */
  async preview(id: string) {
    const doc = await this.findFull(id);
    const { content, validation, ...rest } = this.toDetail(doc);
    return { ...rest, content, validation, preview: true };
  }

  async export(id: string, source: 'live' | 'draft' = 'live') {
    const doc = await this.findFull(id);
    const part = source === 'draft' ? this.working(doc) : this.live(doc);
    return {
      fileName: `${doc.id}.json`,
      body: JSON.stringify(this.fullJson(part), null, 2),
    };
  }

  async revisionsOf(id: string) {
    const doc = await this.findFull(id);
    const rows = await this.revisions.find({
      where: { documentUid: doc.uid },
      order: { createdAt: 'DESC' },
    });
    return rows.map((r) => ({
      id: r.id,
      version: r.version,
      note: r.note,
      editedBy: r.editedByName,
      htmlFileName: r.htmlFileName,
      createdAt: r.createdAt,
      updatedAt: r.updatedAt,
    }));
  }

  async auditOf(id: string) {
    const doc = await this.findFull(id);
    const rows = await this.audits.find({
      where: { documentUid: doc.uid },
      order: { createdAt: 'DESC' },
    });
    return rows.map((r) => ({
      id: r.id,
      documentId: r.documentId,
      action: r.action,
      actorName: r.actorName,
      fromStatus: r.fromStatus,
      toStatus: r.toStatus,
      version: r.version,
      note: r.note,
      createdAt: r.createdAt,
    }));
  }

  // ───────────────────────────── Tạo, lưu ─────────────────────────────

  async create(
    dto: CreateDocumentDto,
    actor: Actor,
    opts: { action?: AuditAction; note?: string } = {},
  ) {
    const given = dto.content ? structuredClone(dto.content) : null;
    const week =
      dto.week ??
      (Number.isInteger(given?.week) ? (given!.week as number) : undefined);
    if (!week)
      throw weeklyError(400, 'WEEK_REQUIRED', 'Chọn tuần cho tài liệu.');
    await this.weeks.ensureUpcoming();
    await this.weeks.findOrFail(week);
    const category = categoryOf(dto.category ?? given?.category);
    const order =
      dto.order ??
      (Number.isInteger(given?.order) && given!.order >= 1
        ? (given!.order as number)
        : await this.nextOrder(week, category));
    if (await this.docs.exists({ where: { week, category, order } })) {
      throw weeklyError(
        409,
        'DOC_ORDER_TAKEN',
        `Tuần ${week} đã có ${categoryLabel(category)} ${order}.`,
        { suggestion: await this.nextOrder(week, category) },
      );
    }

    let json: DocJson;
    if (given) {
      json = given;
      if (dto.title !== undefined) json.title = dto.title.trim();
    } else {
      const t = templateById(dto.template ?? 'reading-lesson');
      if (!t)
        throw weeklyError(400, 'TEMPLATE_NOT_FOUND', 'Không có template này.');
      const title = (dto.title ?? '').trim();
      if (t.kind !== 'import' && (title.length < 3 || title.length > 200)) {
        throw weeklyError(
          400,
          'DOC_TITLE_INVALID',
          'Tên tài liệu cần từ 3 đến 200 ký tự',
        );
      }
      json = buildDocFromTemplate(t, {
        week,
        order,
        title: title || 'Tài liệu mới',
        skill: dto.skill ?? t.skill,
      });
    }
    if (dto.skill !== undefined)
      json.meta = {
        ...(isPlainObject(json.meta) ? json.meta : {}),
        skill: dto.skill,
      };
    if (dto.html !== undefined) json.html = dto.html;
    if (dto.htmlFileName !== undefined) json.htmlFileName = dto.htmlFileName;

    const n = normalizeDoc(json, { week, order, category });
    this.assertHtmlSize(n);
    let doc: WeeklyDocument;
    try {
      doc = await this.docs.save(
        this.docs.create({
          ...this.livePatch(n),
          id: docCode(week, order, category),
          week,
          category,
          order,
          status: DocStatus.DRAFT,
          version: 1,
          createdBy: actor.id || null,
          updatedBy: actor.id || null,
          updatedByName: actor.displayName ?? null,
        }),
      );
    } catch (e) {
      if (isUniqueViolation(e))
        throw weeklyError(
          409,
          'DOC_ORDER_TAKEN',
          `Tuần ${week} đã có ${categoryLabel(category)} ${order}.`,
        );
      throw e;
    }
    await this.addRevision(doc, n, RevisionNote.CREATE, actor);
    await this.audit(doc, opts.action ?? AuditAction.CREATE, actor, {
      to: DocStatus.DRAFT,
      note: opts.note ?? null,
    });
    return this.detail(doc.id);
  }

  /** Import file `.json` (UC-D12): parse → tạo nháp → trả kết quả kiểm tra. */
  async import(
    file: UploadedJsonFile | undefined,
    dto: ImportDocumentDto,
    actor: Actor,
  ) {
    if (!file)
      throw weeklyError(400, 'IMPORT_PARSE_ERROR', 'Chưa chọn file JSON.');
    if (file.size > IMPORT_MAX_BYTES)
      throw weeklyError(413, 'IMPORT_TOO_LARGE', 'File quá lớn (tối đa 1 MB).');
    let parsed: unknown;
    try {
      parsed = JSON.parse(file.buffer.toString('utf8').replace(/^\uFEFF/, ''));
    } catch (e) {
      throw weeklyError(
        422,
        'IMPORT_PARSE_ERROR',
        `File không phải JSON hợp lệ: ${(e as Error).message}`,
      );
    }
    if (!isPlainObject(parsed))
      throw weeklyError(
        422,
        'IMPORT_PARSE_ERROR',
        'File không phải JSON hợp lệ: cần một object.',
      );
    const validation = this.validate(parsed);
    const document = await this.create(
      {
        week: dto.week,
        order: dto.order,
        category: dto.category,
        content: parsed,
      },
      actor,
      { action: AuditAction.IMPORT, note: file.originalname },
    );
    return { document, validation };
  }

  /**
   * Lưu nháp (UC-D03). Được lưu dù còn lỗi. Sai `version` → 409 kèm bản hiện tại.
   * Tài liệu PUBLISHED: ghi vào bản nháp sửa đổi, người dùng chưa thấy cho tới khi `release`.
   */
  async save(id: string, dto: SaveDocumentDto, actor: Actor) {
    const doc = await this.findFull(id);
    if (doc.status === DocStatus.ARCHIVED)
      throw weeklyError(
        409,
        'DOC_EDIT_ARCHIVED',
        'Tài liệu đã gỡ. Khôi phục để sửa tiếp.',
      );
    if (dto.version !== doc.version) throw this.conflict(doc);

    const input: DocJson = structuredClone(dto.content);
    if (dto.title !== undefined) input.title = dto.title;
    const meta = isPlainObject(input.meta) ? input.meta : (input.meta = {});
    if (dto.skill !== undefined) meta.skill = dto.skill;
    if (dto.defaultView !== undefined) meta.defaultView = dto.defaultView;
    if (dto.allowedViews !== undefined) meta.allowedViews = dto.allowedViews;
    if (dto.html !== undefined) input.html = dto.html;
    if (dto.htmlFileName !== undefined) input.htmlFileName = dto.htmlFileName;

    const n = normalizeDoc(input, doc);
    this.assertHtmlSize(n);
    const patch =
      doc.status === DocStatus.PUBLISHED
        ? this.draftPatch(n)
        : this.livePatch(n);
    await this.updateIfVersion(doc, patch, actor);
    await this.recordSave(doc, n, actor);
    return this.detail(doc.id);
  }

  // ───────────────────────────── Vòng đời (file 7 mục 1) ─────────────────────────────

  async publish(id: string, publishAt: string | undefined, actor: Actor) {
    if (publishAt) return this.schedule(id, publishAt, actor);
    const doc = await this.findFull(id);
    this.assertStatus(doc, [DocStatus.DRAFT, DocStatus.SCHEDULED]);
    this.assertPublishable(this.live(doc));
    const res = await this.docs.update(
      { uid: doc.uid, status: In([DocStatus.DRAFT, DocStatus.SCHEDULED]) },
      { status: DocStatus.PUBLISHED, publishedAt: new Date(), publishAt: null },
    );
    if (!res.affected) throw this.conflict(await this.findFull(id));
    await this.addRevision(doc, this.live(doc), RevisionNote.PUBLISH, actor);
    await this.audit(doc, AuditAction.PUBLISH, actor, {
      from: doc.status,
      to: DocStatus.PUBLISHED,
    });
    return this.detail(doc.id);
  }

  async schedule(id: string, publishAt: string, actor: Actor) {
    const at = new Date(publishAt);
    if (
      Number.isNaN(at.getTime()) ||
      at.getTime() < Date.now() + MIN_SCHEDULE_LEAD_MS
    ) {
      throw weeklyError(
        422,
        'DOC_SCHEDULE_PAST',
        'Giờ xuất bản phải sau hiện tại ít nhất 5 phút.',
      );
    }
    const doc = await this.findFull(id);
    this.assertStatus(doc, [DocStatus.DRAFT, DocStatus.SCHEDULED]);
    this.assertPublishable(this.live(doc));
    const res = await this.docs.update(
      { uid: doc.uid, status: In([DocStatus.DRAFT, DocStatus.SCHEDULED]) },
      { status: DocStatus.SCHEDULED, publishAt: at },
    );
    if (!res.affected) throw this.conflict(await this.findFull(id));
    await this.audit(doc, AuditAction.SCHEDULE, actor, {
      from: doc.status,
      to: DocStatus.SCHEDULED,
      note: `Hẹn ${at.toISOString()}`,
    });
    return this.detail(doc.id);
  }

  async unschedule(id: string, actor: Actor) {
    return this.transition(
      id,
      [DocStatus.SCHEDULED],
      { status: DocStatus.DRAFT, publishAt: null },
      AuditAction.UNSCHEDULE,
      actor,
    );
  }

  async unpublish(id: string, reason: string | undefined, actor: Actor) {
    return this.transition(
      id,
      [DocStatus.PUBLISHED],
      { status: DocStatus.ARCHIVED },
      AuditAction.UNPUBLISH,
      actor,
      reason?.trim() || null,
    );
  }

  /** ARCHIVED → DRAFT, giữ nguyên nội dung và id; bản nháp sửa đổi (nếu có) trở thành bản đang soạn (UC-D08). */
  async restore(id: string, actor: Actor) {
    const doc = await this.findFull(id);
    this.assertStatus(doc, [DocStatus.ARCHIVED]);
    const patch: Partial<WeeklyDocument> = { status: DocStatus.DRAFT };
    if (doc.hasRevisionDraft && doc.draftContent) {
      Object.assign(
        patch,
        this.livePatch(normalizeDoc(this.fullJson(this.working(doc)), doc)),
        this.clearedDraft(),
      );
    }
    const res = await this.docs.update(
      { uid: doc.uid, status: DocStatus.ARCHIVED },
      patch,
    );
    if (!res.affected) throw this.conflict(await this.findFull(id));
    await this.audit(doc, AuditAction.RESTORE, actor, {
      from: DocStatus.ARCHIVED,
      to: DocStatus.DRAFT,
    });
    return this.detail(doc.id);
  }

  /** "Cập nhật bản phát hành": bản nháp sửa đổi → bản phát hành (UC-D03). */
  async release(id: string, actor: Actor) {
    const doc = await this.findFull(id);
    this.assertStatus(doc, [DocStatus.PUBLISHED]);
    if (!doc.hasRevisionDraft || !doc.draftContent) return this.detail(doc.id);
    const draft = this.working(doc);
    this.assertPublishable(draft);
    const n = normalizeDoc(this.fullJson(draft), doc);
    await this.updateIfVersion(
      doc,
      { ...this.livePatch(n), ...this.clearedDraft(), publishedAt: new Date() },
      actor,
    );
    await this.addRevision(
      { ...doc, version: doc.version + 1 },
      n,
      RevisionNote.RELEASE,
      actor,
    );
    await this.audit(doc, AuditAction.RELEASE, actor, {
      from: DocStatus.PUBLISHED,
      to: DocStatus.PUBLISHED,
      version: doc.version + 1,
      note:
        n.sectionCount < doc.sectionCount
          ? `Số section giảm ${doc.sectionCount} → ${n.sectionCount}`
          : null,
    });
    return this.detail(doc.id);
  }

  /** "Bỏ thay đổi": xoá bản nháp sửa đổi, quay về bản đang phát hành. */
  async discardRevisionDraft(id: string, actor: Actor) {
    const doc = await this.findFull(id);
    if (!doc.hasRevisionDraft) return this.detail(doc.id);
    await this.updateIfVersion(doc, this.clearedDraft(), actor);
    await this.audit(doc, AuditAction.UPDATE, actor, {
      version: doc.version + 1,
      note: 'Bỏ thay đổi chưa phát hành',
    });
    return this.detail(doc.id);
  }

  /** Chỉ xoá được DRAFT chưa từng xuất bản; xoá mềm 30 ngày, hoàn tác được (UC-D09). */
  async remove(id: string, actor: Actor) {
    const doc = await this.findFull(id);
    if (doc.status !== DocStatus.DRAFT || doc.publishedAt) {
      throw weeklyError(
        409,
        'DOC_DELETE_NOT_ALLOWED',
        'Tài liệu đã từng xuất bản nên không xoá được. Hãy dùng "Gỡ".',
      );
    }
    await this.docs.softDelete({ uid: doc.uid });
    await this.audit(doc, AuditAction.DELETE, actor, {
      from: DocStatus.DRAFT,
      to: null,
    });
    return { id: doc.id, deleted: true };
  }

  async undelete(id: string, actor: Actor) {
    const doc = await this.findFull(id, { deleted: true });
    if (
      await this.docs.exists({
        where: [
          { id: doc.id },
          { week: doc.week, category: doc.category, order: doc.order },
        ],
      })
    ) {
      throw weeklyError(
        409,
        'DOC_ORDER_TAKEN',
        `Tuần ${doc.week} đã có ${categoryLabel(doc.category)} ${doc.order}.`,
      );
    }
    await this.docs.restore({ uid: doc.uid });
    await this.audit(doc, AuditAction.UNDELETE, actor, { to: DocStatus.DRAFT });
    return this.detail(doc.id);
  }

  /** Nhân bản sang tuần đích: DRAFT mới, tiêu đề thêm " (bản sao)", id khối tạo mới (UC-D11). */
  async duplicate(id: string, targetWeek: number, actor: Actor) {
    const src = await this.findFull(id);
    await this.weeks.findOrFail(targetWeek);
    const part = this.working(src);
    const json = regenerateBlockIds(this.fullJson(part));
    json.title =
      `${typeof json.title === 'string' ? json.title : src.title} (bản sao)`.slice(
        0,
        200,
      );
    return this.create(
      {
        week: targetWeek,
        category: src.category,
        order: await this.nextOrder(targetWeek, src.category),
        content: json,
      },
      actor,
      {
        action: AuditAction.DUPLICATE,
        note: `Nhân bản từ ${src.id}`,
      },
    );
  }

  /** Sắp xếp lại trong tuần; chỉ tài liệu chưa từng xuất bản đổi được số (UC-D10). Đổi số = đổi id. */
  async reorder(week: number, items: ReorderItemDto[], actor: Actor) {
    await this.weeks.findOrFail(week);
    await this.dataSource.transaction(async (m) => {
      const docs = await m.find(WeeklyDocument, {
        where: { week },
        lock: { mode: 'pessimistic_write' },
      });
      const byId = new Map(docs.map((d) => [d.id, d]));
      const target = new Map<string, number>();
      for (const it of items) {
        if (!byId.has(it.id))
          throw weeklyError(
            400,
            'DOC_NOT_IN_WEEK',
            `Tài liệu ${it.id} không thuộc Tuần ${week}.`,
          );
        target.set(it.id, it.order);
      }
      const moved = docs.filter(
        (d) => target.has(d.id) && target.get(d.id) !== d.order,
      );
      const locked = moved.find((d) => d.publishedAt);
      if (locked) {
        throw weeklyError(
          409,
          'DOC_MOVE_PUBLISHED',
          'Tài liệu đã xuất bản không đổi tuần hoặc số thứ tự được. Hãy dùng "Nhân bản".',
          { id: locked.id },
        );
      }
      // Tài liệu và bài tập đánh số riêng: chỉ trùng khi cùng loại.
      const finalOrders = docs.map(
        (d) => `${d.category}:${target.get(d.id) ?? d.order}`,
      );
      if (new Set(finalOrders).size !== finalOrders.length) {
        throw weeklyError(
          409,
          'DOC_ORDER_TAKEN',
          `Tuần ${week} có hai tài liệu trùng số thứ tự.`,
        );
      }
      // Hai pha để không vướng ràng buộc duy nhất (week, category, order) và id khi hoán đổi.
      for (const [i, d] of moved.entries()) {
        await m.update(
          WeeklyDocument,
          { uid: d.uid },
          { id: `tmp-${d.uid}`, order: -(i + 1) },
        );
      }
      for (const d of moved) {
        const order = target.get(d.id)!;
        const newId = docCode(week, order, d.category);
        const patch: Partial<WeeklyDocument> = {
          id: newId,
          order,
          content: { ...d.content, id: newId, order },
        };
        await m.update(WeeklyDocument, { uid: d.uid }, patch);
        await this.audit(
          { uid: d.uid, id: newId },
          AuditAction.REORDER,
          actor,
          { note: `${d.id} → ${newId}` },
          m,
        );
      }
    });
    return (await this.list({ week })).data;
  }

  async restoreRevision(id: string, revisionId: string, actor: Actor) {
    const doc = await this.findFull(id);
    if (doc.status === DocStatus.ARCHIVED)
      throw weeklyError(
        409,
        'DOC_EDIT_ARCHIVED',
        'Tài liệu đã gỡ. Khôi phục để sửa tiếp.',
      );
    const rev = await this.revisions
      .createQueryBuilder('r')
      .addSelect('r.html')
      .where('r.id = :revisionId AND r.documentUid = :uid', {
        revisionId,
        uid: doc.uid,
      })
      .getOne();
    if (!rev)
      throw weeklyError(
        404,
        'REVISION_NOT_FOUND',
        'Không tìm thấy phiên bản này.',
      );
    const n = normalizeDoc(
      mergeHtml(rev.content, rev.html, rev.htmlFileName),
      doc,
    );
    await this.updateIfVersion(
      doc,
      doc.status === DocStatus.PUBLISHED
        ? this.draftPatch(n)
        : this.livePatch(n),
      actor,
    );
    await this.addRevision(
      { ...doc, version: doc.version + 1 },
      n,
      RevisionNote.RESTORE,
      actor,
    );
    await this.audit(doc, AuditAction.UPDATE, actor, {
      version: doc.version + 1,
      note: `Khôi phục phiên bản v${rev.version}`,
    });
    return this.detail(doc.id);
  }

  // ───────────────────────────── Job (PublishSchedulerService gọi) ─────────────────────────────

  /** Xuất bản các tài liệu tới giờ hẹn. Còn lỗi thì về DRAFT và ghi nhật ký. Idempotent. */
  async runScheduledPublish(now = new Date()) {
    const due = await this.docs
      .createQueryBuilder('d')
      .addSelect('d.html')
      .where('d.status = :status AND d.publishAt <= :now', {
        status: DocStatus.SCHEDULED,
        now,
      })
      .getMany();
    const published: string[] = [];
    const failed: string[] = [];
    for (const doc of due) {
      const live = this.live(doc);
      const v = this.validate(this.fullJson(live));
      if (v.valid) {
        const res = await this.docs.update(
          { uid: doc.uid, status: DocStatus.SCHEDULED },
          { status: DocStatus.PUBLISHED, publishedAt: now, publishAt: null },
        );
        if (!res.affected) continue;
        await this.addRevision(doc, live, RevisionNote.PUBLISH, SYSTEM);
        await this.audit(doc, AuditAction.PUBLISH, SYSTEM, {
          from: DocStatus.SCHEDULED,
          to: DocStatus.PUBLISHED,
          note: 'Xuất bản theo lịch',
        });
        published.push(doc.id);
      } else {
        const res = await this.docs.update(
          { uid: doc.uid, status: DocStatus.SCHEDULED },
          { status: DocStatus.DRAFT, publishAt: null },
        );
        if (!res.affected) continue;
        const note = `Tài liệu "${doc.title}" chưa được xuất bản lúc ${vnHm(doc.publishAt ?? now)} vì còn ${v.errors.length} lỗi`;
        await this.audit(doc, AuditAction.SCHEDULE_FAILED, SYSTEM, {
          from: DocStatus.SCHEDULED,
          to: DocStatus.DRAFT,
          note,
        });
        failed.push(doc.id);
      }
    }
    return { published, failed };
  }

  /** Xoá hẳn nháp đã xoá mềm quá 30 ngày. */
  async purgeDeleted(now = new Date()) {
    const cutoff = new Date(
      now.getTime() - SOFT_DELETE_RETENTION_DAYS * 24 * 60 * 60 * 1000,
    );
    const old = await this.docs.find({
      where: { deletedAt: LessThan(cutoff) },
      withDeleted: true,
    });
    if (!old.length) return 0;
    const uids = old.map((d) => d.uid);
    await this.revisions.delete({ documentUid: In(uids) });
    await this.docs.delete({ uid: In(uids) });
    return old.length;
  }

  // ───────────────────────────── Nội bộ ─────────────────────────────

  /** Số thứ tự kế tiếp của loại [category] trong tuần (tài liệu và bài tập đánh số riêng). */
  async nextOrder(
    week: number,
    category: DocCategory = DocCategory.LESSON,
  ): Promise<number> {
    const row = await this.docs
      .createQueryBuilder('d')
      .select('MAX(d.order)', 'max')
      .where('d.week = :week', { week })
      .andWhere('d.category = :category', { category })
      .getRawOne<{ max: number | null }>();
    return (row?.max ?? 0) + 1;
  }

  private async findFull(
    id: string,
    opts: { deleted?: boolean } = {},
  ): Promise<WeeklyDocument> {
    const qb = this.docs
      .createQueryBuilder('d')
      .addSelect([
        'd.html',
        'd.draftContent',
        'd.draftHtml',
        'd.draftHtmlFileName',
      ])
      .where('d.id = :id', { id });
    if (opts.deleted)
      qb.withDeleted()
        .andWhere('d.deletedAt IS NOT NULL')
        .orderBy('d.deletedAt', 'DESC');
    const doc = await qb.getOne();
    if (!doc)
      throw weeklyError(404, 'DOC_NOT_FOUND', 'Không tìm thấy tài liệu.');
    return doc;
  }

  private live(doc: WeeklyDocument): DocPart {
    return {
      content: doc.content,
      html: doc.html ?? null,
      htmlFileName: doc.htmlFileName,
    };
  }

  /** Bản đang soạn: bản nháp sửa đổi nếu có, không thì bản đang dùng. */
  private working(doc: WeeklyDocument): DocPart {
    return doc.hasRevisionDraft && doc.draftContent
      ? {
          content: doc.draftContent,
          html: doc.draftHtml ?? null,
          htmlFileName: doc.draftHtmlFileName ?? null,
        }
      : this.live(doc);
  }

  private fullJson(part: DocPart): DocJson {
    return mergeHtml(part.content, part.html, part.htmlFileName);
  }

  toSummary(d: WeeklyDocument) {
    return {
      id: d.id,
      week: d.week,
      order: d.order,
      category: d.category,
      title: d.title,
      skill: d.skill,
      template: d.template,
      isHtml: d.template === 'html',
      defaultView: d.defaultView,
      allowedViews: d.allowedViews,
      status: d.status,
      publishAt: d.publishAt,
      publishedAt: d.publishedAt,
      everPublished: d.publishedAt != null,
      version: d.version,
      sectionCount: d.sectionCount,
      estimatedMinutes: d.estimatedMinutes,
      htmlFileName: d.htmlFileName,
      htmlSize: d.htmlSize,
      hasRevisionDraft: d.hasRevisionDraft,
      createdAt: d.createdAt,
      updatedAt: d.updatedAt,
      updatedBy: d.updatedByName,
    };
  }

  private toDetail(
    doc: WeeklyDocument,
    source: 'working' | 'live' = 'working',
  ) {
    const part = source === 'live' ? this.live(doc) : this.working(doc);
    const content = this.fullJson(part);
    const draftSections =
      doc.hasRevisionDraft && Array.isArray(doc.draftContent?.sections)
        ? (doc.draftContent?.sections as unknown[]).length
        : null;
    return {
      ...this.toSummary(doc),
      source: source === 'live' || !doc.hasRevisionDraft ? 'live' : 'draft',
      // Bản mới giảm số section: FE cảnh báo ở bước 3 (UC-D03).
      ...(draftSections !== null && doc.template !== 'html'
        ? { draftSectionCount: draftSections }
        : {}),
      content,
      validation: this.validate(content),
    };
  }

  private livePatch(n: NormalizedDoc): Partial<WeeklyDocument> {
    return {
      content: n.content,
      html: n.html,
      htmlFileName: n.htmlFileName,
      htmlSize: n.htmlSize,
      title: n.title,
      skill: n.skill,
      template: n.template,
      defaultView: n.defaultView,
      allowedViews: n.allowedViews,
      sectionCount: n.sectionCount,
      estimatedMinutes: n.estimatedMinutes,
      schemaVersion: Number.isInteger(n.content.schemaVersion)
        ? n.content.schemaVersion
        : 1,
    };
  }

  private draftPatch(n: NormalizedDoc): Partial<WeeklyDocument> {
    return {
      hasRevisionDraft: true,
      draftContent: n.content,
      draftHtml: n.html,
      draftHtmlFileName: n.htmlFileName,
    };
  }

  private clearedDraft(): Partial<WeeklyDocument> {
    return {
      hasRevisionDraft: false,
      draftContent: null,
      draftHtml: null,
      draftHtmlFileName: null,
    };
  }

  private assertHtmlSize(n: NormalizedDoc) {
    if (n.htmlSize > MAX_HTML_BYTES)
      throw weeklyError(413, 'HTML_TOO_LARGE', HTML_TOO_LARGE);
  }

  private assertStatus(doc: WeeklyDocument, allowed: DocStatus[]) {
    if (allowed.includes(doc.status)) return;
    if (doc.status === DocStatus.ARCHIVED)
      throw weeklyError(
        409,
        'DOC_EDIT_ARCHIVED',
        'Tài liệu đã gỡ. Khôi phục để sửa tiếp.',
      );
    throw weeklyError(
      409,
      'DOC_INVALID_TRANSITION',
      `Không thực hiện được thao tác này khi tài liệu đang ở trạng thái "${doc.status}".`,
      {
        status: doc.status,
      },
    );
  }

  /** Còn lỗi → 422 kèm danh sách lỗi (file 1 mục 3.4). */
  private assertPublishable(part: DocPart) {
    const v = this.validate(this.fullJson(part));
    if (!v.valid)
      throw weeklyError(
        422,
        'DOC_INVALID_CONTENT',
        `Tài liệu còn ${v.errors.length} lỗi cần sửa trước khi xuất bản.`,
        v,
      );
  }

  private conflict(fresh: WeeklyDocument) {
    const who = fresh.updatedByName ?? 'Một admin khác';
    return weeklyError(
      409,
      'DOC_VERSION_CONFLICT',
      `${who} vừa sửa tài liệu này lúc ${vnHm(fresh.updatedAt)}.`,
      { current: this.toDetail(fresh) },
    );
  }

  private async updateIfVersion(
    doc: WeeklyDocument,
    patch: Partial<WeeklyDocument>,
    actor: Actor,
  ) {
    const res = await this.docs.update(
      { uid: doc.uid, version: doc.version },
      {
        ...patch,
        version: doc.version + 1,
        updatedBy: actor.id || null,
        updatedByName: actor.displayName ?? null,
      },
    );
    if (!res.affected) throw this.conflict(await this.findFull(doc.id));
  }

  private async transition(
    id: string,
    from: DocStatus[],
    patch: Partial<WeeklyDocument>,
    action: AuditAction,
    actor: Actor,
    note: string | null = null,
  ) {
    const doc = await this.findFull(id);
    this.assertStatus(doc, from);
    const res = await this.docs.update(
      { uid: doc.uid, status: In(from) },
      patch,
    );
    if (!res.affected) throw this.conflict(await this.findFull(id));
    await this.audit(doc, action, actor, {
      from: doc.status,
      to: patch.status ?? doc.status,
      note,
    });
    return this.detail(doc.id);
  }

  private async addRevision(
    doc: Pick<WeeklyDocument, 'uid' | 'version'>,
    part: DocPart,
    note: RevisionNote,
    actor: Actor,
  ) {
    await this.revisions.insert({
      documentUid: doc.uid,
      version: doc.version,
      note,
      content: part.content,
      html: part.html,
      htmlFileName: part.htmlFileName,
      editedBy: actor.id || null,
      editedByName: actor.displayName ?? null,
    });
  }

  /** Tự lưu: gộp các lần lưu liên tiếp của cùng người trong một phiên thành một phiên bản (UC-D14). */
  private async recordSave(
    doc: WeeklyDocument,
    n: NormalizedDoc,
    actor: Actor,
  ) {
    const version = doc.version + 1;
    const last = await this.revisions.findOne({
      where: { documentUid: doc.uid },
      order: { createdAt: 'DESC' },
    });
    const sameSession =
      last?.note === RevisionNote.AUTOSAVE &&
      last.editedBy === (actor.id || null) &&
      Date.now() - last.updatedAt.getTime() < AUTOSAVE_SESSION_MS;
    if (sameSession) {
      await this.revisions.update(
        { id: last.id },
        {
          version,
          content: n.content,
          html: n.html,
          htmlFileName: n.htmlFileName,
        },
      );
      return;
    }
    await this.addRevision(
      { uid: doc.uid, version },
      n,
      RevisionNote.AUTOSAVE,
      actor,
    );
    await this.audit(doc, AuditAction.UPDATE, actor, { version });
  }

  private async audit(
    doc: Pick<WeeklyDocument, 'uid' | 'id'>,
    action: AuditAction,
    actor: Actor,
    extra: {
      from?: string | null;
      to?: string | null;
      version?: number | null;
      note?: string | null;
    } = {},
    manager?: EntityManager,
  ) {
    const repo = manager
      ? manager.getRepository(DocumentAuditLog)
      : this.audits;
    await repo.insert({
      documentUid: doc.uid,
      documentId: doc.id,
      action,
      actorId: actor.id || null,
      actorName: actor.displayName ?? null,
      fromStatus: extra.from ?? null,
      toStatus: extra.to ?? null,
      version: extra.version ?? null,
      note: extra.note ? extra.note.slice(0, 500) : null,
    });
  }
}

/** Tìm không phân biệt dấu và hoa thường (UC-D01). */
export function fold(s: string): string {
  return s
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .replace(/[đĐ]/g, 'd')
    .toLowerCase()
    .trim();
}

function isUniqueViolation(e: unknown): boolean {
  return (
    e instanceof QueryFailedError &&
    (e as QueryFailedError & { driverError?: { code?: string } }).driverError
      ?.code === '23505'
  );
}
