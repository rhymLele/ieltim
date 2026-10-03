import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/storage/token_storage.dart';
import 'package:frontend/features/web_resources/presentation/bloc/web_resources_bloc.dart';
import 'package:frontend/features/web_resources/presentation/widgets/web_resource_card.dart';
import 'package:frontend/features/web_resources/presentation/widgets/add_website_dialog.dart';

class WebResourcesPage extends StatefulWidget {
  const WebResourcesPage({super.key});

  @override
  State<WebResourcesPage> createState() => _WebResourcesPageState();
}

class _WebResourcesPageState extends State<WebResourcesPage> {
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _checkRole();
  }

  Future<void> _checkRole() async {
    final role = await TokenStorage().getRole();
    if (mounted) setState(() => _isAdmin = role == 'ADMIN');
  }

  int _crossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 1200) return 4;
    if (width >= 1024) return 3;
    if (width >= 768) return 2;
    if (width >= 480) return 2;
    return 1;
  }

  void _showAddDialog() {
    final bloc = context.read<WebResourcesBloc>();
    showDialog(
      context: context,
      builder: (ctx) => const AddWebsiteDialog(),
    ).then((result) {
      if (result == true) {
        bloc.add(LoadResources());
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;
    final bloc = context.read<WebResourcesBloc>();

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Web Resources',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              if (_isAdmin)
                ElevatedButton.icon(
                  onPressed: _showAddDialog,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Website'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
            child: BlocBuilder<WebResourcesBloc, WebResourcesState>(
              builder: (context, state) {
                if (state.loading) {
                  return _buildSkeleton();
                }
                if (state.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 48, color: Colors.red.withValues(alpha: 0.5)),
                        const SizedBox(height: 12),
                        Text(state.error!,
                            style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: () => bloc.add(LoadResources()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }
                if (state.resources.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.language, size: 48, color: AppColors.textSecondary),
                        SizedBox(height: 12),
                        Text('No web resources yet',
                            style: TextStyle(color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }
                return GridView.builder(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _crossAxisCount(context),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  padding: const EdgeInsets.only(bottom: 16),
                  itemCount: state.resources.length,
                  itemBuilder: (context, index) {
                    final resource = state.resources[index];
                    return WebResourceCard(
                      resource: resource,
                      isAdmin: _isAdmin,
                      onFavorite: () => bloc.add(ToggleFavorite(resource.id)),
                      onDelete: () => _confirmDelete(resource),
                      onEdit: () => _showEditDialog(resource),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeleton() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _crossAxisCount(context),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.85,
      ),
      padding: const EdgeInsets.only(bottom: 16),
      itemCount: 8,
      itemBuilder: (_, _) => Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }

  void _confirmDelete(WebResource resource) {
    final bloc = context.read<WebResourcesBloc>();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Resource'),
        content: Text('Are you sure you want to delete "${resource.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              bloc.add(DeleteResource(resource.id));
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(WebResource resource) {
    final bloc = context.read<WebResourcesBloc>();
    final titleController = TextEditingController(text: resource.title);
    final descController =
        TextEditingController(text: resource.description ?? '');
    final categoryController = TextEditingController(text: resource.category ?? '');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Resource'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: descController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: categoryController,
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await bloc.updateResource(resource.id, {
                  'title': titleController.text.trim(),
                  'description': descController.text.trim(),
                  'category': categoryController.text.trim(),
                });
                bloc.add(LoadResources());
              } catch (_) {}
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}
