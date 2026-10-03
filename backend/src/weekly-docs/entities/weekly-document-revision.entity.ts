import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
  UpdateDateColumn,
} from 'typeorm';
import { RevisionNote } from '../enums/weekly-docs.enums';

/** Lịch sử phiên bản (UC-D14). Các lần tự lưu liên tiếp của cùng người được gộp vào một dòng. */
@Entity('weekly_document_revisions')
@Index(['documentUid', 'createdAt'])
export class WeeklyDocumentRevision {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'document_uid', type: 'uuid' })
  documentUid: string;

  @Column({ type: 'int' })
  version: number;

  @Column({ type: 'varchar', length: 20 })
  note: RevisionNote;

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

  @Column({ name: 'edited_by', type: 'uuid', nullable: true })
  editedBy: string | null;

  @Column({
    name: 'edited_by_name',
    type: 'varchar',
    length: 120,
    nullable: true,
  })
  editedByName: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
