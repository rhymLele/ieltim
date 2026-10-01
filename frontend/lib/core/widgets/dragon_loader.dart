// dragon_loader.dart — IELTS Hub
//
// Loading "cá chép vượt vũ môn hóa rồng".
//
// 1) Vòng lặp vô tận (không biết khi nào tải xong):
//      const DragonLoader()
//
// 1b) Chạy đúng 1 lần (7 giây), thanh tiến trình chạy theo câu chuyện, xong gọi onFinished:
//      DragonLoader(playOnce: true, onFinished: () => context.go('/home'))
//
// 2) Theo tiến độ thật (khuyên dùng): cá bơi lên theo progress, chờ ở chân thác;
//    khi progress = 1 cá nhảy qua vũ môn, hóa rồng rồi gọi onFinished.
//      DragonLoader(progress: p, onFinished: () => context.go('/home'))

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'fx_common.dart';

class DragonLoader extends StatefulWidget {
  const DragonLoader({
    super.key,
    this.progress,
    this.playOnce = false,
    this.duration = const Duration(seconds: 7),
    this.onFinished,
    this.primary = FxColors.primary,
    this.background = FxColors.background,
    this.showLabel = true,
    this.labels = const ['Bơi ngược dòng…', 'Vượt vũ môn…', 'Hóa rồng!'],
  });

  /// null = lặp vô tận. 0..1 = tiến độ tải thật.
  final double? progress;

  /// true = chạy câu chuyện đúng 1 lần rồi gọi [onFinished] (bỏ qua [progress]).
  final bool playOnce;

  /// Độ dài một lần chạy (mặc định 7 giây).
  final Duration duration;
  final VoidCallback? onFinished;
  final Color primary;
  final Color background;
  final bool showLabel;
  final List<String> labels;

  @override
  State<DragonLoader> createState() => _DragonLoaderState();
}

class _DragonLoaderState extends State<DragonLoader>
    with TickerProviderStateMixin {
  Duration get _cycle => widget.duration;

  /// Tiến trình câu chuyện 0..1: 0–0.43 bơi, 0.43–0.6 nhảy, 0.6–1 hóa rồng.
  late final AnimationController _story;

  /// Đồng hồ cho nước chảy, đuôi quẫy (chạy liên tục).
  late final Ticker _clockTicker;
  final ValueNotifier<double> _clock = ValueNotifier<double>(0);
  bool _finishedCalled = false;

  @override
  void initState() {
    super.initState();
    _story = AnimationController(vsync: this, duration: _cycle);
    _clockTicker = createTicker((e) => _clock.value = e.inMicroseconds / 1e6);
    _start();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (reduce && _clockTicker.isActive) {
      _clockTicker.stop();
    } else if (!reduce && !_clockTicker.isActive) {
      _clockTicker.start();
    }
  }

  @override
  void didUpdateWidget(covariant DragonLoader old) {
    super.didUpdateWidget(old);
    if (!widget.playOnce && old.progress != widget.progress) _start();
  }

  void _start() {
    if (widget.playOnce) {
      _story.duration = _cycle;
      _story.forward(from: 0).then((_) {
        if (mounted && !_finishedCalled) {
          _finishedCalled = true;
          widget.onFinished?.call();
        }
      });
      return;
    }
    final p = widget.progress;
    if (p == null) {
      if (!_story.isAnimating) _story.repeat();
      return;
    }
    if (p < 1) {
      _finishedCalled = false;
      _story.animateTo(
        p.clamp(0.0, 1.0) * 0.43,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOut,
      );
    } else {
      final remaining = ((1 - _story.value) * _cycle.inMilliseconds)
          .round()
          .clamp(400, _cycle.inMilliseconds);
      _story.animateTo(1, duration: Duration(milliseconds: remaining)).then((
        _,
      ) {
        if (mounted && !_finishedCalled) {
          _finishedCalled = true;
          widget.onFinished?.call();
        }
      });
    }
  }

  @override
  void dispose() {
    _story.dispose();
    _clockTicker.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scene = RepaintBoundary(
      child: CustomPaint(
        size: Size.infinite,
        painter: _DragonPainter(
          story: _story,
          clock: _clock,
          primary: widget.primary,
          background: widget.background,
        ),
      ),
    );
    return ColoredBox(
      color: widget.background,
      child: Column(
        children: [
          Expanded(child: scene),
          if (widget.showLabel)
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 48),
              child: AnimatedBuilder(
                animation: _story,
                builder: (context, _) {
                  final t = _story.value;
                  final stage = t < 0.40 ? 0 : (t < 0.61 ? 1 : 2);
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: Text(
                          widget.labels[stage],
                          key: ValueKey(stage),
                          style: TextStyle(
                            color: widget.primary,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: 200,
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            value: widget.playOnce
                                ? t
                                : (widget.progress?.clamp(0.0, 1.0) ?? t),
                            minHeight: 6,
                            color: widget.primary,
                            backgroundColor: const Color(0xFFEFDCCB),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _DragonPainter extends CustomPainter {
  _DragonPainter({
    required this.story,
    required this.clock,
    required this.primary,
    required this.background,
  }) : super(repaint: Listenable.merge([story, clock]));

  final Animation<double> story;
  final ValueListenable<double> clock;
  final Color primary;
  final Color background;

  // Khung thiết kế: rộng 390, lấy đoạn y 80..720.
  static const double _w = 390, _top = 80, _h = 640;

  static final Path _river = Path()
    ..moveTo(112, 478)
    ..cubicTo(92, 560, 62, 650, 72, 844)
    ..lineTo(318, 844)
    ..cubicTo(328, 650, 298, 560, 278, 478)
    ..close();

  static final List<(Path, Color, double, double)> _riverStreaks = [
    (
      Path()
        ..moveTo(150, 480)
        ..cubicTo(140, 580, 120, 700, 124, 844),
      FxColors.white,
      3,
      0,
    ),
    (
      Path()
        ..moveTo(195, 480)
        ..cubicTo(195, 600, 190, 720, 195, 844),
      FxColors.white,
      3,
      15,
    ),
    (
      Path()
        ..moveTo(240, 480)
        ..cubicTo(250, 580, 270, 700, 266, 844),
      FxColors.white,
      3,
      28,
    ),
    (
      Path()
        ..moveTo(172, 520)
        ..cubicTo(165, 620, 150, 740, 152, 844),
      FxColors.streak,
      2,
      9,
    ),
    (
      Path()
        ..moveTo(218, 520)
        ..cubicTo(225, 620, 240, 740, 238, 844),
      FxColors.streak,
      2,
      35,
    ),
  ];

  static final Path _rockL = Path()
    ..moveTo(0, 270)
    ..lineTo(124, 270)
    ..cubicTo(118, 330, 121, 420, 112, 482)
    ..cubicTo(80, 520, 40, 560, 0, 580)
    ..close();
  static final Path _rockR = Path()
    ..moveTo(390, 270)
    ..lineTo(266, 270)
    ..cubicTo(272, 330, 269, 420, 278, 482)
    ..cubicTo(310, 520, 350, 560, 390, 580)
    ..close();
  static final Path _rockLines = Path()
    ..moveTo(20, 330)
    ..cubicTo(40, 320, 70, 326, 84, 340)
    ..moveTo(300, 360)
    ..cubicTo(320, 350, 350, 356, 366, 372)
    ..moveTo(30, 450)
    ..cubicTo(50, 440, 70, 446, 80, 458);

  static const _fallLines = <(double, Color, double, double)>[
    (132, FxColors.white, 3, 0),
    (146, FxColors.streak, 2, 9),
    (160, FxColors.white, 3, 16),
    (176, FxColors.white, 3, 4),
    (190, FxColors.streak, 2, 19),
    (204, FxColors.white, 3, 11),
    (218, FxColors.white, 3, 2),
    (232, FxColors.streak, 2, 13),
    (246, FxColors.white, 3, 7),
    (258, FxColors.white, 3, 17),
  ];

  static final Path _dragonBody = Path()
    ..moveTo(0, 118)
    ..cubicTo(-44, 98, -44, 66, 0, 52)
    ..cubicTo(44, 38, 44, 8, 0, -6)
    ..cubicTo(-22, -13, -20, -28, -4, -36);
  static final Path _dragonTail = Path()
    ..moveTo(-2, 116)
    ..cubicTo(-14, 124, -20, 134, -12, 140)
    ..cubicTo(-8, 132, -2, 128, 6, 126)
    ..cubicTo(12, 132, 10, 140, 4, 144)
    ..cubicTo(16, 140, 18, 126, 6, 118)
    ..close();
  static final Path _dragonHead = Path()
    ..moveTo(-15, -34)
    ..cubicTo(-18, -50, -8, -60, 2, -62)
    ..cubicTo(12, -60, 16, -50, 12, -40)
    ..cubicTo(8, -32, -8, -28, -15, -34)
    ..close();
  static final Path _whiskers = Path()
    ..moveTo(8, -52)
    ..cubicTo(22, -56, 28, -44, 36, -50)
    ..moveTo(-10, -50)
    ..cubicTo(-24, -54, -30, -42, -38, -48);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = background);
    final s = math.min(size.width / _w, size.height / _h);
    canvas.save();
    canvas.translate((size.width - _w * s) / 2, (size.height - _h * s) / 2);
    canvas.scale(s);
    canvas.clipRect(const Rect.fromLTWH(0, 0, _w, _h));
    canvas.translate(0, -_top);
    _scene(canvas, story.value, clock.value);
    canvas.restore();
  }

  void _scene(Canvas canvas, double t, double c) {
    // Sông
    canvas.drawPath(_river, Paint()..color = FxColors.water);
    for (final (path, color, width, delay) in _riverStreaks) {
      drawFlowingDashes(
        canvas,
        path,
        Paint()
          ..color = color
          ..strokeWidth = width
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round,
        dash: 10,
        gap: 34,
        phase: c * 44 / 1.4 + delay,
      );
    }

    // Vách đá
    final rock = Paint()..color = FxColors.rock;
    canvas.drawPath(_rockL, rock);
    canvas.drawPath(_rockR, rock);
    canvas.drawPath(
      _rockLines,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeCap = StrokeCap.round
        ..color = FxColors.rockLine,
    );

    // Thác
    canvas.drawRect(
      const Rect.fromLTWH(122, 276, 146, 204),
      Paint()..color = FxColors.falls,
    );
    for (final (x, color, width, delay) in _fallLines) {
      drawFlowingDashes(
        canvas,
        Path()
          ..moveTo(x, 276)
          ..lineTo(x, 480),
        Paint()
          ..color = color
          ..strokeWidth = width
          ..style = PaintingStyle.stroke,
        dash: 18,
        gap: 26,
        phase: c * 44 / 0.55 + delay,
      );
    }
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(195, 276), width: 156, height: 14),
      Paint()..color = FxColors.white,
    );
    for (final (x, w, h, ph) in const [
      (150.0, 56.0, 24.0, 0.0),
      (195.0, 68.0, 28.0, 1.1),
      (240.0, 56.0, 24.0, 2.2),
    ]) {
      final m = 0.5 + 0.5 * math.sin(c * 2 * math.pi / 3.6 + ph);
      final k = 0.85 + 0.3 * m;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 486), width: w * k, height: h * k),
        Paint()..color = FxColors.white.withAlpha((140 + 100 * m).round()),
      );
    }

    // Cổng Vũ Môn
    paintVuMonGate(
      canvas,
      center: const Offset(195, 223),
      primary: primary,
      plaqueFill: background,
    );

    // Bọt nước lúc cá nhảy
    if (t > 0.42 && t < 0.57) {
      final u = ((t - 0.44) / 0.12).clamp(0.0, 1.0);
      final op = t < 0.45 ? ((t - 0.42) / 0.03).clamp(0.0, 1.0) : 1 - u;
      final e = Curves.easeOut.transform(u);
      for (final (dx, dy, r) in const [
        (-34.0, -40.0, 4.0),
        (-16.0, -58.0, 3.0),
        (18.0, -54.0, 4.0),
        (36.0, -36.0, 3.0),
        (4.0, -70.0, 2.5),
      ]) {
        final p = const Offset(195, 478) + Offset(dx, dy) * e;
        canvas.drawCircle(
          p,
          r,
          Paint()..color = FxColors.white.withAlpha((255 * op).round()),
        );
        canvas.drawCircle(
          p,
          r,
          Paint()
            ..style = PaintingStyle.stroke
            ..color = FxColors.streak.withAlpha((255 * op).round()),
        );
      }
    }

    // Cá chép
    final kOp = kf(t, const [(0, 0), (0.05, 1), (0.59, 1), (0.63, 0)]);
    if (kOp > 0.01) {
      final y = kf(t, const [
        (0, 300),
        (0.36, 10),
        (0.43, 22),
        (0.52, -130),
        (0.59, -240),
        (0.63, -248),
      ]);
      final sc = kf(t, const [
        (0, 1),
        (0.36, 1),
        (0.43, 0.94),
        (0.52, 1.06),
        (0.59, 1),
        (0.63, 0.4),
      ]);
      final rot =
          kf(t, const [(0, 0), (0.43, 0), (0.52, 7), (0.59, 0)]) *
          math.pi /
          180;
      final swimming = t < 0.43;
      final wig = math.sin(c * 2 * math.pi / 0.9) * (swimming ? 5 : 1.5);
      canvas.save();
      canvas.translate(195 + wig, 480 + y);
      canvas.rotate(rot);
      canvas.scale(sc);
      canvas.rotate(-math.pi / 2);
      canvas.scale(0.72);
      canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, kOp));
      paintKoi(
        canvas,
        spot: primary,
        tailAngle: math.sin(c * 2 * math.pi / 0.6) * 22 * math.pi / 180,
      );
      canvas.restore();
      canvas.restore();
    }

    // Lóe sáng
    if (t > 0.58 && t < 0.76) {
      final sc = kf(t, const [(0.58, 0), (0.62, 1), (0.74, 7)], Curves.easeOut);
      final op = kf(t, const [(0.58, 0), (0.62, 0.95), (0.74, 0)]);
      canvas.drawCircle(
        const Offset(195, 236),
        12 * sc,
        Paint()..color = FxColors.goldLight.withAlpha((255 * op).round()),
      );
      final sc2 = kf(t, const [
        (0.59, 0),
        (0.63, 1),
        (0.75, 7),
      ], Curves.easeOut);
      final op2 = kf(t, const [(0.59, 0), (0.63, 0.95), (0.75, 0)]);
      canvas.drawCircle(
        const Offset(195, 236),
        16 * sc2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = FxColors.gold.withAlpha((255 * op2).round()),
      );
    }

    // Rồng
    final dOp = kf(t, const [(0.61, 0), (0.63, 1), (0.94, 1), (0.99, 0)]);
    if (dOp > 0.01) {
      final rise = kf(t, const [
        (0.61, 0),
        (0.74, -8),
        (0.94, -84),
        (0.99, -90),
      ]);
      final draw = kf(t, const [(0.61, 0), (0.77, 1)], Curves.easeOut);
      final late = kf(t, const [(0.72, 0), (0.80, 1)]);
      final head = kf(t, const [(0.70, 0.3), (0.78, 1)], Curves.easeOutBack);
      final headOp = kf(t, const [(0.70, 0), (0.76, 1)]);
      final wob = math.sin(c * 2 * math.pi / 2.2) * 5 * math.pi / 180;

      canvas.save();
      canvas.translate(195, 262 + rise);
      canvas.scale(1.1);
      canvas.translate(0, 55);
      canvas.rotate(wob);
      canvas.translate(0, -55);
      canvas.saveLayer(null, Paint()..color = Color.fromRGBO(0, 0, 0, dOp));

      final metric = _dragonBody.computeMetrics().first;
      canvas.drawPath(
        metric.extractPath(0, metric.length * draw),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 15
          ..strokeCap = StrokeCap.round
          ..color = primary,
      );
      if (late > 0) {
        final a = (255 * late).round();
        drawFlowingDashes(
          canvas,
          _dragonBody,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 3
            ..strokeCap = StrokeCap.round
            ..color = FxColors.gold.withAlpha(a),
          dash: 3,
          gap: 7,
        );
        canvas.drawPath(
          _dragonTail,
          Paint()..color = FxColors.gold.withAlpha(a),
        );
        final claw = Paint()
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..color = primary.withAlpha(a);
        canvas.drawLine(const Offset(-30, 80), const Offset(-44, 86), claw);
        canvas.drawLine(const Offset(-30, 80), const Offset(-40, 94), claw);
        canvas.drawLine(const Offset(30, 26), const Offset(44, 20), claw);
        canvas.drawLine(const Offset(30, 26), const Offset(42, 34), claw);
      }
      if (headOp > 0) {
        canvas.save();
        canvas.translate(0, -34);
        canvas.scale(head);
        canvas.translate(0, 34);
        final a = (255 * headOp).round();
        canvas.drawPath(_dragonHead, Paint()..color = primary.withAlpha(a));
        final gold = Paint()
          ..style = PaintingStyle.stroke
          ..strokeCap = StrokeCap.round
          ..color = FxColors.gold.withAlpha(a);
        canvas.drawLine(
          const Offset(-6, -58),
          const Offset(-14, -74),
          gold..strokeWidth = 3,
        );
        canvas.drawLine(const Offset(4, -58), const Offset(10, -74), gold);
        canvas.drawPath(_whiskers, gold..strokeWidth = 2);
        final eye = Paint()..color = background.withAlpha(a);
        canvas.drawCircle(const Offset(-4, -50), 2, eye);
        canvas.drawCircle(const Offset(6, -50), 2, eye);
        canvas.restore();
      }
      canvas.restore(); // saveLayer
      canvas.restore();
    }

    // Lấp lánh
    for (final (x, y, r, color, d) in [
      (120.0, 194.0, 14.0, FxColors.gold, 0.0),
      (276.0, 160.0, 10.0, FxColors.gold, 0.036),
      (262.0, 257.0, 7.0, primary, 0.057),
      (110.0, 127.0, 7.0, primary, 0.079),
    ]) {
      final tt = t - d;
      final sc = kf(tt, const [(0.64, 0), (0.72, 1), (0.86, 0.6), (0.94, 0)]);
      if (sc <= 0.01) continue;
      final rot = kf(tt, const [(0.64, 0), (0.86, 1.57)]);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      canvas.scale(sc);
      canvas.drawPath(sparkPath(r), Paint()..color = color);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _DragonPainter old) =>
      old.primary != primary ||
      old.background != background ||
      old.story != story ||
      old.clock != clock;
}
