import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/features/weekly_docs/domain/models/weekly_doc.dart';
import 'package:frontend/features/weekly_docs/presentation/blocks/block_context.dart';
import 'package:frontend/features/weekly_docs/presentation/widgets/doc_view.dart';

WeeklyDoc _sampleDoc() => WeeklyDoc(
      id: 'd',
      meta: const DocMeta(title: 'Tiêu đề', week: 1, order: 1, skills: ['Listening']),
      sections: [
        DocSection(number: 1, title: 'Phần 1', blocks: [
          DocBlock.heading(id: 'h1', text: 'Chào'),
          DocBlock.paragraph(id: 'p1', text: 'Nội dung đoạn văn'),
          DocBlock.quiz(
              id: 'q1',
              question: 'Chọn đáp án?',
              options: const ['A', 'B', 'C'],
              correctIndex: 1,
              explanation: 'Vì B'),
        ]),
        DocSection(number: 2, title: 'Phần 2', blocks: [
          DocBlock.paragraph(id: 'p2', text: 'Đoạn hai'),
        ]),
      ],
    );

WeeklyDoc _quizDoc() => WeeklyDoc(
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

Future<void> _pumpDoc(WidgetTester tester,
    {required BlockContext base, WeeklyDoc? doc, VoidCallback? onComplete}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DocView(
          doc: doc ?? _sampleDoc(),
          base: base,
          isMobile: true,
          onComplete: onComplete,
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('DocView render tài liệu mẫu', (tester) async {
    await _pumpDoc(tester, base: const BlockContext(mode: RenderMode.doc));
    expect(find.text('Tiêu đề'), findsOneWidget);
    expect(find.text('Phần 1'), findsOneWidget);
    expect(find.text('Chào'), findsOneWidget);
    expect(find.text('Nội dung đoạn văn'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Chọn đáp án?'), -200);
    expect(find.text('Chọn đáp án?'), findsOneWidget);
  });

  // DocView là stateless, đọc đáp án qua closure trong [BlockContext]; trong
  // app thật bloc sẽ rebuild. Ở đây mình re-pump để phản ánh đáp án mới.
  testWidgets('quiz chọn sai → hiện sai + giải thích', (tester) async {
    final answers = <String, int>{};
    final base = BlockContext(
      mode: RenderMode.doc,
      quizAnswerFor: (k) => answers[k],
      onQuizAnswer: (k, i) => answers[k] = i,
    );
    await _pumpDoc(tester, base: base, doc: _quizDoc());
    await tester.tap(find.byKey(const ValueKey('quiz_opt_q1_0')));
    await tester.pump();
    expect(answers['q1'], 0);
    await _pumpDoc(tester, base: base, doc: _quizDoc());
    await tester.pump();
    // chọn 0 (sai): opt 0 hiện cancel, opt 1 (đúng) hiện check, hiện giải thích
    expect(find.byIcon(Icons.cancel), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.text('Vì B'), findsOneWidget);
  });

  testWidgets('quiz chọn đúng → không còn sai', (tester) async {
    final answers = <String, int>{};
    final base = BlockContext(
      mode: RenderMode.doc,
      quizAnswerFor: (k) => answers[k],
      onQuizAnswer: (k, i) => answers[k] = i,
    );
    await _pumpDoc(tester, base: base, doc: _quizDoc());
    await tester.tap(find.byKey(const ValueKey('quiz_opt_q1_1')));
    await tester.pump();
    expect(answers['q1'], 1);
    await _pumpDoc(tester, base: base, doc: _quizDoc());
    await tester.pump();
    expect(find.byIcon(Icons.cancel), findsNothing);
    expect(find.byIcon(Icons.check_circle), findsWidgets);
  });

  testWidgets('chọn lại được (đổi đáp án)', (tester) async {
    final answers = <String, int>{};
    final base = BlockContext(
      mode: RenderMode.doc,
      quizAnswerFor: (k) => answers[k],
      onQuizAnswer: (k, i) => answers[k] = i,
    );
    await _pumpDoc(tester, base: base, doc: _quizDoc());
    await tester.tap(find.byKey(const ValueKey('quiz_opt_q1_0')));
    await tester.pump();
    await _pumpDoc(tester, base: base, doc: _quizDoc());
    await tester.pump();
    expect(find.byIcon(Icons.cancel), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('quiz_opt_q1_1')));
    await tester.pump();
    await _pumpDoc(tester, base: base, doc: _quizDoc());
    await tester.pump();
    expect(answers['q1'], 1);
    expect(find.byIcon(Icons.cancel), findsNothing);
  });

  testWidgets('nút hoàn thành gọi callback', (tester) async {
    var completed = false;
    await _pumpDoc(tester,
        base: const BlockContext(mode: RenderMode.doc),
        doc: _quizDoc(),
        onComplete: () => completed = true);
    await tester.tap(find.text('Đánh dấu đã học xong'));
    await tester.pump();
    expect(completed, isTrue);
  });
}
