import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/word_of_day_card.dart';
import 'package:frontend/core/widgets/app_layout.dart';
import 'package:frontend/core/widgets/vu_mon_progress.dart';
import 'package:frontend/core/widgets/your_pond_card.dart';
import 'package:frontend/features/home/presentation/views/home_page.dart';
import 'package:frontend/features/wordbook/presentation/bloc/wordbook_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  for (final size in [
    const Size(1200, 900),
    const Size(1200, 600),
    const Size(964, 600),
    const Size(768, 700),
    const Size(390, 844),
    const Size(320, 640),
  ]) {
    testWidgets('dashboard fits $size and word card can flip', (tester) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: HomePage())),
      );
      await tester.pump();
      expect(find.byType(YourPondCard), findsOneWidget);
      expect(find.byType(WordOfDayCard), findsOneWidget);
      if (size.width == 1200) {
        final pond = tester.getRect(find.byType(YourPondCard));
        final word = tester.getRect(find.byType(WordOfDayCard));
        expect(pond.width / word.width, closeTo(2, 0.01));
        expect(word.left, greaterThan(pond.right));
      }
      await tester.ensureVisible(find.byType(WordOfDayCard));
      await tester.pump();
      await tester.tap(find.text('TỪ CỦA NGÀY'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 700));
      expect(find.text('Lưu vào Sổ từ'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Lưu vào Sổ từ'));
      for (var i = 0; i < 5; i++) {
        await tester.pump(const Duration(milliseconds: 100));
      }
      final saved = await WordbookRepository().getAll();
      expect(saved.single.word, WordOfDayData.forDate(DateTime.now()).word);
      expect(
        tester.widget<YourPondCard>(find.byType(YourPondCard)).savedWords,
        1,
      );
      // Saving must not bubble up to the card's flip gesture.
      expect(find.text('Đã lưu vào Sổ từ'), findsOneWidget);
      expect(find.text('Lật lại'), findsNothing);
      await tester.tap(
        find.text(WordOfDayData.forDate(DateTime.now()).meaningVi),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      expect(find.text('TỪ CỦA NGÀY'), findsOneWidget);
      expect(find.text('Đã lưu vào Sổ từ'), findsNothing);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }
  testWidgets('sidebar progress remains reachable on a short admin viewport', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({'user_role': 'ADMIN'});
    await tester.binding.setSurfaceSize(const Size(1200, 420));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaterialApp(home: AppLayout()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byType(VuMonProgress), findsOneWidget);
    await tester.ensureVisible(find.byType(VuMonProgress));
    await tester.pump();
    expect(find.text('Thác Vũ Môn'), findsOneWidget);
    expect(find.text('Logout'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
