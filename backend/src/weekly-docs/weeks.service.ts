import { Injectable } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { addDays, isMonday, vnDate } from './domain/vn-time';
import { weeksToGenerate } from './domain/week-plan';
import { CreateWeekDto, UpdateWeekDto } from './dto/week.dto';
import { Week } from './entities/week.entity';
import { WeeklyDocument } from './entities/weekly-document.entity';
import { DocStatus } from './enums/weekly-docs.enums';
import {
  DEFAULT_STAGE_GOAL,
  DEFAULT_WEEKS_AHEAD,
} from './weekly-docs.constants';
import { weeklyError } from './weekly-errors';

export type WeekState = 'locked' | 'open';

/** Quản lý tuần (file 7 mục 3) + các hàm tính trạng thái tuần dùng chung. */
@Injectable()
export class WeeksService {
  constructor(
    @InjectRepository(Week) private weeks: Repository<Week>,
    @InjectRepository(WeeklyDocument) private docs: Repository<WeeklyDocument>,
    private config: ConfigService,
  ) {}

  /** Số tuần tới luôn có sẵn để admin soạn trước (WEEKLY_WEEKS_AHEAD, mặc định 4). */
  weeksAhead(): number {
    const n = Number(
      this.config.get('WEEKLY_WEEKS_AHEAD') ?? DEFAULT_WEEKS_AHEAD,
    );
    return Number.isInteger(n) && n >= 0
      ? Math.min(n, 52)
      : DEFAULT_WEEKS_AHEAD;
  }

  /**
   * Tự sinh tuần: nối tiếp tuần cuối tới hết tuần này + `weeksAhead()` tuần. Gọi lúc liệt kê tuần,
   * lúc tạo tài liệu và trong job mỗi giờ. Chạy song song an toàn (bỏ qua số tuần đã có).
   */
  async ensureUpcoming(now = new Date()): Promise<number[]> {
    const [last] = await this.weeks.find({
      order: { number: 'DESC' },
      take: 1,
    });
    const slots = weeksToGenerate(last ?? null, this.weeksAhead(), now);
    if (!slots.length) return [];
    await this.weeks
      .createQueryBuilder()
      .insert()
      .into(Week)
      .values(slots.map((s) => ({ ...s, stageGoal: DEFAULT_STAGE_GOAL })))
      .orIgnore()
      .execute();
    return slots.map((s) => s.number);
  }

  /** `locked` khi chưa tới ngày bắt đầu (giờ Việt Nam), `open` từ ngày đó trở đi. */
  static stateOf(week: Pick<Week, 'startDate'>, today = vnDate()): WeekState {
    return today < week.startDate ? 'locked' : 'open';
  }

  /** Người dùng chỉ thấy tài liệu PUBLISHED của tuần đã mở (dùng chung cho Sổ từ, ghi chú…). */
  static docVisible(
    doc: Pick<WeeklyDocument, 'status' | 'weekRef'> | null | undefined,
    today = vnDate(),
  ): boolean {
    return (
      doc?.status === DocStatus.PUBLISHED &&
      !!doc.weekRef &&
      WeeksService.stateOf(doc.weekRef, today) === 'open'
    );
  }

  async findOrFail(number: number): Promise<Week> {
    const week = await this.weeks.findOne({ where: { number } });
    if (week) return week;
    const [last] = await this.weeks.find({
      order: { number: 'DESC' },
      take: 1,
    });
    throw weeklyError(
      404,
      'WEEK_NOT_FOUND',
      last
        ? `Chưa có Tuần ${number}. Hệ thống tự tạo sẵn các tuần tới, hiện có tới Tuần ${last.number}.`
        : `Chưa có Tuần ${number}.`,
    );
  }

  /** Tuần chứa ngày hôm nay (giờ Việt Nam), null nếu chưa tạo. */
  async current(today = vnDate()): Promise<Week | null> {
    return this.weeks
      .createQueryBuilder('w')
      .where('w.startDate <= :today AND w.endDate >= :today', { today })
      .getOne();
  }

  async currentStageGoal(today = vnDate()): Promise<number> {
    return (await this.current(today))?.stageGoal ?? DEFAULT_STAGE_GOAL;
  }

  // ───────────────────────────── Admin ─────────────────────────────

  async adminList() {
    await this.ensureUpcoming();
    const today = vnDate();
    const weeks = await this.weeks.find({ order: { number: 'ASC' } });
    const counts: { week: number; status: DocStatus; n: string }[] =
      await this.docs
        .createQueryBuilder('d')
        .select('d.week', 'week')
        .addSelect('d.status', 'status')
        .addSelect('COUNT(*)', 'n')
        .groupBy('d.week')
        .addGroupBy('d.status')
        .getRawMany();
    const last = weeks[weeks.length - 1];
    return {
      data: weeks.map((w) => {
        const byStatus = Object.fromEntries(
          counts
            .filter((c) => c.week === w.number)
            .map((c) => [c.status, Number(c.n)]),
        );
        const docCount = Object.values(byStatus).reduce(
          (a: number, b: number) => a + b,
          0,
        );
        return {
          ...this.toDto(w, today),
          docCount,
          docCountByStatus: byStatus,
        };
      }),
      // Gợi ý cho form tạo tuần (UC-W01).
      suggestion: last
        ? { number: last.number + 1, startDate: addDays(last.startDate, 7) }
        : { number: 1, startDate: nextMonday(today) },
    };
  }

  async create(dto: CreateWeekDto) {
    if (!isMonday(dto.startDate))
      throw weeklyError(
        400,
        'WEEK_START_NOT_MONDAY',
        'Ngày bắt đầu tuần phải là thứ Hai.',
      );
    if (await this.weeks.exists({ where: { number: dto.number } })) {
      throw weeklyError(
        409,
        'WEEK_NUMBER_TAKEN',
        `Tuần ${dto.number} đã tồn tại.`,
      );
    }
    const endDate = addDays(dto.startDate, 6);
    await this.assertNoOverlap(dto.startDate, endDate);
    const week = await this.weeks.save(
      this.weeks.create({
        number: dto.number,
        startDate: dto.startDate,
        endDate,
        title: dto.title?.trim() || null,
        stageGoal: dto.stageGoal ?? DEFAULT_STAGE_GOAL,
      }),
    );
    return this.toDto(week);
  }

  async update(number: number, dto: UpdateWeekDto) {
    const week = await this.findOrFail(number);
    if (dto.startDate !== undefined && dto.startDate !== week.startDate) {
      if (!isMonday(dto.startDate))
        throw weeklyError(
          400,
          'WEEK_START_NOT_MONDAY',
          'Ngày bắt đầu tuần phải là thứ Hai.',
        );
      const hasPublished = await this.docs.exists({
        where: { week: number, status: DocStatus.PUBLISHED },
      });
      if (WeeksService.stateOf(week) === 'open' || hasPublished) {
        throw weeklyError(
          409,
          'WEEK_DATE_LOCKED',
          'Tuần đã mở hoặc đã có tài liệu xuất bản, không đổi được ngày.',
        );
      }
      const endDate = addDays(dto.startDate, 6);
      await this.assertNoOverlap(dto.startDate, endDate, number);
      week.startDate = dto.startDate;
      week.endDate = endDate;
    }
    if (dto.title !== undefined) week.title = dto.title?.trim() || null;
    if (dto.stageGoal !== undefined) week.stageGoal = dto.stageGoal;
    return this.toDto(await this.weeks.save(week));
  }

  async remove(number: number) {
    await this.findOrFail(number);
    if (await this.docs.exists({ where: { week: number } })) {
      throw weeklyError(
        409,
        'WEEK_NOT_EMPTY',
        'Xoá hoặc chuyển hết tài liệu trước khi xoá tuần.',
      );
    }
    // Tài liệu đã xoá mềm vẫn giữ khoá ngoại tới tuần: xoá hẳn trước.
    await this.docs
      .createQueryBuilder()
      .delete()
      .where('week_number = :number AND deleted_at IS NOT NULL', { number })
      .execute();
    await this.weeks.delete({ number });
    return { number, deleted: true };
  }

  toDto(w: Week, today = vnDate()) {
    return {
      id: w.number,
      number: w.number,
      startDate: w.startDate,
      endDate: w.endDate,
      title: w.title,
      stageGoal: w.stageGoal,
      state: WeeksService.stateOf(w, today),
    };
  }

  private async assertNoOverlap(
    startDate: string,
    endDate: string,
    exceptNumber?: number,
  ) {
    const qb = this.weeks
      .createQueryBuilder('w')
      .where('w.startDate <= :endDate AND w.endDate >= :startDate', {
        startDate,
        endDate,
      });
    if (exceptNumber !== undefined)
      qb.andWhere('w.number <> :exceptNumber', { exceptNumber });
    const other = await qb.getOne();
    if (other)
      throw weeklyError(
        409,
        'WEEK_OVERLAP',
        `Khoảng ngày bị trùng với Tuần ${other.number}.`,
      );
  }
}

function nextMonday(today: string): string {
  for (let i = 1; i <= 7; i++) {
    const d = addDays(today, i);
    if (isMonday(d)) return d;
  }
  return today;
}
