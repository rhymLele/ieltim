import 'package:flutter/material.dart';

import '../../../core/app_tokens.dart';
import '../../../domain/entities/learner_doc.dart';
import '../../../domain/entities/week_info.dart';
import '../common_widgets.dart';

/// Số đã học / tổng của từng loại trong tuần đang chọn.
class WeekProgressCounts {
  const WeekProgressCounts({this.lessonDone = 0, this.lessonTotal = 0, this.homeworkDone = 0, this.homeworkTotal = 0});

  factory WeekProgressCounts.of(List<WeekDocEntry> entries) {
    final lessons = entries.where((e) => !e.summary.isHomework).toList();
    final homework = entries.where((e) => e.summary.isHomework).toList();
    int doneOf(List<WeekDocEntry> list) => list.where((e) => e.progress.completed).length;
    return WeekProgressCounts(
      lessonDone: doneOf(lessons),
      lessonTotal: lessons.length,
      homeworkDone: doneOf(homework),
      homeworkTotal: homework.length,
    );
  }

  final int lessonDone;
  final int lessonTotal;
  final int homeworkDone;
  final int homeworkTotal;

  int get done => lessonDone + homeworkDone;
  int get total => lessonTotal + homeworkTotal;

  /// "1/2 tài liệu · 0/1 bài tập"; tuần không có bài tập thì chỉ phần tài liệu.
  String get label => [
        '$lessonDone/$lessonTotal tài liệu',
        if (homeworkTotal > 0) '$homeworkDone/$homeworkTotal bài tập',
      ].join(' · ');
}

/// Thẻ đỏ đầu màn: tuần đang chọn, khoảng ngày, tiến độ tài liệu và bài tập.
class WeekSummaryCard extends StatelessWidget {
  const WeekSummaryCard({super.key, required this.week, required this.counts, required this.desktop});

  final WeekInfo week;
  final WeekProgressCounts counts;
  final bool desktop;

  static const _title = TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.onPrimary);
  static const _caption = TextStyle(fontSize: 12, color: AppColors.softOnPrimary);

  @override
  Widget build(BuildContext context) {
    final bar = PillProgress(
      value: counts.total == 0 ? 0 : counts.done / counts.total,
      height: 8,
      color: AppColors.goldLight,
      track: AppColors.onPrimary.withAlpha(51),
    );
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
                // Có thêm bài tập thì dòng dài ra: cho xuống dòng thay vì tràn.
                Flexible(child: Text('${counts.label} đã học · Học xong tuần để vượt vũ môn', textAlign: TextAlign.right, style: _caption)),
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
                // Vừa một dòng thì hai đầu, không vừa thì câu nhắc xuống dòng dưới (không bẻ đôi từng câu).
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  spacing: AppSpace.sm,
                  runSpacing: 4,
                  children: [
                    Text('${counts.label} đã học', style: _caption),
                    const Text('Học xong tuần để vượt vũ môn', style: _caption),
                  ],
                ),
              ],
            ),
    );
  }
}
