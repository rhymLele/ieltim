import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Vocabulary } from './vocabulary.entity';

@Entity('collocations')
export class Collocation {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'vocabulary_id', type: 'uuid' })
  vocabularyId: string;

  @ManyToOne(() => Vocabulary, { eager: false })
  @JoinColumn({ name: 'vocabulary_id' })
  vocabulary: Vocabulary;

  @Column()
  phrase: string;

  @Column({ type: 'text', nullable: true })
  example: string | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
