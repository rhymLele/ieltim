import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/widgets/shimmer_loading.dart';
import 'package:frontend/features/search/presentation/bloc/search_bloc.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _search() {
    final query = _controller.text.trim();
    if (query.length >= 2) {
      context.read<SearchBloc>().add(PerformSearch(query: query));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Search',
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(
                    hintText: 'Search documents, vocabulary, sentence patterns...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _search,
                child: const Text('Search'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BlocBuilder<SearchBloc, SearchState>(
              builder: (context, state) {
                if (state.loading) {
                  return const ShimmerLoading(itemCount: 4);
                }
                if (state.query.isEmpty) {
                  return const Center(
                    child: Text(
                      'Type at least 2 characters and search',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }
                if (state.documents.isEmpty &&
                    state.vocabularies.isEmpty &&
                    state.sentencePatterns.isEmpty) {
                  return const Center(child: Text('No results found'));
                }
                return ListView(
                  children: [
                    if (state.documents.isNotEmpty) ...[
                      const _SectionLabel('Documents'),
                      ...state.documents.map((d) => _ResultCard(
                            title: d['title'] ?? '',
                            subtitle: d['description']?.toString() ?? '',
                          )),
                    ],
                    if (state.vocabularies.isNotEmpty) ...[
                      const _SectionLabel('Vocabulary'),
                      ...state.vocabularies.map((v) => _ResultCard(
                            title: v['term'] ?? '',
                            subtitle: v['definition']?.toString() ?? '',
                          )),
                    ],
                    if (state.sentencePatterns.isNotEmpty) ...[
                      const _SectionLabel('Sentence Patterns'),
                      ...state.sentencePatterns.map((sp) => _ResultCard(
                            title: sp['pattern'] ?? '',
                            subtitle: sp['meaning']?.toString() ?? '',
                          )),
                    ],
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 16),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _ResultCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            if (subtitle.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
