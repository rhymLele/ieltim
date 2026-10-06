import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../routes/app_routes.dart';
import '../theme/app_colors.dart';
import 'koi_pond.dart';

/// Trang mặc định khi đường dẫn không khớp trang nào (gõ sai, link cũ): báo không tìm thấy, nút về trang chủ.
/// Chưa đăng nhập thì router đã chuyển sang /access trước khi tới đây.
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key, required this.path});

  /// Đường dẫn người dùng mở, hiện lại để họ thấy mình gõ sai chỗ nào.
  final String path;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned.fill(child: KoiPond(fishCount: 4)),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: _NotFoundCard(path: path),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotFoundCard extends StatelessWidget {
  const _NotFoundCard({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
      decoration: BoxDecoration(
        color: AppColors.cardSurface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: const [BoxShadow(color: AppColors.shadowPreview, blurRadius: 28, offset: Offset(0, 12))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const ExcludeSemantics(
            child: Text('404', style: TextStyle(fontSize: 56, height: 1, fontWeight: FontWeight.w800, letterSpacing: -1.5, color: AppColors.primary)),
          ),
          const SizedBox(height: 14),
          const Text(
            'Không tìm thấy trang',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textInk),
          ),
          const SizedBox(height: 8),
          Text(
            'Trang $path không tồn tại hoặc đã được chuyển đi. Kiểm tra lại đường dẫn, hoặc quay về trang chủ.',
            textAlign: TextAlign.center,
            maxLines: 4,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 14, height: 1.5, color: AppColors.textMuted),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton.icon(
              key: const Key('not_found_home_button'),
              onPressed: () => context.go(AppRoutes.home),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.onPrimary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Về trang chủ', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}
