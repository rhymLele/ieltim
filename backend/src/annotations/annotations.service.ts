import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { IsNull, Repository } from 'typeorm';
import { weeklyError } from '../weekly-docs/weekly-errors';
import { MAX_SLIDE_ANNOTATION_BYTES } from './annotations.constants';
import {
  isSlideData,
  isSlideKey,
  jsonBytes,
  trimHighlightContext,
} from './domain/annotation-rules';
import { HighlightDto, SlideAnnotationDto } from './dto/annotations.dto';
import { SlideAnnotation } from './entities/slide-annotation.entity';
import { TextHighlight } from './entities/text-highlight.entity';

/**
 * Ghi chú cá nhân trên tài liệu: highlight (id do client sinh, xoá mềm) và nét vẽ theo slide (khoá lạc quan `rev`).
 * Quyền (người dùng ACTIVE, tài liệu đang xem được) do guard kiểm tra trước.
 */
@Injectable()
export class AnnotationsService {
  constructor(
    @InjectRepository(TextHighlight)
    private highlights: Repository<TextHighlight>,
    @InjectRepository(SlideAnnotation)
    private slides: Repository<SlideAnnotation>,
  ) {}

  async list(userId: string, docId: string) {
    const [hs, ss] = await Promise.all([
      this.highlights.find({
        where: { userId, docId },
        order: { createdAt: 'ASC', id: 'ASC' },
      }),
      this.slides.find({ where: { userId, docId } }),
    ]);
    return {
      highlights: hs.map(toHighlightJson),
      slides: Object.fromEntries(
        ss.map((s) => [
          s.slideKey,
          { data: s.data, rev: s.rev, docVersion: s.docVersion },
        ]),
      ),
    };
  }

  /**
   * Tạo hoặc ghi đè highlight của tôi (khôi phục nếu đã xoá mềm). Một câu lệnh nên gửi lại song song vẫn an toàn.
   * Id đã thuộc người khác / tài liệu khác → 404.
   */
  async upsertHighlight(
    userId: string,
    docId: string,
    id: string,
    dto: HighlightDto,
  ) {
    const { prefix, suffix } = trimHighlightContext(dto.prefix, dto.suffix);
    const rows: { id: string }[] = await this.highlights.query(
      `INSERT INTO text_highlights
         (id, user_id, doc_id, doc_version, block_key, quote, prefix, suffix, start_offset, end_offset, color)
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
       ON CONFLICT (id) DO UPDATE SET
         doc_version = EXCLUDED.doc_version, block_key = EXCLUDED.block_key, quote = EXCLUDED.quote,
         prefix = EXCLUDED.prefix, suffix = EXCLUDED.suffix, start_offset = EXCLUDED.start_offset,
         end_offset = EXCLUDED.end_offset, color = EXCLUDED.color, deleted_at = NULL, updated_at = now()
       WHERE text_highlights.user_id = EXCLUDED.user_id AND text_highlights.doc_id = EXCLUDED.doc_id
       RETURNING id`,
      [
        id,
        userId,
        docId,
        dto.docVersion,
        dto.blockKey,
        dto.quote,
        prefix,
        suffix,
        dto.start ?? null,
        dto.end ?? null,
        dto.color,
      ],
    );
    if (!rows.length)
      throw weeklyError(
        404,
        'HIGHLIGHT_NOT_FOUND',
        'Không tìm thấy highlight này.',
      );
    return toHighlightJson(await this.highlights.findOneByOrFail({ id }));
  }

  /** Xoá mềm, idempotent: không có cũng coi như xong. */
  async deleteHighlight(userId: string, docId: string, id: string) {
    await this.highlights
      .createQueryBuilder()
      .softDelete()
      .where({ id, userId, docId, deletedAt: IsNull() })
      .execute();
  }

  /**
   * Lưu nét vẽ của một slide. `dto.rev` phải bằng rev hiện tại trên server (0 khi chưa có),
   * không thì 409 kèm bản hiện tại. Điều kiện nằm trong câu lệnh nên hai lần lưu cùng rev chỉ một lần thành công.
   * Lưu `{ items: [] }` vẫn giữ dòng (rev tăng) để máy khác thấy đã xoá hết.
   */
  async saveSlide(
    userId: string,
    docId: string,
    slideKey: string,
    dto: SlideAnnotationDto,
  ) {
    if (!isSlideKey(slideKey))
      throw weeklyError(400, 'SLIDE_KEY_INVALID', 'Mã slide không hợp lệ.');
    if (!isSlideData(dto.data))
      throw weeklyError(
        400,
        'ANNOTATION_INVALID',
        'Dữ liệu vẽ phải có dạng { items: [...] }.',
      );
    if (jsonBytes(dto.data) > MAX_SLIDE_ANNOTATION_BYTES)
      throw weeklyError(
        413,
        'ANNOTATION_TOO_LARGE',
        'Ghi chú trên slide này quá lớn (tối đa 256 KB).',
      );
    const data = dto.data as Record<string, any>;
    const res =
      dto.rev === 0
        ? await this.slides
            .createQueryBuilder()
            .insert()
            .into(SlideAnnotation)
            .values({
              userId,
              docId,
              slideKey,
              docVersion: dto.docVersion,
              data,
              rev: 1,
            })
            .orIgnore()
            .returning(['rev'])
            .execute()
        : await this.slides
            .createQueryBuilder()
            .update(SlideAnnotation)
            .set({ data, docVersion: dto.docVersion, rev: () => 'rev + 1' })
            .where({ userId, docId, slideKey, rev: dto.rev })
            .returning(['rev'])
            .execute();
    const saved = (res.raw as { rev: number }[] | undefined)?.[0];
    if (saved) return { rev: saved.rev };

    const current = await this.slides.findOneBy({ userId, docId, slideKey });
    throw weeklyError(
      409,
      'ANNOTATION_CONFLICT',
      'Ghi chú trên slide này vừa được lưu từ thiết bị khác.',
      { data: current?.data ?? null, rev: current?.rev ?? 0 },
    );
  }
}

export function toHighlightJson(h: TextHighlight) {
  return {
    id: h.id,
    blockKey: h.blockKey,
    quote: h.quote,
    prefix: h.prefix,
    suffix: h.suffix,
    color: h.color,
    start: h.startOffset,
    end: h.endOffset,
    docVersion: h.docVersion,
    createdAt: h.createdAt,
    updatedAt: h.updatedAt,
  };
}
