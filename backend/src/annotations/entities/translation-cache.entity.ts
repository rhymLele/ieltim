import { Column, CreateDateColumn, Entity, PrimaryColumn } from 'typeorm';
import type { TranslationPayload } from '../domain/translation';

/** Kết quả dịch dùng lại cho mọi người. Khoá: sha1 của từ / cụm + câu (chữ thường). */
@Entity('translation_cache')
export class TranslationCache {
  @PrimaryColumn({ type: 'text' })
  key: string;

  @Column({ type: 'jsonb' })
  payload: TranslationPayload;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
