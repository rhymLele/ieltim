// annotation_layer.dart — Lớp vẽ đặt đè lên slide (hoặc lên WebView/iframe của tài liệu HTML).
//
//   AnnotationLayer(controller: c, child: SlideContent(...))
//
// Công cụ "view": không bắt thao tác, slide vuốt / bấm như bình thường.
import 'package:flutter/material.dart';

import '../annotate_theme.dart';
import '../annotation_controller.dart';
import '../models.dart';

class AnnotationLayer extends StatefulWidget {
  const AnnotationLayer({super.key, required this.controller, required this.child, this.handFont});

  final AnnotationController controller;
  final Widget child;

  /// Font kiểu viết tay cho chữ thêm vào (vd 'Caveat' nếu đã khai báo). Null = font mặc định, nghiêng.
  final String? handFont;

  @override
  State<AnnotationLayer> createState() => _AnnotationLayerState();
}

class _AnnotationLayerState extends State<AnnotationLayer> {
  Offset? _textAt; // vị trí đang nhập chữ (0..1)
  final _textCtl = TextEditingController();
  final _textFocus = FocusNode();

  AnnotationController get c => widget.controller;

  @override
  void dispose() {
    _textCtl.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  Offset _norm(Offset local, Size size) =>
      Offset((local.dx / size.width).clamp(0.0, 1.0), (local.dy / size.height).clamp(0.0, 1.0));

  void _commitText() {
    final at = _textAt;
    if (at != null) c.addText(at, _textCtl.text);
    setState(() {
      _textAt = null;
      _textCtl.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: c,
      builder: (context, _) => LayoutBuilder(
        builder: (context, box) {
          final size = Size(box.maxWidth, box.maxHeight);
          final d = c.data;
          final tool = c.tool;
          final drawingTool = tool == AnnotationTool.pen || tool == AnnotationTool.marker;
          return Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(child: widget.child),
              // Nét vẽ + khoanh
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _MarksPainter(
                      strokes: d.strokes,
                      ellipses: d.ellipses,
                      drawing: c.drawing,
                      drawingColor: c.color,
                      drawingMarker: tool == AnnotationTool.marker,
                      ellipseDraft: c.ellipseDraft,
                    ),
                  ),
                ),
              ),
              // Chữ
              for (final t in d.texts)
                Positioned(
                  left: t.at.dx * size.width,
                  top: t.at.dy * size.height - 18,
                  child: IgnorePointer(
                    child: Text(
                      t.text,
                      style: TextStyle(
                        fontFamily: widget.handFont,
                        fontStyle: widget.handFont == null ? FontStyle.italic : FontStyle.normal,
                        fontSize: (size.width * 0.032).clamp(14.0, 28.0),
                        fontWeight: FontWeight.w700,
                        color: t.color,
                      ),
                    ),
                  ),
                ),
              // Lớp bắt thao tác (chỉ khi không ở chế độ xem)
              if (tool != AnnotationTool.view)
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (e) {
                      final p = _norm(e.localPosition, size);
                      if (tool == AnnotationTool.text) {
                        setState(() => _textAt = p);
                        WidgetsBinding.instance.addPostFrameCallback((_) => _textFocus.requestFocus());
                      } else if (tool == AnnotationTool.comment) {
                        c.addPin(p);
                      }
                    },
                    onPanStart: (e) {
                      final p = _norm(e.localPosition, size);
                      if (drawingTool) c.strokeStart(p);
                      if (tool == AnnotationTool.circle) c.ellipseStart(p);
                    },
                    onPanUpdate: (e) {
                      final p = _norm(e.localPosition, size);
                      if (drawingTool) c.strokeUpdate(p);
                      if (tool == AnnotationTool.circle) c.ellipseUpdate(p);
                    },
                    onPanEnd: (_) {
                      if (drawingTool) c.strokeEnd();
                      if (tool == AnnotationTool.circle) c.ellipseEnd();
                    },
                    child: MouseRegion(
                      cursor: tool == AnnotationTool.text
                          ? SystemMouseCursors.text
                          : tool == AnnotationTool.comment
                              ? SystemMouseCursors.copy
                              : SystemMouseCursors.precise,
                    ),
                  ),
                ),
              // Ghim (luôn bấm được để mở ghi chú)
              for (var i = 0; i < d.pins.length; i++)
                Positioned(
                  left: d.pins[i].at.dx * size.width - 15,
                  top: d.pins[i].at.dy * size.height - 30,
                  child: _PinButton(number: i + 1, active: c.activePin == i, onTap: () => c.activePin = i),
                ),
              // Ô nhập chữ
              if (_textAt != null)
                Positioned(
                  left: (_textAt!.dx * size.width).clamp(0.0, (size.width - 260).clamp(0.0, double.infinity)),
                  top: (_textAt!.dy * size.height - 20).clamp(0.0, (size.height - 44).clamp(0.0, double.infinity)),
                  child: Material(
                    color: Colors.transparent,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 190,
                          height: 40,
                          child: TextField(
                            controller: _textCtl,
                            focusNode: _textFocus,
                            onSubmitted: (_) => _commitText(),
                            onTapOutside: (_) => _commitText(),
                            decoration: InputDecoration(
                              hintText: 'Gõ chữ…',
                              isDense: true,
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.color, width: 2)),
                              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.color, width: 2)),
                              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: c.color, width: 2)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 6),
                        SizedBox(
                          height: 40,
                          child: FilledButton(
                            style: FilledButton.styleFrom(backgroundColor: AnnColors.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                            onPressed: _commitText,
                            child: const Text('Thêm'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}

class _PinButton extends StatelessWidget {
  const _PinButton({required this.number, required this.active, required this.onTap});
  final int number;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        label: 'Ghi chú $number',
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            width: 30,
            height: 30,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AnnColors.primary : AnnColors.pinInactive,
              border: Border.all(color: Colors.white, width: 2),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(15),
                topRight: Radius.circular(15),
                bottomRight: Radius.circular(15),
                bottomLeft: Radius.circular(4),
              ),
              boxShadow: const [BoxShadow(color: Color(0x402A1418), blurRadius: 10, offset: Offset(0, 4))],
            ),
            child: Text('$number', style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w800)),
          ),
        ),
      );
}

class _MarksPainter extends CustomPainter {
  _MarksPainter({
    required this.strokes,
    required this.ellipses,
    required this.drawing,
    required this.drawingColor,
    required this.drawingMarker,
    required this.ellipseDraft,
  });

  final List<StrokeMark> strokes;
  final List<EllipseMark> ellipses;
  final List<Offset>? drawing;
  final Color drawingColor;
  final bool drawingMarker;
  final Rect? ellipseDraft;

  void _stroke(Canvas canvas, Size size, List<Offset> pts, Color color, bool marker) {
    if (pts.length < 2) return;
    final path = Path()..moveTo(pts.first.dx * size.width, pts.first.dy * size.height);
    for (var i = 1; i < pts.length; i++) {
      path.lineTo(pts[i].dx * size.width, pts[i].dy * size.height);
    }
    final w = marker ? size.width * 0.022 : (size.width * 0.0045).clamp(2.5, 5.0);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = w
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = marker ? color.withOpacity(0.35) : color,
    );
  }

  void _ellipse(Canvas canvas, Size size, Rect r, Color color) {
    canvas.drawOval(
      Rect.fromLTRB(r.left * size.width, r.top * size.height, r.right * size.width, r.bottom * size.height),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (size.width * 0.004).clamp(2.5, 4.0)
        ..color = color,
    );
  }

  @override
  void paint(Canvas canvas, Size size) {
    for (final s in strokes) {
      _stroke(canvas, size, s.points, s.color, s.marker);
    }
    for (final e in ellipses) {
      _ellipse(canvas, size, e.rect, e.color);
    }
    final d = drawing;
    if (d != null) _stroke(canvas, size, d, drawingColor, drawingMarker);
    final ed = ellipseDraft;
    if (ed != null) _ellipse(canvas, size, ed, drawingColor);
  }

  @override
  bool shouldRepaint(covariant _MarksPainter old) => true;
}
