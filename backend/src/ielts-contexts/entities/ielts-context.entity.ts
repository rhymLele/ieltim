import { Entity, PrimaryGeneratedColumn, Column } from 'typeorm';

@Entity('ielts_contexts')
export class IeltsContext {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ unique: true })
  code: string;

  @Column({ unique: true })
  name: string;
}
