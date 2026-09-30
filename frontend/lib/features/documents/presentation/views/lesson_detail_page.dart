import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:frontend/core/theme/app_colors.dart';

import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/wordbook/presentation/bloc/wordbook_bloc.dart';

class LessonDetailPage extends StatefulWidget {
  final String lessonId;

  const LessonDetailPage({super.key, required this.lessonId});

  @override
  State<LessonDetailPage> createState() => _LessonDetailPageState();
}

class _LessonDetailPageState extends State<LessonDetailPage> {
  Map<String, dynamic>? _lesson;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLesson();
  }

  Future<void> _loadLesson() async {
    try {
      final res = await ApiClient().get('/lessons/${widget.lessonId}');
      setState(() {
        _lesson = res.data as Map<String, dynamic>;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load lesson';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(isMobile ? 16 : 32),
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(child: Text(_error!, style: const TextStyle(color: Colors.red)))
                  : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildContent() {
    final lesson = _lesson!;
    final summary = lesson['summary'] as Map<String, dynamic>? ?? {};

    return ListView(
      children: [
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                lesson['title'] ?? '',
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
            ),
          ],
        ),
        if (lesson['studyDate'] != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              lesson['studyDate'].toString(),
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ),
        const SizedBox(height: 8),
        Row(
          children: [
            if (lesson['level'] != null) _Badge(text: lesson['level']!, color: AppColors.primary),
            ...((lesson['topics'] as List? ?? [])
                .map((t) => _Badge(text: t is Map ? t['name']?.toString() ?? '' : t.toString(), color: AppColors.secondary))
                .toList()),
            ...((lesson['contexts'] as List? ?? [])
                .map((c) => _Badge(text: c is Map ? c['name']?.toString() ?? '' : c.toString(), color: const Color(0xFF2E7D32)))
                .toList()),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _SummaryItem(label: 'Vocabulary', count: summary['vocabularyCount'] ?? 0),
              _SummaryItem(label: 'Patterns', count: summary['patternCount'] ?? 0),
              _SummaryItem(label: 'Theory', count: summary['theoryCount'] ?? 0),
              _SummaryItem(label: 'Practice', count: summary['practiceCount'] ?? 0),
            ],
          ),
        ),
        const SizedBox(height: 24),
        if (lesson['description'] != null && (lesson['description'] as String).isNotEmpty) ...[
          _SectionHeader(title: 'Overview'),
          const SizedBox(height: 8),
          _Card(
            child: Text(
              lesson['description'],
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.6),
            ),
          ),
          const SizedBox(height: 24),
        ],
        _SectionHeader(title: 'Vocabulary', count: (lesson['vocabulary'] as List? ?? []).length),
        const SizedBox(height: 12),
        ...((lesson['vocabulary'] as List? ?? []).map((v) => _VocabularyCard(data: v as Map<String, dynamic>))),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Sentence Patterns', count: (lesson['sentencePatterns'] as List? ?? []).length),
        const SizedBox(height: 12),
        ...((lesson['sentencePatterns'] as List? ?? []).map((p) => _SentencePatternCard(data: p as Map<String, dynamic>))),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Theory', count: (lesson['theory'] as List? ?? []).length),
        const SizedBox(height: 12),
        ...((lesson['theory'] as List? ?? []).map((t) => _TheoryBlock(data: t as Map<String, dynamic>))),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Practice', count: (lesson['practice'] as List? ?? []).length),
        const SizedBox(height: 12),
        ...((lesson['practice'] as List? ?? []).map((p) => _PracticeQuestion(data: p as Map<String, dynamic>))),
        const SizedBox(height: 32),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color color;

  const _Badge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final int count;

  const _SummaryItem({required this.label, required this.count});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text('$count', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int? count;

  const _SectionHeader({required this.title, this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        if (count != null && count! > 0)
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text(
              '($count)',
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;

  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _VocabularyCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _VocabularyCard({required this.data});

  void _saveToWordbook(BuildContext context) {
    final now = DateTime.now();
    final collocations = (data['collocations'] as List? ?? [])
        .map((c) => c is Map ? c['phrase']?.toString() ?? '' : c.toString())
        .where((s) => s.isNotEmpty)
        .join(', ');
    final item = LocalWordbookItem(
      id: '${now.microsecondsSinceEpoch}',
      word: data['term'] ?? '',
      meaning: data['vietnameseMeaning'],
      definition: data['definition'],
      example: data['example'],
      level: data['level']?.toString(),
      collocations: collocations.isEmpty ? null : collocations,
      sourceReferenceId: data['id'],
      sourceReferenceType: SourceType.vocabulary,
      createdAt: now,
      updatedAt: now,
    );
    WordbookRepository().save(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('"${data['term']}" added to wordbook'), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final collocations = (data['collocations'] as List? ?? [])
        .map((c) => c is Map ? c['phrase']?.toString() ?? '' : c.toString())
        .where((s) => s.isNotEmpty)
        .toList();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data['term'] ?? '',
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
              ),
              if (data['level'] != null)
                _Badge(text: data['level'].toString(), color: AppColors.primary),
              IconButton(
                icon: const Icon(Icons.bookmark_add_outlined, size: 16, color: AppColors.textSecondary),
                tooltip: 'Save to wordbook',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _saveToWordbook(context),
              ),
            ],
          ),
          if (data['definition'] != null) ...[
            const SizedBox(height: 8),
            Text(
              data['definition'].toString(),
              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
            ),
          ],
          if (data['vietnameseMeaning'] != null && (data['vietnameseMeaning'] as String).isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              data['vietnameseMeaning'].toString(),
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
            ),
          ],
          if (data['example'] != null && (data['example'] as String).isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                data['example'].toString(),
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontStyle: FontStyle.italic),
              ),
            ),
          ],
          if (collocations.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text('Collocations:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: collocations.map((c) => _Badge(text: c, color: AppColors.secondary)).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _SentencePatternCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _SentencePatternCard({required this.data});

  void _saveToWordbook(BuildContext context) {
    final now = DateTime.now();
    final item = LocalWordbookItem(
      id: '${now.microsecondsSinceEpoch}',
      word: data['pattern'] ?? '',
      meaning: data['meaning'],
      definition: data['usage'],
      example: data['example'],
      level: data['level']?.toString(),
      sourceReferenceId: data['id'],
      sourceReferenceType: SourceType.sentencePattern,
      createdAt: now,
      updatedAt: now,
    );
    WordbookRepository().save(item);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: const Text('Pattern saved to wordbook'), duration: const Duration(seconds: 2)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  data['pattern'] ?? '',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              if (data['level'] != null)
                _Badge(text: data['level'].toString(), color: AppColors.primary),
              IconButton(
                icon: const Icon(Icons.bookmark_add_outlined, size: 16, color: AppColors.textSecondary),
                tooltip: 'Save to wordbook',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => _saveToWordbook(context),
              ),
            ],
          ),
          if (data['meaning'] != null && (data['meaning'] as String).isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              data['meaning'].toString(),
              style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
          if (data['example'] != null && (data['example'] as String).isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                data['example'].toString(),
                style: const TextStyle(fontSize: 12, color: AppColors.textPrimary, fontStyle: FontStyle.italic),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TheoryBlock extends StatelessWidget {
  final Map<String, dynamic> data;

  const _TheoryBlock({required this.data});

  @override
  Widget build(BuildContext context) {
    final type = data['type']?.toString() ?? 'paragraph';
    final content = data['content']?.toString() ?? '';

    switch (type) {
      case 'heading':
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            content,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
        );
      case 'bullet_list':
        final items = content.split('\n').where((l) => l.trim().isNotEmpty).toList();
        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: items
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('• ', style: TextStyle(color: AppColors.primary)),
                          Expanded(
                            child: Text(
                              item.trim().replaceAll(RegExp(r'^[-•]\s*'), ''),
                              style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        );
      case 'callout':
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.04),
            borderRadius: BorderRadius.circular(8),
            border: Border(
              left: BorderSide(color: AppColors.primary.withOpacity(0.4), width: 3),
            ),
          ),
          child: Text(
            content,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.5),
          ),
        );
      default:
        return _Card(
          child: Text(
            content,
            style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, height: 1.6),
          ),
        );
    }
  }
}

class _PracticeQuestion extends StatefulWidget {
  final Map<String, dynamic> data;

  const _PracticeQuestion({required this.data});

  @override
  State<_PracticeQuestion> createState() => _PracticeQuestionState();
}

class _PracticeQuestionState extends State<_PracticeQuestion> {
  bool _showAnswer = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.data;
    final type = data['type']?.toString() ?? 'short_answer';
    final hasAnswer = data['suggestedAnswer'] != null && (data['suggestedAnswer'] as String).isNotEmpty;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _Badge(text: type.replaceAll('_', ' '), color: AppColors.secondary),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            data['question']?.toString() ?? '',
            style: const TextStyle(fontSize: 14, color: AppColors.textPrimary, height: 1.5),
          ),
          if (hasAnswer) ...[
            const SizedBox(height: 12),
            if (_showAnswer)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E7D32).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: const Color(0xFF2E7D32).withOpacity(0.2)),
                ),
                child: Text(
                  'Suggested: ${data['suggestedAnswer']}',
                  style: const TextStyle(fontSize: 13, color: Color(0xFF2E7D32)),
                ),
              )
            else
              TextButton.icon(
                onPressed: () => setState(() => _showAnswer = true),
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('Show Answer'),
                style: TextButton.styleFrom(foregroundColor: AppColors.primary),
              ),
          ],
        ],
      ),
    );
  }
}
