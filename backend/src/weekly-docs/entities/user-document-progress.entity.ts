import { Column, Entity, PrimaryColumn, UpdateDateColumn } from 'typeorm';

export interface QuizAnswer {
  option: number;
  firstCorrect: boolean;
  answeredAt: string;
}

@Entity('user_document_progress')
export class UserDocumentProgress {
  @PrimaryColumn({ name: 'user_id', type: 'uuid' })
  userId: string;

  @PrimaryColumn({ name: 'document_uid', type: 'uuid' })
  documentUid: string;

  @Column({ name: 'last_section', type: 'int', default: 0 })
  lastSection: number;

  @Column({
    name: 'seen_sections',
    type: 'int',
    array: true,
    default: () => "'{}'",
  })
  seenSections: number[];

  @Column({ name: 'view_mode', type: 'varchar', length: 10, nullable: true })
  viewMode: string | null;

  @Column({ name: 'quiz_answers', type: 'jsonb', default: () => "'{}'" })
  quizAnswers: Record<string, QuizAnswer>;

  @Column({ name: 'completed_at', type: 'timestamptz', nullable: true })
  completedAt: Date | null;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
