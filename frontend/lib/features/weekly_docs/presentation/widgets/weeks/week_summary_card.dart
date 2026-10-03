import 'package:flutter/material.dart';

import '../../../core/app_tokens.dart';
import '../../../domain/entities/week_info.dart';
import '../common_widgets.dart';

/// Thẻ đỏ đầu màn: tuần đang chọn, khoảng ngày, tiến độ x/y tài liệu.
class WeekSummaryCard extends StatelessWidget {
  const WeekSummaryCard({super.key, required this.week, required this.done, required this.total, required this.desktop});

  final WeekInfo week;
  final int done;
  final int total;
  final bool desktop;

  static const _title = TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onPrimary);
  static const _caption = TextStyle(fontSize: 12, color: AppColors.softOnPrimary);

  @override
  Widget build(BuildContext context) {
    final bar = PillProgress(value: total == 0 ? 0 : done / total, height: 8, color: AppColors.goldLight, track: AppColors.onPrimary.withAlpha(51));
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg),
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(AppRadius.cardLg)),
      child: desktop
          ? Row(
              children: [
                Text('Tuần ${week.number}', style: _title),
                const SizedBox(width: AppSpace.md),
                Text(week.rangeLabel, style: _caption),
                const SizedBox(width: AppSpace.xxl),
                Expanded(child: bar),
                const SizedBox(width: AppSpace.lg),
                Text('$done/$total tài liệu đã học · Học xong tuần để vượt vũ môn', style: _caption),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text('Tuần ${week.number}', style: _title),
                    const Spacer(),
                    Text(week.rangeLabel, style: _caption),
                  ],
                ),
                const SizedBox(height: 10),
                bar,
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text('$done/$total tài liệu đã học', style: _caption),
                    const Spacer(),
                    const Flexible(child: Text('Học xong tuần để vượt vũ môn', textAlign: TextAlign.right, style: _caption)),
                  ],
                ),
              ],
            ),
    );
  }
}
