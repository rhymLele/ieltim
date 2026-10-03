import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryGeneratedColumn,
  Unique,
} from 'typeorm';

/** Sổ từ của người dùng (bỏ trùng theo `word_norm`). */
@Entity('vocab_entries')
@Unique('uq_vocab_entries_user_word', ['userId', 'wordNorm'])
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

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;
}
