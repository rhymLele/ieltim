import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { VocabulariesController } from './vocabularies.controller';
import { VocabulariesService } from './vocabularies.service';
import { Vocabulary } from './entities/vocabulary.entity';
import { Collocation } from './entities/collocation.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Vocabulary, Collocation])],
  controllers: [VocabulariesController],
  providers: [VocabulariesService],
  exports: [VocabulariesService],
})
export class VocabulariesModule {}
