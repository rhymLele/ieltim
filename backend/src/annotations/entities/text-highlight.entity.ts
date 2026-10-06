import {
  Column,
  CreateDateColumn,
  DeleteDateColumn,
  Entity,
  Index,
  PrimaryColumn,
  UpdateDateColumn,
} from 'typeorm';

/**
 * Highlight của người dùng trên tài liệu. `id` do client sinh (uuid) để lưu offline rồi đồng bộ.
 * Vị trí neo theo `blockKey` + `quote` + ngữ cảnh `prefix` / `suffix` (offset chỉ là gợi ý).
 */
@Entity('text_highlights')
@Index('idx_text_highlights_user_doc', ['userId', 'docId'], {
  where: '"deleted_at" IS NULL',
})
export class TextHighlight {
  @PrimaryColumn({ type: 'uuid' })
  id: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  /** Mã công khai của tài liệu (`w12-doc2`, `w12-hw1`). */
  @Column({ name: 'doc_id', type: 'varchar', length: 40 })
  docId: string;

  @Column({ name: 'doc_version', type: 'int' })
  docVersion: number;

  /** Khoá khối trong JSON tài liệu, hoặc `html` với tài liệu HTML. */
  @Column({ name: 'block_key', type: 'varchar', length: 80 })
  blockKey: string;

  @Column({ type: 'text' })
  quote: string;

  @Column({ type: 'varchar', length: 64, default: '' })
  prefix: string;

  @Column({ type: 'varchar', length: 64, default: '' })
  suffix: string;

  @Column({ name: 'start_offset', type: 'int', nullable: true })
  startOffset: number | null;

  @Column({ name: 'end_offset', type: 'int', nullable: true })
  endOffset: number | null;

  @Column({ type: 'varchar', length: 8 })
  color: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;

  @DeleteDateColumn({ name: 'deleted_at', type: 'timestamptz' })
  deletedAt: Date | null;
}
