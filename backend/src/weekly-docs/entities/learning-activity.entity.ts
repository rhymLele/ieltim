import { Column, Entity, Index, PrimaryGeneratedColumn } from 'typeorm';
import { LearningActivityType } from '../enums/weekly-docs.enums';

/** Hoạt động học, dùng tính streak (file 1 mục 6). */
@Entity('learning_activities')
@Index(['userId', 'occurredAt'])
export class LearningActivity {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'user_id', type: 'uuid' })
  userId: string;

  @Column({ type: 'varchar', length: 20 })
  type: LearningActivityType;

  @Column({ name: 'ref_id', type: 'varchar', length: 80, nullable: true })
  refId: string | null;

  @Column({ name: 'occurred_at', type: 'timestamptz', default: () => 'now()' })
  occurredAt: Date;
}
