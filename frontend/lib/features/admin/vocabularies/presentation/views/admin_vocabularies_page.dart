import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/network/api_client.dart';

class AdminVocabulariesPage extends StatefulWidget {
  const AdminVocabulariesPage({super.key});

  @override
  State<AdminVocabulariesPage> createState() => _AdminVocabulariesPageState();
}

class _AdminVocabulariesPageState extends State<AdminVocabulariesPage> {
  final _apiClient = ApiClient();
  List<Map<String, dynamic>> _vocabularies = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await _apiClient.get('/vocabularies');
      if (mounted) {
        setState(() {
          _vocabularies = (response.data['data'] as List? ?? []).cast<Map<String, dynamic>>();
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Vocabulary',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => context.go('/admin/vocabularies/create'),
                icon: const Icon(Icons.add),
                label: const Text('New'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_vocabularies.isEmpty)
            const Center(child: Text('No vocabulary yet'))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _vocabularies.length,
                itemBuilder: (context, index) {
                  final v = _vocabularies[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(v['term'] ?? ''),
                      subtitle: Text(v['level'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => context.go('/admin/vocabularies/${v['id']}/edit'),
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
