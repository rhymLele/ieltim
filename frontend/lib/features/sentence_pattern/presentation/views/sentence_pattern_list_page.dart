import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/network/api_client.dart';

class SentencePatternListPage extends StatefulWidget {
  const SentencePatternListPage({super.key});

  @override
  State<SentencePatternListPage> createState() => _SentencePatternListPageState();
}

class _SentencePatternListPageState extends State<SentencePatternListPage> {
  final _apiClient = ApiClient();
  List<Map<String, dynamic>> _patterns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPatterns();
  }

  Future<void> _loadPatterns() async {
    try {
      final response = await _apiClient.get('/sentence-patterns',
          queryParameters: {'status': 'PUBLISHED'});
      if (mounted) {
        setState(() {
          _patterns = (response.data['data'] as List? ?? []).cast<Map<String, dynamic>>();
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 768 ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Sentence Patterns',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_patterns.isEmpty)
            const Center(child: Text('No sentence patterns found'))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _patterns.length,
                itemBuilder: (context, index) {
                  final sp = _patterns[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            sp['pattern'] ?? '',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          if (sp['meaning'] != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              sp['meaning'],
                              style: const TextStyle(
                                fontSize: 14,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          if (sp['example'] != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Example: ${sp['example']}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontStyle: FontStyle.italic,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
