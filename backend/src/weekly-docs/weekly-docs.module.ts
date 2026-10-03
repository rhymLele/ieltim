import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { AdminDocumentsController } from './admin-documents.controller';
import { AdminDocumentsService } from './admin-documents.service';
import { AdminWeeksController } from './admin-weeks.controller';
import { WEEKLY_DOC_ENTITIES } from './entities';
import { LearnerController } from './learner.controller';
import { LearnerService } from './learner.service';
import { PublishSchedulerService } from './publish-scheduler.service';
import { WeeklySeedService } from './weekly-seed.service';
import { WeeksService } from './weeks.service';

@Module({
  imports: [TypeOrmModule.forFeature(WEEKLY_DOC_ENTITIES)],
  controllers: [
    AdminWeeksController,
    AdminDocumentsController,
    LearnerController,
  ],
  providers: [
    WeeksService,
    AdminDocumentsService,
    LearnerService,
    PublishSchedulerService,
    WeeklySeedService,
  ],
  exports: [WeeklySeedService, PublishSchedulerService],
})
export class WeeklyDocsModule {}
