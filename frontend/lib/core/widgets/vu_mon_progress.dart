// vu_mon_progress.dart — IELTS Hub
//
// Thác Vũ Môn cho sidebar: cá chép leo dần theo số chặng đã học trong tuần,
// đủ chặng thì cá vượt cổng và lóe sáng vàng.
//
// Trong sidebar (ẩn khi cửa sổ thấp để menu không bị chật):
//
//   Expanded(
//     child: LayoutBuilder(builder: (context, c) {
//       if (c.maxHeight < 280) return const SizedBox.shrink();
//       return Align(
//         alignment: Alignment.bottomCenter,
//         child: Padding(
//           padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
//           child: VuMonProgress(completed: weekDone, total: 5),
//         ),
//       );
//     }),
//   ),
//
// Chưa có dữ liệu chặng học: cá leo hết thác đúng 1 lần, vượt cổng rồi dừng ở
// trên (chú thích không hiện số chặng):
//
//   VuMonProgress(playOnce: true)
//
// Hoặc lặp mãi: leo → lóe sáng → nghỉ → cá mờ đi rồi hiện lại ở chân thác:
//
//   VuMonProgress(repeat: true)

import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'fx_common.dart';

class VuMonProgress extends StatefulWidget {
  const VuMonProgress({
    super.key,
    this.completed = 0,
    this.total = 5,
    this.playOnce = false,
    this.repeat = false,
    this.duration = const Duration(seconds: 4),
    this.primary = FxColors.primary,
    this.background = FxColors.sidebar,
    this.showCaption = true,
    this.onPassedGate,
  }) : assert(total >= 2),
       assert(!(playOnce && repeat), 'Chọn playOnce hoặc repeat, không cả hai');

  final int completed;
  final int total;

  /// true = cá leo từ chân thác qua cổng đúng 1 lần (bỏ qua [completed]).
  final bool playOnce;

  /// true = cá leo qua cổng lặp đi lặp lại (bỏ qua [completed]). Khi người
  /// dùng tắt hiệu ứng, cá đứng yên trên cổng.
  final bool repeat;

  /// Thời gian cá leo hết thác khi [playOnce] hoặc [repeat].
  final Duration duration;
  final Color primary;

  /// Màu nền sidebar (dùng cho bảng tên cổng và chấm rỗng).
  final Color background;
  final bool showCaption;

  /// Gọi khi cá vượt cổng: một lần khi completed chạm total hoặc hết lượt
  /// [playOnce]; mỗi vòng khi [repeat].
  final VoidCallback? onPassedGate;

  @override
  State<VuMonProgress> createState() => _VuMonProgressState();
}

class _VuMonProgressState extends State<VuMonProgress>
    with TickerProviderStateMixin {
  late final AnimationController _level; // 0..1 = completed / total
  late final AnimationController _celebrate;
  late final Ticker _clockTicker;
  final ValueNotifier<double> _clock = ValueNotifier<double>(0);
  bool _played = false;
  bool? _reduceMotion;

  // Một vòng khi [VuMonProgress.repeat]: leo (duration) → lóe sáng → nghỉ →
  // mờ đi. Cá hiện lại dần ở chân thác trong lúc bắt đầu leo vòng sau.
  static const _flash = Duration(milliseconds: 1600);
  static const _hold = Duration(milliseconds: 1200);
  static const _fade = Duration(milliseconds: 400);
  late final AnimationController _cycle;
  CurvedAnimation? _loopLevel;
  CurvedAnimation? _loopCelebrate;
  Animation<double> _loopFish = kAlwaysCompleteAnimation;
  double _climbEnd = 1, _flashEnd = 1, _lastCycle = 0;

  double get _target => (widget.completed / widget.total).clamp(0.0, 1.0);

  @override
  void initState() {
    super.initState();
    _level = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
      value: widget.playOnce ? 0 : _target,
    );
    _celebrate = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _cycle = AnimationController(vsync: this)..addListener(_onCycleTick);
    _clockTicker = createTicker((e) => _clock.value = e.inMicroseconds / 1e6);
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
    // Chạy ở đây (không phải initState) để biết người dùng có tắt hiệu ứng.
    if (widget.playOnce && !_played) {
      _played = true;
      _playOnce(reduce);
    }
    if (_reduceMotion != reduce) {
      _reduceMotion = reduce;
      _syncLoop();
    }
  }

  /// Bật / tắt vòng lặp theo [VuMonProgress.repeat] và cài đặt hiện tại.
  void _syncLoop() {
    if (!widget.repeat) {
      _cycle.stop();
      return;
    }
    final climb = widget.duration.inMilliseconds;
    final total =
        climb +
        _flash.inMilliseconds +
        _hold.inMilliseconds +
        _fade.inMilliseconds;
    _climbEnd = climb / total;
    _flashEnd = (climb + _flash.inMilliseconds) / total;
    final fade = _fade.inMilliseconds / total;
    _cycle.duration = Duration(milliseconds: total);
    _loopLevel?.dispose();
    _loopCelebrate?.dispose();
    _loopLevel = CurvedAnimation(
      parent: _cycle,
      curve: Interval(0, _climbEnd, curve: Curves.easeInOut),
    );
    _loopCelebrate = CurvedAnimation(
      parent: _cycle,
      curve: Interval(_climbEnd, _flashEnd),
    );
    _loopFish = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0, end: 1), weight: fade),
      TweenSequenceItem(tween: ConstantTween(1), weight: 1 - 2 * fade),
      TweenSequenceItem(tween: Tween(begin: 1, end: 0), weight: fade),
    ]).animate(_cycle);
    if (_reduceMotion ?? false) {
      // Đứng yên ngay sau lúc vượt cổng: cá ở trên, hiện rõ, không lóe sáng.
      _cycle.stop();
      _cycle.value = _flashEnd;
    } else {
      _lastCycle = _cycle.value;
      _cycle.repeat();
    }
  }

  void _onCycleTick() {
    final t = _cycle.value;
    if (_cycle.isAnimating && _lastCycle < _climbEnd && t >= _climbEnd) {
      widget.onPassedGate?.call();
    }
    _lastCycle = t;
  }

  void _playOnce(bool reduce) {
    _level
        .animateTo(
          1,
          duration: reduce ? Duration.zero : widget.duration,
          curve: Curves.easeInOut,
        )
        .then((_) {
          if (!mounted) return;
          if (!reduce) _celebrate.forward(from: 0);
          widget.onPassedGate?.call();
        });
  }

  @override
  void didUpdateWidget(covariant VuMonProgress old) {
    super.didUpdateWidget(old);
    if (old.repeat != widget.repeat ||
        (widget.repeat && old.duration != widget.duration)) {
      _syncLoop();
    }
    if (old.playOnce && !widget.playOnce) {
      // Bỏ lượt leo đang dở: dừng kiểu canceled nên .then của nó không chạy,
      // không lóe sáng hay gọi onPassedGate muộn.
      _level.stop();
      _celebrate.reset();
      _played = false;
    }
    // Đổi sang playOnce lúc đang chạy (ví dụ hot reload).
    if (widget.playOnce && !_played) {
      _played = true;
      _playOnce(_reduceMotion ?? false);
    }
    // Rời playOnce / repeat để hiện dữ liệu thật: cá phải về đúng số chặng
    // dù completed không đổi trong lần cập nhật này.
    final leftDemo = old.playOnce || old.repeat;
    if (!widget.playOnce &&
        !widget.repeat &&
        (leftDemo ||
            old.completed != widget.completed ||
            old.total != widget.total)) {
      final wasDone = !leftDemo && old.completed >= old.total;
      _level.animateTo(_target, curve: Curves.easeInOutCubic).then((_) {
        if (!mounted) return;
        if (!wasDone && widget.completed >= widget.total) {
          _celebrate.forward(from: 0);
          widget.onPassedGate?.call();
        }
      });
    }
  }

  @override
  void dispose() {
    _level.dispose();
    _celebrate.dispose();
    _loopLevel?.dispose();
    _loopCelebrate?.dispose();
    _cycle.dispose();
    _clockTicker.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final left = widget.total - widget.completed;
    final loop = widget.repeat;
    // Chưa có dữ liệu thật thì không hiện số chặng.
    final demo = widget.playOnce || loop;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: demo
              ? 'Thác Vũ Môn'
              : 'Thác Vũ Môn: đã vượt ${widget.completed} trên ${widget.total} chặng tuần này',
          child: AspectRatio(
            aspectRatio: 208 / 236,
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _VuMonPainter(
                  level: loop ? _loopLevel! : _level,
                  celebrate: loop ? _loopCelebrate! : _celebrate,
                  fish: loop ? _loopFish : kAlwaysCompleteAnimation,
                  clock: _clock,
                  total: widget.total,
                  primary: widget.primary,
                  background: widget.background,
                ),
              ),
            ),
          ),
        ),
        if (widget.showCaption) ...[
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              demo
                  ? 'Thác Vũ Môn'
                  : 'Tuần này: ${widget.completed}/${widget.total} chặng',
              style: TextStyle(
                color: widget.primary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              demo
                  ? 'Học đều mỗi ngày để cá vượt vũ môn'
                  : left > 0
                  ? 'Còn $left bài nữa để vượt vũ môn'
                  : 'Đã vượt vũ môn tuần này!',
              style: const TextStyle(
                color: Color(0xFF6B4A4F),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _VuMonPainter extends CustomPainter {
  _VuMonPainter({
    required this.level,
    required this.celebrate,
    required this.fish,
    required this.clock,
    required this.total,
    required this.primary,
    required this.background,
  }) : super(repaint: Listenable.merge([level, celebrate, fish, clock]));

  final Animation<double> level;
  final Animation<double> celebrate;

  /// Độ hiện của cá 0..1 (chỉ đổi khi lặp: mờ đi ở cổng, hiện lại ở chân thác).
  final Animation<double> fish;
  final ValueListenable<double> clock;
  final int total;
  final Color primary;
  final Color background;

  static const double _w = 208, _h = 236;

  static final Path _river = Path()
    ..moveTo(56, 196)
    ..cubicTo(44, 212, 30, 224, 16, 236)
    ..lineTo(192, 236)
    ..cubicTo(178, 224, 164, 212, 152, 196)
    ..close();
  static final List<Path> _riverStreaks = [
    Path()
      ..moveTo(84, 198)
      ..cubicTo(80, 212, 72, 224, 66, 236),
    Path()
      ..moveTo(104, 198)
      ..lineTo(104, 236),
    Path()
      ..moveTo(124, 198)
      ..cubicTo(128, 212, 136, 224, 142, 236),
  ];
  static final Path _rockL = Path()
    ..moveTo(0, 74)
    ..lineTo(70, 74)
    ..cubicTo(66, 110, 68, 160, 60, 198)
    ..cubicTo(40, 214, 18, 222, 0, 226)
    ..close();
  static final Path _rockR = Path()
    ..moveTo(208, 74)
    ..lineTo(138, 74)
    ..cubicTo(142, 110, 140, 160, 148, 198)
    ..cubicTo(168, 214, 190, 222, 208, 226)
    ..close();
  static const _falls = <(double, Color, double, double)>[
    (76, FxColors.white, 2.5, 0),
    (88, FxColors.streak, 1.5, 10),
    (100, FxColors.white, 2.5, 20),
    (112, FxColors.white, 2.5, 5),
    (124, FxColors.streak, 1.5, 15),
    (133, FxColors.white, 2.5, 27),
  ];

  double _dotY(int i) => 188 - i * (104 / (total - 1));

  /// Vị trí y của cá theo mức 0..1.
  double _koiY(double v) {
    final pts = <double>[210];
    for (var i = 1; i < total; i++) {
      pts.add(_dotY(i - 1));
    }
    pts.add(50);
    final x = v * total;
    final i = x.floor().clamp(0, total - 1);
    final f = (x - i).clamp(0.0, 1.0);
    return pts[i] + (pts[i + 1] - pts[i]) * f;
  }

  @override
  void paint(Canvas canvas, Size size) {
    final s = math.min(size.width / _w, size.height / _h);
    canvas.save();
    canvas.translate((size.width - _w * s) / 2, (size.height - _h * s) / 2);
    canvas.scale(s);
    final c = clock.value;
    final v = level.value;

    canvas.drawPath(_river, Paint()..color = FxColors.water);
    for (var i = 0; i < _riverStreaks.length; i++) {
      drawFlowingDashes(
        canvas,
        _riverStreaks[i],
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeCap = StrokeCap.round
          ..color = FxColors.white,
        dash: 8,
        gap: 22,
        phase: c * 30 / 2 + i * 11,
      );
    }
    final rock = Paint()..color = const Color(0xFFEAD3BE);
    canvas.drawPath(_rockL, rock);
    canvas.drawPath(_rockR, rock);

    canvas.drawRect(
      const Rect.fromLTWH(69, 76, 70, 122),
      Paint()..color = FxColors.falls,
    );
    for (final (x, color, w, d) in _falls) {
      drawFlowingDashes(
        canvas,
        Path()
          ..moveTo(x, 76)
          ..lineTo(x, 198),
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = w
          ..color = color,
        dash: 14,
        gap: 20,
        phase: c * 34 / 0.9 + d,
      );
    }
    canvas.drawOval(
      Rect.fromCenter(center: const Offset(104, 76), width: 74, height: 8),
      Paint()..color = FxColors.white,
    );
    for (final (x, ph) in const [(84.0, 0.0), (124.0, 1.6)]) {
      final m = 0.5 + 0.5 * math.sin(c * 2 * math.pi / 4.8 + ph);
      final k = 0.85 + 0.3 * m;
      canvas.drawOval(
        Rect.fromCenter(center: Offset(x, 200), width: 36 * k, height: 14 * k),
        Paint()..color = FxColors.white.withAlpha((128 + 100 * m).round()),
      );
    }

    // Cổng (thu nhỏ từ khung 390 px)
    paintVuMonGate(
      canvas,
      center: const Offset(104, 43),
      primary: primary,
      plaqueFill: background,
      scale: 0.6,
    );

    // Chấm chặng
    final done = v * total;
    final line = Paint()
      ..strokeWidth = 1
      ..color = primary.withAlpha(128);
    for (var y = _dotY(0); y > _dotY(total - 1); y -= 6) {
      canvas.drawLine(
        Offset(154, y),
        Offset(154, math.max(_dotY(total - 1), y - 2)),
        line,
      );
    }
    for (var i = 0; i < total; i++) {
      final center = Offset(154, _dotY(i));
      final filled = done >= i + 1 - 0.02;
      canvas.drawCircle(
        center,
        4.5,
        Paint()..color = filled ? primary : background,
      );
      if (!filled) {
        canvas.drawCircle(
          center,
          4.5,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..color = primary,
        );
      }
    }

    // Lóe sáng khi vượt cổng
    final cel = celebrate.value;
    if (cel > 0 && cel < 1) {
      final r = 6 + 40 * Curves.easeOut.transform(cel);
      final a = ((1 - cel) * 230).round();
      canvas.drawCircle(
        const Offset(104, 46),
        r,
        Paint()..color = FxColors.goldLight.withAlpha((a * 0.6).round()),
      );
      canvas.drawCircle(
        const Offset(104, 46),
        r * 1.2,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = FxColors.gold.withAlpha(a),
      );
      for (var i = 0; i < 4; i++) {
        final ang = i * math.pi / 2 + cel * 1.2;
        canvas.save();
        canvas.translate(
          104 + math.cos(ang) * r * 0.9,
          46 + math.sin(ang) * r * 0.9,
        );
        canvas.scale(1 - cel);
        canvas.drawPath(sparkPath(6), Paint()..color = FxColors.gold);
        canvas.restore();
      }
    }

    // Cá chép
    final opacity = fish.value.clamp(0.0, 1.0);
    if (opacity > 0) {
      final bob = Offset(
        math.sin(c * 2 * math.pi / 3.2) * 2,
        math.cos(c * 2 * math.pi / 3.2) * 3,
      );
      canvas.save();
      canvas.translate(104 + bob.dx, _koiY(v) + bob.dy);
      canvas.rotate(-math.pi / 2);
      canvas.scale(0.46);
      if (opacity < 1) {
        canvas.saveLayer(
          null,
          Paint()..color = Color.fromRGBO(0, 0, 0, opacity),
        );
      }
      paintKoi(
        canvas,
        spot: primary,
        fins: false,
        tailAngle: math.sin(c * 2 * math.pi / 0.9) * 22 * math.pi / 180,
      );
      if (opacity < 1) canvas.restore();
      canvas.restore();
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _VuMonPainter old) =>
      old.level != level ||
      old.celebrate != celebrate ||
      old.fish != fish ||
      old.total != total ||
      old.primary != primary ||
      old.background != background;
}
