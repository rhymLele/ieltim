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

String _greetingVi(DateTime time) {
  final hour = time.hour;
  if (hour >= 5 && hour < 12) return 'Chào buổi sáng';
  if (hour >= 12 && hour < 18) return 'Chào buổi chiều';
  return 'Chào buổi tối';
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

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 840;
        if (isMobile) return const _MobileHome();
        return _DesktopHome(constraints: constraints);
      },
    );
  }
}

// ─── Mobile Home ─────────────────────────────────────────────────────────────

class _MobileHome extends StatelessWidget {
  const _MobileHome();

  static const _border = Color(0xFFEFDCCB);
  static const _textPrimary = Color(0xFF2A1418);
  static const _textSecondary = Color(0xFF6B4A4F);

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Greeting
        Text(
          '${_greetingVi(DateTime.now())}, User',
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Hôm nay học gì nào?',
          style: const TextStyle(
            fontSize: 14,
            color: _textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        // Word of the day
        BlocBuilder<WordbookBloc, WordbookState>(
          builder: (context, state) {
            final word = WordOfDayData.forDate(DateTime.now());
            final saved = state.items
                .where((item) => item.word.toLowerCase() == word.word.toLowerCase())
                .firstOrNull;
            return SizedBox(
              height: 380,
              child: WordOfDayCard(
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
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        // Your pond
        BlocBuilder<WordbookBloc, WordbookState>(
          builder: (context, state) {
            return YourPondCard(
              streakDays: 0,
              savedWords: state.items.length,
              pondHeight: 190,
            );
          },
        ),
        const SizedBox(height: 16),
        // Features grid
        const Text(
          'CHỨC NĂNG',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: _textSecondary,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        BlocBuilder<WordbookBloc, WordbookState>(
          builder: (context, state) {
            final wordCount = state.items.length;
            return GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _MobileFeatureTile(
                  icon: Icons.calendar_month,
                  title: 'Theo tuần',
                  subtitle: 'Tài liệu theo tuần',
                  route: '/weekly',
                ),
                _MobileFeatureTile(
                  icon: Icons.book_outlined,
                  title: 'Sổ từ',
                  subtitle: 'Từ vựng của bạn',
                  route: '/wordbook',
                  badge: wordCount,
                ),
                _MobileFeatureTile(
                  icon: Icons.format_quote,
                  title: 'Mẫu câu',
                  subtitle: 'Cấu trúc câu hay',
                  route: '/search?type=sentence_pattern',
                ),
                _MobileFeatureTile(
                  icon: Icons.description,
                  title: 'Tài liệu web',
                  subtitle: 'Nguồn tài liệu',
                  route: '/resources',
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _MobileFeatureTile extends StatelessWidget {
  const _MobileFeatureTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    this.badge,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final int? badge;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => context.go(route),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _MobileHome._border),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Icon(icon, size: 24, color: AppColors.primary),
                    if (badge != null && badge! > 0)
                      Positioned(
                        right: -6,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 5,
                            vertical: 2,
                          ),
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.all(
                              Radius.circular(10),
                            ),
                          ),
                          child: Text(
                            badge.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: _MobileHome._textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _MobileHome._textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Desktop Home ────────────────────────────────────────────────────────────

class _DesktopHome extends StatelessWidget {
  const _DesktopHome({required this.constraints});

  final BoxConstraints constraints;

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
    final padding = 32.0;
    final contentWidth = constraints.maxWidth - padding * 2;
    final sideBySide = contentWidth >= 900;
    final scroll = !sideBySide || constraints.maxHeight < 760;
    final heading = <Widget>[
      Text(
        greetingFor(DateTime.now()),
        style: const TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppColors.textPrimary,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        'Your personal knowledge base for IELTS preparation.',
        style: const TextStyle(
          fontSize: 16,
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
          streakDays: 0,
          savedWords: state.items.length,
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
