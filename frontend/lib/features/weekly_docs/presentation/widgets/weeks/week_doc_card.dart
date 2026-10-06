import 'package:flutter/material.dart';

import '../../../core/app_tokens.dart';
import '../../../domain/entities/learner_doc.dart';
import '../../../domain/entities/weekly_doc.dart';
import '../common_widgets.dart';

/// Thẻ một tài liệu / bài tập trong tuần: kiểu xem, số phần, số phút, trạng thái học; bài tập có tag HOMEWORK.
class WeekDocCard extends StatelessWidget {
  const WeekDocCard({super.key, required this.entry, required this.onTap});

  final WeekDocEntry entry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final doc = entry.summary;
    final progress = entry.progress;
    final total = doc.sectionCount;
    final done = progress.completed;
    final seen = done ? total : progress.seenCount.clamp(0, total);
    final status = done ? 'Đã học' : (seen == 0 ? 'Chưa học' : 'Đang học $seen/$total');
    final statusColor = done ? AppColors.success : (seen == 0 ? AppColors.textMuted : AppColors.primary);
    final isSlide = doc.defaultView == DocViewMode.slide;
    // Tài liệu HTML chỉ có 2 trạng thái: Chưa học / Đã học.
    final kind = doc.isHtml ? 'HTML · tự trình chiếu' : '${isSlide ? 'Slide' : 'Doc'} · $total phần · khoảng ${doc.estimatedMinutes} phút';
    final icon = doc.isHtml ? Icons.code_rounded : (isSlide ? Icons.slideshow_outlined : Icons.description_outlined);
    return AppCard(
      key: Key('weekly_docs_doc_${doc.id}_card'),
      radius: AppRadius.cardLg,
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(color: done ? AppColors.successBg : AppColors.sidebar, borderRadius: BorderRadius.circular(AppRadius.lg)),
                child: Icon(icon, color: done ? AppColors.success : AppColors.primary),
              ),
              const SizedBox(width: AppSpace.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${doc.numberLabel} · ${skillLabels[doc.skill] ?? doc.skill}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.caption.copyWith(fontWeight: FontWeight.w700),
                          ),
                        ),
                        if (doc.isHomework) ...[const SizedBox(width: 6), const HomeworkTag()],
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(doc.title, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, height: 1.25, fontWeight: FontWeight.w800, color: AppColors.textInk)),
                    const SizedBox(height: 3),
                    Text(kind, style: AppText.caption),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: PillProgress(value: done ? 1 : (total == 0 ? 0 : seen / total), color: done ? AppColors.success : AppColors.primary)),
              const SizedBox(width: 10),
              Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: statusColor)),
            ],
          ),
        ],
      ),
    );
  }
}

/// Lưới thẻ cho desktop (2 cột, ≥ 1200px thì 3 cột).
class WeekDocGrid extends StatelessWidget {
  const WeekDocGrid({super.key, required this.entries, required this.screenWidth, required this.onOpen});

  final List<WeekDocEntry> entries;
  final double screenWidth;
  final ValueChanged<WeekDocEntry> onOpen;

  @override
  Widget build(BuildContext context) {
    final cols = screenWidth >= 1200 ? 3 : 2;
    return LayoutBuilder(builder: (context, c) {
      const gap = 16.0;
      final width = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [
          for (final e in entries) SizedBox(width: width, child: WeekDocCard(entry: e, onTap: () => onOpen(e))),
        ],
      );
    });
  }
}
