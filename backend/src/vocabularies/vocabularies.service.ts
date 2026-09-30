import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Vocabulary } from './entities/vocabulary.entity';
import { Collocation } from './entities/collocation.entity';
import { Status } from '../common/enums/status.enum';
import { Level } from '../common/enums/level.enum';

@Injectable()
export class VocabulariesService {
  constructor(
    @InjectRepository(Vocabulary)
    private vocabRepo: Repository<Vocabulary>,
    @InjectRepository(Collocation)
    private collocationRepo: Repository<Collocation>,
  ) {}

  async findAll(query: {
    level?: Level;
    status?: Status;
    role?: string;
    page?: number;
    pageSize?: number;
  }) {
    const page = query.page || 1;
    const pageSize = query.pageSize || 20;

    const qb = this.vocabRepo.createQueryBuilder('v');

    if (query.level) {
      qb.andWhere('v.level = :level', { level: query.level });
    }
    if (query.role === 'USER') {
      qb.andWhere('v.status = :status', { status: Status.PUBLISHED });
    } else if (query.status) {
      qb.andWhere('v.status = :status', { status: query.status });
    }

    qb.orderBy('v.createdAt', 'DESC')
      .skip((page - 1) * pageSize)
      .take(pageSize);

    const [data, total] = await qb.getManyAndCount();
    return {
      data,
      pagination: { page, pageSize, total, totalPages: Math.ceil(total / pageSize) },
    };
  }

  async findById(id: string, role: string) {
    const vocab = await this.vocabRepo.findOne({ where: { id } });
    if (!vocab) return null;
    if (role === 'USER' && vocab.status !== Status.PUBLISHED) return null;

    const collocations = await this.collocationRepo.find({
      where: { vocabularyId: id },
    });
    return { ...vocab, collocations };
  }

  async create(data: Partial<Vocabulary>, userId: string) {
    const vocab = this.vocabRepo.create({ ...data, createdBy: userId });
    return this.vocabRepo.save(vocab);
  }

  async update(id: string, data: Partial<Vocabulary>) {
    const vocab = await this.vocabRepo.findOne({ where: { id } });
    if (!vocab) return null;
    Object.assign(vocab, data);
    return this.vocabRepo.save(vocab);
  }

  async remove(id: string) {
    await this.collocationRepo.delete({ vocabularyId: id });
    return this.vocabRepo.delete(id);
  }

  async publish(id: string) {
    const vocab = await this.vocabRepo.findOne({ where: { id } });
    if (!vocab) return null;
    vocab.status = Status.PUBLISHED;
    return this.vocabRepo.save(vocab);
  }
}
