import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/network/api_client.dart';

class DocumentDetailPage extends StatefulWidget {
  final String documentId;

  const DocumentDetailPage({super.key, required this.documentId});

  @override
  State<DocumentDetailPage> createState() => _DocumentDetailPageState();
}

class _DocumentDetailPageState extends State<DocumentDetailPage> {
  final _apiClient = ApiClient();
  Map<String, dynamic> _document = {};
  List<Map<String, dynamic>> _blocks = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      final docResponse = await _apiClient.get('/documents/${widget.documentId}');
      final blocksResponse =
          await _apiClient.get('/documents/${widget.documentId}/blocks');

      if (mounted) {
        setState(() {
          _document = Map<String, dynamic>.from(docResponse.data);
          final blocksData = blocksResponse.data;
          if (blocksData is Map && blocksData['data'] is List) {
            _blocks = (blocksData['data'] as List)
                .map((b) => Map<String, dynamic>.from(b as Map))
                .toList();
          } else if (blocksData is List) {
            _blocks = blocksData
                .map((b) => Map<String, dynamic>.from(b as Map))
                .toList();
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_document.isEmpty) {
      return const Center(child: Text('Document not found'));
    }

    final isMobile = MediaQuery.of(context).size.width < 1024;
    final headings = _blocks
        .where((b) => b['blockType'] == 'HEADING')
        .map((b) => (b['data'] as Map?)?['content'] ?? '')
        .where((h) => h.isNotEmpty)
        .toList();

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _document['title'] ?? 'Untitled',
            style: TextStyle(
              fontSize: isMobile ? 22 : 28,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          if (_document['description']?.toString().isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Text(
              _document['description'],
              style: TextStyle(
                fontSize: isMobile ? 14 : 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (!isMobile && headings.length > 1) ...[
            const SizedBox(height: 24),
            Container(
              width: 240,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Table of Contents',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...headings.asMap().entries.map(
                    (entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${entry.key + 1}. ${entry.value}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          ..._blocks.map((block) => _buildBlock(block)),
        ],
      ),
    );
  }

  Widget _buildBlock(Map<String, dynamic> block) {
    final type = block['blockType'] as String? ?? 'TEXT';
    final data = (block['data'] as Map?)?.cast<String, dynamic>() ?? {};

    switch (type) {
      case 'HEADING':
        return Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 12),
          child: Text(
            data['content'] ?? '',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
        );
      case 'TEXT':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text(
            data['content'] ?? '',
            style: const TextStyle(
              fontSize: 16,
              color: AppColors.textPrimary,
              height: 1.6,
            ),
          ),
        );
      case 'QUOTE':
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(8),
            border: const Border(
              left: BorderSide(color: AppColors.primary, width: 4),
            ),
          ),
          child: Text(
            data['content'] ?? '',
            style: const TextStyle(
              fontSize: 16,
              fontStyle: FontStyle.italic,
              color: AppColors.textPrimary,
            ),
          ),
        );
      case 'LINK':
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Row(
            children: [
              const Icon(Icons.link, size: 16, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  data['url'] ?? data['content'] ?? '',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        );
      case 'DIVIDER':
        return const Divider(height: 32, thickness: 1, color: AppColors.border);
      case 'VOCABULARY':
        return _VocabularyBlock(data: data);
      case 'SENTENCE_PATTERN':
        return _SentencePatternBlock(data: data);
      default:
        return const SizedBox.shrink();
    }
  }
}

class _VocabularyBlock extends StatelessWidget {
  final Map<String, dynamic> data;

  _VocabularyBlock({required this.data});

  static final _apiClient = ApiClient();

  @override
  Widget build(BuildContext context) {
    final vocabularyId = data['vocabularyId']?.toString() ?? '';
    return FutureBuilder(
      future: vocabularyId.isNotEmpty
          ? _apiClient.get('/vocabularies/$vocabularyId')
          : Future.value(null),
      builder: (context, snapshot) {
        if (snapshot.data == null) return const SizedBox.shrink();
        final response = snapshot.data as dynamic;
        final v = Map<String, dynamic>.from(response.data);
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.translate, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    v['term'] ?? '',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
              if (v['level'] != null) ...[
                const SizedBox(height: 8),
                Text('Level: ${v['level']}',
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              ],
              if (v['definition'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  'Definition: ${v['definition']}',
                  style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
                ),
              ],
              if (v['vietnameseMeaning'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Vi: ${v['vietnameseMeaning']}',
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
              if (v['example'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Example: ${v['example']}',
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.textPrimary),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _SentencePatternBlock extends StatelessWidget {
  final Map<String, dynamic> data;

  _SentencePatternBlock({required this.data});

  static final _apiClient = ApiClient();

  @override
  Widget build(BuildContext context) {
    final spId = data['sentencePatternId']?.toString() ?? '';
    return FutureBuilder(
      future: spId.isNotEmpty
          ? _apiClient.get('/sentence-patterns/$spId')
          : Future.value(null),
      builder: (context, snapshot) {
        if (snapshot.data == null) return const SizedBox.shrink();
        final response = snapshot.data as dynamic;
        final sp = Map<String, dynamic>.from(response.data);
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.format_quote, size: 18, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      sp['pattern'] ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
              if (sp['meaning'] != null) ...[
                const SizedBox(height: 8),
                Text(
                  sp['meaning'],
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
              ],
              if (sp['example'] != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Example: ${sp['example']}',
                  style: const TextStyle(fontSize: 14, fontStyle: FontStyle.italic, color: AppColors.textPrimary),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
