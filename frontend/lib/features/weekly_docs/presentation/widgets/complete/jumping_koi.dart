import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/app_tokens.dart';

/// Cá chép vàng nhảy trong vòng nước (lặp lại; tắt khi người dùng bật giảm chuyển động).
class JumpingKoi extends StatefulWidget {
  const JumpingKoi({super.key, this.size = 160});

  final double size;

  @override
  State<JumpingKoi> createState() => _JumpingKoiState();
}

class _JumpingKoiState extends State<JumpingKoi> with SingleTickerProviderStateMixin {
  late final AnimationController _jump = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotionOf(context)) {
      _jump.stop();
    } else if (!_jump.isAnimating) {
      _jump.repeat();
    }
  }

  @override
  void dispose() {
    _jump.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ExcludeSemantics(
      child: SizedBox(
        width: widget.size,
        height: widget.size,
        child: AnimatedBuilder(animation: _jump, builder: (_, _) => CustomPaint(painter: _JumpingKoiPainter(t: _jump.value))),
      ),
    );
  }
}

/// Vòng nước + cá chép vàng nhảy + ngôi sao lấp lánh.
class _JumpingKoiPainter extends CustomPainter {
  _JumpingKoiPainter({required this.t});
  final double t;

  @override
  void paint(Canvas canvas, Size size) {
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, size.width / 2, Paint()..color = AppColors.water);
    final wave = Path()
      ..moveTo(size.width * 0.12, size.height * 0.7)
      ..cubicTo(size.width * 0.28, size.height * 0.62, size.width * 0.38, size.height * 0.75, size.width * 0.5, size.height * 0.69)
      ..cubicTo(size.width * 0.62, size.height * 0.62, size.width * 0.72, size.height * 0.75, size.width * 0.88, size.height * 0.67);
    canvas.drawPath(
      wave,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round
        ..color = AppColors.cardSurface,
    );
    // Sao lấp lánh lệch nhịp.
    for (final (x, y, r, color, ph) in [
      (0.19, 0.32, 8.0, AppColors.gold, 0.0),
      (0.8, 0.24, 6.0, AppColors.gold, 0.35),
      (0.82, 0.58, 5.0, AppColors.primary, 0.7),
    ]) {
      final k = 0.4 + 0.6 * (0.5 + 0.5 * math.sin((t + ph) * 2 * math.pi));
      canvas.save();
      canvas.translate(size.width * x, size.height * y);
      canvas.scale(k);
      canvas.drawPath(_spark(r), Paint()..color = color.withAlpha((255 * k).round()));
      canvas.restore();
    }
    // Cá nhảy: lên ở 45%, xoay nhẹ.
    final up = math.sin(t * math.pi);
    final dy = 10 - 36 * up;
    final rot = -math.pi / 2 + 0.35 * math.sin(t * 2 * math.pi);
    canvas.save();
    canvas.translate(c.dx, c.dy + dy);
    canvas.rotate(rot);
    canvas.scale(0.8);
    final tail = Path()
      ..moveTo(-26, 0)
      ..cubicTo(-34, -4, -42, -12, -48, -13)
      ..cubicTo(-45, -5, -45, 5, -48, 13)
      ..cubicTo(-42, 12, -34, 4, -26, 0)
      ..close();
    final body = Path()
      ..moveTo(36, 0)
      ..cubicTo(34, -8, 22, -11, 8, -10)
      ..cubicTo(-8, -9, -20, -5, -28, 0)
      ..cubicTo(-20, 5, -8, 9, 8, 10)
      ..cubicTo(22, 11, 34, 8, 36, 0)
      ..close();
    canvas.save();
    canvas.translate(-26, 0);
    canvas.rotate(0.35 * math.sin(t * 10 * math.pi));
    canvas.translate(26, 0);
    canvas.drawPath(tail, Paint()..color = AppColors.gold);
    canvas.restore();
    canvas.drawPath(body, Paint()..color = AppColors.gold);
    canvas.save();
    canvas.clipPath(body);
    canvas.drawOval(Rect.fromCenter(center: const Offset(18, -1), width: 18, height: 10), Paint()..color = AppColors.primary);
    canvas.restore();
    canvas.restore();
  }

  Path _spark(double r) {
    final p = Path();
    for (var i = 0; i < 8; i++) {
      final a = -math.pi / 2 + i * math.pi / 4;
      final rr = i.isEven ? r : r * 0.3;
      final o = Offset(math.cos(a) * rr, math.sin(a) * rr);
      if (i == 0) {
        p.moveTo(o.dx, o.dy);
      } else {
        p.lineTo(o.dx, o.dy);
      }
    }
    return p..close();
  }

  @override
  bool shouldRepaint(covariant _JumpingKoiPainter old) => old.t != t;
}
