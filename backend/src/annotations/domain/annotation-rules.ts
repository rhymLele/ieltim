import {
  HIGHLIGHT_CONTEXT_CHARS,
  SLIDE_KEY_PATTERN,
} from '../annotations.constants';

// Quy tắc thuần (không đụng DB) cho highlight, ghi chú slide và Sổ từ.

/** Giữ `n` ký tự cuối, đếm theo code point để không cắt đôi emoji / ký tự ghép. */
export function keepLast(s: string, n: number): string {
  const chars = Array.from(s);
  return chars.length <= n ? s : chars.slice(chars.length - n).join('');
}

/** Giữ `n` ký tự đầu (theo code point). */
export function keepFirst(s: string, n: number): string {
  const chars = Array.from(s);
  return chars.length <= n ? s : chars.slice(0, n).join('');
}

/** Ngữ cảnh highlight: prefix là đoạn ngay trước nên giữ phần cuối, suffix giữ phần đầu. */
export function trimHighlightContext(
  prefix: string | null | undefined,
  suffix: string | null | undefined,
): { prefix: string; suffix: string } {
  return {
    prefix: keepLast(prefix ?? '', HIGHLIGHT_CONTEXT_CHARS),
    suffix: keepFirst(suffix ?? '', HIGHLIGHT_CONTEXT_CHARS),
  };
}

export function isSlideKey(key: string): boolean {
  return SLIDE_KEY_PATTERN.test(key);
}

/** Kích thước JSON (UTF-8) của dữ liệu vẽ. */
export function jsonBytes(value: unknown): number {
  return Buffer.byteLength(JSON.stringify(value ?? null), 'utf8');
}

/** Dữ liệu vẽ hợp lệ: object có `items` là mảng. */
export function isSlideData(value: unknown): value is { items: unknown[] } {
  return (
    typeof value === 'object' &&
    value !== null &&
    !Array.isArray(value) &&
    Array.isArray((value as { items?: unknown }).items)
  );
}

/** Bỏ khoảng trắng thừa hai đầu và gộp khoảng trắng giữa (giữ hoa / thường). */
export function cleanText(s: string): string {
  return s.trim().replace(/\s+/g, ' ');
}
