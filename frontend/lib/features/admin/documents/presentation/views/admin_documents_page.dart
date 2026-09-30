import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/theme/app_colors.dart';
import 'package:frontend/core/widgets/shimmer_loading.dart';
import 'package:frontend/features/admin/documents/presentation/bloc/admin_documents_bloc.dart';

class AdminDocumentsPage extends StatelessWidget {
  const AdminDocumentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Padding(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Documents',
                style: TextStyle(
                  fontSize: isMobile ? 20 : 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              ElevatedButton.icon(
                onPressed: () => context.go('/admin/documents/create'),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('New'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: BlocBuilder<AdminDocumentsBloc, AdminDocumentsState>(
              builder: (context, state) {
                if (state.loading) {
                  return const ShimmerLoading(itemCount: 5);
                }
                if (state.error != null) {
                  return Center(
                    child: Text(state.error!, style: const TextStyle(color: Colors.red)));
                }
                if (state.documents.isEmpty) {
                  return const Center(child: Text('No documents yet'));
                }
                return ListView.builder(
                  itemCount: state.documents.length,
                  itemBuilder: (context, index) {
                    final doc = state.documents[index];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        title: Text(
                          doc['title'] ?? 'Untitled',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                        ),
                        subtitle: Row(
                          children: [
                            _StatusBadge(status: doc['status'] ?? 'DRAFT'),
                            const SizedBox(width: 8),
                            Text(
                              '${doc['type'] ?? ''}',
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.edit, size: 18),
                          onPressed: () => context.go('/admin/documents/${doc['id']}/edit'),
                        ),
                      ),
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
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    switch (status) {
      case 'PUBLISHED':
        color = Colors.green;
        break;
      case 'ARCHIVED':
        color = Colors.grey;
        break;
      default:
        color = Colors.orange;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status,
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}
