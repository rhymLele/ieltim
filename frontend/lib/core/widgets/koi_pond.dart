// koi_pond.dart — IELTS Hub
//
// Ao cá koi động: cá bơi tự nhiên (thân uốn theo chuỗi khúc), quẫy đuôi,
// chạm vào mặt nước tạo gợn sóng và cá gần đó giật mình bơi tản ra.
// Không cần package ngoài, chỉ dùng CustomPainter + Ticker.
//
// Cách dùng (màn Welcome):
//
//   Scaffold(
//     body: Stack(
//       children: [
//         const Positioned.fill(child: KoiPond()),
//         SafeArea(child: /* logo, tiêu đề, nút Bắt đầu ... */),
//       ],
//     ),
//   )
//
// - Tự dừng khi người dùng bật "giảm chuyển động" (MediaQuery.disableAnimations).
// - Tự dừng khi màn hình bị che (TickerMode của Navigator).
//
// Gợn sóng nhẹ (bật sẵn, tắt riêng từng thứ nếu muốn):
// - wakes: vệt nước chữ V sau mỗi con cá
// - caustics: ánh nước trôi rất chậm (độ mờ ~3–5%)
// - ambientRipples: thỉnh thoảng có gợn tròn đôi lan ra (cá không giật mình)

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

class KoiPond extends StatefulWidget {
  const KoiPond({
    super.key,
    this.fishCount = 6,
    this.backgroundColor = const Color(0xFFFFF9F2),
    this.primary = const Color(0xFF800020),
    this.gold = const Color(0xFFE7A23B),
    this.lilyPadColor = const Color(0xFF9FB08F),
    this.showLilyPads = true,
    this.interactive = true,
    this.wakes = true,
    this.caustics = true,
    this.ambientRipples = true,
    this.seed,
  });

  /// Số cá trong ao (5–8 là đẹp trên điện thoại).
  final int fishCount;
  final Color backgroundColor;

  /// Màu đốm đỏ của cá (mặc định là màu primary của app).
  final Color primary;
  final Color gold;
  final Color lilyPadColor;
  final bool showLilyPads;

  /// Chạm để tạo gợn nước.
  final bool interactive;

  /// Vệt nước chữ V sau đuôi cá.
  final bool wakes;

  /// Ánh nước trôi chậm trên nền.
  final bool caustics;

  /// Gợn tròn tự xuất hiện thưa thớt.
  final bool ambientRipples;

  /// Cố định seed nếu muốn đàn cá giống nhau mỗi lần mở.
  final int? seed;

  @override
  State<KoiPond> createState() => _KoiPondState();
}

class _KoiPondState extends State<KoiPond> with SingleTickerProviderStateMixin {
  late final Ticker _ticker;
  final ValueNotifier<int> _frame = ValueNotifier<int>(0);
  late math.Random _rng;

  final List<_Koi> _fish = [];
  final List<_Ripple> _ripples = [];
  final List<_LilyPad> _pads = [];

  Size _size = Size.zero;
  Duration _last = Duration.zero;
  double _time = 0;
  double _nextAmbient = 1.2;
  bool _reduceMotion = false;

  @override
  void initState() {
    super.initState();
    _rng = math.Random(widget.seed);
    _ticker = createTicker(_onTick);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    _syncTicker();
  }

  @override
  void didUpdateWidget(covariant KoiPond oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.fishCount != widget.fishCount ||
        oldWidget.primary != widget.primary ||
        oldWidget.gold != widget.gold) {
      _fish.clear();
      _size = Size.zero; // sinh lại đàn cá ở lần build kế tiếp
    }
  }

  void _syncTicker() {
    if (_reduceMotion) {
      if (_ticker.isActive) _ticker.stop();
    } else if (!_ticker.isActive) {
      _last = Duration.zero;
      _ticker.start();
    }
  }

  @override
  void dispose() {
    _ticker.dispose();
    _frame.dispose();
    super.dispose();
  }

  void _onTick(Duration elapsed) {
    final dt = ((elapsed - _last).inMicroseconds / 1e6).clamp(0.0, 1 / 20);
    _last = elapsed;
    if (_size.isEmpty) return;
    _time += dt;
    for (final f in _fish) {
      f.update(dt, _size, _ripples);
    }
    if (widget.ambientRipples && _time >= _nextAmbient) {
      _nextAmbient = _time + 2.0 + _rng.nextDouble() * 1.5;
      _ripples.add(
        _Ripple(
          Offset(
            _size.width * (0.12 + _rng.nextDouble() * 0.76),
            _size.height * (0.1 + _rng.nextDouble() * 0.55),
          ),
          scare: false,
        ),
      );
    }
    for (final r in _ripples) {
      r.age += dt;
    }
    _ripples.removeWhere((r) => r.age > _Ripple.life);
    _frame.value++;
  }

  void _ensureWorld(Size size) {
    if (size == _size || size.isEmpty) return;
    _size = size;
    if (_fish.isEmpty) {
      for (var i = 0; i < widget.fishCount; i++) {
        _fish.add(_spawnKoi(size, i));
      }
    }
    if (_pads.isEmpty) {
      const layout = [
        (Offset(0.84, 0.13), 0.085),
        (Offset(0.10, 0.52), 0.065),
        (Offset(0.92, 0.40), 0.05),
      ];
      for (final (pos, r) in layout) {
        _pads.add(
          _LilyPad(
            frac: pos,
            radiusFrac: r,
            angle: _rng.nextDouble() * math.pi * 2,
            flower: _pads.length == 2,
          ),
        );
      }
    }
  }

  _Koi _spawnKoi(Size size, int index) {
    final shortest = size.shortestSide;
    final length = (shortest * (0.20 + _rng.nextDouble() * 0.10)).clamp(
      60.0,
      140.0,
    );
    final margin = length;
    final head = Offset(
      margin + _rng.nextDouble() * math.max(1.0, size.width - margin * 2),
      margin + _rng.nextDouble() * math.max(1.0, size.height - margin * 2),
    );
    final kind = _KoiKind.values[index % _KoiKind.values.length];
    return _Koi(
      head: head,
      heading: _rng.nextDouble() * math.pi * 2,
      length: length,
      cruise: 24 + _rng.nextDouble() * 20,
      rng: _rng,
      skin: _Skin.of(kind, widget.primary, widget.gold, _rng),
    );
  }

  void _addRipple(Offset p) {
    if (_reduceMotion) return;
    _ripples.add(_Ripple(p));
    if (_ripples.length > 6) _ripples.removeAt(0);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        _ensureWorld(size);
        final pond = RepaintBoundary(
          child: CustomPaint(size: size, painter: _PondPainter(this, _frame)),
        );
        if (!widget.interactive) return pond;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _addRipple(d.localPosition),
          child: pond,
        );
      },
    );
  }
}

// ───────────────────────────── Koi ─────────────────────────────

enum _KoiKind { kohaku, yamabuki, tancho, showa, sanke, kohaku2 }

class _Spot {
  const _Spot(this.t, this.side, this.radius, this.color);
  final double t; // 0 = đầu, 1 = đuôi
  final double side; // -1..1 so với bề ngang thân
  final double radius; // theo nửa bề ngang lớn nhất
  final Color color;
}

class _Skin {
  const _Skin(this.base, this.fin, this.spots, {this.outline = false});
  final Color base;
  final Color fin;
  final List<_Spot> spots;
  final bool outline;

  static _Skin of(_KoiKind kind, Color red, Color gold, math.Random rng) {
    const white = Color(0xFFFFFFFF);
    const ink = Color(0xFF1E1A1A);
    double r(double a, double b) => a + rng.nextDouble() * (b - a);
    switch (kind) {
      case _KoiKind.kohaku:
      case _KoiKind.kohaku2:
        return _Skin(white, white.withAlpha(215), [
          _Spot(r(0.08, 0.14), r(-0.2, 0.2), r(0.75, 0.95), red),
          _Spot(r(0.32, 0.42), r(-0.4, 0.4), r(0.8, 1.0), red),
          _Spot(r(0.55, 0.65), r(-0.3, 0.3), r(0.6, 0.8), red),
        ], outline: true);
      case _KoiKind.tancho:
        return _Skin(white, white.withAlpha(215), [
          _Spot(0.09, 0, 0.55, red),
        ], outline: true);
      case _KoiKind.yamabuki:
        return _Skin(gold, gold.withAlpha(190), [
          _Spot(0.3, -0.2, 0.7, white.withAlpha(70)),
        ]);
      case _KoiKind.showa:
        return _Skin(red, red.withAlpha(200), [
          _Spot(r(0.25, 0.35), r(-0.3, 0.3), r(0.7, 0.9), white),
          _Spot(r(0.5, 0.6), r(-0.3, 0.3), r(0.5, 0.7), white),
        ]);
      case _KoiKind.sanke:
        return _Skin(white, white.withAlpha(215), [
          _Spot(r(0.12, 0.2), r(-0.3, 0.3), r(0.8, 0.95), red),
          _Spot(r(0.42, 0.5), r(-0.3, 0.3), r(0.7, 0.9), red),
          _Spot(r(0.3, 0.36), r(0.4, 0.7), 0.3, ink),
          _Spot(r(0.6, 0.66), r(-0.7, -0.4), 0.25, ink),
        ], outline: true);
    }
  }
}

class _Koi {
  _Koi({
    required Offset head,
    required this.heading,
    required this.length,
    required this.cruise,
    required this.skin,
    required math.Random rng,
  }) : _rng = rng,
       speed = cruise,
       phase = rng.nextDouble() * math.pi * 2 {
    final seg = length / (segments - 1);
    final back = _polar(heading + math.pi, seg);
    points = List.generate(segments, (i) => head + back * i.toDouble());
  }

  static const int segments = 16;

  final double length;
  final double cruise;
  final _Skin skin;
  final math.Random _rng;

  late List<Offset> points;
  double heading;
  double speed;
  double phase;
  double turn = 0; // tốc độ quay (rad/s)
  double panic = 0; // 0..1 sau khi bị gợn nước làm giật mình

  double get maxHalfWidth => length * 0.13;
  double get _seg => length / (segments - 1);

  void update(double dt, Size size, List<_Ripple> ripples) {
    // 1) Lượn ngẫu nhiên nhẹ nhàng.
    turn += (_rng.nextDouble() - 0.5) * 3.0 * dt;
    turn *= math.pow(0.4, dt).toDouble();
    turn = turn.clamp(-1.1, 1.1);
    heading += turn * dt;

    // 2) Tránh mép ao: càng gần mép càng quay mạnh về giữa.
    final head = points.first;
    final margin = length * 0.9;
    final edge = [
      margin - head.dx,
      head.dx - (size.width - margin),
      margin - head.dy,
      head.dy - (size.height - margin),
    ].reduce(math.max);
    if (edge > 0) {
      final c = size.center(Offset.zero) - head;
      _steerTo(
        math.atan2(c.dy, c.dx),
        2.8 * (edge / margin).clamp(0.2, 1.0),
        dt,
      );
    }

    // 3) Giật mình khi có gợn nước gần.
    for (final r in ripples) {
      if (!r.scare || r.age > 0.9) continue;
      final d = head - r.center;
      final dist = d.distance;
      const reach = 170.0;
      if (dist < reach) {
        _steerTo(math.atan2(d.dy, d.dx), 7, dt);
        panic = math.max(panic, 1 - dist / reach);
      }
    }
    panic = math.max(0.0, panic - dt * 0.5);

    // 4) Tốc độ + nhịp quẫy.
    final target = cruise * (1 + 2.4 * panic);
    speed += (target - speed) * math.min(1.0, 3 * dt);
    phase += dt * (3.2 + speed / length * 7);
    heading = _wrap(heading);

    // 5) Đầu đi trước (hơi lắc), thân bám theo từng khúc → uốn tự nhiên.
    final dir = heading + math.sin(phase) * (0.16 + 0.1 * panic);
    points[0] = head + _polar(dir, speed * dt);
    final seg = _seg;
    for (var i = 1; i < points.length; i++) {
      final delta = points[i - 1] - points[i];
      final dist = delta.distance;
      if (dist > 0) points[i] = points[i - 1] - delta / dist * seg;
    }
  }

  void _steerTo(double target, double k, double dt) {
    heading += _wrap(target - heading) * math.min(1.0, k * dt);
  }

  double halfWidth(double t) {
    final w = maxHalfWidth;
    if (t < 0.25) return w * (0.62 + 0.38 * math.sin(t / 0.25 * math.pi / 2));
    final u = (t - 0.25) / 0.75;
    return w * (0.09 + 0.91 * math.pow(1 - u, 1.25));
  }

  Offset _dirAt(int i) {
    final a = i == 0 ? points[0] - points[1] : points[i - 1] - points[i];
    return _norm(a);
  }

  Offset _spineAt(double t) {
    final x = t * (points.length - 1);
    final i0 = x.floor().clamp(0, points.length - 1);
    final i1 = math.min(i0 + 1, points.length - 1);
    return Offset.lerp(points[i0], points[i1], x - i0)!;
  }

  Path bodyPath() {
    final n = points.length;
    final left = <Offset>[];
    final right = <Offset>[];
    for (var i = 0; i < n; i++) {
      final d = _dirAt(i);
      final nrm = Offset(-d.dy, d.dx);
      final w = halfWidth(i / (n - 1));
      left.add(points[i] + nrm * w);
      right.add(points[i] - nrm * w);
    }
    final nose = points[0] + _dirAt(0) * maxHalfWidth * 0.95;
    final seq = [...left.reversed, nose, ...right];
    return _smooth(seq)..close();
  }

  void _paintWake(Canvas canvas, Color color, double time) {
    final d = _dirAt(0);
    final back = -d;
    final nrm = Offset(-d.dy, d.dx);
    final len = length * 0.75;
    final strength = (0.7 + 0.6 * panic).clamp(0.0, 1.0);
    for (final side in const [-1.0, 1.0]) {
      final start = points[1] + nrm * side * halfWidth(0.1) * 0.9;
      final dirV = _norm(back + nrm * side * 0.36);
      final end = start + dirV * len;
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4
        ..strokeCap = StrokeCap.round
        ..shader = ui.Gradient.linear(start, end, [
          color.withAlpha((82 * strength).round()),
          color.withAlpha(0),
        ]);
      // Nét đứt chạy lùi ra sau (7 px nét, 5 px trống).
      const dash = 7.0, gap = 5.0, period = dash + gap;
      var t = (time * 15) % period - period;
      while (t < len) {
        final a = math.max(0.0, t);
        final b = math.min(len, t + dash);
        if (b > a) canvas.drawLine(start + dirV * a, start + dirV * b, paint);
        t += period;
      }
    }
  }

  void paint(
    Canvas canvas,
    Color outlineColor, {
    double time = 0,
    bool wake = true,
  }) {
    final body = bodyPath();
    final n = points.length;
    final headDir = _dirAt(0);

    // Vệt nước chữ V sau đuôi.
    if (wake) _paintWake(canvas, outlineColor, time);

    // Bóng dưới nước.
    canvas.drawPath(
      body.shift(Offset(maxHalfWidth * 0.5, maxHalfWidth * 0.8)),
      Paint()
        ..color = const Color(0xFF3A0010).withAlpha(30)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, maxHalfWidth * 0.5),
    );

    final finPaint = Paint()..color = skin.fin;
    final finEdge = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = outlineColor.withAlpha(skin.outline ? 40 : 0);

    // Vây ngực (vẫy nhẹ).
    const pi3 = 3;
    final pd = _dirAt(pi3);
    final pAngle = math.atan2(pd.dy, pd.dx);
    final pn = Offset(-pd.dy, pd.dx);
    final flap = math.sin(phase * 0.8);
    for (final s in const [-1.0, 1.0]) {
      final base = points[pi3] + pn * s * halfWidth(pi3 / (n - 1)) * 0.75;
      final a = pAngle + s * (math.pi / 2 + 0.55 + flap * 0.3);
      canvas.save();
      canvas.translate(base.dx, base.dy);
      canvas.rotate(a);
      final r = Rect.fromLTWH(
        0,
        -maxHalfWidth * 0.3,
        maxHalfWidth * 1.35,
        maxHalfWidth * 0.6,
      );
      canvas.drawOval(r, finPaint);
      canvas.drawOval(r, finEdge);
      canvas.restore();
    }

    // Vây đuôi (quẫy trễ pha so với thân).
    final tail = points.last;
    final back = _norm(points[n - 1] - points[n - 2]);
    final backAngle =
        math.atan2(back.dy, back.dx) + math.sin(phase - 1.3) * 0.45;
    final finLen = length * 0.3;
    final tip1 = tail + _polar(backAngle + 0.5, finLen);
    final tip2 = tail + _polar(backAngle - 0.5, finLen);
    final notch = tail + _polar(backAngle, finLen * 0.55);
    final tailPath = Path()
      ..moveTo(tail.dx, tail.dy)
      ..quadraticBezierTo(
        (tail + _polar(backAngle + 0.2, finLen * 0.7)).dx,
        (tail + _polar(backAngle + 0.2, finLen * 0.7)).dy,
        tip1.dx,
        tip1.dy,
      )
      ..lineTo(notch.dx, notch.dy)
      ..lineTo(tip2.dx, tip2.dy)
      ..quadraticBezierTo(
        (tail + _polar(backAngle - 0.2, finLen * 0.7)).dx,
        (tail + _polar(backAngle - 0.2, finLen * 0.7)).dy,
        tail.dx,
        tail.dy,
      )
      ..close();
    canvas.drawPath(tailPath, finPaint);
    canvas.drawPath(tailPath, finEdge);

    // Thân + đốm (cắt theo thân).
    canvas.drawPath(body, Paint()..color = skin.base);
    canvas.save();
    canvas.clipPath(body);
    for (final s in skin.spots) {
      final p = _spineAt(s.t);
      final i = (s.t * (n - 1)).round().clamp(0, n - 1);
      final d = _dirAt(i);
      final c = p + Offset(-d.dy, d.dx) * s.side * halfWidth(s.t);
      canvas.drawCircle(c, s.radius * maxHalfWidth, Paint()..color = s.color);
    }
    canvas.restore();
    if (skin.outline) {
      canvas.drawPath(
        body,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.8
          ..color = outlineColor.withAlpha(45),
      );
    }

    // Mắt.
    final eyeBase = points[0] + headDir * maxHalfWidth * 0.35;
    final en = Offset(-headDir.dy, headDir.dx);
    final eye = Paint()..color = const Color(0xFF1E1A1A).withAlpha(170);
    canvas.drawCircle(
      eyeBase + en * maxHalfWidth * 0.5,
      maxHalfWidth * 0.1,
      eye,
    );
    canvas.drawCircle(
      eyeBase - en * maxHalfWidth * 0.5,
      maxHalfWidth * 0.1,
      eye,
    );
  }
}

// ─────────────────────────── Ripple & lily pad ───────────────────────────

class _Ripple {
  _Ripple(this.center, {this.scare = true});
  static const double life = 2.4;
  final Offset center;

  /// true = do người dùng chạm (cá giật mình); false = gợn tự nhiên, nhẹ hơn.
  final bool scare;
  double age = 0;
}

class _LilyPad {
  _LilyPad({
    required this.frac,
    required this.radiusFrac,
    required this.angle,
    this.flower = false,
  });
  final Offset frac;
  final double radiusFrac;
  final double angle;
  final bool flower;
}

// ───────────────────────────── Painter ─────────────────────────────

class _PondPainter extends CustomPainter {
  _PondPainter(this.s, Listenable repaint) : super(repaint: repaint);
  final _KoiPondState s;

  @override
  void paint(Canvas canvas, Size size) {
    final w = s.widget;
    canvas.drawRect(Offset.zero & size, Paint()..color = w.backgroundColor);

    if (w.caustics) {
      _paintCaustics(
        canvas,
        size,
        w.primary,
        tileW: 120,
        tileH: 60,
        period: 28,
        dir: const Offset(-1, -1),
        alpha: 13,
        stroke: 1.2,
      );
      _paintCaustics(
        canvas,
        size,
        w.primary,
        tileW: 160,
        tileH: 80,
        period: 36,
        dir: const Offset(1, -1),
        alpha: 9,
        stroke: 1,
      );
    }

    // Gợn nước.
    for (final r in s._ripples) {
      final k = r.age / _Ripple.life;
      for (var ring = 0; ring < 2; ring++) {
        final a = r.age - ring * 0.3;
        if (a <= 0) continue;
        final radius = r.scare ? 6 + a * 95 : 4 + a * 34;
        final alpha = ((1 - k) * (ring == 0 ? 110 : 70) * (r.scare ? 1 : 0.6))
            .clamp(0, 255)
            .toInt();
        canvas.drawCircle(
          r.center,
          radius,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4
            ..color = w.primary.withAlpha(alpha),
        );
      }
    }

    for (final f in s._fish) {
      f.paint(canvas, w.primary, time: s._time, wake: w.wakes);
    }

    if (w.showLilyPads) {
      for (var i = 0; i < s._pads.length; i++) {
        _paintPad(canvas, size, s._pads[i], i, w);
      }
    }
  }

  /// Một lớp vân sóng lặp lại, trôi hết một ô sau [period] giây.
  void _paintCaustics(
    Canvas canvas,
    Size size,
    Color color, {
    required double tileW,
    required double tileH,
    required double period,
    required Offset dir,
    required int alpha,
    required double stroke,
  }) {
    final p = (s._time / period) % 1.0;
    final ox = dir.dx * p * tileW;
    final oy = dir.dy * p * tileH;
    final path = Path();
    final amp = tileH * 0.2;
    for (
      var y = -tileH + (oy % tileH) + tileH / 2;
      y < size.height + tileH;
      y += tileH
    ) {
      var x = -tileW * 2 + (ox % tileW);
      path.moveTo(x, y);
      while (x < size.width + tileW) {
        path.cubicTo(
          x + tileW / 6,
          y - amp,
          x + tileW / 3,
          y + amp,
          x + tileW / 2,
          y,
        );
        path.cubicTo(
          x + tileW * 2 / 3,
          y - amp,
          x + tileW * 5 / 6,
          y + amp,
          x + tileW,
          y,
        );
        x += tileW;
      }
    }
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = color.withAlpha(alpha),
    );
  }

  void _paintPad(Canvas canvas, Size size, _LilyPad p, int i, KoiPond w) {
    final c = Offset(p.frac.dx * size.width, p.frac.dy * size.height);
    final r = p.radiusFrac * size.shortestSide * 1.6;
    final a = p.angle + math.sin(s._time * 0.4 + i) * 0.08;
    final drift =
        Offset(math.sin(s._time * 0.3 + i * 2), math.cos(s._time * 0.25 + i)) *
        2.5;
    final center = c + drift;

    canvas.drawCircle(
      center + Offset(r * 0.12, r * 0.18),
      r,
      Paint()
        ..color = const Color(0xFF3A0010).withAlpha(18)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, r * 0.15),
    );
    final pad = Path()
      ..moveTo(center.dx, center.dy)
      ..lineTo(
        (center + _polar(a + 0.22, r)).dx,
        (center + _polar(a + 0.22, r)).dy,
      )
      ..arcTo(
        Rect.fromCircle(center: center, radius: r),
        a + 0.22,
        math.pi * 2 - 0.44,
        false,
      )
      ..close();
    canvas.drawPath(pad, Paint()..color = w.lilyPadColor);
    final vein = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Color.lerp(w.lilyPadColor, Colors.black, 0.12)!;
    for (var k = 1; k < 6; k++) {
      final va = a + 0.22 + k * (math.pi * 2 - 0.44) / 6;
      canvas.drawLine(center, center + _polar(va, r * 0.85), vein);
    }
    if (p.flower) {
      final fc = center + _polar(a + math.pi, r * 0.9);
      final petal = Paint()..color = const Color(0xFFF4C7CF);
      for (var k = 0; k < 6; k++) {
        canvas.drawCircle(
          fc + _polar(k * math.pi / 3 + s._time * 0.1, r * 0.22),
          r * 0.2,
          petal,
        );
      }
      canvas.drawCircle(fc, r * 0.14, Paint()..color = w.gold);
    }
  }

  @override
  bool shouldRepaint(covariant _PondPainter old) => old.s != s;
}

// ───────────────────────────── helpers ─────────────────────────────

Offset _polar(double a, double r) => Offset(math.cos(a) * r, math.sin(a) * r);

Offset _norm(Offset o) {
  final d = o.distance;
  return d == 0 ? const Offset(1, 0) : o / d;
}

double _wrap(double a) {
  while (a > math.pi) {
    a -= math.pi * 2;
  }
  while (a < -math.pi) {
    a += math.pi * 2;
  }
  return a;
}

/// Nối các điểm bằng đường cong mượt (quadratic qua trung điểm).
Path _smooth(List<Offset> pts) {
  final path = Path()..moveTo(pts.first.dx, pts.first.dy);
  for (var i = 1; i < pts.length - 1; i++) {
    final mid = Offset.lerp(pts[i], pts[i + 1], 0.5)!;
    path.quadraticBezierTo(pts[i].dx, pts[i].dy, mid.dx, mid.dy);
  }
  path.lineTo(pts.last.dx, pts.last.dy);
  return path;
}
