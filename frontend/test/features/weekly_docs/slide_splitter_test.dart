import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/weekly_docs/domain/models/weekly_doc.dart';
import 'package:frontend/features/weekly_docs/domain/slide_splitter.dart';

WeeklyDoc _doc(List<List<DocBlock>> sections) => WeeklyDoc(
      id: 'd',
      meta: const DocMeta(title: 'T'),
      sections: [
        for (var i = 0; i < sections.length; i++)
          DocSection(number: i + 1, title: 'S${i + 1}', blocks: sections[i]),
      ],
    );

void main() {
  test('2 section, không slideBreak → 2 slide', () {
    final slides = splitSlides(_doc([
      [DocBlock.heading(text: 'A')],
      [DocBlock.paragraph(text: 'B')],
    ]));
    expect(slides, hasLength(2));
    expect(slides[0].sectionIndex, 0);
    expect(slides[0].blocks, hasLength(1));
    expect(slides[1].sectionIndex, 1);
    expect(slides[1].blocks.first, isA<ParagraphBlock>());
  });

  test('1 section, slideBreak giữa → 2 slide chia khối', () {
    final slides = splitSlides(_doc([
      [
        DocBlock.heading(text: 'A'),
        DocBlock.slideBreak(),
        DocBlock.paragraph(text: 'B'),
      ],
    ]));
    expect(slides, hasLength(2));
    expect(slides[0].blocks, hasLength(1));
    expect(slides[0].blocks.first, isA<HeadingBlock>());
    expect(slides[1].blocks, hasLength(1));
    expect(slides[1].blocks.first, isA<ParagraphBlock>());
    expect(slides[1].sectionIndex, 0); // cùng section
  });

  test('nhiều khối trước/sau break', () {
    final slides = splitSlides(_doc([
      [
        DocBlock.paragraph(text: 'a'),
        DocBlock.paragraph(text: 'b'),
        DocBlock.slideBreak(),
        DocBlock.paragraph(text: 'c'),
        DocBlock.paragraph(text: 'd'),
      ],
    ]));
    expect(slides, hasLength(2));
    expect(slides[0].blocks, hasLength(2));
    expect(slides[1].blocks, hasLength(2));
  });

  test('nhiều slideBreak → nhiều slide', () {
    final slides = splitSlides(_doc([
      [
        DocBlock.paragraph(text: 'a'),
        DocBlock.slideBreak(),
        DocBlock.paragraph(text: 'b'),
        DocBlock.slideBreak(),
        DocBlock.paragraph(text: 'c'),
      ],
    ]));
    expect(slides, hasLength(3));
    for (final s in slides) {
      expect(s.blocks, hasLength(1));
    }
  });

  test('section rỗng → 1 slide rỗng', () {
    final slides = splitSlides(_doc([[]]));
    expect(slides, hasLength(1));
    expect(slides[0].blocks, isEmpty);
  });

  test('break ở cuối → slide cuối rỗng (giữ thứ tự)', () {
    final slides = splitSlides(_doc([
      [DocBlock.paragraph(text: 'a'), DocBlock.slideBreak()],
    ]));
    expect(slides, hasLength(2));
    expect(slides[0].blocks, hasLength(1));
    expect(slides[1].blocks, isEmpty);
  });
}
