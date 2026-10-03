// Template tài liệu (file nghiệp vụ 1 mục 3.5) — cùng khung với FE (doc_templates.dart).

import { DocJson } from './doc-content';

export interface DocTemplate {
  id: string;
  name: string;
  skill: string;
  description: string;
  /** `template`: khung có section; `import`: nhập file JSON; `html`: tải file HTML (file 9). */
  kind: 'template' | 'import' | 'html';
  sections: DocJson[];
}

export function newBlock(type: string): DocJson {
  switch (type) {
    case 'heading':
      return { type: 'heading', text: '[Tiêu đề]' };
    case 'paragraph':
      return {
        type: 'paragraph',
        text: '[Nội dung, dùng **chữ đậm** để nhấn mạnh]',
      };
    case 'callout':
      return { type: 'callout', tone: 'tip', text: '[Mẹo]' };
    case 'steps':
      return { type: 'steps', items: ['[Bước 1]', '[Bước 2]', '[Bước 3]'] };
    case 'passage':
      return {
        type: 'passage',
        label: 'PARAGRAPH A',
        text: '[Dán đoạn văn đề thi]',
      };
    case 'quiz':
      return {
        type: 'quiz',
        question: '[Câu hỏi]',
        options: ['[Đáp án i]', '[Đáp án ii]', '[Đáp án iii]'],
        answer: 0,
        explain: '[Giải thích]',
      };
    case 'vocab':
      return {
        type: 'vocab',
        items: [{ word: '[từ]', pos: 'n.', ipa: '/…/', meaning: '[nghĩa]' }],
      };
    case 'pattern':
      return {
        type: 'pattern',
        structure: '[Cấu trúc]',
        example: '[Câu ví dụ]',
      };
    case 'image':
      return { type: 'image', url: 'https://', caption: '', alt: '' };
    case 'slideBreak':
      return { type: 'slideBreak' };
    default:
      return { type: 'paragraph', text: '' };
  }
}

export const DOC_TEMPLATES: DocTemplate[] = [
  {
    id: 'reading-lesson',
    name: 'Reading lesson',
    skill: 'reading',
    description: 'Dạng bài → chiến thuật → ví dụ có trắc nghiệm → từ vựng.',
    kind: 'template',
    sections: [
      {
        title: 'DẠNG BÀI',
        blocks: [
          { type: 'heading', text: '[Tên dạng bài]' },
          {
            type: 'paragraph',
            text: '[Mô tả dạng bài, dùng **chữ đậm** cho ý quan trọng]',
          },
          { type: 'callout', tone: 'tip', text: '[Mẹo làm bài]' },
        ],
      },
      {
        title: 'CHIẾN THUẬT',
        blocks: [
          { type: 'heading', text: 'Các bước làm bài' },
          newBlock('steps'),
        ],
      },
      { title: 'VÍ DỤ', blocks: [newBlock('passage'), newBlock('quiz')] },
      { title: 'TỪ VỰNG', blocks: [newBlock('vocab'), newBlock('pattern')] },
    ],
  },
  {
    id: 'writing-task2',
    name: 'Writing Task 2',
    skill: 'writing',
    description: 'Đề bài → dàn ý 4 phần → bài mẫu → từ vựng và mẫu câu.',
    kind: 'template',
    sections: [
      {
        title: 'ĐỀ BÀI',
        blocks: [
          { type: 'heading', text: '[Đề Writing Task 2]' },
          {
            type: 'callout',
            tone: 'tip',
            text: '[Dạng đề: Opinion / Discussion / Problem–Solution…]',
          },
        ],
      },
      {
        title: 'DÀN Ý',
        blocks: [
          {
            type: 'steps',
            items: [
              'Mở bài: [ý]',
              'Thân bài 1: [ý]',
              'Thân bài 2: [ý]',
              'Kết bài: [ý]',
            ],
          },
        ],
      },
      {
        title: 'BÀI MẪU',
        blocks: [{ type: 'paragraph', text: '[Dán bài mẫu]' }],
      },
      {
        title: 'TỪ VỰNG & MẪU CÂU',
        blocks: [newBlock('vocab'), newBlock('pattern')],
      },
    ],
  },
  {
    id: 'vocab-set',
    name: 'Vocab set',
    skill: 'vocabulary',
    description: 'Bộ từ theo chủ đề, kết thúc bằng câu hỏi luyện tập.',
    kind: 'template',
    sections: [
      {
        title: 'CHỦ ĐỀ',
        blocks: [
          { type: 'heading', text: '[Chủ đề]' },
          { type: 'paragraph', text: '[Giới thiệu ngắn]' },
        ],
      },
      { title: 'TỪ VỰNG', blocks: [newBlock('vocab')] },
      { title: 'LUYỆN TẬP', blocks: [newBlock('quiz')] },
    ],
  },
  {
    id: 'speaking-part2',
    name: 'Speaking Part 2',
    skill: 'speaking',
    description: 'Cue card → ý tưởng → câu trả lời mẫu → từ vựng.',
    kind: 'template',
    sections: [
      {
        title: 'CUE CARD',
        blocks: [
          { type: 'heading', text: 'Describe [a …]' },
          {
            type: 'steps',
            items: [
              'You should say: [ý 1]',
              '[ý 2]',
              '[ý 3]',
              'and explain [ý 4]',
            ],
          },
        ],
      },
      { title: 'Ý TƯỞNG', blocks: [{ type: 'paragraph', text: '[Gạch ý]' }] },
      {
        title: 'BÀI MẪU',
        blocks: [{ type: 'paragraph', text: '[Câu trả lời mẫu]' }],
      },
      { title: 'TỪ VỰNG', blocks: [newBlock('vocab')] },
    ],
  },
  {
    id: 'blank',
    name: 'Trống',
    skill: 'reading',
    description: 'Bắt đầu từ một section trống, tự thêm khối.',
    kind: 'template',
    sections: [{ title: 'SECTION 1', blocks: [newBlock('heading')] }],
  },
  {
    id: 'import',
    name: 'Nhập từ file JSON',
    skill: 'reading',
    description:
      'Đã có file JSON? Tải lên hoặc dán vào, hệ thống kiểm tra key rồi dựng tài liệu.',
    kind: 'import',
    sections: [{ title: 'SECTION 1', blocks: [newBlock('heading')] }],
  },
  {
    id: 'html',
    name: 'Tải lên file HTML',
    skill: 'vocabulary',
    description: 'File HTML tự lo trình chiếu. App chỉ hiển thị nguyên file.',
    kind: 'html',
    sections: [],
  },
];

export function templateById(id: string): DocTemplate | undefined {
  return DOC_TEMPLATES.find((t) => t.id === id);
}

/** JSON tài liệu mới dựng từ template (bản sao sâu). */
export function buildDocFromTemplate(
  t: DocTemplate,
  init: { week: number; order: number; title: string; skill: string },
): DocJson {
  return structuredClone({
    schemaVersion: 1,
    id: `w${init.week}-doc${init.order}`,
    week: init.week,
    order: init.order,
    title: init.title,
    template: t.kind === 'import' ? 'custom' : t.id,
    meta: {
      skill: init.skill,
      defaultView: 'slide',
      allowedViews: ['slide', 'doc'],
    },
    sections: t.sections,
  });
}

/** Tài liệu mẫu đã xuất bản cho seed (đủ 8 loại khối) — cùng nội dung với FE `sampleReadingDoc`. */
export function sampleReadingDoc(week: number): DocJson {
  return {
    schemaVersion: 1,
    id: `w${week}-doc1`,
    week,
    order: 1,
    title: 'Reading: Matching Headings',
    template: 'reading-lesson',
    meta: {
      skill: 'reading',
      defaultView: 'slide',
      allowedViews: ['slide', 'doc'],
    },
    sections: [
      {
        title: 'DẠNG BÀI',
        blocks: [
          { type: 'heading', text: 'Matching Headings là gì?' },
          {
            type: 'paragraph',
            text: 'Đề cho một **danh sách tiêu đề** (i, ii, iii…) và bạn chọn tiêu đề phù hợp cho **từng đoạn văn**. Số tiêu đề luôn nhiều hơn số đoạn, nên sẽ có tiêu đề thừa.',
          },
          {
            type: 'callout',
            tone: 'tip',
            text: 'Làm dạng này trước các câu hỏi khác của cùng bài đọc, vì nó giúp bạn nắm ý chính từng đoạn.',
          },
        ],
      },
      {
        title: 'CHIẾN THUẬT',
        blocks: [
          { type: 'heading', text: '3 bước làm bài' },
          {
            type: 'steps',
            items: [
              'Đọc lướt danh sách tiêu đề, gạch chân từ khoá của từng tiêu đề.',
              'Đọc câu đầu và câu cuối mỗi đoạn để tìm ý chính.',
              'Loại trừ: tiêu đề chỉ nói về một chi tiết nhỏ trong đoạn thường là bẫy.',
            ],
          },
        ],
      },
      {
        title: 'VÍ DỤ',
        blocks: [
          {
            type: 'passage',
            label: 'PARAGRAPH A',
            text: 'In recent years, a growing number of city councils have offered grants to residents who convert flat roofs into vegetable gardens. Officials argue that such spaces reduce heat, absorb rainwater and give residents access to fresh produce, while critics question whether the yields justify the cost.',
          },
          {
            type: 'quiz',
            question: 'Chọn tiêu đề phù hợp cho Paragraph A',
            options: [
              'The history of urban farming',
              'Why cities are encouraging rooftop gardens',
              'The rising cost of imported vegetables',
            ],
            answer: 1,
            explain:
              'Đoạn văn nêu lý do chính quyền khuyến khích vườn trên mái: giảm nhiệt, thấm nước mưa, có rau tươi. (i) quá rộng vì không nói về lịch sử; (iii) không được nhắc tới.',
          },
        ],
      },
      {
        title: 'TỪ VỰNG',
        blocks: [
          {
            type: 'vocab',
            items: [
              {
                word: 'grant',
                pos: 'n.',
                ipa: '/ɡrɑːnt/',
                meaning: 'khoản trợ cấp, tiền tài trợ',
              },
              {
                word: 'yield',
                pos: 'n.',
                ipa: '/jiːld/',
                meaning: 'sản lượng, năng suất',
              },
              {
                word: 'justify',
                pos: 'v.',
                ipa: '/ˈdʒʌstɪfaɪ/',
                meaning: 'chứng minh là xứng đáng',
              },
            ],
          },
          {
            type: 'pattern',
            structure: 'Critics question whether + S + V',
            example: 'Critics question whether the yields justify the cost.',
          },
        ],
      },
    ],
  };
}
