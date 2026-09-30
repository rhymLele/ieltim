import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Tag } from './entities/tag.entity';
import { TagType } from '../common/enums/tag-type.enum';

@Injectable()
export class TagsService {
  constructor(
    @InjectRepository(Tag)
    private tagRepo: Repository<Tag>,
  ) {}

  findAll() {
    return this.tagRepo.find({ order: { name: 'ASC' } });
  }

  async create(data: { name: string; type?: TagType }) {
    const slug = data.name
      .toLowerCase()
      .replace(/[^a-z0-9]+/g, '-')
      .replace(/(^-|-$)/g, '');
    const tag = this.tagRepo.create({ name: data.name, slug, type: data.type || TagType.GENERAL });
    return this.tagRepo.save(tag);
  }

  async update(id: string, data: Partial<Tag>) {
    const tag = await this.tagRepo.findOne({ where: { id } });
    if (!tag) return null;
    Object.assign(tag, data);
    return this.tagRepo.save(tag);
  }

  async remove(id: string) {
    return this.tagRepo.delete(id);
  }
}
