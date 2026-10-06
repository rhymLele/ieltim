// doc_templates.dart — Template tài liệu + khối mặc định + tài liệu mẫu.

import '../entities/doc_category.dart';

class DocTemplate {
  const DocTemplate({
    required this.id,
    required this.name,
    required this.skill,
    required this.description,
    required this.sections,
    this.isImport = false,
    this.isHtml = false,
  });

  final String id;
  final String name;
  final String skill;
  final String description;
  final List<Map<String, dynamic>> sections;
  final bool isImport;
  final bool isHtml;

  List<String> get outline => isHtml
      ? const ['<!doctype html>', '<html>…</html>', 'Tự lo trình chiếu']
      : isImport
          ? const ['schemaVersion', 'title', 'sections[ ]', 'blocks[ ]']
          : sections.map((s) => s['title'] as String).toList();
}

/// JSON khối mới (có chỗ trống để admin điền).
Map<String, dynamic> newBlockJson(String type) => switch (type) {
      'heading' => {'type': 'heading', 'text': '[Tiêu đề]'},
      'paragraph' => {'type': 'paragraph', 'text': '[Nội dung, dùng **chữ đậm** để nhấn mạnh]'},
      'callout' => {'type': 'callout', 'tone': 'tip', 'text': '[Mẹo]'},
      'steps' => {'type': 'steps', 'items': ['[Bước 1]', '[Bước 2]', '[Bước 3]']},
      'passage' => {'type': 'passage', 'label': 'PARAGRAPH A', 'text': '[Dán đoạn văn đề thi]'},
      'quiz' => {
          'type': 'quiz',
          'question': '[Câu hỏi]',
          'options': ['[Đáp án i]', '[Đáp án ii]', '[Đáp án iii]'],
          'answer': 0,
          'explain': '[Giải thích]',
        },
      'vocab' => {
          'type': 'vocab',
          'items': [
            {'word': '[từ]', 'pos': 'n.', 'ipa': '/…/', 'meaning': '[nghĩa]'},
          ],
        },
      'pattern' => {'type': 'pattern', 'structure': '[Cấu trúc]', 'example': '[Câu ví dụ]'},
      'image' => {'type': 'image', 'url': 'https://', 'caption': '', 'alt': ''},
      'slideBreak' => {'type': 'slideBreak'},
      _ => {'type': 'paragraph', 'text': ''},
    };

/// Các loại khối admin được thêm từ form (thứ tự chip).
const addableBlockTypes = ['heading', 'paragraph', 'callout', 'steps', 'passage', 'quiz', 'vocab', 'pattern', 'image', 'slideBreak'];

final docTemplates = <DocTemplate>[
  DocTemplate(
    id: 'reading-lesson',
    name: 'Reading lesson',
    skill: 'reading',
    description: 'Dạng bài → chiến thuật → ví dụ có trắc nghiệm → từ vựng.',
    sections: [
      {
        'title': 'DẠNG BÀI',
        'blocks': [
          {'type': 'heading', 'text': '[Tên dạng bài]'},
          {'type': 'paragraph', 'text': '[Mô tả dạng bài, dùng **chữ đậm** cho ý quan trọng]'},
          {'type': 'callout', 'tone': 'tip', 'text': '[Mẹo làm bài]'},
        ],
      },
      {
        'title': 'CHIẾN THUẬT',
        'blocks': [
          {'type': 'heading', 'text': 'Các bước làm bài'},
          newBlockJson('steps'),
        ],
      },
      {'title': 'VÍ DỤ', 'blocks': [newBlockJson('passage'), newBlockJson('quiz')]},
      {'title': 'TỪ VỰNG', 'blocks': [newBlockJson('vocab'), newBlockJson('pattern')]},
    ],
  ),
  DocTemplate(
    id: 'writing-task2',
    name: 'Writing Task 2',
    skill: 'writing',
    description: 'Đề bài → dàn ý 4 phần → bài mẫu → từ vựng và mẫu câu.',
    sections: [
      {
        'title': 'ĐỀ BÀI',
        'blocks': [
          {'type': 'heading', 'text': '[Đề Writing Task 2]'},
          {'type': 'callout', 'tone': 'tip', 'text': '[Dạng đề: Opinion / Discussion / Problem–Solution…]'},
        ],
      },
      {
        'title': 'DÀN Ý',
        'blocks': [
          {'type': 'steps', 'items': ['Mở bài: [ý]', 'Thân bài 1: [ý]', 'Thân bài 2: [ý]', 'Kết bài: [ý]']},
        ],
      },
      {
        'title': 'BÀI MẪU',
        'blocks': [
          {'type': 'paragraph', 'text': '[Dán bài mẫu]'},
        ],
      },
      {'title': 'TỪ VỰNG & MẪU CÂU', 'blocks': [newBlockJson('vocab'), newBlockJson('pattern')]},
    ],
  ),
  DocTemplate(
    id: 'vocab-set',
    name: 'Vocab set',
    skill: 'vocabulary',
    description: 'Bộ từ theo chủ đề, kết thúc bằng câu hỏi luyện tập.',
    sections: [
      {
        'title': 'CHỦ ĐỀ',
        'blocks': [
          {'type': 'heading', 'text': '[Chủ đề]'},
          {'type': 'paragraph', 'text': '[Giới thiệu ngắn]'},
        ],
      },
      {'title': 'TỪ VỰNG', 'blocks': [newBlockJson('vocab')]},
      {'title': 'LUYỆN TẬP', 'blocks': [newBlockJson('quiz')]},
    ],
  ),
  DocTemplate(
    id: 'speaking-part2',
    name: 'Speaking Part 2',
    skill: 'speaking',
    description: 'Cue card → ý tưởng → câu trả lời mẫu → từ vựng.',
    sections: [
      {
        'title': 'CUE CARD',
        'blocks': [
          {'type': 'heading', 'text': 'Describe [a …]'},
          {'type': 'steps', 'items': ['You should say: [ý 1]', '[ý 2]', '[ý 3]', 'and explain [ý 4]'] },
        ],
      },
      {
        'title': 'Ý TƯỞNG',
        'blocks': [
          {'type': 'paragraph', 'text': '[Gạch ý]'},
        ],
      },
      {
        'title': 'BÀI MẪU',
        'blocks': [
          {'type': 'paragraph', 'text': '[Câu trả lời mẫu]'},
        ],
      },
      {'title': 'TỪ VỰNG', 'blocks': [newBlockJson('vocab')]},
    ],
  ),
  DocTemplate(
    id: 'blank',
    name: 'Trống',
    skill: 'reading',
    description: 'Bắt đầu từ một section trống, tự thêm khối.',
    sections: [
      {'title': 'SECTION 1', 'blocks': [newBlockJson('heading')]},
    ],
  ),
  DocTemplate(
    id: 'import',
    name: 'Nhập từ file JSON',
    skill: 'reading',
    description: 'Đã có file JSON? Tải lên hoặc dán vào, hệ thống kiểm tra key rồi dựng tài liệu.',
    isImport: true,
    sections: [
      {'title': 'SECTION 1', 'blocks': [newBlockJson('heading')]},
    ],
  ),
  DocTemplate(
    id: 'html',
    name: 'Tải lên file HTML',
    skill: 'vocabulary',
    description: 'File HTML tự lo trình chiếu. App chỉ hiển thị nguyên file.',
    isHtml: true,
    sections: [],
  ),
];

DocTemplate templateById(String id) => docTemplates.firstWhere((t) => t.id == id, orElse: () => docTemplates.first);

/// Dựng JSON tài liệu mới từ template (sao chép sâu để sửa an toàn).
Map<String, dynamic> buildDocJson({
  required int week,
  required int order,
  required String title,
  required String templateId,
  required String skill,
  DocCategory category = DocCategory.lesson,
}) {
  final t = templateById(templateId);
  return deepCopyJson(<String, dynamic>{
    'schemaVersion': 1,
    'id': category.code(week, order),
    'week': week,
    'order': order,
    'category': category.name,
    'title': title,
    'template': t.isImport ? 'custom' : t.id,
    'meta': {
      'skill': skill,
      'defaultView': 'slide',
      'allowedViews': ['slide', 'doc'],
    },
    'sections': t.sections,
  });
}

/// Sao chép sâu Map/List JSON. Map → `Map<String, dynamic>`, List → `List<dynamic>`
/// (kiểu "mở" để sửa/chèn tự do trong editor).
dynamic deepCopyJson(Object? value) {
  if (value is Map) {
    return <String, dynamic>{for (final e in value.entries) e.key.toString(): deepCopyJson(e.value)};
  }
  if (value is List) return <dynamic>[for (final e in value) deepCopyJson(e)];
  return value;
}

/// Tài liệu mẫu đã xuất bản (dùng cho dữ liệu giả).
Map<String, dynamic> sampleReadingDoc() => {
      'schemaVersion': 1,
      'id': 'w12-doc1',
      'week': 12,
      'order': 1,
      'title': 'Reading: Matching Headings',
      'template': 'reading-lesson',
      'meta': {
        'skill': 'reading',
        'defaultView': 'slide',
        'allowedViews': ['slide', 'doc'],
      },
      'sections': [
        {
          'title': 'DẠNG BÀI',
          'blocks': [
            {'type': 'heading', 'text': 'Matching Headings là gì?'},
            {
              'type': 'paragraph',
              'text': 'Đề cho một **danh sách tiêu đề** (i, ii, iii…) và bạn chọn tiêu đề phù hợp cho **từng đoạn văn**. Số tiêu đề luôn nhiều hơn số đoạn, nên sẽ có tiêu đề thừa.',
            },
            {'type': 'callout', 'tone': 'tip', 'text': 'Làm dạng này trước các câu hỏi khác của cùng bài đọc, vì nó giúp bạn nắm ý chính từng đoạn.'},
          ],
        },
        {
          'title': 'CHIẾN THUẬT',
          'blocks': [
            {'type': 'heading', 'text': '3 bước làm bài'},
            {
              'type': 'steps',
              'items': [
                'Đọc lướt danh sách tiêu đề, gạch chân từ khoá của từng tiêu đề.',
                'Đọc câu đầu và câu cuối mỗi đoạn để tìm ý chính.',
                'Loại trừ: tiêu đề chỉ nói về một chi tiết nhỏ trong đoạn thường là bẫy.',
              ],
            },
          ],
        },
        {
          'title': 'VÍ DỤ',
          'blocks': [
            {
              'type': 'passage',
              'label': 'PARAGRAPH A',
              'text': 'In recent years, a growing number of city councils have offered grants to residents who convert flat roofs into vegetable gardens. Officials argue that such spaces reduce heat, absorb rainwater and give residents access to fresh produce, while critics question whether the yields justify the cost.',
            },
            {
              'type': 'quiz',
              'question': 'Chọn tiêu đề phù hợp cho Paragraph A',
              'options': ['The history of urban farming', 'Why cities are encouraging rooftop gardens', 'The rising cost of imported vegetables'],
              'answer': 1,
              'explain': 'Đoạn văn nêu lý do chính quyền khuyến khích vườn trên mái: giảm nhiệt, thấm nước mưa, có rau tươi. (i) quá rộng vì không nói về lịch sử; (iii) không được nhắc tới.',
            },
          ],
        },
        {
          'title': 'TỪ VỰNG',
          'blocks': [
            {
              'type': 'vocab',
              'items': [
                {'word': 'grant', 'pos': 'n.', 'ipa': '/ɡrɑːnt/', 'meaning': 'khoản trợ cấp, tiền tài trợ'},
                {'word': 'yield', 'pos': 'n.', 'ipa': '/jiːld/', 'meaning': 'sản lượng, năng suất'},
                {'word': 'justify', 'pos': 'v.', 'ipa': '/ˈdʒʌstɪfaɪ/', 'meaning': 'chứng minh là xứng đáng'},
              ],
            },
            {'type': 'pattern', 'structure': 'Critics question whether + S + V', 'example': 'Critics question whether the yields justify the cost.'},
          ],
        },
      ],
    };
