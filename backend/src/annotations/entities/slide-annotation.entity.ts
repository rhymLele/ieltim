import { Column, Entity, PrimaryColumn, UpdateDateColumn } from 'typeorm';

/** Nét vẽ / ghi chú của người dùng trên một slide. `rev` tăng mỗi lần lưu để phát hiện sửa chồng giữa các máy. */
@Entity('slide_annotations')
export class SlideAnnotation {
  @PrimaryColumn({ name: 'user_id', type: 'uuid' })
  userId: string;

  @PrimaryColumn({ name: 'doc_id', type: 'varchar', length: 40 })
  docId: string;

  /** Khoá slide do FE đặt (`0-1`, `s3`, `doc`…). */
  @PrimaryColumn({ name: 'slide_key', type: 'varchar', length: 40 })
  slideKey: string;

  @Column({ name: 'doc_version', type: 'int' })
  docVersion: number;

  /** `{ items: [...] }`, tối đa 256 KB. */
  @Column({ type: 'jsonb' })
  data: Record<string, any>;

  @Column({ type: 'int', default: 1 })
  rev: number;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
