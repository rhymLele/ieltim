import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/di/service_locator.dart';
import 'package:frontend/core/routes/app_routes.dart';
import 'package:frontend/core/services/logger_service.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/core/widgets/annotate/annotate.dart';
import 'package:frontend/features/annotate/data/datasources/fake_annotate_remote_datasource.dart';
import 'package:frontend/features/annotate/data/repositories/annotate_repository_impl.dart';
import 'package:frontend/features/annotate/domain/repositories/annotate_repository.dart';
import 'package:frontend/features/vocab/data/repositories/fake_vocab_repository.dart';
import 'package:frontend/features/vocab/domain/repositories/vocab_repository.dart';
import 'package:frontend/features/weekly_docs/data/repositories/fake_weekly_docs_repository.dart';
import 'package:frontend/features/weekly_docs/domain/repositories/weekly_docs_repository.dart';
import 'package:frontend/features/weekly_docs/presentation/pages/doc_reader_page.dart';
import 'package:go_router/go_router.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _open(WidgetTester tester, String docId, {required Size size}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final router = GoRouter(
    initialLocation: AppRoutes.weeklyDoc(docId),
    routes: [
      GoRoute(
        path: AppRoutes.weekly,
        builder: (_, _) => const SizedBox.shrink(),
        routes: [GoRoute(path: AppRoutes.weeklyDocSegment, builder: (_, state) => DocReaderPage(docId: state.pathParameters['id']!))],
      ),
    ],
  );
  await tester.pumpWidget(MaterialApp.router(theme: AppTheme.light, routerConfig: router));
  await _settle(tester);
}

/// Có animation lặp nên không dùng pumpAndSettle.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

bool _hasBackground(InlineSpan span, Color color) {
  var found = false;
  span.visitChildren((child) {
    if (child is TextSpan && child.style?.backgroundColor == color) found = true;
    return !found;
  });
  return found;
}

Finder _textWithBackground(Color color) => find.byWidgetPredicate((w) => w is RichText && _hasBackground(w.text, color));

Finder _swatch(HighlightColor color) => find.byWidgetPredicate((w) => w is Container && w.decoration is BoxDecoration && (w.decoration! as BoxDecoration).color == color.color);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    registerSingleton<LoggerService>(LoggerService(Logger(level: Level.off)));
    registerSingleton<WeeklyDocsRepository>(FakeWeeklyDocsRepository(latency: Duration.zero));
    registerSingleton<VocabRepository>(FakeVocabRepository());
    registerSingleton<AnnotateRepository>(
      AnnotateRepositoryImpl(remote: FakeAnnotateRemoteDataSource(latency: Duration.zero), currentUserId: () async => 'u1', saveDelay: Duration.zero),
    );
  });
  tearDown(resetSingletons);

  testWidgets('bôi đen → hộp thoại; chọn màu → nền đổi; chạm đoạn tô → ✕ bỏ highlight', (tester) async {
    await _open(tester, 'w11-doc1', size: const Size(1280, 900));
    final paragraph = find.textContaining('Đề cho một', findRichText: true).first;
    final box = tester.getRect(paragraph);

    // Kéo chuột bôi đen một đoạn trên dòng đầu.
    final from = box.topLeft + const Offset(2, 10);
    final gesture = await tester.startGesture(from, kind: PointerDeviceKind.mouse);
    await tester.pump();
    await gesture.moveTo(from + const Offset(120, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pump();

    expect(find.byType(SelectionActionsCard), findsOneWidget);
    expect(find.text('Dịch nghĩa'), findsOneWidget);
    expect(_textWithBackground(HighlightColor.yellow.color), findsNothing);

    await tester.tap(_swatch(HighlightColor.yellow));
    await _settle(tester);
    expect(find.byType(SelectionActionsCard), findsNothing);
    expect(_textWithBackground(HighlightColor.yellow.color), findsOneWidget);

    // Chạm vào đoạn vừa tô → hộp thoại có màu hiện tại + nút ✕.
    await tester.tapAt(from + const Offset(20, 0));
    await _settle(tester);
    final remove = find.descendant(of: find.byType(SelectionActionsCard), matching: find.byIcon(Icons.close));
    expect(remove, findsOneWidget);
    await tester.tap(remove);
    await _settle(tester);
    expect(_textWithBackground(HighlightColor.yellow.color), findsNothing);
  });

  testWidgets('đóng hộp thoại bôi đen ở slide 3 vẫn ở slide 3 (không nhảy về slide đầu)', (tester) async {
    await _open(tester, 'w11-doc1', size: const Size(1280, 900));
    for (var i = 0; i < 2; i++) {
      await tester.tap(find.byTooltip('Slide sau'));
      await _settle(tester);
    }
    expect(find.textContaining('3 / '), findsOneWidget);
    final passage = find.textContaining('In recent years', findRichText: true);
    final from = tester.getRect(passage).topLeft + const Offset(2, 10);
    final gesture = await tester.startGesture(from, kind: PointerDeviceKind.mouse);
    await tester.pump();
    await gesture.moveTo(from + const Offset(150, 0));
    await tester.pump();
    await gesture.up();
    await tester.pump();
    await tester.pump();
    await tester.tap(_swatch(HighlightColor.values.last));
    await _settle(tester);
    expect(find.textContaining('3 / '), findsOneWidget);
    expect(passage, findsOneWidget);
    expect(_textWithBackground(HighlightColor.values.last.color), findsOneWidget);
  });

  testWidgets('Bút khoá vuốt chuyển slide (vuốt = vẽ); về Xem thì vuốt chuyển slide như cũ', (tester) async {
    await _open(tester, 'w11-doc1', size: const Size(390, 844));
    expect(find.textContaining('1 / '), findsOneWidget);
    final toolbar = find.byKey(const Key('weekly_docs_annotation_toolbar'));
    final slide = tester.getCenter(find.byType(PageView));

    await tester.tap(find.descendant(of: toolbar, matching: find.byIcon(Icons.edit_outlined)));
    await tester.pump();
    await tester.dragFrom(slide, const Offset(-250, 0));
    await _settle(tester);
    expect(find.textContaining('1 / '), findsOneWidget, reason: 'đang cầm bút: không sang slide');
    expect(find.byTooltip('Hoàn tác'), findsOneWidget);
    expect(tester.widget<IconButton>(find.widgetWithIcon(IconButton, Icons.undo_rounded)).onPressed, isNotNull, reason: 'nét vừa vẽ có thể hoàn tác');

    await tester.tap(find.descendant(of: toolbar, matching: find.byIcon(Icons.pan_tool_alt_outlined)));
    await tester.pump();
    await tester.dragFrom(slide, const Offset(-250, 0));
    await _settle(tester);
    expect(find.textContaining('2 / '), findsOneWidget);
  });
}
