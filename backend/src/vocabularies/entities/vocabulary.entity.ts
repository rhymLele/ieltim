import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  OneToMany,
} from 'typeorm';
import { Level } from '../../common/enums/level.enum';
import { Status } from '../../common/enums/status.enum';
import { Collocation } from './collocation.entity';

@Entity('vocabularies')
export class Vocabulary {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column()
  term: string;

  @Column({ type: 'text' })
  definition: string;

  @Column({ name: 'vietnamese_meaning', type: 'text', nullable: true })
  vietnameseMeaning: string | null;

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

  @OneToMany(() => Collocation, (c) => c.vocabulary)
  collocations: Collocation[];
}
