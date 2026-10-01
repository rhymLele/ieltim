import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/widgets/word_of_day_card.dart';
import 'package:frontend/core/widgets/your_pond_card.dart';
import 'package:frontend/features/wordbook/presentation/bloc/wordbook_bloc.dart';

/// Greeting for the dashboard heading based on the hour of [time].
String greetingFor(DateTime time) {
  final hour = time.hour;
  if (hour >= 5 && hour < 12) return 'Good morning';
  if (hour >= 12 && hour < 18) return 'Good afternoon';
  return 'Good evening';
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => WordbookBloc()..add(LoadWordbook()),
      child: const _HomeContent(),
    );
  }
}

class _HomeContent extends StatelessWidget {
  const _HomeContent();

  static const _quickCards = [
    _QuickCard(
      icon: Icons.calendar_month,
      title: 'Weekly Documents',
      subtitle: 'Browse by week and day',
      route: '/weekly',
    ),
    _QuickCard(
      icon: Icons.translate,
      title: 'Vocabulary',
      subtitle: 'Explore vocabulary lists',
      route: '/search?type=vocabulary',
    ),
    _QuickCard(
      icon: Icons.format_quote,
      title: 'Sentence Patterns',
      subtitle: 'Useful structures',
      route: '/search?type=sentence_pattern',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 768;
        final padding = compact ? 16.0 : 32.0;
        final contentWidth = constraints.maxWidth - padding * 2;
        final sideBySide = contentWidth >= 900;
        final scroll = !sideBySide || constraints.maxHeight < 760;
        final heading = <Widget>[
          Text(
            greetingFor(DateTime.now()),
            style: TextStyle(
              fontSize: compact ? 22 : 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your personal knowledge base for IELTS preparation.',
            style: TextStyle(
              fontSize: compact ? 14 : 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          if (contentWidth < 650)
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _quickCards[0],
                const SizedBox(height: 12),
                _quickCards[1],
                const SizedBox(height: 12),
                _quickCards[2],
              ],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _quickCards[0]),
                const SizedBox(width: 16),
                Expanded(child: _quickCards[1]),
                const SizedBox(width: 16),
                Expanded(child: _quickCards[2]),
              ],
            ),
          const SizedBox(height: 24),
        ];
        final cards = _LearningCards(sideBySide: sideBySide);

        if (scroll) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...heading,
                if (sideBySide) SizedBox(height: 460, child: cards) else cards,
              ],
            ),
          );
        }
        return Padding(
          padding: EdgeInsets.all(padding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...heading,
              Expanded(child: cards),
            ],
          ),
        );
      },
    );
  }
}

class _LearningCards extends StatelessWidget {
  const _LearningCards({required this.sideBySide});

  final bool sideBySide;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WordbookBloc, WordbookState>(
      builder: (context, state) {
        final word = WordOfDayData.forDate(DateTime.now());
        final saved = state.items
            .where((item) => item.word.toLowerCase() == word.word.toLowerCase())
            .firstOrNull;
        final pond = YourPondCard(
          // Keep zero until real study streak tracking is available.
          streakDays: 0,
          savedWords: state.items.length,
          // Side by side the row always has a bounded height (460 when the
          // page scrolls), so the pond fills it; stacked it needs its own.
          pondHeight: sideBySide ? null : 260,
        );
        final wordCard = WordOfDayCard(
          word: word,
          isSaved: saved != null,
          onSaveChanged: (save) {
            final bloc = context.read<WordbookBloc>();
            if (!save && saved != null) {
              bloc.add(DeleteWord(saved.id));
            } else if (save && saved == null) {
              final now = DateTime.now();
              bloc.add(
                AddWord(
                  LocalWordbookItem(
                    id: 'word-of-day:${word.word.toLowerCase()}',
                    word: word.word,
                    meaning: word.meaningVi,
                    example: word.example,
                    note: '${word.ipa} · ${word.partOfSpeech}',
                    sourceReferenceType: SourceType.manual,
                    createdAt: now,
                    updatedAt: now,
                  ),
                ),
              );
            }
          },
        );

        if (sideBySide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(flex: 2, child: pond),
              const SizedBox(width: 16),
              Expanded(child: wordCard),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            pond,
            const SizedBox(height: 16),
            SizedBox(height: 400, child: wordCard),
          ],
        );
      },
    );
  }
}

class _QuickCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;

  const _QuickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => context.go(route),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 32, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
