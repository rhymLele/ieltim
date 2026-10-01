import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/widgets/app_layout.dart';

void main() {
  Future<List<int>> mount(
    WidgetTester tester, {
    required List<TabPage> tabs,
    required bool inDrawer,
    int activeIndex = 0,
  }) async {
    final taps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: SizedBox(
              width: 240,
              child: NavPanel(
                tabs: tabs,
                activeIndex: activeIndex,
                inDrawer: inDrawer,
                onTabSelected: taps.add,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return taps;
  }

  Finder inPanel(String text) =>
      find.descendant(of: find.byType(NavPanel), matching: find.text(text));

  for (final inDrawer in [false, true]) {
    testWidgets('admin tabs sit in their own section (drawer: $inDrawer)', (
      tester,
    ) async {
      final tabs = allTabs;
      final tagsIndex = tabs.indexWhere((t) => t.label == 'Tags');
      final taps = await mount(
        tester,
        tabs: tabs,
        inDrawer: inDrawer,
        activeIndex: tagsIndex,
      );
      expect(inPanel('Knowledge'), inDrawer ? findsNothing : findsOneWidget);
      expect(inPanel('Admin'), findsOneWidget);
      final adminLabel = tester.getRect(inPanel('Admin'));
      final lastUserTab = tabs.lastWhere((t) => !t.adminOnly).label;
      final firstAdminTab = tabs.firstWhere((t) => t.adminOnly).label;
      expect(
        tester.getRect(inPanel(lastUserTab)).bottom,
        lessThan(adminLabel.top),
      );
      expect(
        tester.getRect(inPanel(firstAdminTab)).top,
        greaterThan(adminLabel.bottom),
      );
      // The highlight sits on the active admin tab, below the label.
      final indicator = tester.getRect(find.byType(AnimatedPositioned));
      expect(indicator.contains(tester.getCenter(inPanel('Tags'))), isTrue);
      // Tapping reports the index in the tab list the layout renders from.
      await tester.tap(inPanel(firstAdminTab));
      await tester.tap(inPanel('Sổ từ'));
      expect(taps, [
        tabs.indexWhere((t) => t.label == firstAdminTab),
        tabs.indexWhere((t) => t.label == 'Sổ từ'),
      ]);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('users without admin rights see no admin section', (
    tester,
  ) async {
    await mount(
      tester,
      tabs: allTabs.where((t) => !t.adminOnly).toList(),
      inDrawer: false,
    );
    expect(inPanel('Knowledge'), findsOneWidget);
    expect(inPanel('Admin'), findsNothing);
    expect(inPanel('Tags'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
