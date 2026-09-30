import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/network/api_client.dart';
import 'package:frontend/features/web_resources/presentation/bloc/web_resources_bloc.dart';

class AddWebsiteDialog extends StatefulWidget {
  const AddWebsiteDialog({super.key});

  @override
  State<AddWebsiteDialog> createState() => _AddWebsiteDialogState();
}

class _AddWebsiteDialogState extends State<AddWebsiteDialog> {
  final _urlController = TextEditingController();
  String? _fetchError;
  bool _fetching = false;
  bool _saving = false;

  Map<String, dynamic>? _preview;
  String _category = '';
  String _tags = '';

  Future<void> _fetchPreview() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      setState(() => _fetchError = 'Please enter a URL');
      return;
    }
    setState(() {
      _fetching = true;
      _fetchError = null;
      _preview = null;
    });

    try {
      final res = await ApiClient().get('/web-resources/link-preview',
          queryParameters: {'url': url});
      setState(() {
        _preview = res.data as Map<String, dynamic>;
        _fetching = false;
      });
    } catch (e) {
      setState(() {
        _fetching = false;
        _fetchError = 'Failed to fetch preview. Try again.';
      });
    }
  }

  Future<void> _save() async {
    if (_preview == null) return;

    setState(() => _saving = true);
    try {
      final p = _preview!;
      await ApiClient().post('/web-resources', data: {
        'title': p['title'] ?? _urlController.text.trim(),
        'url': _urlController.text.trim(),
        'domain': p['domain'],
        'description': p['description'],
        'imageUrl': p['imageUrl'],
        'faviconUrl': p['faviconUrl'],
        'category': _category.isNotEmpty ? _category : null,
        'tags': _tags.isNotEmpty ? _tags : null,
        'status': 'PUBLISHED',
        'resourceType': 'WEBSITE',
      });
      if (context.mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() {
        _saving = false;
        _fetchError = e.toString().contains('DUPLICATE_URL')
            ? 'This URL already exists'
            : 'Failed to save: $e';
      });
    }
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Add Website',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _urlController,
                      decoration: const InputDecoration(
                        labelText: 'Website URL',
                        hintText: 'https://flutter.dev',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.link, size: 18),
                      ),
                      onSubmitted: (_) => _fetchPreview(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _fetching ? null : _fetchPreview,
                    icon: _fetching
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.refresh, size: 16),
                    label: const Text('Fetch'),
                  ),
                ],
              ),
              if (_fetchError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(_fetchError!,
                      style: const TextStyle(color: Colors.red, fontSize: 12)),
                ),
              if (_preview != null) ...[
                const SizedBox(height: 16),
                _buildPreview(),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _category.isEmpty ? null : _category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'Study',
                          'Practice',
                          'Tools',
                          'News',
                          'Community',
                        ].map((c) => DropdownMenuItem(
                              value: c,
                              child: Text(c),
                            )).toList(),
                        onChanged: (v) => setState(() => _category = v ?? ''),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: null,
                        onChanged: (v) => setState(() => _tags = v),
                        decoration: const InputDecoration(
                          labelText: 'Tags (comma separated)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: (_preview != null && !_saving) ? _save : null,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Save'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreview() {
    final p = _preview!;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          if (p['imageUrl'] != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                p['imageUrl'],
                width: 80,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 60,
                  color: Colors.white,
                  child: const Icon(Icons.image_not_supported, size: 24),
                ),
              ),
            )
          else if (p['faviconUrl'] != null)
            Image.network(
              p['faviconUrl'],
              width: 32,
              height: 32,
              errorBuilder: (_, __, ___) => const Icon(Icons.language),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p['title'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  p['domain'] ?? '',
                  style: const TextStyle(fontSize: 12, color: AppColors.primary),
                ),
                if (p['description'] != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    p['description'],
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
