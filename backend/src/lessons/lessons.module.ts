import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { LessonsController } from './lessons.controller';
import { LessonsService } from './lessons.service';
import { Document } from '../documents/entities/document.entity';
import { LessonVocabulary } from './entities/lesson-vocabulary.entity';
import { LessonSentencePattern } from './entities/lesson-sentence-pattern.entity';
import { TheoryBlock } from './entities/theory-block.entity';
import { Practice } from './entities/practice.entity';
import { Vocabulary } from '../vocabularies/entities/vocabulary.entity';
import { Collocation } from '../vocabularies/entities/collocation.entity';
import { SentencePattern } from '../sentence-patterns/entities/sentence-pattern.entity';
import { Tag } from '../tags/entities/tag.entity';
import { IeltsContext } from '../ielts-contexts/entities/ielts-context.entity';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      Document,
      LessonVocabulary,
      LessonSentencePattern,
      TheoryBlock,
      Practice,
      Vocabulary,
      Collocation,
      SentencePattern,
      Tag,
      IeltsContext,
    ]),
  ],
  controllers: [LessonsController],
  providers: [LessonsService],
  exports: [LessonsService],
})
export class LessonsModule {}
