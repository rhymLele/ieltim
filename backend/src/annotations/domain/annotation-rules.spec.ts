import {
  cleanText,
  isSlideData,
  isSlideKey,
  jsonBytes,
  keepFirst,
  keepLast,
  trimHighlightContext,
} from './annotation-rules';

describe('annotation-rules', () => {
  it('prefix giữ 32 ký tự cuối, suffix giữ 32 ký tự đầu', () => {
    const long = 'abcdefghijklmnopqrstuvwxyz0123456789'; // 36 ký tự
    const r = trimHighlightContext(long, long);
    expect(r.prefix).toBe('efghijklmnopqrstuvwxyz0123456789');
    expect(r.suffix).toBe('abcdefghijklmnopqrstuvwxyz012345');
    expect(r.prefix).toHaveLength(32);
    expect(r.suffix).toHaveLength(32);
  });

  it('ngữ cảnh ngắn giữ nguyên, thiếu thì là chuỗi rỗng', () => {
    expect(trimHighlightContext('trước ', ' sau')).toEqual({
      prefix: 'trước ',
      suffix: ' sau',
    });
    expect(trimHighlightContext(undefined, null)).toEqual({
      prefix: '',
      suffix: '',
    });
  });

  it('cắt theo code point, không cắt đôi emoji', () => {
    const s = '😀'.repeat(40);
    expect(Array.from(keepLast(s, 32))).toHaveLength(32);
    expect(keepFirst(s, 32)).toBe('😀'.repeat(32));
    expect(keepLast('a😀b', 2)).toBe('😀b');
  });

  it('mã slide: chữ, số, _ và -, tối đa 40 ký tự', () => {
    for (const k of ['0-1', 's3', 'y2', 'doc', 'a_b-C'])
      expect(isSlideKey(k)).toBe(true);
    for (const k of ['', 'a b', 'a/b', 'x'.repeat(41), 'ô'])
      expect(isSlideKey(k)).toBe(false);
  });

  it('dữ liệu vẽ phải là object có items là mảng', () => {
    expect(isSlideData({ items: [] })).toBe(true);
    expect(isSlideData({ items: [{ t: 'pen' }], extra: 1 })).toBe(true);
    expect(isSlideData({ items: {} })).toBe(false);
    expect(isSlideData([])).toBe(false);
    expect(isSlideData(null)).toBe(false);
  });

  it('kích thước JSON tính theo UTF-8', () => {
    expect(jsonBytes({ a: 'ă' })).toBe(Buffer.byteLength('{"a":"ă"}'));
  });

  it('cleanText bỏ khoảng trắng thừa, giữ hoa thường', () => {
    expect(cleanText('  Take   Part \n in ')).toBe('Take Part in');
  });
});
