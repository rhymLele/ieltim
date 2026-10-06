import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';
import { DEFAULT_VOCAB_DECK } from '../weekly-docs.constants';

/** Sổ từ của người dùng (bỏ trùng theo `word_norm` trong từng sổ `deck`). */
@Entity('vocab_entries')
@Unique('uq_vocab_entries_user_word_deck', ['userId', 'wordNorm', 'deck'])
export class VocabEntry {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @Column({ type: 'varchar', length: 120 })
  word: string;

  @Column({ name: 'word_norm', type: 'varchar', length: 120 })
  wordNorm: string;

  @Column({ type: 'varchar', length: 20, nullable: true })
  pos: string | null;

  @Column({ type: 'varchar', length: 80, nullable: true })
  ipa: string | null;

  @Column({ type: 'text' })
  meaning: string;

  @Column({ type: 'text', nullable: true })
  example: string | null;

  @Column({
    name: 'source_document_id',
    type: 'varchar',
    length: 40,
    nullable: true,
  })
  sourceDocumentId: string | null;

  @Column({
    name: 'source_block_key',
    type: 'varchar',
    length: 60,
    nullable: true,
  })
  sourceBlockKey: string | null;

  /** Tên sổ từ người dùng tự đặt; dữ liệu cũ nhận mặc định 'Sổ chung'. */
  @Column({ type: 'varchar', length: 60, default: DEFAULT_VOCAB_DECK })
  deck: string;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
