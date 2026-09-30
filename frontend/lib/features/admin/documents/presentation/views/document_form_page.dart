import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/network/api_client.dart';

class DocumentFormPage extends StatefulWidget {
  final String? documentId;

  const DocumentFormPage({super.key, this.documentId});

  @override
  State<DocumentFormPage> createState() => _DocumentFormPageState();
}

class _DocumentFormPageState extends State<DocumentFormPage> {
  final _apiClient = ApiClient();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _type = 'WEEKLY';
  String _status = 'DRAFT';
  String? _studyDate;
  int? _week;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.documentId != null) {
      _loadDocument();
    }
  }

  Future<void> _loadDocument() async {
    try {
      final response = await _apiClient.get('/documents/${widget.documentId}');
      final doc = response.data;
      _titleController.text = doc['title'] ?? '';
      _descriptionController.text = doc['description'] ?? '';
      _type = doc['type'] ?? 'WEEKLY';
      _status = doc['status'] ?? 'DRAFT';
      _studyDate = doc['studyDate']?.toString();
      _week = doc['weekNumber'];
    } catch (_) {}
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final data = {
      'title': _titleController.text.trim(),
      'description': _descriptionController.text.trim(),
      'type': _type,
      'status': _status,
      if (_studyDate != null) 'studyDate': _studyDate,
      if (_week != null) 'weekNumber': _week,
    };

    try {
      if (widget.documentId != null) {
        await _apiClient.patch('/documents/${widget.documentId}', data: data);
      } else {
        await _apiClient.post('/documents', data: data);
      }
      if (mounted) context.go('/admin');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
            widget.documentId != null ? 'Edit Document' : 'Create Document',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 24),
          Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  decoration: const InputDecoration(labelText: 'Title *'),
                  validator: (v) => v?.isEmpty == true ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField(
                        value: _type,
                        decoration: const InputDecoration(labelText: 'Type'),
                        items: ['WEEKLY', 'WEB_RESOURCE', 'ARTICLE']
                            .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                            .toList(),
                        onChanged: (v) => setState(() => _type = v!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField(
                        value: _status,
                        decoration: const InputDecoration(labelText: 'Status'),
                        items: ['DRAFT', 'PUBLISHED', 'ARCHIVED']
                            .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                            .toList(),
                        onChanged: (v) => setState(() => _status = v!),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Study Date (YYYY-MM-DD)'),
                        onChanged: (v) => _studyDate = v,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(labelText: 'Week Number'),
                        keyboardType: TextInputType.number,
                        onChanged: (v) => _week = int.tryParse(v),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: _saving ? null : _save,
                      child: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
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
