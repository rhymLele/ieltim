import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  ManyToOne,
  JoinColumn,
  CreateDateColumn,
  Unique,
} from 'typeorm';
import { Document } from '../../documents/entities/document.entity';
import { SentencePattern } from '../../sentence-patterns/entities/sentence-pattern.entity';

@Entity('lesson_sentence_patterns')
@Unique(['lessonId', 'sentencePatternId'])
export class LessonSentencePattern {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'lesson_id', type: 'uuid' })
  lessonId: string;

  @ManyToOne(() => Document, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'lesson_id' })
  lesson: Document;

  @Column({ name: 'sentence_pattern_id', type: 'uuid' })
  sentencePatternId: string;

  @ManyToOne(() => SentencePattern, { onDelete: 'CASCADE' })
  @JoinColumn({ name: 'sentence_pattern_id' })
  sentencePattern: SentencePattern;

  @Column({ type: 'int', default: 0 })
  position: number;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;
}
