import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
} from 'typeorm';
import { Level } from '../../common/enums/level.enum';
import { Status } from '../../common/enums/status.enum';

@Entity('sentence_patterns')
export class SentencePattern {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ type: 'text' })
  pattern: string;

  @Column({ type: 'text', nullable: true })
  meaning: string | null;

  @Column({ type: 'text', nullable: true })
  usage: string | null;

  @Column({ type: 'text', nullable: true })
  example: string | null;

  @Column({ type: 'enum', enum: Level, default: Level.B1 })
  level: Level;

  @Column({ type: 'enum', enum: Status, default: Status.DRAFT })
  status: Status;

  @Column({ name: 'created_by', type: 'uuid', nullable: true })
  createdBy: string | null;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
