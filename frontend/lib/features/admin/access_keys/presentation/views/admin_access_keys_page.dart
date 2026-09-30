import 'package:flutter/material.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/network/api_client.dart';

class AdminAccessKeysPage extends StatefulWidget {
  const AdminAccessKeysPage({super.key});

  @override
  State<AdminAccessKeysPage> createState() => _AdminAccessKeysPageState();
}

class _AdminAccessKeysPageState extends State<AdminAccessKeysPage> {
  final _apiClient = ApiClient();
  final _keyController = TextEditingController();
  final _userController = TextEditingController();
  List<Map<String, dynamic>> _keys = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final response = await _apiClient.get('/access-keys');
      if (mounted) {
        setState(() {
          _keys = response.data['data'] as List? ?? (response.data is List ? response.data : []);
          _loading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createKey() async {
    if (_keyController.text.trim().isEmpty || _userController.text.trim().isEmpty) return;
    try {
      await _apiClient.post('/access-keys', data: {
        'key': _keyController.text.trim(),
        'userId': _userController.text.trim(),
      });
      _keyController.clear();
      _userController.clear();
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
            'Access Keys',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _keyController,
                  decoration: const InputDecoration(
                    hintText: 'Access key (e.g. ABC-123-DEF)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _userController,
                  decoration: const InputDecoration(
                    hintText: 'User ID (UUID)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: _createKey,
                child: const Text('Create'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_keys.isEmpty)
            const Center(child: Text('No access keys yet'))
          else
            Expanded(
              child: ListView.builder(
                itemCount: _keys.length,
                itemBuilder: (context, index) {
                  final key = _keys[index];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text('Key ending: ****${key['id']?.substring(key['id']?.length - 4 ?? 0)}'),
                      subtitle: Text('Status: ${key['status'] ?? ''}'),
                      trailing: key['status'] == 'ACTIVE'
                          ? TextButton(
                              onPressed: () async {
                                await _apiClient.patch('/access-keys/${key['id']}/status',
                                    data: {'status': 'DISABLED'});
                                _load();
                              },
                              child: const Text('Disable', style: TextStyle(color: Colors.red)),
                            )
                          : TextButton(
                              onPressed: () async {
                                await _apiClient.patch('/access-keys/${key['id']}/status',
                                    data: {'status': 'ACTIVE'});
                                _load();
                              },
                              child: const Text('Enable', style: TextStyle(color: Colors.green)),
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
