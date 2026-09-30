import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/theme/app_colors.dart';

import 'package:frontend/features/documents/presentation/bloc/weekly_documents_bloc.dart';

class WeeklyDocumentsPage extends StatelessWidget {
  const WeeklyDocumentsPage({super.key});

  static const _dayNames = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Weekly Lessons',
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          BlocBuilder<WeeklyDocumentsBloc, WeeklyDocumentsState>(
            builder: (context, state) {
              return Row(
                children: [
                  const Text(
                    'Week: ',
                    style: TextStyle(fontSize: 15, color: AppColors.textPrimary),
                  ),
                  DropdownButton<int>(
                    value: state.selectedWeek,
                    items: List.generate(52, (i) => i + 1)
                        .map((w) => DropdownMenuItem(value: w, child: Text('Week $w')))
                        .toList(),
                    onChanged: (week) {
                      if (week != null) {
                        context.read<WeeklyDocumentsBloc>().add(LoadDocuments(week: week));
                      }
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BlocBuilder<WeeklyDocumentsBloc, WeeklyDocumentsState>(
              builder: (context, state) {
                if (state.loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state.error != null) {
                  return Center(
                    child: Text(state.error!, style: const TextStyle(color: Colors.red)),
                  );
                }
                if (state.lessons.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.school_outlined, size: 48, color: AppColors.textSecondary),
                        SizedBox(height: 12),
                        Text('No lessons for this week',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 15)),
                      ],
                    ),
                  );
                }
                return _buildDayGrid(state.lessons, isMobile);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayGrid(List<Lesson> lessons, bool isMobile) {
    final lessonsByDay = <int, List<Lesson>>{};
    for (final lesson in lessons) {
      final day = lesson.dayOfWeek ?? 1;
      lessonsByDay.putIfAbsent(day, () => []).add(lesson);
    }

    return ListView.builder(
      padding: EdgeInsets.zero,
      itemCount: 7,
      itemBuilder: (context, index) {
        final dayNumber = index + 1;
        final dayLessons = lessonsByDay[dayNumber] ?? [];
        return _DayCard(
          dayName: _dayNames[index],
          lessons: dayLessons,
        );
      },
    );
  }
}

class _DayCard extends StatelessWidget {
  final String dayName;
  final List<Lesson> lessons;

  const _DayCard({required this.dayName, required this.lessons});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              dayName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            if (lessons.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'No lessons',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary.withOpacity(0.6)),
                ),
              )
            else ...[
              const SizedBox(height: 10),
              ...lessons.map((lesson) => _LessonChip(lesson: lesson)),
            ],
          ],
        ),
      ),
    );
  }
}

class _LessonChip extends StatelessWidget {
  final Lesson lesson;

  const _LessonChip({required this.lesson});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              lesson.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ),
          if (lesson.level != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                lesson.level!,
                style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
    );
  }
}
