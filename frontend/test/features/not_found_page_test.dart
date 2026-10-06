import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/routes/app_router.dart';
import 'package:frontend/core/routes/app_routes.dart';
import 'package:frontend/core/widgets/not_found_page.dart';
import 'package:frontend/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Có ao cá chạy liên tục nên không dùng pumpAndSettle.
Future<void> _settle(WidgetTester tester) async {
  for (var i = 0; i < 6; i++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
}

void main() {
  testWidgets('đường dẫn không tồn tại → trang 404; bấm "Về trang chủ" → /home', (tester) async {
    tester.view
      ..physicalSize = const Size(1280, 900)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    SharedPreferences.setMockInitialValues({'access_token': 'test-token', 'user_role': 'USER', 'user_id': 'u1'});

    await tester.pumpWidget(const MyApp());
    await _settle(tester);
    appRouter.go('/khong-co-trang-nay');
    await _settle(tester);

    expect(find.byType(NotFoundPage), findsOneWidget);
    expect(find.text('Không tìm thấy trang'), findsOneWidget);
    expect(find.textContaining('/khong-co-trang-nay'), findsOneWidget);

    await tester.tap(find.byKey(const Key('not_found_home_button')));
    await _settle(tester);
    expect(find.byType(NotFoundPage), findsNothing);
    expect(appRouter.routerDelegate.currentConfiguration.uri.path, AppRoutes.home);
  });
}
