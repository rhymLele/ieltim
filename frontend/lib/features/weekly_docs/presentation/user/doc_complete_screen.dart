// doc_complete_screen.dart — U3: hoàn thành tài liệu. Bố cục: file 6 mục U3.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/app_tokens.dart';
import '../../data/weekly_docs_repository.dart';
import '../../domain/weekly_doc.dart';
import 'doc_reader_screen.dart';

class DocCompleteScreen extends StatefulWidget {
  const DocCompleteScreen({super.key, required this.repo, required this.doc, required this.result, this.nextDoc});

  final WeeklyDocsRepository repo;
  final WeeklyDoc doc;
  final CompleteResult result;
  final DocRecord? nextDoc;

  @override
  State<DocCompleteScreen> createState() => _DocCompleteScreenState();
}

class _DocCompleteScreenState extends State<DocCompleteScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _jump = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
  bool _saving = false;
  int? _savedCount;

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

  Future<void> _saveVocab() async {
    setState(() => _saving = true);
    try {
      final added = await widget.repo.saveVocabFrom(widget.doc);
      if (!mounted) return;
      setState(() {
        _saving = false;
        _savedCount = added;
      });
    } on RepoException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  void _openNext() {
    final next = widget.nextDoc;
    if (next == null) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(builder: (_) => DocReaderScreen(repo: widget.repo, docId: next.id)));
  }

  @override
  Widget build(BuildContext context) {
    final desktop = MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop;
    final content = _content();
    if (desktop) {
      return Scaffold(
        backgroundColor: AppColors.text.withAlpha(115),
        body: Center(
          child: Container(
            width: 480,
            padding: const EdgeInsets.all(AppSpace.xxxl),
            decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(AppRadius.slide)),
            child: content,
          ),
        ),
      );
    }
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(padding: const EdgeInsets.all(AppSpace.xxl), child: content),
        ),
      ),
    );
  }

  Widget _content() {
    final r = widget.result;
    final vocabCount = widget.doc.allVocab.length;
    final passed = r.stageDone >= r.stageGoal;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ExcludeSemantics(
          child: SizedBox(
            width: 160,
            height: 160,
            child: AnimatedBuilder(
              animation: _jump,
              builder: (_, __) => CustomPaint(painter: _JumpingKoiPainter(t: _jump.value)),
            ),
          ),
        ),
        const SizedBox(height: AppSpace.lg),
        Text('Hoàn thành Tài liệu ${widget.doc.order}!', textAlign: TextAlign.center, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: -0.5, color: AppColors.text)),
        const SizedBox(height: AppSpace.sm),
        Text(
          r.completedNow ? 'Cá chép tiến thêm một chặng trên thác Vũ Môn.' : 'Bạn đã học xong tài liệu này trước đó.',
          textAlign: TextAlign.center,
          style: AppText.body.copyWith(color: AppColors.textMuted),
        ),
        const SizedBox(height: AppSpace.lg),
        Semantics(
          label: 'Tuần này ${r.stageDone} trên ${r.stageGoal} chặng',
          excludeSemantics: true,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(color: passed ? AppColors.gold : AppColors.border, width: passed ? 1.5 : 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < r.stageGoal; i++)
                  Container(
                    margin: const EdgeInsets.only(right: 5),
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < r.stageDone ? AppColors.primary : AppColors.border,
                      boxShadow: r.completedNow && i == r.stageDone - 1
                          ? const [BoxShadow(color: AppColors.surface, spreadRadius: 2), BoxShadow(color: AppColors.primary, spreadRadius: 3.5)]
                          : null,
                    ),
                  ),
                const SizedBox(width: 4),
                Text(
                  passed ? 'Đã vượt vũ môn tuần này!' : 'Tuần này ${r.stageDone}/${r.stageGoal} chặng',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpace.xxl),
        if (vocabCount > 0) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton(
              onPressed: _saving || _savedCount != null ? null : _saveVocab,
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card))),
              child: Text(_savedCount != null ? 'Đã lưu $vocabCount từ vào Sổ từ' : (_saving ? 'Đang lưu…' : 'Lưu $vocabCount từ vựng của bài vào Sổ từ')),
            ),
          ),
          const SizedBox(height: 10),
        ],
        SizedBox(
          width: double.infinity,
          height: 52,
          child: FilledButton(
            onPressed: widget.nextDoc == null ? () => Navigator.of(context).maybePop() : _openNext,
            style: FilledButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.card))),
            child: Text(widget.nextDoc == null ? 'Về danh sách tuần' : 'Học Tài liệu ${widget.nextDoc!.order} →', style: const TextStyle(fontSize: 16)),
          ),
        ),
        if (widget.nextDoc != null) ...[
          const SizedBox(height: 6),
          TextButton(onPressed: () => Navigator.of(context).maybePop(), child: const Text('Về danh sách tuần')),
        ],
      ],
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
        ..color = AppColors.surface,
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
