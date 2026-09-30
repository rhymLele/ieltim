import { Injectable, HttpException, HttpStatus } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { WebResource } from './entities/web-resource.entity';
import { Status } from '../common/enums/status.enum';

@Injectable()
export class WebResourcesService {
  constructor(
    @InjectRepository(WebResource)
    private resRepo: Repository<WebResource>,
  ) {}

  async findAll(role: string | undefined, page = 1, pageSize = 20) {
    const qb = this.resRepo.createQueryBuilder('r');
    if (role === 'USER') {
      qb.andWhere('r.status = :status', { status: Status.PUBLISHED });
    }
    qb.orderBy('r.createdAt', 'DESC').skip((page - 1) * pageSize).take(pageSize);
    const [data, total] = await qb.getManyAndCount();
    return {
      data,
      pagination: { page, pageSize, total, totalPages: Math.ceil(total / pageSize) },
    };
  }

  private normalizeUrl(url: string): string {
    return url.trim().replace(/\/+$/, '').toLowerCase();
  }

  private extractDomain(url: string): string {
    try {
      return new URL(url.startsWith('http') ? url : `https://${url}`).hostname.replace(/^www\./, '');
    } catch {
      return url;
    }
  }

  async create(data: Partial<WebResource>, userId: string) {
    if (data.url) {
      const normalizedUrl = this.normalizeUrl(data.url);
      const all = await this.resRepo.find();
      const existing = all.find(r => this.normalizeUrl(r.url) === normalizedUrl);
      if (existing) {
        throw new HttpException(
          { statusCode: 409, code: 'DUPLICATE_URL', message: 'A resource with this URL already exists' },
          HttpStatus.CONFLICT,
        );
      }
      data.url = normalizedUrl;
      if (!data.domain) data.domain = this.extractDomain(normalizedUrl);
    }
    const res = this.resRepo.create({ ...data, createdBy: userId });
    return this.resRepo.save(res);
  }

  async update(id: string, data: Partial<WebResource>) {
    const res = await this.resRepo.findOne({ where: { id } });
    if (!res) return null;
    Object.assign(res, data);
    if (data.url) {
      res.url = this.normalizeUrl(data.url);
      res.domain = this.extractDomain(res.url);
    }
    return this.resRepo.save(res);
  }

  async remove(id: string) {
    return this.resRepo.delete(id);
  }
}
