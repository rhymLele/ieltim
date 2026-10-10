import 'package:flutter/widgets.dart';

/// Theo dõi popup (dialog, bottom sheet, menu) đang mở trên mọi Navigator của app.
///
/// Dùng cho nội dung web nhúng (iframe tài liệu HTML): trên web, Flutter vẽ popup đè lên iframe nhưng chuột
/// vẫn rơi vào iframe, nên khi có popup mở thì iframe phải nhường chuột cho Flutter.
/// Mỗi Navigator cần một observer riêng (GoRouter và ShellRoute); trạng thái dùng chung ở [hasOpenPopup].
class PopupRouteTracker extends NavigatorObserver {
  static final _routes = <Route<dynamic>>{};
  static final _changes = ValueNotifier<int>(0);

  /// Báo mỗi khi có popup mở / đóng.
  static Listenable get changes => _changes;

  /// Đang có popup mở (bỏ qua popup của Navigator đã bị huỷ).
  static bool get hasOpenPopup {
    _routes.removeWhere((r) => !r.isActive);
    return _routes.isNotEmpty;
  }

  static void _add(Route<dynamic>? route) {
    if (route is PopupRoute && _routes.add(route)) _changes.value++;
  }

  static void _remove(Route<dynamic>? route) {
    if (route != null && _routes.remove(route)) _changes.value++;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) => _add(route);

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) => _remove(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) => _remove(route);

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _remove(oldRoute);
    _add(newRoute);
  }
}
