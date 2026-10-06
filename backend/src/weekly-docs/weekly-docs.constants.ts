// Hằng số dùng chung của module Tài liệu theo tuần (file nghiệp vụ 1, 7, 9).

export const SKILLS = [
  'reading',
  'listening',
  'writing',
  'speaking',
  'vocabulary',
] as const;
export const VIEW_MODES = ['slide', 'doc'] as const;
/** `lesson` = "Tài liệu", `homework` = "Bài tập" (tag HOMEWORK). Mỗi loại đánh số riêng trong tuần. */
export const DOC_CATEGORIES = ['lesson', 'homework'] as const;
export const CONTENT_TEMPLATES = [
  'reading-lesson',
  'writing-task2',
  'vocab-set',
  'speaking-part2',
  'blank',
] as const;
export const TEMPLATE_IDS = [...CONTENT_TEMPLATES, 'custom', 'html'] as const;

/** Chuỗi `html` của tài liệu HTML, tính theo UTF-8 (file 9 mục 2). */
export const MAX_HTML_BYTES = 5 * 1024 * 1024;
/** Body của API admin tài liệu (file 9 mục 7: ≥ 6 MB; dư cho phần escape JSON của file 5 MB). */
export const ADMIN_DOC_BODY_LIMIT = '8mb';
export const ADMIN_DOC_PATH = '/api/admin/weekly';
/** Sổ từ mặc định: từ lưu từ tài liệu và từ thêm tay không chọn sổ. */
export const DEFAULT_VOCAB_DECK = 'Sổ chung';
/** File JSON import (file 7 mục 5). */
export const IMPORT_MAX_BYTES = 1024 * 1024;

export const MIN_SCHEDULE_LEAD_MS = 5 * 60 * 1000;
export const SOFT_DELETE_RETENTION_DAYS = 30;
export const DEFAULT_STAGE_GOAL = 5;
/** Tự sinh tuần: luôn có sẵn tuần này + N tuần tới (ghi đè bằng WEEKLY_WEEKS_AHEAD). */
export const DEFAULT_WEEKS_AHEAD = 4;
/** Gộp các lần tự lưu cùng người trong khoảng này thành một phiên bản (UC-D14). */
export const AUTOSAVE_SESSION_MS = 30 * 60 * 1000;
