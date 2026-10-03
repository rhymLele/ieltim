import { Injectable } from '@nestjs/common';
import { InjectDataSource, InjectRepository } from '@nestjs/typeorm';
import { DataSource, EntityManager, In, Repository } from 'typeorm';
import {
  VocabItem,
  findBlock,
  mergeHtml,
  normalizeWord,
  vocabItems,
} from './domain/doc-content';
import { streakDays, vnCalendarWeek, vnDate } from './domain/vn-time';
import {
  ProgressDto,
  QuizAnswerDto,
  VocabFromDocumentDto,
} from './dto/learner.dto';
import { LearningActivity } from './entities/learning-activity.entity';
import { UserDocumentProgress } from './entities/user-document-progress.entity';
import { VocabEntry } from './entities/vocab-entry.entity';
import { Week } from './entities/week.entity';
import { WeeklyDocument } from './entities/weekly-document.entity';
import { DocStatus, LearningActivityType } from './enums/weekly-docs.enums';
import { WeeksService } from './weeks.service';
import { weeklyError } from './weekly-errors';

const STREAK_LOOKBACK_DAYS = 400;

/**
 * Phía người dùng (file nghiệp vụ 1 mục 5, 6): danh sách tuần, đọc tài liệu, tiến độ, trắc nghiệm,
 * hoàn thành, Sổ từ. Mọi API ghi đều idempotent (FE mobile có thể gửi lại).
 */
@Injectable()
export class LearnerService {
  constructor(
    @InjectRepository(Week) private weekRepo: Repository<Week>,
    @InjectRepository(WeeklyDocument) private docs: Repository<WeeklyDocument>,
    @InjectRepository(UserDocumentProgress)
    private progress: Repository<UserDocumentProgress>,
    @InjectRepository(LearningActivity)
    private activities: Repository<LearningActivity>,
    @InjectRepository(VocabEntry) private vocab: Repository<VocabEntry>,
    @InjectDataSource() private dataSource: DataSource,
    private weeks: WeeksService,
  ) {}

  // ───────────────────────────── Đọc ─────────────────────────────

  async weekList(userId: string) {
    await this.weeks.ensureUpcoming();
    const today = vnDate();
    const weeks = await this.weekRepo.find({ order: { number: 'ASC' } });
    const totals = await this.docs
      .createQueryBuilder('d')
      .select('d.week', 'week')
      .addSelect('COUNT(*)', 'n')
      .where('d.status = :status', { status: DocStatus.PUBLISHED })
      .groupBy('d.week')
      .getRawMany<{ week: number; n: string }>();
    const done = await this.progress
      .createQueryBuilder('p')
      .innerJoin(
        WeeklyDocument,
        'd',
        'd.uid = p.documentUid AND d.deletedAt IS NULL',
      )
      .select('d.week', 'week')
      .addSelect('COUNT(*)', 'n')
      .where(
        'p.userId = :userId AND p.completedAt IS NOT NULL AND d.status = :status',
        { userId, status: DocStatus.PUBLISHED },
      )
      .groupBy('d.week')
      .getRawMany<{ week: number; n: string }>();
    const count = (rows: { week: number; n: string }[], w: number) =>
      Number(rows.find((r) => Number(r.week) === w)?.n ?? 0);
    const current = weeks.find(
      (w) => w.startDate <= today && w.endDate >= today,
    );
    return {
      currentWeek: current?.number ?? null,
      data: weeks.map((w) => {
        const dto = this.weeks.toDto(w, today);
        const open = dto.state === 'open';
        return {
          ...dto,
          docTotal: open ? count(totals, w.number) : 0,
          docDone: open ? count(done, w.number) : 0,
        };
      }),
    };
  }

  async weekDocuments(userId: string, number: number) {
    const week = await this.weeks.findOrFail(number);
    if (WeeksService.stateOf(week) === 'locked')
      throw weeklyError(403, 'WEEK_LOCKED', `Tuần ${number} chưa mở.`);
    const docs = await this.docs.find({
      where: { week: number, status: DocStatus.PUBLISHED },
      order: { order: 'ASC' },
    });
    const rows = docs.length
      ? await this.progress.find({
          where: { userId, documentUid: In(docs.map((d) => d.uid)) },
        })
      : [];
    const byDoc = new Map(rows.map((p) => [p.documentUid, p]));
    return docs.map((d) => this.toSummary(d, byDoc.get(d.uid)));
  }

  /** Nội dung + tiến độ của tôi. ETag gồm phiên bản nội dung và lần cập nhật tiến độ. */
  async document(userId: string, id: string) {
    const doc = await this.visibleDoc(id, true);
    const p = await this.progress.findOne({
      where: { userId, documentUid: doc.uid },
    });
    const summary = this.toSummary(doc, p ?? undefined);
    const body = {
      ...summary,
      content: mergeHtml(doc.content, doc.html, doc.htmlFileName),
      progress: this.progressDetail(doc, p ?? undefined),
    };
    return {
      etag: `W/"${doc.uid}.${doc.version}.${p?.updatedAt?.getTime() ?? 0}"`,
      body,
    };
  }

  // ───────────────────────────── Ghi ─────────────────────────────

  async saveProgress(userId: string, id: string, dto: ProgressDto) {
    const doc = await this.visibleDoc(id);
    // Tài liệu HTML không có section: chỉ có Chưa học / Đã học (file 9 mục 5).
    if (doc.sectionCount > 0 && dto.sectionIndex >= doc.sectionCount) {
      throw weeklyError(
        422,
        'SECTION_OUT_OF_RANGE',
        `Tài liệu chỉ có ${doc.sectionCount} phần.`,
      );
    }
    await this.dataSource.transaction(async (m) => {
      const p = await this.lockProgress(m, userId, doc.uid);
      const si = dto.sectionIndex;
      const isNew = doc.sectionCount > 0 && !p.seenSections.includes(si);
      await m.update(
        UserDocumentProgress,
        { userId, documentUid: doc.uid },
        {
          lastSection: doc.sectionCount > 0 ? si : p.lastSection,
          seenSections: isNew ? [...p.seenSections, si] : p.seenSections,
          viewMode: dto.viewMode ?? p.viewMode,
        },
      );
      if (isNew)
        await m.insert(LearningActivity, {
          userId,
          type: LearningActivityType.SECTION_VIEW,
          refId: `${doc.id}#${si}`,
        });
    });
    const p = await this.progress.findOne({
      where: { userId, documentUid: doc.uid },
    });
    return this.progressDetail(doc, p ?? undefined);
  }

  /** Lưu lựa chọn (lần cuối), giữ `firstCorrect` của lần đầu. */
  async answerQuiz(userId: string, id: string, dto: QuizAnswerDto) {
    const doc = await this.visibleDoc(id);
    const block = findBlock(doc.content, dto.blockKey);
    if (!block || block.type !== 'quiz')
      throw weeklyError(404, 'BLOCK_NOT_FOUND', 'Không tìm thấy câu hỏi này.');
    const options: unknown[] = Array.isArray(block.options)
      ? block.options
      : [];
    if (dto.option >= options.length)
      throw weeklyError(400, 'QUIZ_OPTION_INVALID', 'Đáp án không hợp lệ.');
    const correct = dto.option === block.answer;
    await this.dataSource.transaction(async (m) => {
      const p = await this.lockProgress(m, userId, doc.uid);
      const prev = p.quizAnswers?.[dto.blockKey];
      const answers = {
        ...(p.quizAnswers ?? {}),
        [dto.blockKey]: {
          option: dto.option,
          firstCorrect: prev ? prev.firstCorrect : correct,
          answeredAt: new Date().toISOString(),
        },
      };
      await m.update(
        UserDocumentProgress,
        { userId, documentUid: doc.uid },
        { quizAnswers: answers },
      );
      await m.insert(LearningActivity, {
        userId,
        type: LearningActivityType.QUIZ_ANSWER,
        refId: `${doc.id}#${dto.blockKey}`,
      });
    });
    return {
      correct,
      answer: block.answer,
      explain: typeof block.explain === 'string' ? block.explain : null,
    };
  }

  /** Ghi `completedAt` lần đầu (idempotent), trả chặng Vũ Môn và streak. */
  async complete(userId: string, id: string) {
    const doc = await this.visibleDoc(id);
    await this.ensureProgress(this.dataSource.manager, userId, doc.uid);
    const allSections = Array.from({ length: doc.sectionCount }, (_, i) => i);
    const res = await this.progress
      .createQueryBuilder()
      .update(UserDocumentProgress)
      .set({ completedAt: () => 'now()', seenSections: allSections })
      .where(
        'user_id = :userId AND document_uid = :uid AND completed_at IS NULL',
        { userId, uid: doc.uid },
      )
      .execute();
    const completedNow = (res.affected ?? 0) > 0;
    if (completedNow)
      await this.activities.insert({
        userId,
        type: LearningActivityType.DOC_COMPLETE,
        refId: doc.id,
      });
    const stage = await this.stage(userId);
    return {
      completedNow,
      weekStage: {
        ...stage,
        passedGate: stage.done >= stage.goal,
        // Chỉ true ở lần hoàn thành làm `done` chạm `goal` lần đầu trong tuần.
        justPassedGate:
          completedNow &&
          stage.done - 1 < stage.goal &&
          stage.done >= stage.goal,
      },
      streak: await this.streak(userId),
    };
  }

  /** Lưu từ vựng của tài liệu vào Sổ từ, bỏ trùng theo `word_norm`, không ghi đè nghĩa của từ đã có. */
  async vocabFromDocument(userId: string, dto: VocabFromDocumentDto) {
    const doc = await this.visibleDoc(dto.documentId);
    const unique = new Map<string, VocabItem>();
    for (const it of vocabItems(doc.content, dto.blockKeys)) {
      const norm = normalizeWord(it.word).slice(0, 120);
      if (!unique.has(norm)) unique.set(norm, it);
    }
    let added = 0;
    if (unique.size) {
      const res = await this.vocab
        .createQueryBuilder()
        .insert()
        .into(VocabEntry)
        .values(
          [...unique].map(([wordNorm, it]) => ({
            userId,
            word: it.word.slice(0, 120),
            wordNorm,
            pos: it.pos?.slice(0, 20) ?? null,
            ipa: it.ipa?.slice(0, 80) ?? null,
            meaning: it.meaning,
            example: it.example ?? null,
            sourceDocumentId: doc.id,
            sourceBlockKey: it.blockKey.slice(0, 60),
          })),
        )
        .orIgnore()
        .returning(['id'])
        .execute();
      added = Array.isArray(res.raw) ? res.raw.length : 0;
    }
    const total = await this.vocab.count({ where: { userId } });
    return { added, existed: unique.size - added, total };
  }

  /** Cho trang chủ ("Ao của bạn", thác Vũ Môn). */
  async summary(userId: string) {
    const { start, end } = vnCalendarWeek();
    const [stage, streakDays, savedWords, wordsLearnedThisWeek] =
      await Promise.all([
        this.stage(userId),
        this.streak(userId),
        this.vocab.count({ where: { userId } }),
        this.vocab
          .createQueryBuilder('v')
          .where(
            'v.userId = :userId AND v.createdAt >= :start AND v.createdAt < :end',
            { userId, start, end },
          )
          .getCount(),
      ]);
    return {
      streakDays,
      savedWords,
      weekStage: { ...stage, passedGate: stage.done >= stage.goal },
      // Chưa có tính năng ôn từ (spaced repetition): luôn 0.
      wordsToReview: 0,
      wordsLearnedThisWeek,
    };
  }

  // ───────────────────────────── Quy tắc tính (file 1 mục 6) ─────────────────────────────

  /** Chặng Vũ Môn: số tài liệu hoàn thành lần đầu trong tuần lịch hiện tại (thứ Hai → Chủ nhật, giờ VN). */
  async stage(userId: string, now = new Date()) {
    const { start, end } = vnCalendarWeek(now);
    const done = await this.progress
      .createQueryBuilder('p')
      .where(
        'p.userId = :userId AND p.completedAt >= :start AND p.completedAt < :end',
        { userId, start, end },
      )
      .getCount();
    return { done, goal: await this.weeks.currentStageGoal(vnDate(now)) };
  }

  async streak(userId: string, now = new Date()) {
    const since = new Date(
      now.getTime() - STREAK_LOOKBACK_DAYS * 24 * 60 * 60 * 1000,
    );
    const rows = await this.activities
      .createQueryBuilder('a')
      .select(
        `DISTINCT to_char((a.occurred_at AT TIME ZONE 'UTC') + interval '7 hours', 'YYYY-MM-DD')`,
        'day',
      )
      .where('a.userId = :userId AND a.occurredAt >= :since', { userId, since })
      .getRawMany<{ day: string }>();
    return streakDays(
      rows.map((r) => r.day),
      vnDate(now),
    );
  }

  // ───────────────────────────── Nội bộ ─────────────────────────────

  /** Người dùng chỉ thấy tài liệu PUBLISHED của tuần đã mở; còn lại 404. */
  private async visibleDoc(
    id: string,
    withHtml = false,
  ): Promise<WeeklyDocument> {
    const qb = this.docs
      .createQueryBuilder('d')
      .innerJoinAndSelect('d.weekRef', 'w')
      .where('d.id = :id', { id });
    if (withHtml) qb.addSelect('d.html');
    const doc = await qb.getOne();
    if (
      doc?.status === DocStatus.PUBLISHED &&
      WeeksService.stateOf(doc.weekRef!) === 'open'
    )
      return doc;
    if (doc?.status === DocStatus.ARCHIVED)
      throw weeklyError(404, 'DOC_UNPUBLISHED', 'Tài liệu này đã được gỡ.');
    throw weeklyError(
      404,
      'DOC_NOT_FOUND',
      'Không tìm thấy tài liệu hoặc tài liệu đã được gỡ.',
    );
  }

  private async ensureProgress(
    m: EntityManager,
    userId: string,
    documentUid: string,
  ) {
    await m
      .createQueryBuilder()
      .insert()
      .into(UserDocumentProgress)
      .values({ userId, documentUid })
      .orIgnore()
      .execute();
  }

  private async lockProgress(
    m: EntityManager,
    userId: string,
    documentUid: string,
  ): Promise<UserDocumentProgress> {
    await this.ensureProgress(m, userId, documentUid);
    return m.findOneOrFail(UserDocumentProgress, {
      where: { userId, documentUid },
      lock: { mode: 'pessimistic_write' },
    });
  }

  private toSummary(d: WeeklyDocument, p?: UserDocumentProgress) {
    // Số section giảm sau khi sửa: kẹp lastSection về section cuối, giữ nguyên "đã hoàn thành".
    const seen = new Set(
      (p?.seenSections ?? []).filter((i) => i < d.sectionCount),
    );
    return {
      id: d.id,
      week: d.week,
      order: d.order,
      title: d.title,
      skill: d.skill,
      template: d.template,
      isHtml: d.template === 'html',
      defaultView: d.defaultView,
      allowedViews: d.allowedViews,
      sectionCount: d.sectionCount,
      estimatedMinutes: d.estimatedMinutes,
      version: d.version,
      progress: {
        lastSection: Math.min(
          p?.lastSection ?? 0,
          Math.max(d.sectionCount - 1, 0),
        ),
        seenCount: seen.size,
        seenSections: [...seen].sort((a, b) => a - b),
        completed: p?.completedAt != null,
      },
    };
  }

  private progressDetail(d: WeeklyDocument, p?: UserDocumentProgress) {
    const answers = Object.fromEntries(
      Object.entries(p?.quizAnswers ?? {}).map(([k, a]) => [
        k,
        { option: a.option, firstCorrect: a.firstCorrect },
      ]),
    );
    return {
      ...this.toSummary(d, p).progress,
      seenSections: (p?.seenSections ?? [])
        .filter((i) => i < d.sectionCount)
        .sort((a, b) => a - b),
      viewMode: p?.viewMode ?? null,
      quizAnswers: answers,
      completedAt: p?.completedAt ?? null,
    };
  }
}
