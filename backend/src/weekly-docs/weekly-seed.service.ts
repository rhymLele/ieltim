import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { normalizeDoc, docCode } from './domain/doc-content';
import {
  DOC_TEMPLATES,
  buildDocFromTemplate,
  sampleReadingDoc,
} from './domain/templates';
import { addDays, vnCalendarWeek } from './domain/vn-time';
import { Week } from './entities/week.entity';
import { WeeklyDocument } from './entities/weekly-document.entity';
import { DocStatus } from './enums/weekly-docs.enums';

/**
 * Seed (file 2 mục 5): trên DB trống, Tuần 10–13 quanh tuần hiện tại (Tuần 12 = tuần này, 13 ở tương lai),
 * `w12-doc1` đã xuất bản (đủ 8 loại khối), `w12-doc2` nháp Writing Task 2. Chạy lại không tạo trùng.
 */
@Injectable()
export class WeeklySeedService {
  constructor(
    @InjectRepository(Week) private weeks: Repository<Week>,
    @InjectRepository(WeeklyDocument) private docs: Repository<WeeklyDocument>,
  ) {}

  async seed(now = new Date()) {
    const { monday } = vnCalendarWeek(now);
    const created: string[] = [];
    // Chỉ dựng Tuần 10–13 trên DB trống: DB đã có tuần (tự sinh hoặc seed trước) thì giữ nguyên để không chồng ngày.
    const weeksToSeed =
      (await this.weeks.count()) === 0 ? [10, 11, 12, 13] : [];
    for (const number of weeksToSeed) {
      const startDate = addDays(monday, (number - 12) * 7);
      await this.weeks.insert({
        number,
        startDate,
        endDate: addDays(startDate, 6),
        stageGoal: 5,
      });
      created.push(`Tuần ${number}`);
    }

    const writing = DOC_TEMPLATES.find((t) => t.id === 'writing-task2')!;
    const samples = [
      { json: sampleReadingDoc(12), order: 1, status: DocStatus.PUBLISHED },
      {
        json: buildDocFromTemplate(writing, {
          week: 12,
          order: 2,
          title: 'Writing Task 2: Opinion essay',
          skill: 'writing',
        }),
        order: 2,
        status: DocStatus.DRAFT,
      },
    ];
    // Tài liệu mẫu chỉ tạo khi có Tuần 12.
    const hasWeek12 = await this.weeks.exists({ where: { number: 12 } });
    for (const s of hasWeek12 ? samples : []) {
      const id = docCode(12, s.order);
      if (await this.docs.exists({ where: { id } })) continue;
      const n = normalizeDoc(s.json, { week: 12, order: s.order });
      await this.docs.insert({
        id,
        week: 12,
        order: s.order,
        content: n.content,
        title: n.title,
        skill: n.skill,
        template: n.template,
        defaultView: n.defaultView,
        allowedViews: n.allowedViews,
        sectionCount: n.sectionCount,
        estimatedMinutes: n.estimatedMinutes,
        status: s.status,
        publishedAt: s.status === DocStatus.PUBLISHED ? now : null,
        updatedByName: 'Seed',
      });
      created.push(id);
    }
    return { created };
  }
}
