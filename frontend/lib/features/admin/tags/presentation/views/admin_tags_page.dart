import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/network/api_client.dart';

class AdminTagsPage extends StatefulWidget {
  const AdminTagsPage({super.key});

  @override
  State<AdminTagsPage> createState() => _AdminTagsPageState();
}

class _AdminTagsPageState extends State<AdminTagsPage> {
  final _apiClient = ApiClient();
  final _nameController = TextEditingController();
  List<Map<String, dynamic>> _tags = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await _apiClient.get('/tags');
      if (mounted) {
        setState(() {
          _tags = response.data['data'] as List? ?? (response.data is List ? response.data : []);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addTag() async {
    if (_nameController.text.trim().isEmpty) return;
    try {
      await _apiClient.post('/tags', data: {
        'name': _nameController.text.trim(),
        'type': 'GENERAL',
      });
      _nameController.clear();
      _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
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
            'Tags',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    hintText: 'New tag name',
                    border: OutlineInputBorder(),
                  ),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _addTag,
                child: const Text('Add'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_tags.isEmpty)
            const Center(child: Text('No tags yet'))
          else
            Expanded(
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _tags.map((tag) => Chip(
                  label: Text(tag['name'] ?? ''),
                  backgroundColor: AppColors.surface,
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
