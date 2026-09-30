import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/network/api_client.dart';

class SentencePatternFormPage extends StatefulWidget {
  final String? sentencePatternId;

  const SentencePatternFormPage({super.key, this.sentencePatternId});

  @override
  State<SentencePatternFormPage> createState() => _SentencePatternFormPageState();
}

class _SentencePatternFormPageState extends State<SentencePatternFormPage> {
  final _apiClient = ApiClient();
  final _formKey = GlobalKey<FormState>();
  final _patternController = TextEditingController();
  final _meaningController = TextEditingController();
  final _usageController = TextEditingController();
  final _exampleController = TextEditingController();
  String _level = 'B1';
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.sentencePatternId != null) _load();
  }

  Future<void> _load() async {
    try {
      final response = await _apiClient.get('/sentence-patterns/${widget.sentencePatternId}');
      final sp = response.data;
      _patternController.text = sp['pattern'] ?? '';
      _meaningController.text = sp['meaning'] ?? '';
      _usageController.text = sp['usage'] ?? '';
      _exampleController.text = sp['example'] ?? '';
      _level = sp['level'] ?? 'B1';
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = {
      'pattern': _patternController.text.trim(),
      'level': _level,
      if (_meaningController.text.isNotEmpty) 'meaning': _meaningController.text.trim(),
      if (_usageController.text.isNotEmpty) 'usage': _usageController.text.trim(),
      if (_exampleController.text.isNotEmpty) 'example': _exampleController.text.trim(),
    };

    try {
      if (widget.sentencePatternId != null) {
        await _apiClient.patch('/sentence-patterns/${widget.sentencePatternId}', data: data);
      } else {
        await _apiClient.post('/sentence-patterns', data: data);
      }
      if (mounted) context.go('/admin');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.all(MediaQuery.of(context).size.width < 768 ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.sentencePatternId != null ? 'Edit Sentence Pattern' : 'Create Sentence Pattern',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _patternController,
                  decoration: const InputDecoration(labelText: 'Pattern *'),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _meaningController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Meaning'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _usageController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Usage'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _exampleController,
                  maxLines: 2,
                  decoration: const InputDecoration(labelText: 'Example'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField(
                  value: _level,
                  decoration: const InputDecoration(labelText: 'Level *'),
                  items: ['A1', 'A2', 'B1', 'B2', 'C1', 'C2']
                      .map((l) => DropdownMenuItem(value: l, child: Text(l)))
                      .toList(),
                  onChanged: (v) => setState(() => _level = v!),
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Save'),
                    ),
                    const SizedBox(width: 12),
                    TextButton(
                      onPressed: () => context.go('/admin'),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
