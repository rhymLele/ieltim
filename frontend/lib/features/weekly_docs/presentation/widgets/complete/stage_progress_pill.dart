import 'package:flutter/material.dart';

import '../../../core/app_tokens.dart';
import '../../../domain/entities/learning_results.dart';

/// Viên "Tuần này 3/5 chặng": mỗi chặng một chấm, chấm vừa đạt có viền nổi.
class StageProgressPill extends StatelessWidget {
  const StageProgressPill({super.key, required this.result});

  final CompleteResult result;

  @override
  Widget build(BuildContext context) {
    final r = result;
    final passed = r.stageDone >= r.stageGoal;
    return Semantics(
      label: 'Tuần này ${r.stageDone} trên ${r.stageGoal} chặng',
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.cardSurface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: passed ? AppColors.gold : AppColors.borderLight, width: passed ? 1.5 : 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < r.stageGoal; i++) _StageDot(done: i < r.stageDone, justReached: r.completedNow && i == r.stageDone - 1),
            const SizedBox(width: 4),
            Text(
              passed ? 'Đã vượt vũ môn tuần này!' : 'Tuần này ${r.stageDone}/${r.stageGoal} chặng',
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageDot extends StatelessWidget {
  const _StageDot({required this.done, required this.justReached});

  final bool done;
  final bool justReached;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 5),
      width: 10,
      height: 10,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: done ? AppColors.primary : AppColors.borderLight,
        boxShadow: justReached ? const [BoxShadow(color: AppColors.cardSurface, spreadRadius: 2), BoxShadow(color: AppColors.primary, spreadRadius: 3.5)] : null,
      ),
    );
  }
}
