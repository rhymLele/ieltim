import 'package:flutter/widgets.dart';

import '../../../../../core/widgets/annotate/models.dart';

/// Highlight của người học cho các khối chữ bên dưới (BlockView đọc để tô màu) và sổ key của từng khối
/// (để biết chữ vừa bôi đen nằm ở khối nào). Không có scope (admin xem trước, màn soạn) thì khối hiển thị như cũ.
class AnnotationScope extends InheritedWidget {
  const AnnotationScope({super.key, required this.highlights, required this.registry, required this.onTapHighlight, required super.child});

  final List<TextHighlight> highlights;
  final BlockKeyRegistry registry;

  /// Chạm vào đoạn đã highlight (đổi màu / bỏ).
  final ValueChanged<String> onTapHighlight;

  static AnnotationScope? maybeOf(BuildContext context) => context.dependOnInheritedWidgetOfExactType<AnnotationScope>();

  List<TextHighlight> highlightsOf(String blockKey) => [for (final h in highlights) if (h.blockKey == blockKey) h];

  @override
  bool updateShouldNotify(AnnotationScope old) => !identical(old.highlights, highlights) || old.onTapHighlight != onTapHighlight;
}

/// GlobalKey cho từng khối chữ đang hiển thị (blockKey → key).
class BlockKeyRegistry {
  final _keys = <String, GlobalKey>{};

  GlobalKey keyFor(String blockKey) => _keys[blockKey] ??= GlobalKey(debugLabel: 'block $blockKey');

  /// Khối đang dựng trên màn (có context): blockKey → RenderBox.
  Map<String, RenderBox> get mounted => {
        for (final MapEntry(key: blockKey, value: key) in _keys.entries)
          if (key.currentContext?.findRenderObject() case final RenderBox box when box.attached) blockKey: box,
      };
}
