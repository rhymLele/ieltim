import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/di/service_locator.dart';
import 'package:frontend/core/routes/app_routes.dart';
import 'package:frontend/core/theme/app_theme.dart';
import 'package:frontend/features/weekly_docs/data/repositories/fake_weekly_docs_repository.dart';
import 'package:frontend/features/weekly_docs/domain/repositories/weekly_docs_repository.dart';
import 'package:frontend/features/weekly_docs/presentation/cubits/doc_complete_cubit.dart';
import 'package:frontend/features/weekly_docs/presentation/pages/admin_docs_page.dart';
import 'package:frontend/features/weekly_docs/presentation/pages/doc_complete_page.dart';
import 'package:frontend/features/weekly_docs/presentation/pages/doc_creator_page.dart';
import 'package:frontend/features/weekly_docs/presentation/pages/doc_reader_page.dart';
import 'package:frontend/features/weekly_docs/presentation/pages/weeks_page.dart';
import 'package:go_router/go_router.dart';

/// Các route của Tài liệu theo tuần như app_router (bỏ phần đăng nhập và AppLayout).
GoRouter _router(String initialLocation) => GoRouter(
      initialLocation: initialLocation,
      routes: [
        GoRoute(
          path: AppRoutes.weekly,
          builder: (_, _) => const WeeksPage(),
          routes: [
            GoRoute(
              path: AppRoutes.weeklyDocSegment,
              builder: (_, state) => DocReaderPage(docId: state.pathParameters['id']!),
              routes: [
                GoRoute(path: AppRoutes.weeklyDocDoneSegment, builder: (_, state) => DocCompletePage(args: state.extra! as DocCompleteArgs)),
              ],
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.adminWeeklyDocs,
          builder: (_, _) => const AdminDocsPage(),
          routes: [
            GoRoute(
              path: AppRoutes.adminWeeklyDocCreateSegment,
              builder: (_, state) => DocCreatorPage(initialWeek: int.tryParse(state.uri.queryParameters['week'] ?? '') ?? 0),
            ),
            GoRoute(path: AppRoutes.adminWeeklyDocEditSegment, builder: (_, state) => DocCreatorPage(docId: state.pathParameters['id'])),
            GoRoute(path: AppRoutes.adminWeeklyDocPreviewSegment, builder: (_, state) => DocReaderPage(docId: state.pathParameters['id']!, isAdminPreview: true)),
          ],
        ),
      ],
    );

Future<void> _open(WidgetTester tester, String location, {Size size = const Size(1280, 900)}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(MaterialApp.router(theme: AppTheme.light, routerConfig: _router(location)));
  await _settle(tester);
}

/// Có animation lặp (cá chép, vòng xoay) nên không dùng pumpAndSettle.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 8; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  setUp(() => registerSingleton<WeeklyDocsRepository>(FakeWeeklyDocsRepository(latency: Duration.zero)));
  tearDown(resetSingletons);

  testWidgets('U1 → U2 → U3: mở tài liệu dạng Doc, học xong thì sang màn hoàn thành', (tester) async {
    await _open(tester, AppRoutes.weekly);
    expect(find.byKey(const Key('weekly_docs_week_12_chip')), findsOneWidget);
    expect(find.byKey(const Key('weekly_docs_doc_w12-doc1_card')), findsOneWidget);

    await tester.tap(find.byKey(const Key('weekly_docs_doc_w12-doc2_card')));
    await _settle(tester);
    expect(find.text('Writing Task 2: Opinion essay'), findsWidgets);

    final markDone = find.byKey(const Key('weekly_docs_reader_mark_done_button'));
    await tester.ensureVisible(markDone);
    await tester.pump();
    await tester.tap(markDone);
    await _settle(tester);
    expect(find.text('Hoàn thành Tài liệu 2!'), findsOneWidget);
    expect(find.byKey(const Key('weekly_docs_complete_next_button')), findsOneWidget);
  });

  testWidgets('U2 kiểu Slide trên điện thoại: chuyển slide bằng nút, thanh dưới hiện số trang', (tester) async {
    // Tài liệu đã học xong mở lại từ slide đầu.
    await _open(tester, AppRoutes.weeklyDoc('w11-doc1'), size: const Size(390, 844));
    expect(find.textContaining('1 / '), findsOneWidget);
    await tester.tap(find.byTooltip('Slide sau'));
    await _settle(tester);
    expect(find.textContaining('2 / '), findsOneWidget);
  });

  testWidgets('A1: danh sách tuần hiện tại, mở menu thao tác', (tester) async {
    await _open(tester, AppRoutes.adminWeeklyDocs);
    expect(find.byKey(const Key('weekly_docs_admin_doc_w12-doc1_row')), findsOneWidget);
    expect(find.byKey(const Key('weekly_docs_admin_doc_w12-doc3_row')), findsOneWidget);
    await tester.tap(find.byKey(const Key('weekly_docs_admin_doc_w12-doc3_menu')));
    await _settle(tester);
    expect(find.byKey(const Key('weekly_docs_admin_action_delete_item')), findsOneWidget);
  });

  testWidgets('A2 tạo mới: điền tên → Tiếp tục tạo nháp và sang bước soạn', (tester) async {
    await _open(tester, AppRoutes.adminWeeklyDocCreate(week: 12));
    expect(tester.widget<TextField>(find.byKey(const Key('weekly_docs_creator_order_field'))).controller?.text, '4');
    expect(find.text('w12-doc4.json'), findsOneWidget);

    await tester.enterText(find.byKey(const Key('weekly_docs_creator_title_field')), 'Listening: Map labelling');
    await tester.tap(find.byKey(const Key('weekly_docs_creator_forward_button')));
    await _settle(tester);
    expect(find.byKey(const Key('weekly_docs_creator_form_mode_button')), findsOneWidget);
    expect(find.text('w12-doc4.json'), findsOneWidget);
  });

  testWidgets('A2 sửa: tab JSON nạp nội dung hiện tại', (tester) async {
    await _open(tester, AppRoutes.adminWeeklyDocEdit('w12-doc3'));
    await tester.tap(find.byKey(const Key('weekly_docs_creator_json_mode_button')));
    await _settle(tester);
    final field = tester.widget<TextField>(find.byKey(const Key('weekly_docs_creator_json_field')));
    expect(field.controller?.text, contains('"schemaVersion"'));
    expect(field.controller?.text, contains('Speaking Part 2'));
  });
}
