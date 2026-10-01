import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/word_of_day_card.dart';

void main() {
  for (final reduceMotion in [false, true]) {
    testWidgets(
      'card toggles both ways; saving does not flip (reduce motion: $reduceMotion)',
      (tester) async {
        final changes = <bool>[];
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: reduceMotion),
              child: Scaffold(
                body: Center(
                  child: SizedBox(
                    width: 288,
                    height: 400,
                    child: WordOfDayCard(
                      word: WordOfDayData.samples.first,
                      onSaveChanged: changes.add,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        expect(find.text('TỪ CỦA NGÀY'), findsOneWidget);
        expect(find.text('Lưu vào Sổ từ'), findsNothing);
        // The speak button next to the word must not flip the card.
        await tester.tap(find.byTooltip('Nghe phát âm'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expect(find.text('TỪ CỦA NGÀY'), findsOneWidget);
        expect(find.text('Lưu vào Sổ từ'), findsNothing);
        await tester.tap(find.text('TỪ CỦA NGÀY'));
        await tester.pumpAndSettle();
        expect(find.text('Lưu vào Sổ từ'), findsOneWidget);
        expect(find.text('Lật lại'), findsNothing);
        await tester.tap(find.text('Lưu vào Sổ từ'));
        await tester.pumpAndSettle();
        expect(changes, [true]);
        expect(find.text('Đã lưu vào Sổ từ'), findsOneWidget);
        expect(find.text('TỪ CỦA NGÀY'), findsNothing);
        // The back has its own speak button in the header; it must not flip.
        await tester.tap(find.byTooltip('Nghe phát âm'));
        await tester.pumpAndSettle();
        expect(find.text('Đã lưu vào Sổ từ'), findsOneWidget);
        expect(find.text('TỪ CỦA NGÀY'), findsNothing);
        await tester.tap(find.text(WordOfDayData.samples.first.meaningVi));
        // The koi swims forever on the front, so the tree never settles.
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 700));
        expect(find.text('TỪ CỦA NGÀY'), findsOneWidget);
        expect(find.text('Đã lưu vào Sổ từ'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
