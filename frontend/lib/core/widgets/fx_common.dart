// fx_common.dart — IELTS Hub
// Hình cá chép, nét đứt chạy, keyframe… dùng chung cho DragonLoader và VuMonProgress.

import 'dart:math' as math;

import 'package:flutter/material.dart';

class FxColors {
  static const primary = Color(0xFF800020);
  static const background = Color(0xFFFFF9F2);
  static const sidebar = Color(0xFFF3E5D5);
  static const gold = Color(0xFFE7A23B);
  static const goldLight = Color(0xFFF2C06B);
  static const water = Color(0xFFE4EDF0);
  static const falls = Color(0xFFD6E4E9);
  static const streak = Color(0xFFA9C2CC);
  static const rock = Color(0xFFEBD9C6);
  static const rockLine = Color(0xFFD9C2AA);
  static const white = Color(0xFFFFFFFF);
}

/// Hình cá chép nhìn từ trên xuống, đầu hướng +x, gốc toạ độ ở giữa thân.
class KoiShapes {
  static final Path tail = Path()
    ..moveTo(-26, 0)
    ..cubicTo(-34, -4, -42, -12, -48, -13)
    ..cubicTo(-45, -5, -45, 5, -48, 13)
    ..cubicTo(-42, 12, -34, 4, -26, 0)
    ..close();
  static final Path body = Path()
    ..moveTo(36, 0)
    ..cubicTo(34, -8, 22, -11, 8, -10)
    ..cubicTo(-8, -9, -20, -5, -28, 0)
    ..cubicTo(-20, 5, -8, 9, 8, 10)
    ..cubicTo(22, 11, 34, 8, 36, 0)
    ..close();
  static final Path finA = Path()
    ..moveTo(12, 8)
    ..cubicTo(8, 16, 2, 20, -4, 20)
    ..cubicTo(0, 15, 4, 11, 8, 7)
    ..close();
  static final Path finB = Path()
    ..moveTo(12, -8)
    ..cubicTo(8, -16, 2, -20, -4, -20)
    ..cubicTo(0, -15, 4, -11, 8, -7)
    ..close();
}

/// Một đốm trên thân cá (hình elip, toạ độ theo hệ của [KoiShapes]).
class KoiSpot {
  const KoiSpot(this.center, this.width, this.height, this.color);
  final Offset center;
  final double width;
  final double height;
  final Color color;
}

/// Vẽ cá chép vàng đốm đỏ (dáng mặc định của IELTS Hub).
void paintKoi(
  Canvas canvas, {
  Color base = FxColors.gold,
  Color fin = FxColors.goldLight,
  Color spot = FxColors.primary,
  List<KoiSpot>? spots,
  double tailAngle = 0,
  bool fins = true,
}) {
  canvas.save();
  canvas.translate(-26, 0);
  canvas.rotate(tailAngle);
  canvas.translate(26, 0);
  canvas.drawPath(KoiShapes.tail, Paint()..color = base);
  canvas.restore();
  if (fins) {
    final p = Paint()..color = fin;
    canvas.drawPath(KoiShapes.finA, p);
    canvas.drawPath(KoiShapes.finB, p);
  }
  canvas.drawPath(KoiShapes.body, Paint()..color = base);
  final list = spots ??
      [
        KoiSpot(const Offset(18, -1), 18, 10, spot),
        KoiSpot(const Offset(-4, 2), 16, 8, spot.withAlpha(217)),
      ];
  canvas.save();
  canvas.clipPath(KoiShapes.body);
  for (final s in list) {
    canvas.drawOval(Rect.fromCenter(center: s.center, width: s.width, height: s.height), Paint()..color = s.color);
  }
  canvas.restore();
}

/// Vẽ nét đứt dọc theo [path]; tăng [phase] thì các đoạn chạy xuôi theo hướng path.
void drawFlowingDashes(
  Canvas canvas,
  Path path,
  Paint paint, {
  required double dash,
  required double gap,
  double phase = 0,
}) {
  final period = dash + gap;
  for (final m in path.computeMetrics()) {
    var d = (phase % period) - period;
    while (d < m.length) {
      final s = math.max(0.0, d);
      final e = math.min(m.length, d + dash);
      if (e > s) canvas.drawPath(m.extractPath(s, e), paint);
      d += period;
    }
  }
}

/// Nội suy theo keyframe: [k] là danh sách (thời điểm 0..1, giá trị).
double kf(double t, List<(double, double)> k, [Curve curve = Curves.easeInOut]) {
  if (t <= k.first.$1) return k.first.$2;
  for (var i = 1; i < k.length; i++) {
    final b = k[i];
    if (t <= b.$1) {
      final a = k[i - 1];
      final span = b.$1 - a.$1;
      final u = span <= 0 ? 1.0 : ((t - a.$1) / span).clamp(0.0, 1.0);
      return a.$2 + (b.$2 - a.$2) * curve.transform(u);
    }
  }
  return k.last.$2;
}

/// Ngôi sao 4 cánh (lấp lánh).
Path sparkPath(double r) {
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

/// Vẽ chữ căn giữa tại [center].
void paintCenteredText(Canvas canvas, String text, Offset center, TextStyle style) {
  final tp = TextPainter(
    text: TextSpan(text: text, style: style),
    textDirection: TextDirection.ltr,
    textAlign: TextAlign.center,
  )..layout();
  tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
}

/// Cổng Vũ Môn. Toạ độ gốc theo khung 390 px của màn loading; dùng [scale] để thu nhỏ.
void paintVuMonGate(
  Canvas canvas, {
  required Offset center, // tâm bảng tên
  required Color primary,
  required Color plaqueFill,
  double scale = 1,
}) {
  canvas.save();
  canvas.translate(center.dx, center.dy);
  canvas.scale(scale);
  canvas.translate(-195, -223);
  final p = Paint()..color = primary;
  canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(130, 206, 10, 72), const Radius.circular(2)), p);
  canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(250, 206, 10, 72), const Radius.circular(2)), p);
  final roof = Path()
    ..moveTo(102, 202)
    ..cubicTo(150, 212, 240, 212, 288, 202)
    ..lineTo(284, 214)
    ..cubicTo(240, 222, 150, 222, 106, 214)
    ..close();
  canvas.drawPath(roof, p);
  canvas.drawRRect(RRect.fromRectAndRadius(const Rect.fromLTWH(122, 228, 146, 6), const Radius.circular(2)), p);
  final plaque = RRect.fromRectAndRadius(const Rect.fromLTWH(172, 214, 46, 18), const Radius.circular(2));
  canvas.drawRRect(plaque, Paint()..color = plaqueFill);
  canvas.drawRRect(
    plaque,
    Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = primary,
  );
  paintCenteredText(
    canvas,
    'VŨ MÔN',
    const Offset(195, 223.5),
    TextStyle(color: primary, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1),
  );
  canvas.restore();
}
