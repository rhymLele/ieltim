import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/vu_mon_progress.dart';

void main() {
  // The painter is private; read its animations dynamically.
  dynamic painter(WidgetTester tester) => tester
      .widget<CustomPaint>(
        find
            .descendant(
              of: find.byType(VuMonProgress),
              matching: find.byType(CustomPaint),
            )
            .first,
      )
      .painter;

  for (final reduceMotion in [false, true]) {
    testWidgets('playOnce climbs through the gate once '
        '(reduce motion: $reduceMotion)', (tester) async {
      var passed = 0;
      Widget app() => MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(disableAnimations: reduceMotion),
          child: Scaffold(
            body: SizedBox(
              width: 208,
              child: VuMonProgress(
                playOnce: true,
                onPassedGate: () => passed++,
              ),
            ),
          ),
        ),
      );
      await tester.pumpWidget(app());
      expect(find.text('Thác Vũ Môn'), findsOneWidget);
      expect(find.textContaining('Tuần này'), findsNothing);
      if (!reduceMotion) {
        await tester.pump(const Duration(seconds: 2));
        expect(passed, 0);
      }
      await tester.pump(const Duration(seconds: 4));
      await tester.pump();
      expect(passed, 1);
      // Rebuilding with the same config must not replay the climb.
      await tester.pumpWidget(app());
      await tester.pump(const Duration(seconds: 6));
      expect(passed, 1);
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('repeat passes the gate every cycle and cleans up', (
    tester,
  ) async {
    var passed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 208,
            child: VuMonProgress(
              repeat: true,
              duration: const Duration(seconds: 2),
              onPassedGate: () => passed++,
            ),
          ),
        ),
      ),
    );
    expect(find.text('Thác Vũ Môn'), findsOneWidget);
    expect(find.textContaining('Tuần này'), findsNothing);
    // One cycle = 2s climb + 1.6s flash + 1.2s hold + 0.4s fade = 5.2s.
    for (var i = 0; i < 18; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(passed, 0);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(passed, 1);
    for (var i = 0; i < 52; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(passed, 2);
    expect(tester.takeException(), isNull);
    // Disposing mid-cycle must not leave timers or tickers running.
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('repeat stays still on the gate when motion is reduced', (
    tester,
  ) async {
    var passed = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: SizedBox(
              width: 208,
              child: VuMonProgress(repeat: true, onPassedGate: () => passed++),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 20));
    expect(passed, 0);
    expect(tester.binding.hasScheduledFrame, isFalse);
    // Parked just after the gate: fish on top, fully visible, no flash.
    expect(painter(tester).level.value, 1);
    expect(painter(tester).fish.value, 1);
    expect(painter(tester).celebrate.value, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('switching playOnce to repeat starts the loop (hot reload)', (
    tester,
  ) async {
    var passed = 0;
    Widget app({required bool repeat}) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 208,
          child: VuMonProgress(
            playOnce: !repeat,
            repeat: repeat,
            duration: const Duration(seconds: 1),
            onPassedGate: () => passed++,
          ),
        ),
      ),
    );
    await tester.pumpWidget(app(repeat: false));
    await tester.pump(const Duration(seconds: 2));
    expect(passed, 1);
    await tester.pumpWidget(app(repeat: true));
    for (var i = 0; i < 2 * 42 + 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(passed, 3);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('leaving playOnce drops the pending climb', (tester) async {
    var passed = 0;
    Widget app({bool playOnce = false, bool repeat = false}) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 208,
          child: VuMonProgress(
            playOnce: playOnce,
            repeat: repeat,
            onPassedGate: () => passed++,
          ),
        ),
      ),
    );
    // Real data arrives mid-climb with 0 lessons done: fish goes back down.
    await tester.pumpWidget(app(playOnce: true));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(app());
    await tester.pump(const Duration(seconds: 6));
    expect(passed, 0);
    expect(painter(tester).level.value, 0);
    expect(painter(tester).celebrate.value, 0);
    expect(find.text('Tuần này: 0/5 chặng'), findsOneWidget);
    // playOnce -> repeat mid-climb: only the loop's own pass is reported.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpWidget(app(playOnce: true));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(app(repeat: true));
    for (var i = 0; i < 38; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(passed, 0);
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    expect(passed, 1);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets('leaving repeat shows the real completed count', (tester) async {
    Widget app({required bool repeat}) => MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 208,
          child: VuMonProgress(repeat: repeat, completed: 3),
        ),
      ),
    );
    await tester.pumpWidget(app(repeat: true));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpWidget(app(repeat: false));
    await tester.pump(const Duration(seconds: 2));
    expect(painter(tester).level.value, closeTo(0.6, 1e-9));
    expect(painter(tester).fish.value, 1);
    expect(find.text('Tuần này: 3/5 chặng'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
