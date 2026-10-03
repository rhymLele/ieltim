// Xử lý JSON nội dung tài liệu (file nghiệp vụ 1 mục 3.3, file 9 mục 2).
// `content` lưu trong JSONB không kèm `html`; chuỗi html (tới 5 MB) nằm ở cột riêng để API danh sách không phải đọc.

import { randomUUID } from 'crypto';
import { SKILLS, VIEW_MODES } from '../weekly-docs.constants';

export type DocJson = Record<string, any>;

export const KNOWN_TOP_LEVEL_KEYS = [
  'schemaVersion',
  'id',
  'week',
  'order',
  'title',
  'template',
  'meta',
  'sections',
  'html',
  'htmlFileName',
];

export interface NormalizedDoc {
  /** JSON nội dung, đã bỏ `html` / `htmlFileName` và key lạ ở cấp trên cùng. */
  content: DocJson;
  html: string | null;
  htmlFileName: string | null;
  htmlSize: number;
  title: string;
  skill: string;
  template: string;
  defaultView: string;
  allowedViews: string[];
  sectionCount: number;
  estimatedMinutes: number;
}

export function docCode(week: number, order: number): string {
  return `w${week}-doc${order}`;
}

export function isPlainObject(v: unknown): v is DocJson {
  return typeof v === 'object' && v !== null && !Array.isArray(v);
}

const str = (v: unknown): string => (typeof v === 'string' ? v : '');

/**
 * Chuẩn hoá JSON tài liệu trước khi lưu: tách html, ghi đè id / week / order theo bản ghi,
 * tính sẵn các trường hiển thị. Không kiểm tra hợp lệ (nháp được lưu dù còn lỗi).
 */
export function normalizeDoc(
  input: DocJson,
  record: { week: number; order: number },
): NormalizedDoc {
  const src = structuredClone(input);
  const content: DocJson = {};
  for (const key of KNOWN_TOP_LEVEL_KEYS) {
    if (key in src && key !== 'html' && key !== 'htmlFileName')
      content[key] = src[key];
  }
  content.id = docCode(record.week, record.order);
  content.week = record.week;
  content.order = record.order;
  if (!isPlainObject(content.meta)) content.meta = {};

  const template =
    typeof content.template === 'string' && content.template
      ? content.template
      : 'custom';
  const isHtml = template === 'html';
  if (isHtml && !Array.isArray(content.sections)) content.sections = [];

  const html =
    isHtml && typeof src.html === 'string' && src.html.length > 0
      ? src.html
      : null;
  const htmlFileName =
    isHtml && typeof src.htmlFileName === 'string' && src.htmlFileName
      ? src.htmlFileName.slice(0, 255)
      : null;

  const meta = content.meta as DocJson;
  const skill = (SKILLS as readonly string[]).includes(meta.skill)
    ? meta.skill
    : 'reading';
  const views = Array.isArray(meta.allowedViews)
    ? meta.allowedViews.filter((v: unknown) =>
        (VIEW_MODES as readonly unknown[]).includes(v),
      )
    : [];
  const allowedViews = views.length
    ? [...new Set<string>(views)]
    : ['slide', 'doc'];
  const defaultView = (VIEW_MODES as readonly string[]).includes(
    meta.defaultView,
  )
    ? meta.defaultView
    : allowedViews[0];
  const sections = Array.isArray(content.sections) ? content.sections : [];

  return {
    content,
    html,
    htmlFileName,
    htmlSize: html ? Buffer.byteLength(html, 'utf8') : 0,
    title: str(content.title).trim().slice(0, 200),
    skill,
    template,
    defaultView,
    allowedViews,
    sectionCount: isHtml ? 0 : sections.length,
    estimatedMinutes: isHtml ? 1 : estimatedMinutes(sections),
  };
}

/** Ghép lại JSON đầy đủ như FE dùng (tài liệu HTML có thêm `html`, `htmlFileName`). */
export function mergeHtml(
  content: DocJson,
  html: string | null | undefined,
  htmlFileName: string | null | undefined,
): DocJson {
  if (content.template !== 'html') return content;
  return {
    ...content,
    ...(html != null ? { html } : {}),
    ...(htmlFileName != null ? { htmlFileName } : {}),
  };
}

/** Chữ thuần của một khối, cùng cách đếm với FE (`plainText`). */
export function blockPlainText(b: DocJson): string {
  switch (b.type) {
    case 'paragraph':
      return str(b.text).replace(/\*\*/g, '').replace(/\*/g, '');
    case 'heading':
    case 'callout':
    case 'passage':
      return str(b.text);
    case 'steps':
      return Array.isArray(b.items) ? b.items.map(str).join(' ') : '';
    case 'quiz':
      return [
        str(b.question),
        ...(Array.isArray(b.options) ? b.options.map(str) : []),
      ].join(' ');
    case 'vocab':
      return Array.isArray(b.items)
        ? b.items
            .map((i: DocJson) => `${str(i?.word)} ${str(i?.meaning)}`)
            .join(' ')
        : '';
    case 'pattern':
      return `${str(b.structure)} ${str(b.example)}`;
    case 'image':
      return str(b.caption);
    default:
      return '';
  }
}

/** Số từ ÷ 180 (làm tròn lên) + 1 phút mỗi quiz, tối thiểu 1. */
export function estimatedMinutes(sections: unknown[]): number {
  let words = 0;
  let quizzes = 0;
  for (const s of sections) {
    const blocks = isPlainObject(s) && Array.isArray(s.blocks) ? s.blocks : [];
    for (const b of blocks) {
      if (!isPlainObject(b)) continue;
      words += blockPlainText(b).split(/\s+/).filter(Boolean).length;
      if (b.type === 'quiz') quizzes++;
    }
  }
  return Math.max(1, Math.ceil(words / 180) + quizzes);
}

/** Khoá khối: `id` của khối nếu có, không thì `"{section}-{block}"`. */
export function blockKey(
  sectionIndex: number,
  blockIndex: number,
  block: DocJson,
): string {
  return typeof block.id === 'string' && block.id
    ? block.id
    : `${sectionIndex}-${blockIndex}`;
}

export function* eachBlock(
  content: DocJson,
): Generator<{ key: string; block: DocJson; sectionIndex: number }> {
  const sections = Array.isArray(content.sections) ? content.sections : [];
  for (let si = 0; si < sections.length; si++) {
    const blocks =
      isPlainObject(sections[si]) && Array.isArray(sections[si].blocks)
        ? sections[si].blocks
        : [];
    for (let bi = 0; bi < blocks.length; bi++) {
      if (isPlainObject(blocks[bi]))
        yield {
          key: blockKey(si, bi, blocks[bi]),
          block: blocks[bi],
          sectionIndex: si,
        };
    }
  }
}

export function findBlock(content: DocJson, key: string): DocJson | null {
  for (const b of eachBlock(content)) if (b.key === key) return b.block;
  return null;
}

export interface VocabItem {
  word: string;
  meaning: string;
  pos?: string;
  ipa?: string;
  example?: string;
  blockKey: string;
}

/** Từ vựng của các khối `vocab` (lọc theo `blockKeys` nếu có). */
export function vocabItems(
  content: DocJson,
  blockKeys?: string[],
): VocabItem[] {
  const out: VocabItem[] = [];
  for (const { key, block } of eachBlock(content)) {
    if (block.type !== 'vocab' || !Array.isArray(block.items)) continue;
    if (blockKeys && blockKeys.length && !blockKeys.includes(key)) continue;
    for (const it of block.items) {
      if (!isPlainObject(it) || !str(it.word).trim() || !str(it.meaning).trim())
        continue;
      out.push({
        word: str(it.word).trim(),
        meaning: str(it.meaning).trim(),
        pos: str(it.pos) || undefined,
        ipa: str(it.ipa) || undefined,
        example: str(it.example) || undefined,
        blockKey: key,
      });
    }
  }
  return out;
}

/** Bỏ trùng từ vựng: viết thường, gộp khoảng trắng thừa. */
export function normalizeWord(word: string): string {
  return word.trim().replace(/\s+/g, ' ').toLowerCase();
}

/** Nhân bản: tạo `id` mới cho các khối đang có `id` (UC-D11). */
export function regenerateBlockIds(content: DocJson): DocJson {
  const copy = structuredClone(content);
  for (const { block } of eachBlock(copy)) {
    if (typeof block.id === 'string' && block.id)
      block.id = randomUUID().slice(0, 8);
  }
  return copy;
}
