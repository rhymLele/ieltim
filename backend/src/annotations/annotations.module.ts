import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { User } from '../users/entities/user.entity';
import { VocabEntry } from '../weekly-docs/entities/vocab-entry.entity';
import { WeeklyDocument } from '../weekly-docs/entities/weekly-document.entity';
import { ActiveUserGuard, VisibleDocGuard } from './access.guards';
import { AnnotationsController } from './annotations.controller';
import { AnnotationsService } from './annotations.service';
import { DictionaryLookup, FreeDictionaryLookup } from './dictionary';
import { ANNOTATION_ENTITIES } from './entities';
import { TranslateController } from './translate.controller';
import { TranslateService } from './translate.service';
import { GeminiTranslatorLlm, TranslatorLlm } from './translator-llm';
import { VocabController } from './vocab.controller';
import { VocabService } from './vocab.service';

@Module({
  imports: [
    TypeOrmModule.forFeature([
      ...ANNOTATION_ENTITIES,
      VocabEntry,
      WeeklyDocument,
      User,
    ]),
  ],
  controllers: [AnnotationsController, VocabController, TranslateController],
  providers: [
    AnnotationsService,
    VocabService,
    TranslateService,
    ActiveUserGuard,
    VisibleDocGuard,
    { provide: TranslatorLlm, useClass: GeminiTranslatorLlm },
    { provide: DictionaryLookup, useClass: FreeDictionaryLookup },
  ],
})
export class AnnotationsModule {}
