import { Injectable } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Document } from '../documents/entities/document.entity';
import { Vocabulary } from '../vocabularies/entities/vocabulary.entity';
import { SentencePattern } from '../sentence-patterns/entities/sentence-pattern.entity';
import { WebResource } from '../web-resources/entities/web-resource.entity';
import { Status } from '../common/enums/status.enum';

@Injectable()
export class SearchService {
  constructor(
    @InjectRepository(Document)
    private docRepo: Repository<Document>,
    @InjectRepository(Vocabulary)
    private vocabRepo: Repository<Vocabulary>,
    @InjectRepository(SentencePattern)
    private spRepo: Repository<SentencePattern>,
    @InjectRepository(WebResource)
    private resRepo: Repository<WebResource>,
  ) {}

  async search(query: string, role: string) {
    const likePattern = `%${query}%`;
    const statusCondition =
      role === 'USER' ? ` AND status = '${Status.PUBLISHED}'` : '';

    const documents = await this.docRepo
      .createQueryBuilder('doc')
      .where(`(doc.title ILIKE :q OR doc.description ILIKE :q)${statusCondition}`, { q: likePattern })
      .take(10)
      .getMany();

    const vocabularies = await this.vocabRepo
      .createQueryBuilder('v')
      .where(
        `(v.term ILIKE :q OR v.definition ILIKE :q OR v.vietnameseMeaning ILIKE :q OR v.example ILIKE :q)${statusCondition}`,
        { q: likePattern },
      )
      .take(10)
      .getMany();

    const sentencePatterns = await this.spRepo
      .createQueryBuilder('sp')
      .where(
        `(sp.pattern ILIKE :q OR sp.meaning ILIKE :q OR sp.example ILIKE :q)${statusCondition}`,
        { q: likePattern },
      )
      .take(10)
      .getMany();

    const webResources = await this.resRepo
      .createQueryBuilder('r')
      .where(`(r.title ILIKE :q OR r.description ILIKE :q)${statusCondition}`, { q: likePattern })
      .take(10)
      .getMany();

    return {
      documents,
      vocabularies,
      sentencePatterns,
      webResources,
    };
  }
}
