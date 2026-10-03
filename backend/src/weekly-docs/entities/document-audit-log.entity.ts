import {
  Column,
  CreateDateColumn,
  Entity,
  Index,
  PrimaryGeneratedColumn,
} from 'typeorm';
import { AuditAction } from '../enums/weekly-docs.enums';

/** Nhật ký thao tác trên tài liệu (file 7 mục 6). */
@Entity('document_audit_logs')
@Index(['documentUid', 'createdAt'])
export class DocumentAuditLog {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'document_uid', type: 'uuid' })
  documentUid: string;

  /** Mã tài liệu tại thời điểm ghi (mã đổi được khi sắp xếp lại). */
  @Column({ name: 'document_id', type: 'varchar', length: 40 })
  documentId: string;

  @Column({ type: 'varchar', length: 20 })
  action: AuditAction;

  @Column({ name: 'actor_id', type: 'uuid', nullable: true })
  actorId: string | null;

  @Column({ name: 'actor_name', type: 'varchar', length: 120, nullable: true })
  actorName: string | null;

  @Column({ name: 'from_status', type: 'varchar', length: 12, nullable: true })
  fromStatus: string | null;

  @Column({ name: 'to_status', type: 'varchar', length: 12, nullable: true })
  toStatus: string | null;

  @Column({ type: 'int', nullable: true })
  version: number | null;

  @Column({ type: 'varchar', length: 500, nullable: true })
  note: string | null;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
