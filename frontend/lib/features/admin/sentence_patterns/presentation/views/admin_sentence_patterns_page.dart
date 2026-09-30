import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/network/api_client.dart';

class AdminSentencePatternsPage extends StatefulWidget {
  const AdminSentencePatternsPage({super.key});

  @override
  State<AdminSentencePatternsPage> createState() => _AdminSentencePatternsPageState();
}

class _AdminSentencePatternsPageState extends State<AdminSentencePatternsPage> {
  final _apiClient = ApiClient();
  List<Map<String, dynamic>> _patterns = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await _apiClient.get('/sentence-patterns');
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Sentence Patterns',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              ElevatedButton.icon(
                onPressed: () => context.go('/admin/sentence-patterns/create'),
                icon: const Icon(Icons.add),
                label: const Text('New'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_patterns.isEmpty)
            const Center(child: Text('No sentence patterns yet'))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _patterns.length,
                itemBuilder: (context, index) {
                  final sp = _patterns[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(sp['pattern'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(sp['level'] ?? ''),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, size: 20),
                        onPressed: () => context.go('/admin/sentence-patterns/${sp['id']}/edit'),
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
