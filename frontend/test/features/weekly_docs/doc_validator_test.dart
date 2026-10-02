import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/weekly_docs/domain/doc_validator.dart';
import 'package:frontend/features/weekly_docs/domain/models/weekly_doc.dart';

DocMeta _meta({
  String title = 'T',
  int week = 1,
  int minutes = 8,
  DocViewMode defaultView = DocViewMode.slide,
  List<DocViewMode> allowed = const [DocViewMode.slide, DocViewMode.doc],
}) =>
    DocMeta(
      title: title,
      week: week,
      order: 1,
      estimatedMinutes: minutes,
      defaultView: defaultView,
      allowedViews: allowed,
    );

WeeklyDoc _doc({
  DocMeta? meta,
  List<DocSection>? sections,
}) =>
    WeeklyDoc(
      id: 'd',
      meta: meta ?? _meta(),
      sections: sections ??
          [
            DocSection(
                number: 1, title: 'S', blocks: [DocBlock.paragraph(text: 'hi')]),
          ],
    );

List<ValidationIssue> _atPath(ValidationResult r, String path,
        {bool warning = false}) =>
    (warning ? r.warnings : r.errors).where((e) => e.path == path).toList();

void main() {
  test('tài liệu hợp lệ → không có error', () {
    final r = validateWeeklyDoc(_doc());
    expect(r.isReady, isTrue);
    expect(r.errors, isEmpty);
  });

  test('thiếu tiêu đề → error meta.title', () {
    final r = validateWeeklyDoc(_doc(meta: _meta(title: '   ')));
    expect(r.hasErrors, isTrue);
    expect(_atPath(r, 'meta.title'), isNotEmpty);
  });

  test('không section → error sections', () {
    final r = validateWeeklyDoc(_doc(sections: []));
    expect(_atPath(r, 'sections'), isNotEmpty);
  });

  test('section không tên → error sections[i].title', () {
    final r = validateWeeklyDoc(_doc(sections: [
      DocSection(number: 1, title: '', blocks: [DocBlock.paragraph(text: 'x')]),
    ]));
    expect(_atPath(r, 'sections[0].title'), isNotEmpty);
  });

  test('section rỗng → warning sections[i].blocks', () {
    final r = validateWeeklyDoc(_doc(sections: [
      DocSection(number: 1, title: 'S', blocks: []),
    ]));
    expect(_atPath(r, 'sections[0].blocks', warning: true), isNotEmpty);
  });

  test('quiz < 2 đáp án → error', () {
    final r = validateWeeklyDoc(_doc(sections: [
      DocSection(
          number: 1,
          title: 'S',
          blocks: [
            DocBlock.quiz(question: 'q', options: ['a'], correctIndex: 0)
          ]),
    ]));
    expect(_atPath(r, 'sections[0].blocks[0].options'), isNotEmpty);
  });

  test('quiz correctIndex vượt phạm vi → error', () {
    final r = validateWeeklyDoc(_doc(sections: [
      DocSection(
          number: 1,
          title: 'S',
          blocks: [
            DocBlock.quiz(
                question: 'q', options: ['a', 'b'], correctIndex: 5)
          ]),
    ]));
    expect(_atPath(r, 'sections[0].blocks[0].correctIndex'), isNotEmpty);
  });

  test('ảnh thiếu url → error; thiếu alt → warning', () {
    final r = validateWeeklyDoc(_doc(sections: [
      DocSection(
          number: 1, title: 'S', blocks: [DocBlock.image(url: '', alt: '')]),
    ]));
    expect(_atPath(r, 'sections[0].blocks[0].url'), isNotEmpty);
    expect(_atPath(r, 'sections[0].blocks[0].alt', warning: true), isNotEmpty);
  });

  test('vocab thiếu từ → error; thiếu nghĩa → warning', () {
    final r = validateWeeklyDoc(_doc(sections: [
      DocSection(
          number: 1,
          title: 'S',
          blocks: [DocBlock.vocab(items: [const VocabItem(word: '')])]),
    ]));
    expect(_atPath(r, 'sections[0].blocks[0].items[0].word'), isNotEmpty);
    expect(
        _atPath(r, 'sections[0].blocks[0].items[0].meaning', warning: true),
        isNotEmpty);
  });

  test('khối unknown → warning', () {
    final r = validateWeeklyDoc(_doc(sections: [
      DocSection(
          number: 1,
          title: 'S',
          blocks: [
            DocBlock.unknown(type: 'mystery', raw: const {})
          ]),
    ]));
    expect(
        _atPath(r, 'sections[0].blocks[0]', warning: true), isNotEmpty);
  });

  test('defaultView không trong allowedViews → warning', () {
    final r = validateWeeklyDoc(_doc(
      meta: _meta(
          defaultView: DocViewMode.doc, allowed: [DocViewMode.slide]),
    ));
    expect(_atPath(r, 'meta.defaultView', warning: true), isNotEmpty);
  });

  test('steps rỗng → error', () {
    final r = validateWeeklyDoc(_doc(sections: [
      DocSection(
          number: 1, title: 'S', blocks: [DocBlock.steps(items: [])]),
    ]));
    expect(_atPath(r, 'sections[0].blocks[0]'), isNotEmpty);
  });
}
