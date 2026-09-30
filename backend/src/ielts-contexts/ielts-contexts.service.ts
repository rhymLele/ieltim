import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { IeltsContext } from './entities/ielts-context.entity';

@Injectable()
export class IeltsContextsService {
  constructor(
    @InjectRepository(IeltsContext)
    private contextRepo: Repository<IeltsContext>,
  ) {}

  findAll() {
    return this.contextRepo.find();
  }

  async seed() {
    const contexts = [
      { code: 'WRITING_TASK_1', name: 'Writing Task 1' },
      { code: 'WRITING_TASK_2', name: 'Writing Task 2' },
      { code: 'SPEAKING_PART_1', name: 'Speaking Part 1' },
      { code: 'SPEAKING_PART_2', name: 'Speaking Part 2' },
      { code: 'SPEAKING_PART_3', name: 'Speaking Part 3' },
    ];

    for (const ctx of contexts) {
      const existing = await this.contextRepo.findOne({ where: { code: ctx.code } });
      if (!existing) {
        await this.contextRepo.save(this.contextRepo.create(ctx));
      }
    }
  }
}
