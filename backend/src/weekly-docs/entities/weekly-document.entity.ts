import {
  Column,
  CreateDateColumn,
  DeleteDateColumn,
  Entity,
  Index,
  JoinColumn,
  ManyToOne,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { DocStatus } from '../enums/weekly-docs.enums';
import { Week } from './week.entity';

/**
 * Tài liệu theo tuần. `uid` là khoá nội bộ (tiến độ, lịch sử trỏ vào đây); `id` (`w12-doc1`) là mã công khai,
 * đổi được khi sắp xếp lại tài liệu chưa từng xuất bản (UC-D10).
 * Cột `html` / `draft_*` không tự select: API danh sách không đọc chuỗi html tới 5 MB.
 */
@Entity('weekly_documents')
@Index('uq_weekly_documents_code', ['id'], {
  unique: true,
  where: '"deleted_at" IS NULL',
})
@Index('uq_weekly_documents_week_order', ['week', 'order'], {
  unique: true,
  where: '"deleted_at" IS NULL',
})
export class WeeklyDocument {
  @PrimaryGeneratedColumn('uuid')
  uid: string;

  @Column({ type: 'varchar', length: 40 })
  id: string;

  @Column({ name: 'week_number', type: 'int' })
  week: number;

  @ManyToOne(() => Week, { onDelete: 'RESTRICT' })
  @JoinColumn({ name: 'week_number' })
  weekRef?: Week;

  @Column({ name: 'order', type: 'int' })
  order: number;

  @Column({ type: 'varchar', length: 200 })
  title: string;

  @Column({ type: 'varchar', length: 20 })
  skill: string;

  @Column({ type: 'varchar', length: 40 })
  template: string;

  @Column({
    name: 'default_view',
    type: 'varchar',
    length: 10,
    default: 'slide',
  })
  defaultView: string;

  @Column({
    name: 'allowed_views',
    type: 'text',
    array: true,
    default: () => "'{slide,doc}'",
  })
  allowedViews: string[];

  @Column({ name: 'schema_version', type: 'int', default: 1 })
  schemaVersion: number;

  /** Bản đang dùng: bản phát hành nếu PUBLISHED, bản đang soạn nếu DRAFT / SCHEDULED / ARCHIVED. */
  @Column({ type: 'jsonb' })
  content: Record<string, any>;

  @Column({ type: 'text', nullable: true, select: false })
  html: string | null;

  @Column({
    name: 'html_file_name',
    type: 'varchar',
    length: 255,
    nullable: true,
  })
  htmlFileName: string | null;

  @Column({ name: 'html_size', type: 'int', default: 0 })
  htmlSize: number;

  /** Bản nháp sửa đổi của tài liệu đang PUBLISHED (UC-D03): chỉ áp dụng khi "Cập nhật bản phát hành". */
  @Column({ name: 'has_revision_draft', type: 'boolean', default: false })
  hasRevisionDraft: boolean;

  @Column({
    name: 'draft_content',
    type: 'jsonb',
    nullable: true,
    select: false,
  })
  draftContent: Record<string, any> | null;

  @Column({ name: 'draft_html', type: 'text', nullable: true, select: false })
  draftHtml: string | null;

  @Column({
    name: 'draft_html_file_name',
    type: 'varchar',
    length: 255,
    nullable: true,
    select: false,
  })
  draftHtmlFileName: string | null;

  @Column({ type: 'varchar', length: 12, default: DocStatus.DRAFT })
  status: DocStatus;

  @Column({ name: 'publish_at', type: 'timestamptz', nullable: true })
  publishAt: Date | null;

  /** Lần xuất bản gần nhất; khác null nghĩa là "đã từng xuất bản" (không xoá, không đổi thứ tự được). */
  @Column({ name: 'published_at', type: 'timestamptz', nullable: true })
  publishedAt: Date | null;

  @Column({ type: 'int', default: 1 })
  version: number;

  @Column({ name: 'section_count', type: 'int', default: 0 })
  sectionCount: number;

  @Column({ name: 'estimated_minutes', type: 'int', default: 1 })
  estimatedMinutes: number;

  @Column({ name: 'created_by', type: 'uuid', nullable: true })
  createdBy: string | null;

  @Column({ name: 'updated_by', type: 'uuid', nullable: true })
  updatedBy: string | null;

  @Column({
    name: 'updated_by_name',
    type: 'varchar',
    length: 120,
    nullable: true,
  })
  updatedByName: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

  @DeleteDateColumn({ name: 'deleted_at', type: 'timestamptz' })
  deletedAt: Date | null;
}
