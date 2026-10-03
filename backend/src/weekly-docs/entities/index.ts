import { DocumentAuditLog } from './document-audit-log.entity';
import { LearningActivity } from './learning-activity.entity';
import { UserDocumentProgress } from './user-document-progress.entity';
import { VocabEntry } from './vocab-entry.entity';
import { Week } from './week.entity';
import { WeeklyDocument } from './weekly-document.entity';
import { WeeklyDocumentRevision } from './weekly-document-revision.entity';

export {
  DocumentAuditLog,
  LearningActivity,
  UserDocumentProgress,
  VocabEntry,
  Week,
  WeeklyDocument,
  WeeklyDocumentRevision,
};

export const WEEKLY_DOC_ENTITIES = [
  Week,
  WeeklyDocument,
  WeeklyDocumentRevision,
  DocumentAuditLog,
  UserDocumentProgress,
  LearningActivity,
  VocabEntry,
];
