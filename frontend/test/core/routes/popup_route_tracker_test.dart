import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/routes/popup_route_tracker.dart';

void main() {
  testWidgets('đếm dialog / bottom sheet đang mở, kể cả Navigator lồng; Navigator bị huỷ thì không còn tính', (tester) async {
    final nested = GlobalKey<NavigatorState>();
    var changes = 0;
    void onChange() => changes++;
    PopupRouteTracker.changes.addListener(onChange);
    addTearDown(() => PopupRouteTracker.changes.removeListener(onChange));

    await tester.pumpWidget(MaterialApp(
      navigatorObservers: [PopupRouteTracker()],
      home: Scaffold(
        body: Navigator(
          key: nested,
          observers: [PopupRouteTracker()],
          onGenerateRoute: (_) => MaterialPageRoute<void>(builder: (_) => const SizedBox.expand()),
        ),
      ),
    ));
    expect(PopupRouteTracker.hasOpenPopup, isFalse);

    // Bottom sheet trên Navigator lồng (như form Sổ từ ở màn đọc).
    showModalBottomSheet<void>(context: nested.currentContext!, builder: (_) => const SizedBox(height: 100));
    await tester.pumpAndSettle();
    expect(PopupRouteTracker.hasOpenPopup, isTrue);
    nested.currentState!.pop();
    await tester.pumpAndSettle();
    expect(PopupRouteTracker.hasOpenPopup, isFalse);

    // Dialog trên Navigator gốc (như "Ghi chú của tôi" trên desktop).
    showDialog<void>(context: nested.currentContext!, builder: (_) => const AlertDialog(content: Text('x')));
    await tester.pumpAndSettle();
    expect(PopupRouteTracker.hasOpenPopup, isTrue);
    expect(changes, 3);

    // Rời app khi dialog còn mở: Navigator huỷ, không được kẹt ở trạng thái "đang có popup".
    await tester.pumpWidget(const SizedBox());
    expect(PopupRouteTracker.hasOpenPopup, isFalse);
  });
}
