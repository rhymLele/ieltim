import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { SentencePattern } from './entities/sentence-pattern.entity';
import { Status } from '../common/enums/status.enum';
import { Level } from '../common/enums/level.enum';

@Injectable()
export class SentencePatternsService {
  constructor(
    @InjectRepository(SentencePattern)
    private spRepo: Repository<SentencePattern>,
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

    const qb = this.spRepo.createQueryBuilder('sp');

    if (query.level) {
      qb.andWhere('sp.level = :level', { level: query.level });
    }
    if (query.role === 'USER') {
      qb.andWhere('sp.status = :status', { status: Status.PUBLISHED });
    } else if (query.status) {
      qb.andWhere('sp.status = :status', { status: query.status });
    }

    qb.orderBy('sp.createdAt', 'DESC')
      .skip((page - 1) * pageSize)
      .take(pageSize);

    const [data, total] = await qb.getManyAndCount();
    return {
      data,
      pagination: { page, pageSize, total, totalPages: Math.ceil(total / pageSize) },
    };
  }

  async findById(id: string, role: string) {
    const sp = await this.spRepo.findOne({ where: { id } });
    if (!sp) return null;
    if (role === 'USER' && sp.status !== Status.PUBLISHED) return null;
    return sp;
  }

  async create(data: Partial<SentencePattern>, userId: string) {
    const sp = this.spRepo.create({ ...data, createdBy: userId });
    return this.spRepo.save(sp);
  }

  async update(id: string, data: Partial<SentencePattern>) {
    const sp = await this.spRepo.findOne({ where: { id } });
    if (!sp) return null;
    Object.assign(sp, data);
    return this.spRepo.save(sp);
  }

  async remove(id: string) {
    return this.spRepo.delete(id);
  }

  async publish(id: string) {
    const sp = await this.spRepo.findOne({ where: { id } });
    if (!sp) return null;
    sp.status = Status.PUBLISHED;
    return this.spRepo.save(sp);
  }
}
