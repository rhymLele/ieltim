import {
  Column,
  CreateDateColumn,
  Entity,
  PrimaryColumn,
  UpdateDateColumn,
} from 'typeorm';

/** Tuần học. `number` là khoá vì id tài liệu `w{number}-doc{order}` phụ thuộc vào nó và không đổi được (UC-W02). */
@Entity('weeks')
export class Week {
  @PrimaryColumn({ type: 'int' })
  number: number;

  @Column({ name: 'start_date', type: 'date' })
  startDate: string;

  @Column({ name: 'end_date', type: 'date' })
  endDate: string;

  @Column({ type: 'varchar', length: 80, nullable: true })
  title: string | null;

  @Column({ name: 'stage_goal', type: 'int', default: 5 })
  stageGoal: number;

  @CreateDateColumn({ name: 'created_at', type: 'timestamptz' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at', type: 'timestamptz' })
  updatedAt: Date;
}
