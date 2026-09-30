import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_colors.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome to IELTS Knowledge Hub',
            style: TextStyle(
              fontSize: isMobile ? 22 : 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your personal knowledge base for IELTS preparation.',
            style: TextStyle(
              fontSize: isMobile ? 14 : 16,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 32),
          if (isMobile)
            Column(
              children: [
                _QuickCard(
                  icon: Icons.calendar_month,
                  title: 'Weekly Documents',
                  subtitle: 'Browse by week and day',
                  route: '/weekly',
                ),
                const SizedBox(height: 12),
                _QuickCard(
                  icon: Icons.translate,
                  title: 'Vocabulary',
                  subtitle: 'Explore vocabulary lists',
                  route: '/search?type=vocabulary',
                ),
                const SizedBox(height: 12),
                _QuickCard(
                  icon: Icons.format_quote,
                  title: 'Sentence Patterns',
                  subtitle: 'Useful structures',
                  route: '/search?type=sentence_pattern',
                ),
              ],
            )
          else
            Row(
              children: [
                Expanded(
                  child: _QuickCard(
                    icon: Icons.calendar_month,
                    title: 'Weekly Documents',
                    subtitle: 'Browse by week and day',
                    route: '/weekly',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _QuickCard(
                    icon: Icons.translate,
                    title: 'Vocabulary',
                    subtitle: 'Explore vocabulary lists',
                    route: '/search?type=vocabulary',
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _QuickCard(
                    icon: Icons.format_quote,
                    title: 'Sentence Patterns',
                    subtitle: 'Useful structures',
                    route: '/search?type=sentence_pattern',
                  ),
                ),
              ],
            ),
        ],
      ),
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
