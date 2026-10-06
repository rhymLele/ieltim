// annotatable_selection_area.dart — Bọc nội dung chữ (Doc / Slide JSON) để bôi đen → hiện SelectionActionsCard.
//
// • Điện thoại: nhấn giữ để chọn, kéo tay cầm, thả tay → hộp thoại hiện cạnh vùng chọn (thay menu Copy mặc định).
// • Web / desktop: kéo chuột bôi đen, thả chuột → hộp thoại hiện ở vị trí con trỏ. Chuột phải cũng mở hộp thoại.
//
//   AnnotatableSelectionArea(
//     cardBuilder: (context, text, close) => SelectionActionsCard(text: text, ...),
//     child: DocContent(...),
//   )
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

typedef SelectionCardBuilder = Widget Function(BuildContext context, String selectedText, VoidCallback close);

class AnnotatableSelectionArea extends StatefulWidget {
  const AnnotatableSelectionArea({super.key, required this.child, required this.cardBuilder, this.onSelectionChanged});

  final Widget child;
  final SelectionCardBuilder cardBuilder;

  /// Báo chữ đang chọn (rỗng khi bỏ chọn) nếu bên ngoài cần.
  final ValueChanged<String>? onSelectionChanged;

  @override
  State<AnnotatableSelectionArea> createState() => AnnotatableSelectionAreaState();
}

class AnnotatableSelectionAreaState extends State<AnnotatableSelectionArea> {
  String _text = '';
  int _epoch = 0; // đổi key để xoá vùng chọn
  OverlayEntry? _entry;

  String get selectedText => _text;

  @override
  void dispose() {
    _removeEntry();
    super.dispose();
  }

  void _removeEntry() {
    _entry?.remove();
    _entry = null;
  }

  /// Đóng hộp thoại và bỏ vùng chọn.
  void close() {
    _removeEntry();
    if (!mounted) return;
    setState(() {
      _epoch++;
      _text = '';
    });
    widget.onSelectionChanged?.call('');
  }

  void _showAt(Offset globalPos) {
    _removeEntry();
    final t = _text.trim();
    if (t.isEmpty) return;
    final overlay = Overlay.of(context);
    _entry = OverlayEntry(
      builder: (ctx) => Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(behavior: HitTestBehavior.translucent, onTapDown: (_) => _removeEntry()),
          ),
          CustomSingleChildLayout(
            delegate: _CardLayout(anchorTop: globalPos.translate(0, -12), anchorBottom: globalPos.translate(0, 16)),
            child: widget.cardBuilder(ctx, t, close),
          ),
        ],
      ),
    );
    overlay.insert(_entry!);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerUp: (e) {
        if (e.kind != PointerDeviceKind.mouse) return; // cảm ứng dùng contextMenuBuilder
        final pos = e.position;
        // Chờ SelectionArea cập nhật vùng chọn xong
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted && _text.trim().isNotEmpty) _showAt(pos);
        });
      },
      child: KeyedSubtree(
        key: ValueKey(_epoch),
        child: SelectionArea(
          onSelectionChanged: (content) {
            _text = content?.plainText ?? '';
            widget.onSelectionChanged?.call(_text);
            if (_text.trim().isEmpty) _removeEntry();
          },
          contextMenuBuilder: (ctx, region) {
            final t = _text.trim();
            if (t.isEmpty) return const SizedBox.shrink();
            final a = region.contextMenuAnchors;
            return CustomSingleChildLayout(
              delegate: _CardLayout(anchorTop: a.primaryAnchor, anchorBottom: a.secondaryAnchor ?? a.primaryAnchor.translate(0, 28)),
              child: widget.cardBuilder(ctx, t, close),
            );
          },
          child: widget.child,
        ),
      ),
    );
  }
}

/// Đặt hộp thoại phía trên vùng chọn nếu đủ chỗ, không thì phía dưới; luôn nằm trong màn hình.
class _CardLayout extends SingleChildLayoutDelegate {
  _CardLayout({required this.anchorTop, required this.anchorBottom});

  final Offset anchorTop;
  final Offset anchorBottom;
  static const _pad = 12.0;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints.loose(Size(constraints.maxWidth - _pad * 2, constraints.maxHeight - _pad * 2));

  @override
  Offset getPositionForChild(Size size, Size child) {
    final x = (anchorTop.dx - child.width / 2).clamp(_pad, size.width - child.width - _pad);
    final above = anchorTop.dy - child.height - 8;
    final y = above >= _pad + 24 ? above : (anchorBottom.dy + 8).clamp(_pad, size.height - child.height - _pad);
    return Offset(x.toDouble(), y.toDouble());
  }

  @override
  bool shouldRelayout(covariant _CardLayout old) => old.anchorTop != anchorTop || old.anchorBottom != anchorBottom;
}
