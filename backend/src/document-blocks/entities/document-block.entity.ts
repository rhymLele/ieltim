import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { BlockType } from '../../common/enums/block-type.enum';
import { Document } from '../../documents/entities/document.entity';

@Entity('document_blocks')
export class DocumentBlock {
  @PrimaryGeneratedColumn('uuid')
  id: string;

  @Column({ name: 'document_id', type: 'uuid' })
  documentId: string;

  @ManyToOne(() => Document, { eager: false })
  @JoinColumn({ name: 'document_id' })
  document: Document;

  @Column({ name: 'block_type', type: 'enum', enum: BlockType })
  blockType: BlockType;

  @Column({ type: 'int' })
  position: number;

  @Column({ type: 'jsonb' })
  data: Record<string, any>;

  @CreateDateColumn({ name: 'created_at' })
  createdAt: Date;

  @UpdateDateColumn({ name: 'updated_at' })
  updatedAt: Date;
}
