import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/weekly_docs/domain/block_parser.dart';
import 'package:frontend/features/weekly_docs/domain/models/weekly_doc.dart';

void main() {
  group('parseDocBlock — đủ 10 loại khối', () {
    test('heading', () {
      final b = parseDocBlock(
          {'type': 'heading', 'id': 'h1', 'text': 'Mở bài'}) as HeadingBlock;
      expect(b.text, 'Mở bài');
      expect(b.idOrNull, 'h1');
    });

    test('paragraph', () {
      final b = parseDocBlock({
        'type': 'paragraph',
        'text': 'Một **đoạn** văn'
      }) as ParagraphBlock;
      expect(b.text, 'Một **đoạn** văn');
    });

    test('callout', () {
      final b = parseDocBlock({
        'type': 'callout',
        'text': 'Mẹo: đọc trước câu hỏi'
      }) as CalloutBlock;
      expect(b.text, 'Mẹo: đọc trước câu hỏi');
    });

    test('steps', () {
      final b = parseDocBlock({
        'type': 'steps',
        'items': ['Bước 1', 'Bước 2', 'Bước 3']
      }) as StepsBlock;
      expect(b.items, ['Bước 1', 'Bước 2', 'Bước 3']);
    });

    test('passage', () {
      final b = parseDocBlock({
        'type': 'passage',
        'label': 'Listening',
        'text': 'The passage text...'
      }) as PassageBlock;
      expect(b.label, 'Listening');
      expect(b.text, 'The passage text...');
    });

    test('quiz', () {
      final b = parseDocBlock({
        'type': 'quiz',
        'question': 'Câu hỏi?',
        'options': ['a', 'b', 'c'],
        'correctIndex': 1,
        'explanation': 'Giải thích'
      }) as QuizBlock;
      expect(b.question, 'Câu hỏi?');
      expect(b.options, ['a', 'b', 'c']);
      expect(b.correctIndex, 1);
      expect(b.explanation, 'Giải thích');
    });

    test('vocab', () {
      final b = parseDocBlock({
        'type': 'vocab',
        'items': [
          {'word': 'run', 'partOfSpeech': 'v', 'ipa': '/rʌn/', 'meaning': 'chạy'},
          {'word': 'house', 'meaning': 'ngôi nhà'}
        ]
      }) as VocabBlock;
      expect(b.items, hasLength(2));
      expect(b.items[0].word, 'run');
      expect(b.items[0].partOfSpeech, 'v');
      expect(b.items[0].ipa, '/rʌn/');
      expect(b.items[0].meaning, 'chạy');
      expect(b.items[1].word, 'house');
      expect(b.items[1].meaning, 'ngôi nhà');
    });

    test('pattern', () {
      final b = parseDocBlock({
        'type': 'pattern',
        'text': 'One of the main reasons is that + clause'
      }) as PatternBlock;
      expect(b.text, 'One of the main reasons is that + clause');
    });

    test('image', () {
      final b = parseDocBlock({
        'type': 'image',
        'url': 'https://example.com/a.png',
        'alt': 'Biểu đồ'
      }) as ImageBlock;
      expect(b.url, 'https://example.com/a.png');
      expect(b.alt, 'Biểu đồ');
    });

    test('slideBreak', () {
      final b = parseDocBlock({'type': 'slideBreak', 'id': 'br1'})
          as SlideBreakBlock;
      expect(b.idOrNull, 'br1');
    });
  });

  group('parseDocBlock — UnknownBlock (không throw)', () {
    test('type lạ → UnknownBlock giữ nguyên JSON', () {
      final b = parseDocBlock(
          {'type': 'mystery', 'id': 'm1', 'foo': 'bar', 'n': 5}) as UnknownBlock;
      expect(b.type, 'mystery');
      expect(b.raw['foo'], 'bar');
      expect(b.raw['n'], 5);
      expect(b.idOrNull, 'm1');
    });

    test('thiếu type → UnknownBlock type rỗng', () {
      final b = parseDocBlock({'id': 'x'}) as UnknownBlock;
      expect(b.type, '');
      expect(b.raw['id'], 'x');
    });

    test('type đã biết nhưng thiếu field → không throw, dùng default', () {
      expect(() => parseDocBlock({'type': 'quiz'}), returnsNormally);
      final b = parseDocBlock({'type': 'quiz'}) as QuizBlock;
      expect(b.options, isEmpty);
      expect(b.correctIndex, 0);
    });

    test('block rỗng {} → UnknownBlock', () {
      expect(parseDocBlock({}), isA<UnknownBlock>());
    });
  });

  group('parseWeeklyDoc', () {
    const full = {
      'id': 'doc-1',
      'meta': {
        'title': 'Writing Task 2',
        'week': 4,
        'order': 2,
        'skills': ['Writing'],
        'estimatedMinutes': 8,
        'status': 'published',
        'defaultView': 'slide',
      },
      'sections': [
        {
          'id': 's1',
          'title': 'Mở bài',
          'blocks': [
            {'type': 'heading', 'text': 'Xin chào'},
            {'type': 'paragraph', 'text': 'Nội dung.'},
            {'type': 'slideBreak'},
            {'type': 'quiz', 'question': 'Q', 'options': ['a', 'b'], 'correctIndex': 0},
          ],
        },
        {
          'title': 'Thân bài',
          'blocks': [
            {'type': 'vocab', 'items': [{'word': 'run', 'meaning': 'chạy'}]},
          ],
        },
      ],
    };

    test('parse meta + sections + blocks', () {
      final doc = parseWeeklyDoc(full);
      expect(doc.id, 'doc-1');
      expect(doc.meta.title, 'Writing Task 2');
      expect(doc.meta.week, 4);
      expect(doc.meta.status, DocStatus.published);
      expect(doc.meta.defaultView, DocViewMode.slide);
      expect(doc.meta.skill, 'Writing');
      expect(doc.partsCount, 2);
      expect(doc.sections[0].blocks, hasLength(4));
      expect(doc.sections[1].number, 2); // auto = index+1
      expect(doc.sections[1].blocks.first, isA<VocabBlock>());
    });

    test('round-trip toMap giữ nguyên nội dung', () {
      final doc = parseWeeklyDoc(full);
      final m = weeklyDocToMap(doc);
      expect(m['id'], 'doc-1');
      expect((m['sections'] as List).length, 2);
      final s1 = (m['sections'] as List)[0] as Map;
      final blocks = s1['blocks'] as List;
      expect((blocks[2] as Map)['type'], 'slideBreak');
      expect((blocks[3] as Map)['type'], 'quiz');
      // parse lại → cùng kiểu
      final again = parseWeeklyDoc(m);
      expect(again.sections[0].blocks[2], isA<SlideBreakBlock>());
    });
  });
}
