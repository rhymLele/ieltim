import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SearchController } from './search.controller';
import { SearchService } from './search.service';
import { Document } from '../documents/entities/document.entity';
import { Vocabulary } from '../vocabularies/entities/vocabulary.entity';
import { SentencePattern } from '../sentence-patterns/entities/sentence-pattern.entity';
import { WebResource } from '../web-resources/entities/web-resource.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Document, Vocabulary, SentencePattern, WebResource])],
  controllers: [SearchController],
  providers: [SearchService],
})
export class SearchModule {}
