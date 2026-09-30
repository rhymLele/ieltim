import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { SentencePatternsController } from './sentence-patterns.controller';
import { SentencePatternsService } from './sentence-patterns.service';
import { SentencePattern } from './entities/sentence-pattern.entity';

@Module({
  imports: [TypeOrmModule.forFeature([SentencePattern])],
  controllers: [SentencePatternsController],
  providers: [SentencePatternsService],
  exports: [SentencePatternsService],
})
export class SentencePatternsModule {}
