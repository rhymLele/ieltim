export enum DocStatus {
  DRAFT = 'draft',
  SCHEDULED = 'scheduled',
  PUBLISHED = 'published',
  ARCHIVED = 'archived',
}

export enum LearningActivityType {
  SECTION_VIEW = 'section_view',
  QUIZ_ANSWER = 'quiz_answer',
  DOC_COMPLETE = 'doc_complete',
  VOCAB_REVIEW = 'vocab_review',
}

/** Nhật ký thao tác (file 7 mục 6). */
export enum AuditAction {
  CREATE = 'create',
  UPDATE = 'update',
  PUBLISH = 'publish',
  SCHEDULE = 'schedule',
  SCHEDULE_FAILED = 'schedule_failed',
  UNSCHEDULE = 'unschedule',
  UNPUBLISH = 'unpublish',
  RESTORE = 'restore',
  RELEASE = 'release',
  DELETE = 'delete',
  UNDELETE = 'undelete',
  DUPLICATE = 'duplicate',
  IMPORT = 'import',
  REORDER = 'reorder',
}

export enum RevisionNote {
  CREATE = 'create',
  AUTOSAVE = 'autosave',
  PUBLISH = 'publish',
  RELEASE = 'release',
  RESTORE = 'restore',
}
