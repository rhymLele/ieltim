import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/weekly_docs/domain/models/weekly_doc.dart';
import 'package:frontend/features/weekly_docs/presentation/blocks/block_context.dart';
import 'package:frontend/features/weekly_docs/presentation/widgets/doc_view.dart';
import 'package:frontend/features/weekly_docs/presentation/widgets/slide_view.dart';

WeeklyDoc _slideDoc() => WeeklyDoc(
      id: 'd',
      meta: const DocMeta(title: 'T'),
      sections: [
        DocSection(number: 1, title: 'P1', blocks: [
          DocBlock.heading(id: 'h1', text: 'Trang 1'),
          DocBlock.slideBreak(),
          DocBlock.paragraph(id: 'p2', text: 'Trang 2'),
        ]),
      ],
    );

WeeklyDoc _quizSlideDoc() => WeeklyDoc(
      id: 'd',
      meta: const DocMeta(title: 'T'),
      sections: [
        DocSection(number: 1, title: 'P1', blocks: [
          DocBlock.quiz(
              id: 'q1',
              question: 'Chọn?',
              options: const ['A', 'B', 'C'],
              correctIndex: 1,
              explanation: 'Vì B'),
        ]),
      ],
    );

Future<void> _pumpSlide(
  WidgetTester tester, {
  required BlockContext base,
  required int current,
  required WeeklyDoc doc,
  required ValueChanged<int> onSlideChanged,
  required VoidCallback onComplete,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SlideView(
          doc: doc,
          base: base,
          currentSlide: current,
          onSlideChanged: onSlideChanged,
          onComplete: onComplete,
          isLandscape: false,
          enableKeyboard: false,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('SlideView render mẫu', (tester) async {
    await _pumpSlide(
      tester,
      base: const BlockContext(mode: RenderMode.slide),
      current: 0,
      doc: _slideDoc(),
      onSlideChanged: (_) {},
      onComplete: () {},
    );
    expect(find.text('P1'), findsOneWidget);
    expect(find.text('Trang 1'), findsOneWidget);
  });

  testWidgets('không phải slide cuối → nút Tiếp (chevron)', (tester) async {
    await _pumpSlide(
      tester,
      base: const BlockContext(mode: RenderMode.slide),
      current: 0,
      doc: _slideDoc(),
      onSlideChanged: (_) {},
      onComplete: () {},
    );
    expect(find.byKey(const Key('slide_next')), findsOneWidget);
    expect(find.text('Hoàn thành'), findsNothing);
  });

  testWidgets('slide cuối → nút Hoàn thành, không có Tiếp', (tester) async {
    await _pumpSlide(
      tester,
      base: const BlockContext(mode: RenderMode.slide),
      current: 1,
      doc: _slideDoc(),
      onSlideChanged: (_) {},
      onComplete: () {},
    );
    expect(find.byKey(const Key('slide_complete')), findsOneWidget);
    expect(find.text('Hoàn thành'), findsOneWidget);
    expect(find.byKey(const Key('slide_next')), findsNothing);
  });

  testWidgets('bấm Hoàn thành ở slide cuối → gọi onComplete', (tester) async {
    var completed = 0;
    await _pumpSlide(
      tester,
      base: const BlockContext(mode: RenderMode.slide),
      current: 1,
      doc: _slideDoc(),
      onSlideChanged: (_) {},
      onComplete: () => completed++,
    );
    await tester.tap(find.text('Hoàn thành'));
    await tester.pump();
    expect(completed, 1);
  });

  testWidgets('chuyển view (Doc → Slide) giữ đáp án quiz', (tester) async {
    final answers = <String, int>{};
    final baseDoc = BlockContext(
      mode: RenderMode.doc,
      quizAnswerFor: (k) => answers[k],
      onQuizAnswer: (k, i) => answers[k] = i,
    );
    final baseSlide = BlockContext(
      mode: RenderMode.slide,
      quizAnswerFor: (k) => answers[k],
      onQuizAnswer: (k, i) => answers[k] = i,
    );

    // 1) Trả lời trong DocView.
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DocView(
            doc: _quizSlideDoc(),
            base: baseDoc,
            isMobile: true,
          ),
        ),
      ),
    );
    await tester.tap(find.byKey(const ValueKey('quiz_opt_q1_0')));
    await tester.pump();
    expect(answers['q1'], 0);

    // 2) Mở cùng tài liệu trong SlideView → đáp án vẫn còn.
    await _pumpSlide(
      tester,
      base: baseSlide,
      current: 0,
      doc: _quizSlideDoc(),
      onSlideChanged: (_) {},
      onComplete: () {},
    );
    // 0 là sai → hiện cancel; 1 đúng → hiện check.
    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('Vì B'), findsOneWidget);
  });
}
