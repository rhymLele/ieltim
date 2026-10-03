// common_widgets.dart — Thành phần nhỏ dùng chung trong feature.

import 'package:flutter/material.dart';

import '../../core/app_tokens.dart';
import '../../data/weekly_docs_repository.dart';
import '../../domain/weekly_doc.dart';

/// Nhãn section: huy hiệu số + tên section viết hoa.
class SectionLabel extends StatelessWidget {
  const SectionLabel({super.key, required this.number, required this.title, this.size = 24, this.fontSize = 11});
  final int number;
  final String title;
  final double size;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          constraints: BoxConstraints(minWidth: size),
          height: size,
          padding: const EdgeInsets.symmetric(horizontal: 6),
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.pill)),
          child: Text('$number', style: TextStyle(color: AppColors.onPrimary, fontSize: size * 0.46, fontWeight: FontWeight.w800)),
        ),
        const SizedBox(width: AppSpace.sm),
        Flexible(
          child: Text(
            title.toUpperCase(),
            overflow: TextOverflow.ellipsis,
            style: AppText.eyebrow.copyWith(fontSize: fontSize, letterSpacing: fontSize * 0.12),
          ),
        ),
      ],
    );
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: AppText.eyebrow);
}

/// Thanh tiến độ bo tròn.
class PillProgress extends StatelessWidget {
  const PillProgress({super.key, required this.value, this.height = 6, this.color = AppColors.primary, this.track = AppColors.sidebar});
  final double value;
  final double height;
  final Color color;
  final Color track;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Positioned.fill(child: ColoredBox(color: track)),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: AnimatedContainer(duration: motion(context, 400), color: color),
            ),
          ],
        ),
      ),
    );
  }
}

/// Segmented 2 lựa chọn Slide / Doc.
class ViewModeToggle extends StatelessWidget {
  const ViewModeToggle({
    super.key,
    required this.value,
    required this.onChanged,
    this.iconOnly = false,
    this.compact = false,
    this.order = const [DocViewMode.slide, DocViewMode.doc],
  });
  final DocViewMode value;
  final ValueChanged<DocViewMode> onChanged;
  final bool iconOnly;
  final bool compact;
  final List<DocViewMode> order;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'Kiểu xem',
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(color: AppColors.sidebar, borderRadius: BorderRadius.circular(compact ? AppRadius.md : AppRadius.lg)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [for (final m in order) _segment(context, m)],
        ),
      ),
    );
  }

  Widget _segment(BuildContext context, DocViewMode m) {
    final on = m == value;
    final icon = m == DocViewMode.slide ? Icons.slideshow_outlined : Icons.description_outlined;
    final label = m == DocViewMode.slide ? 'Slide' : 'Doc';
    final fg = on ? AppColors.onPrimary : AppColors.textMuted;
    return Tooltip(
      message: m == DocViewMode.slide ? 'Xem dạng slide' : 'Xem dạng tài liệu',
      child: Material(
        color: on ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(compact ? AppRadius.sm : 9),
        child: InkWell(
          borderRadius: BorderRadius.circular(compact ? AppRadius.sm : 9),
          onTap: () => onChanged(m),
          child: Container(
            height: compact ? 30 : (iconOnly ? 34 : 38),
            constraints: BoxConstraints(minWidth: iconOnly ? 38 : 0),
            padding: EdgeInsets.symmetric(horizontal: iconOnly ? 0 : (compact ? 12 : 16)),
            alignment: Alignment.center,
            child: iconOnly
                ? Icon(icon, size: 18, color: fg)
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!compact) ...[Icon(icon, size: 16, color: fg), const SizedBox(width: 8)],
                      Text(label, style: TextStyle(color: fg, fontSize: compact ? 12 : 14, fontWeight: FontWeight.w800)),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

/// Badge trạng thái tài liệu (admin).
class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status, this.suffix});
  final DocStatus status;
  final String? suffix;

  @override
  Widget build(BuildContext context) {
    final (fg, bg) = switch (status) {
      DocStatus.draft => (AppColors.textMuted, AppColors.sidebar),
      DocStatus.scheduled => (AppColors.warnText, AppColors.tipBg),
      DocStatus.published => (AppColors.success, AppColors.successBg),
      DocStatus.archived => (AppColors.archived, AppColors.archivedBg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: fg, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(suffix == null ? status.label : '${status.label} · $suffix', style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

/// Card trắng viền chuẩn.
class AppCard extends StatelessWidget {
  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(AppSpace.lg), this.radius = AppRadius.card, this.onTap, this.color = AppColors.surface, this.borderColor = AppColors.border});
  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final VoidCallback? onTap;
  final Color color;
  final Color borderColor;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(radius), side: BorderSide(color: borderColor));
    return Material(
      color: color,
      shape: shape,
      clipBehavior: Clip.antiAlias,
      child: onTap == null ? Padding(padding: padding, child: child) : InkWell(onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

/// Icon `</>` của tài liệu dạng HTML.
class HtmlFileBadge extends StatelessWidget {
  const HtmlFileBadge({super.key, this.size = 44});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: AppColors.codeBg, borderRadius: BorderRadius.circular(AppRadius.lg)),
      child: Text('</>', style: TextStyle(fontFamily: 'monospace', fontSize: size * 0.32, fontWeight: FontWeight.w800, color: AppColors.goldLight)),
    );
  }
}

/// Trạng thái rỗng / lỗi có minh hoạ lá sen.
class EmptyState extends StatelessWidget {
  const EmptyState({super.key, required this.message, this.actionLabel, this.onAction, this.isError = false});
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ExcludeSemantics(child: CustomPaint(size: const Size(72, 56), painter: _LilyPadPainter(isError: isError))),
            const SizedBox(height: AppSpace.md),
            Text(message, textAlign: TextAlign.center, style: AppText.body.copyWith(color: AppColors.textMuted)),
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpace.lg),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class _LilyPadPainter extends CustomPainter {
  _LilyPadPainter({required this.isError});
  final bool isError;
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width * 0.45, size.height * 0.55);
    final r = size.height * 0.42;
    final pad = Path()
      ..moveTo(c.dx, c.dy)
      ..arcTo(Rect.fromCircle(center: c, radius: r), -0.2, 5.9, false)
      ..close();
    canvas.drawPath(pad, Paint()..color = isError ? AppColors.borderStrong : const Color(0xFF9FB08F));
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.28), 7, Paint()..color = const Color(0xFFF4C7CF));
    canvas.drawCircle(Offset(size.width * 0.82, size.height * 0.28), 3, Paint()..color = AppColors.gold);
  }

  @override
  bool shouldRepaint(covariant _LilyPadPainter old) => old.isError != isError;
}

/// Khung xương (skeleton) nhấp nháy nhẹ.
class SkeletonBox extends StatefulWidget {
  const SkeletonBox({super.key, required this.height, this.width, this.radius = AppRadius.cardLg});
  final double height;
  final double? width;
  final double radius;

  @override
  State<SkeletonBox> createState() => _SkeletonBoxState();
}

class _SkeletonBoxState extends State<SkeletonBox> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduceMotionOf(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween(begin: 0.55, end: 1.0).animate(_c),
      child: Container(
        height: widget.height,
        width: widget.width,
        decoration: BoxDecoration(color: AppColors.sidebar, borderRadius: BorderRadius.circular(widget.radius)),
      ),
    );
  }
}
