import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { DocumentBlock } from './entities/document-block.entity';
import { BlockType } from '../common/enums/block-type.enum';

@Injectable()
export class DocumentBlocksService {
  constructor(
    @InjectRepository(DocumentBlock)
    private blockRepo: Repository<DocumentBlock>,
  ) {}

  async findByDocumentId(documentId: string) {
    return this.blockRepo.find({
      where: { documentId },
      order: { position: 'ASC' },
    });
  }

  async create(data: {
    documentId: string;
    blockType: BlockType;
    position: number;
    data: Record<string, any>;
  }) {
    const block = this.blockRepo.create(data);
    return this.blockRepo.save(block);
  }

  async update(id: string, data: Partial<Pick<DocumentBlock, 'blockType' | 'position' | 'data'>>) {
    const block = await this.blockRepo.findOne({ where: { id } });
    if (!block) return null;
    Object.assign(block, data);
    return this.blockRepo.save(block);
  }

  async remove(id: string) {
    return this.blockRepo.delete(id);
  }

  async reorder(documentId: string, orderedIds: string[]) {
    for (let i = 0; i < orderedIds.length; i++) {
      await this.blockRepo.update(orderedIds[i], { position: i + 1 });
    }
    return this.findByDocumentId(documentId);
  }
}
