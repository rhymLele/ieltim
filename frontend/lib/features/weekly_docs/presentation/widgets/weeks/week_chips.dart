import 'package:flutter/material.dart';

import '../../../core/app_tokens.dart';
import '../../../domain/entities/week_info.dart';

/// Hàng chọn tuần (đã xong ✓ · tuần đang chọn · khoá). Tự cuộn tới tuần đang chọn.
class WeekChips extends StatefulWidget {
  const WeekChips({super.key, required this.weeks, required this.selectedWeek, required this.onSelected});

  final List<WeekInfo> weeks;
  final int selectedWeek;
  final ValueChanged<int> onSelected;

  @override
  State<WeekChips> createState() => _WeekChipsState();
}

class _WeekChipsState extends State<WeekChips> {
  static const _chipExtent = 92.0;
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void didUpdateWidget(WeekChips old) {
    super.didUpdateWidget(old);
    if (old.weeks.length != widget.weeks.length) WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToSelected());
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  void _scrollToSelected() {
    if (!mounted || !_scroll.hasClients) return;
    final i = widget.weeks.indexWhere((w) => w.number == widget.selectedWeek);
    _scroll.jumpTo((i * _chipExtent - 16).clamp(0.0, _scroll.position.maxScrollExtent));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: ListView.separated(
        controller: _scroll,
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: widget.weeks.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpace.sm),
        itemBuilder: (_, i) {
          final week = widget.weeks[i];
          return WeekChip(
            key: ValueKey(week.number),
            week: week,
            selected: week.number == widget.selectedWeek,
            onTap: week.isLocked ? null : () => widget.onSelected(week.number),
          );
        },
      ),
    );
  }
}

class WeekChip extends StatelessWidget {
  const WeekChip({super.key, required this.week, required this.selected, required this.onTap});

  final WeekInfo week;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final total = week.docTotal ?? 0;
    final done = week.docDone ?? 0;
    final allDone = total > 0 && done == total;
    final sub = week.isLocked ? week.opensLabel : (allDone && !selected ? '$done/$total ✓' : '$done/$total tài liệu');
    final bg = selected ? AppColors.primary : (week.isLocked ? AppColors.locked : AppColors.cardSurface);
    final fg = selected ? AppColors.onPrimary : (week.isLocked ? AppColors.textDisabled : AppColors.textInk);
    return Semantics(
      button: !week.isLocked,
      selected: selected,
      label: 'Tuần ${week.number}, $sub${week.isLocked ? ', chưa mở' : ''}',
      excludeSemantics: true,
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.card),
          side: BorderSide(color: selected ? AppColors.primary : AppColors.borderLight, width: 1.5),
        ),
        child: InkWell(
          key: Key('weekly_docs_week_${week.number}_chip'),
          borderRadius: BorderRadius.circular(AppRadius.card),
          onTap: onTap,
          child: Container(
            constraints: const BoxConstraints(minWidth: 84),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tuần ${week.number}', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: fg)),
                const SizedBox(height: 2),
                Text(sub, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg.withAlpha(217))),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
