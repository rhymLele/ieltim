import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Document } from './entities/document.entity';
import { Status } from '../common/enums/status.enum';
import { DocumentType } from '../common/enums/document-type.enum';

@Injectable()
export class DocumentsService {
  constructor(
    @InjectRepository(Document)
    private docRepo: Repository<Document>,
  ) {}

  async findAll(query: {
    type?: DocumentType;
    week?: number;
    status?: Status;
    role?: string;
    page?: number;
    pageSize?: number;
  }) {
    const page = query.page || 1;
    const pageSize = query.pageSize || 20;

    const qb = this.docRepo.createQueryBuilder('doc');

    if (query.type) {
      qb.andWhere('doc.type = :type', { type: query.type });
    }
    if (query.week) {
      qb.andWhere('doc.weekNumber = :week', { week: query.week });
    }
    if (query.role === 'USER') {
      qb.andWhere('doc.status = :status', { status: Status.PUBLISHED });
    } else if (query.status) {
      qb.andWhere('doc.status = :status', { status: query.status });
    }

    qb.orderBy('doc.createdAt', 'DESC')
      .skip((page - 1) * pageSize)
      .take(pageSize);

    const [data, total] = await qb.getManyAndCount();
    return {
      data,
      pagination: {
        page,
        pageSize,
        total,
        totalPages: Math.ceil(total / pageSize),
      },
    };
  }

  async findById(id: string, role: string) {
    const doc = await this.docRepo.findOne({ where: { id } });
    if (!doc) return null;
    if (role === 'USER' && doc.status !== Status.PUBLISHED) return null;
    return doc;
  }

  async create(data: Partial<Document>, userId: string) {
    const doc = this.docRepo.create({ ...data, createdBy: userId });
    if (doc.status === Status.PUBLISHED) {
      doc.publishedAt = new Date();
    }
    return this.docRepo.save(doc);
  }

  async update(id: string, data: Partial<Document>) {
    const doc = await this.docRepo.findOne({ where: { id } });
    if (!doc) return null;
    Object.assign(doc, data);
    if (data.status === Status.PUBLISHED && !doc.publishedAt) {
      doc.publishedAt = new Date();
    }
    return this.docRepo.save(doc);
  }

  async remove(id: string) {
    return this.docRepo.delete(id);
  }

  async publish(id: string) {
    const doc = await this.docRepo.findOne({ where: { id } });
    if (!doc) return null;
    doc.status = Status.PUBLISHED;
    doc.publishedAt = new Date();
    return this.docRepo.save(doc);
  }

  async archive(id: string) {
    const doc = await this.docRepo.findOne({ where: { id } });
    if (!doc) return null;
    doc.status = Status.ARCHIVED;
    return this.docRepo.save(doc);
  }
}
