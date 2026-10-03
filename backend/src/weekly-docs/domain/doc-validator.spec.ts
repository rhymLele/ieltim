import { MAX_HTML_BYTES } from '../weekly-docs.constants';
import {
  hasPlaceholder,
  validateDocJson,
  validateDocText,
} from './doc-validator';
import { sampleReadingDoc } from './templates';

const paths = (issues: { path: string }[]) => issues.map((i) => i.path);

describe('validateDocJson', () => {
  it('JSON hợp lệ (tài liệu mẫu đủ 8 loại khối): không lỗi, không cảnh báo', () => {
    const v = validateDocJson(sampleReadingDoc(12));
    expect(v.errors).toEqual([]);
    expect(v.warnings).toEqual([]);
    expect(v.valid).toBe(true);
  });

  it('thiếu title', () => {
    const doc = sampleReadingDoc(12);
    delete doc.title;
    expect(validateDocJson(doc).errors).toContainEqual({
      path: 'title',
      message: 'thiếu tên tài liệu',
    });
  });

  it('type lạ', () => {
    const doc = sampleReadingDoc(12);
    doc.sections[0].blocks.push({ type: 'video', url: 'x' });
    expect(validateDocJson(doc).errors).toContainEqual({
      path: 'sections[0].blocks[3].type',
      message: 'loại khối "video" không được hỗ trợ',
    });
  });

  it('answer ngoài phạm vi', () => {
    const doc = sampleReadingDoc(12);
    doc.sections[2].blocks[1].answer = 3;
    expect(validateDocJson(doc).errors).toContainEqual({
      path: 'sections[2].blocks[1].answer',
      message: 'phải nằm trong 0…2',
    });
  });

  it('URL ảnh sai host / không phải https', () => {
    const doc = sampleReadingDoc(12);
    doc.sections[0].blocks.push(
      { type: 'image', url: 'https://evil.example/a.png' },
      { type: 'image', url: 'http://cdn.ieltshub.app/a.png' },
    );
    const v = validateDocJson(doc, { allowedImageHosts: ['cdn.ieltshub.app'] });
    expect(v.errors).toContainEqual({
      path: 'sections[0].blocks[3].url',
      message: 'host ảnh không được phép',
    });
    expect(v.errors).toContainEqual({
      path: 'sections[0].blocks[4].url',
      message: 'phải là link https',
    });
  });

  it('còn chỗ trống [ … ] → cảnh báo, vẫn hợp lệ', () => {
    const doc = sampleReadingDoc(12);
    doc.sections[0].blocks[0].text = '[Tên dạng bài]';
    const v = validateDocJson(doc);
    expect(v.valid).toBe(true);
    expect(v.warnings).toContainEqual({
      path: '',
      message: '1 khối còn chỗ trống [ … ] chưa điền',
    });
  });

  it('mảng trong khối (steps, quiz, vocab) không bị coi là chỗ trống; link markdown cũng không', () => {
    expect(
      hasPlaceholder({ type: 'steps', items: ['Bước một', 'Bước hai'] }),
    ).toBe(false);
    expect(
      hasPlaceholder({
        type: 'paragraph',
        text: 'Xem [tài liệu](https://a.b)',
      }),
    ).toBe(false);
    expect(hasPlaceholder({ type: 'steps', items: ['Mở bài: [ý]'] })).toBe(
      true,
    );
  });

  it('section dài → gợi ý ngắt slide; key lạ → cảnh báo', () => {
    const doc = sampleReadingDoc(12) as Record<string, any>;
    doc.sections[0].blocks.push(
      ...Array.from({ length: 5 }, () => ({ type: 'heading', text: 'x' })),
    );
    doc.extra = 1;
    expect(paths(validateDocJson(doc).warnings)).toEqual(
      expect.arrayContaining(['sections[0]', 'extra']),
    );
  });

  it('defaultView ngoài allowedViews, schemaVersion sai, sections rỗng', () => {
    const v = validateDocJson({
      schemaVersion: 2,
      title: 'A',
      meta: { defaultView: 'doc', allowedViews: ['slide'] },
      sections: [],
    });
    expect(paths(v.errors)).toEqual([
      'schemaVersion',
      'meta.defaultView',
      'sections',
    ]);
  });

  it('JSON sai cú pháp', () => {
    expect(validateDocText('{ "title": ').errors[0].message).toMatch(
      /^Lỗi cú pháp JSON/,
    );
  });
});

describe('validateDocJson — tài liệu HTML (file 9)', () => {
  const htmlDoc = (html?: string) => ({
    schemaVersion: 1,
    title: 'Collocations',
    template: 'html',
    meta: { skill: 'vocabulary' },
    sections: [],
    html,
  });

  it('thiếu html → chỉ một lỗi "Chưa tải file HTML"', () => {
    expect(validateDocJson(htmlDoc()).errors).toEqual([
      { path: '', message: 'Chưa tải file HTML' },
    ]);
  });

  it('có html → hợp lệ, bỏ qua sections rỗng', () => {
    expect(validateDocJson(htmlDoc('<p>x</p>')).valid).toBe(true);
  });

  it('html quá 5 MB (tính theo UTF-8) → lỗi', () => {
    expect(
      validateDocJson(htmlDoc('é'.repeat(MAX_HTML_BYTES / 2 + 1))).errors,
    ).toEqual([{ path: 'html', message: 'file lớn hơn 5 MB' }]);
  });
});
