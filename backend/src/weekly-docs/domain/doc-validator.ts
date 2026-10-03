// Kiểm tra JSON tài liệu: cùng quy tắc, đường dẫn và câu thông báo với FE
// (frontend/lib/features/weekly_docs/domain/doc_validator.dart), mục 3.4 file nghiệp vụ 1 và file 9.

import { MAX_HTML_BYTES } from '../weekly-docs.constants';
import { KNOWN_TOP_LEVEL_KEYS, isPlainObject } from './doc-content';

export interface ValidationIssue {
  path: string;
  message: string;
}

export interface ValidationResult {
  valid: boolean;
  errors: ValidationIssue[];
  warnings: ValidationIssue[];
}

export interface ValidateOptions {
  /** Rỗng = mọi host https đều được. */
  allowedImageHosts?: string[];
}

export const SUPPORTED_BLOCK_TYPES = [
  'heading',
  'paragraph',
  'callout',
  'steps',
  'passage',
  'quiz',
  'vocab',
  'pattern',
  'image',
  'slideBreak',
];

const PLACEHOLDER = /\[[^\]\n]*\](?!\()/;
const str = (v: unknown): string => (typeof v === 'string' ? v : '');

/** Còn chỗ trống `[ … ]` trong chuỗi nào đó của khối (link markdown `[x](…)` không tính). */
export function hasPlaceholder(value: unknown): boolean {
  if (typeof value === 'string') return PLACEHOLDER.test(value);
  if (Array.isArray(value)) return value.some(hasPlaceholder);
  if (isPlainObject(value)) return Object.values(value).some(hasPlaceholder);
  return false;
}

export function validateDocText(
  text: string,
  opts: ValidateOptions = {},
): ValidationResult {
  let parsed: unknown;
  try {
    parsed = JSON.parse(text);
  } catch (e) {
    return result(
      [{ path: '', message: `Lỗi cú pháp JSON: ${(e as Error).message}` }],
      [],
    );
  }
  return validateDocJson(parsed, opts);
}

export function validateDocJson(
  json: unknown,
  opts: ValidateOptions = {},
): ValidationResult {
  const errors: ValidationIssue[] = [];
  const warnings: ValidationIssue[] = [];
  const err = (path: string, message: string) => errors.push({ path, message });

  if (!isPlainObject(json))
    return result(
      [{ path: '', message: 'File không phải một object JSON' }],
      [],
    );
  const j = json;

  for (const key of Object.keys(j)) {
    if (!KNOWN_TOP_LEVEL_KEYS.includes(key))
      warnings.push({ path: key, message: 'key lạ, sẽ bị bỏ qua' });
  }

  if (j.schemaVersion !== 1) err('schemaVersion', 'phải là 1');
  const title = j.title;
  if (typeof title !== 'string' || !title.trim()) {
    err('title', 'thiếu tên tài liệu');
  } else if (title.trim().length > 200) {
    err('title', 'tối đa 200 ký tự');
  }

  // Tài liệu HTML (file 9): bỏ qua meta.defaultView và sections, chỉ cần chuỗi html.
  if (j.template === 'html') {
    const html = j.html;
    if (typeof html !== 'string' || !html.trim()) {
      err('', 'Chưa tải file HTML');
    } else if (Buffer.byteLength(html, 'utf8') > MAX_HTML_BYTES) {
      err('html', 'file lớn hơn 5 MB');
    }
    return result(errors, warnings);
  }

  const meta = isPlainObject(j.meta) ? j.meta : {};
  const views = meta.allowedViews;
  if (
    Array.isArray(views) &&
    meta.defaultView != null &&
    !views.includes(meta.defaultView)
  ) {
    err('meta.defaultView', 'phải nằm trong allowedViews');
  }

  const sections = j.sections;
  if (!Array.isArray(sections) || sections.length === 0) {
    err('sections', 'phải là mảng và có ít nhất 1 section');
    return result(errors, warnings);
  }

  let placeholderBlocks = 0;
  sections.forEach((raw, si) => {
    const sp = `sections[${si}]`;
    const s = isPlainObject(raw) ? raw : {};
    if (!str(s.title).trim()) err(`${sp}.title`, 'thiếu tên section');
    const blocks = s.blocks;
    if (!Array.isArray(blocks) || blocks.length === 0) {
      err(`${sp}.blocks`, 'section chưa có khối nào');
      return;
    }
    let chars = 0;
    blocks.forEach((rawBlock, bi) => {
      const p = `${sp}.blocks[${bi}]`;
      const b = isPlainObject(rawBlock) ? rawBlock : {};
      const type = b.type;
      if (!SUPPORTED_BLOCK_TYPES.includes(type)) {
        err(`${p}.type`, `loại khối "${type}" không được hỗ trợ`);
        return;
      }
      const text = str(b.text);
      chars += text.length + str(b.question).length + str(b.structure).length;
      switch (type) {
        case 'heading':
        case 'paragraph':
        case 'callout':
        case 'passage':
          if (!text.trim()) err(`${p}.text`, 'thiếu nội dung');
          break;
        case 'steps':
          if (
            !Array.isArray(b.items) ||
            !b.items.some((e: unknown) => str(e).trim())
          )
            err(`${p}.items`, 'cần ít nhất 1 bước');
          break;
        case 'quiz': {
          const options = b.options;
          if (!str(b.question).trim()) err(`${p}.question`, 'thiếu câu hỏi');
          if (
            !Array.isArray(options) ||
            options.length < 2 ||
            options.length > 6
          ) {
            err(`${p}.options`, 'cần từ 2 đến 6 đáp án');
          } else if (
            !Number.isInteger(b.answer) ||
            b.answer < 0 ||
            b.answer >= options.length
          ) {
            err(`${p}.answer`, `phải nằm trong 0…${options.length - 1}`);
          }
          break;
        }
        case 'vocab':
          if (!Array.isArray(b.items) || b.items.length === 0) {
            err(`${p}.items`, 'cần ít nhất 1 từ');
          } else {
            b.items.forEach((rawItem: unknown, i: number) => {
              const it = isPlainObject(rawItem) ? rawItem : {};
              if (!str(it.word).trim() || !str(it.meaning).trim())
                err(`${p}.items[${i}]`, 'mỗi từ cần "word" và "meaning"');
            });
          }
          break;
        case 'pattern':
          if (!str(b.structure).trim()) err(`${p}.structure`, 'thiếu cấu trúc');
          break;
        case 'image': {
          let url: URL | null = null;
          try {
            url = new URL(str(b.url));
          } catch {
            url = null;
          }
          if (!url || url.protocol !== 'https:' || !url.hostname) {
            err(`${p}.url`, 'phải là link https');
          } else if (
            opts.allowedImageHosts?.length &&
            !opts.allowedImageHosts.includes(url.hostname)
          ) {
            err(`${p}.url`, 'host ảnh không được phép');
          }
          break;
        }
      }
      if (hasPlaceholder(b)) placeholderBlocks++;
    });
    if (blocks.length > 6 || chars > 900) {
      warnings.push({
        path: sp,
        message: 'section dài, nên tách thêm section hoặc chèn "Ngắt slide"',
      });
    }
  });
  if (placeholderBlocks > 0) {
    warnings.push({
      path: '',
      message: `${placeholderBlocks} khối còn chỗ trống [ … ] chưa điền`,
    });
  }
  return result(errors, warnings);
}

function result(
  errors: ValidationIssue[],
  warnings: ValidationIssue[],
): ValidationResult {
  return { valid: errors.length === 0, errors, warnings };
}

/** `sections[2].blocks[1].answer: phải nằm trong 0…2` — dùng cho message gộp. */
export function issueText(i: ValidationIssue): string {
  return i.path ? `${i.path}: ${i.message}` : i.message;
}
