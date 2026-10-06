import { DocCategory } from '../enums/weekly-docs.enums';
import {
  blockKey,
  categoryOf,
  docCode,
  estimatedMinutes,
  findBlock,
  mergeHtml,
  normalizeDoc,
  normalizeWord,
  regenerateBlockIds,
  vocabItems,
} from './doc-content';
import { sampleReadingDoc } from './templates';

describe('doc-content', () => {
  it('normalizeDoc ghi đè id / week / order theo bản ghi, bỏ key lạ, tính sẵn trường', () => {
    const n = normalizeDoc(
      { ...sampleReadingDoc(11), extra: true, html: '<p>bỏ</p>' },
      { week: 12, order: 3 },
    );
    expect(n.content).toMatchObject({ id: 'w12-doc3', week: 12, order: 3 });
    expect(n.content).not.toHaveProperty('extra');
    expect(n.content).not.toHaveProperty('html');
    expect(n.html).toBeNull();
    expect(n).toMatchObject({
      sectionCount: 4,
      skill: 'reading',
      defaultView: 'slide',
      allowedViews: ['slide', 'doc'],
    });
    expect(n.estimatedMinutes).toBe(
      estimatedMinutes(sampleReadingDoc(12).sections),
    );
  });

  it('bài tập (HOMEWORK): mã w{tuần}-hw{số}, category theo bản ghi chứ không theo JSON', () => {
    expect(docCode(12, 1, DocCategory.HOMEWORK)).toBe('w12-hw1');
    expect(docCode(12, 1)).toBe('w12-doc1');
    const n = normalizeDoc(
      { ...sampleReadingDoc(12), category: 'lesson' },
      { week: 12, order: 2, category: DocCategory.HOMEWORK },
    );
    expect(n.content).toMatchObject({
      id: 'w12-hw2',
      category: 'homework',
      order: 2,
    });
    expect(categoryOf('homework')).toBe(DocCategory.HOMEWORK);
    expect(categoryOf('lạ')).toBe(DocCategory.LESSON);
    expect(categoryOf(undefined)).toBe(DocCategory.LESSON);
  });

  it('tài liệu HTML: tách html ra cột riêng, 0 section, ghép lại khi đọc', () => {
    const n = normalizeDoc(
      {
        schemaVersion: 1,
        title: 'H',
        template: 'html',
        html: '<p>é</p>',
        htmlFileName: 'a.html',
      },
      { week: 1, order: 1 },
    );
    expect(n.content).toEqual({
      schemaVersion: 1,
      id: 'w1-doc1',
      week: 1,
      order: 1,
      category: 'lesson',
      title: 'H',
      template: 'html',
      meta: {},
      sections: [],
    });
    expect(n).toMatchObject({
      html: '<p>é</p>',
      htmlFileName: 'a.html',
      htmlSize: 9,
      sectionCount: 0,
      estimatedMinutes: 1,
    });
    expect(mergeHtml(n.content, n.html, n.htmlFileName)).toMatchObject({
      html: '<p>é</p>',
      htmlFileName: 'a.html',
    });
  });

  it('phút ước tính: số từ ÷ 180 làm tròn lên + 1 phút mỗi quiz, tối thiểu 1', () => {
    expect(estimatedMinutes([])).toBe(1);
    const words = Array.from({ length: 181 }, () => 'w').join(' ');
    expect(
      estimatedMinutes([
        {
          blocks: [
            { type: 'paragraph', text: words },
            { type: 'quiz', question: 'q', options: ['a', 'b'], answer: 0 },
          ],
        },
      ]),
    ).toBe(3); // ⌈(181 + 3 chữ của quiz) / 180⌉ = 2, + 1 quiz
  });

  it('blockKey ưu tiên id của khối; tìm khối và từ vựng theo khoá', () => {
    const doc = sampleReadingDoc(12);
    expect(blockKey(2, 1, doc.sections[2].blocks[1])).toBe('2-1');
    expect(blockKey(0, 0, { id: 'abc' })).toBe('abc');
    expect(findBlock(doc, '2-1')?.type).toBe('quiz');
    expect(vocabItems(doc).map((v) => v.word)).toEqual([
      'grant',
      'yield',
      'justify',
    ]);
    expect(vocabItems(doc, ['0-0'])).toEqual([]);
    expect(normalizeWord('  Carbon   Footprint ')).toBe('carbon footprint');
  });

  it('nhân bản tạo id khối mới', () => {
    const doc = {
      sections: [
        { title: 'S', blocks: [{ id: 'keep', type: 'heading', text: 'x' }] },
      ],
    };
    expect(regenerateBlockIds(doc).sections[0].blocks[0].id).not.toBe('keep');
  });
});
