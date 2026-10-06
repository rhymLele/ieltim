import 'package:flutter/foundation.dart';

import '../../../../core/widgets/annotate/annotate.dart';

/// Mỗi slide một [AnnotationController] (vuốt giữa hai slide thì mỗi bên giữ nét của mình);
/// công cụ và màu dùng chung: đổi slide vẫn cầm đúng bút đang dùng.
class SlideAnnotationControllers extends ChangeNotifier {
  SlideAnnotationControllers({required this.onChanged});

  /// Nội dung ghi chú một slide vừa đổi → lưu.
  final void Function(String slideKey, SlideAnnotations data) onChanged;

  final _controllers = <String, AnnotationController>{};
  final _epochs = <String, int>{};
  String? _activeKey;
  AnnotationTool _tool = AnnotationTool.view;
  int _colorIndex = 0;
  bool _syncing = false;

  String? get activeKey => _activeKey;
  AnnotationController? get active => _activeKey == null ? null : _controllers[_activeKey];
  AnnotationTool get tool => _tool;

  /// Đang cầm bút / khoanh / chữ / ghi chú: khoá vuốt slide và phím ← →.
  bool get isDrawing => _tool != AnnotationTool.view;

  AnnotationController controllerFor(String slideKey, {SlideAnnotations? initial}) {
    final existing = _controllers[slideKey];
    if (existing != null) return existing;
    final controller = AnnotationController(initial: initial, onChanged: (d) => onChanged(slideKey, d))
      ..tool = _tool
      ..colorIndex = _colorIndex;
    controller.addListener(() => _syncFrom(controller));
    return _controllers[slideKey] = controller;
  }

  /// Slide đang xem (thanh công cụ, danh sách ghi chú trỏ vào slide này).
  void activate(String slideKey, {SlideAnnotations? initial}) {
    controllerFor(slideKey, initial: initial);
    if (_activeKey == slideKey) return;
    _activeKey = slideKey;
    notifyListeners();
  }

  /// Về chế độ Xem (vd chuyển sang kiểu Doc).
  void stopDrawing() => active?.tool = AnnotationTool.view;

  /// Ghi chú bị thay từ ngoài (tải từ máy chủ, gộp với máy khác): nạp lại slide đó, trừ khi đang vẽ dở.
  void sync(Map<String, SlideAnnotations> slides, Map<String, int> epochs) {
    for (final MapEntry(key: key, value: epoch) in epochs.entries) {
      if (_epochs[key] == epoch) continue;
      _epochs[key] = epoch;
      final controller = _controllers[key];
      if (controller != null && controller.drawing == null && controller.ellipseDraft == null) {
        controller.load(slides[key] ?? const SlideAnnotations());
      }
    }
  }

  void _syncFrom(AnnotationController source) {
    if (_syncing || (source.tool == _tool && source.colorIndex == _colorIndex)) return;
    _syncing = true;
    _tool = source.tool;
    _colorIndex = source.colorIndex;
    for (final c in _controllers.values) {
      if (identical(c, source)) continue;
      c
        ..tool = _tool
        ..colorIndex = _colorIndex;
    }
    _syncing = false;
    notifyListeners();
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }
}
