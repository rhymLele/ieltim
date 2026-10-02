import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../../core/theme/brand_colors.dart';
import '../../../domain/models/weekly_doc.dart';
import '../block_context.dart';
import '../../doc_theme.dart';

/// Steps: mỗi bước có số trong ô bo góc nền #F3E5D5.
class StepsBlockWidget extends StatelessWidget {
  const StepsBlockWidget({super.key, required this.block, required this.ctx});

  final StepsBlock block;
  final BlockContext ctx;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < block.items.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Brand.stepBox,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${i + 1}',
                  style: DocFonts.body(
                      size: 14, weight: FontWeight.w700, color: Brand.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 3),
                  child: Text(
                    block.items[i],
                    style: DocFonts.body(size: 15, height: 1.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Passage: khung nền kem viền #EFDCCB, nhãn nhỏ màu primary, chữ serif.
class PassageBlockWidget extends StatelessWidget {
  const PassageBlockWidget({super.key, required this.block, required this.ctx});

  final PassageBlock block;
  final BlockContext ctx;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Brand.passageBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Brand.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (block.label.trim().isNotEmpty) ...[
            Text(
              block.label.toUpperCase(),
              style: DocFonts.kicker(size: 11, color: Brand.primary),
            ),
            const SizedBox(height: 10),
          ],
          Text(
            block.text,
            style: DocFonts.serif(size: 16),
          ),
        ],
      ),
    );
  }
}

/// Image: CachedNetworkImage, có alt cho trợ năng, bấm phóng to.
/// Ảnh lỗi → khung giữ chỗ.
class ImageBlockWidget extends StatelessWidget {
  const ImageBlockWidget({super.key, required this.block, required this.ctx});

  final ImageBlock block;
  final BlockContext ctx;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: block.alt.isNotEmpty ? block.alt : 'Ảnh',
      image: true,
      button: true,
      child: GestureDetector(
        onTap: () => _openViewer(context),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320, minHeight: 120),
            child: CachedNetworkImage(
              imageUrl: block.url,
              fit: BoxFit.cover,
              width: double.infinity,
              placeholder: (context, url) => const _ImagePlaceholder(
                icon: Icons.image_outlined,
                label: 'Đang tải ảnh…',
              ),
              errorWidget: (context, url, error) => const _ImagePlaceholder(
                icon: Icons.broken_image_outlined,
                label: 'Không tải được ảnh',
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _openViewer(BuildContext context) {
    if (!context.mounted) return;
    showDialog(
      context: context,
      barrierColor: Colors.black.withAlpha(220),
      builder: (dialogContext) => _ImageViewer(url: block.url, alt: block.alt),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  const _ImagePlaceholder({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Brand.unknownBackground,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 32, color: Brand.unknownText),
          const SizedBox(height: 8),
          Text(label, style: DocFonts.body(size: 13, color: Brand.unknownText)),
        ],
      ),
    );
  }
}

class _ImageViewer extends StatelessWidget {
  const _ImageViewer({required this.url, required this.alt});

  final String url;
  final String alt;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: url,
                  fit: BoxFit.contain,
                  width: double.infinity,
                  errorWidget: (context, u, e) => const Center(
                    child: Icon(Icons.broken_image_outlined,
                        size: 48, color: Colors.white54),
                  ),
                ),
              ),
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 8,
              right: 8,
              child: IconButton(
                tooltip: 'Đóng',
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// UnknownBlock: ô xám "Nội dung chưa hỗ trợ, hãy cập nhật app".
class UnknownBlockWidget extends StatelessWidget {
  const UnknownBlockWidget({super.key, required this.block, required this.ctx});

  final UnknownBlock block;
  final BlockContext ctx;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Brand.unknownBackground,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.help_outline, size: 20, color: Brand.unknownText),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nội dung chưa hỗ trợ, hãy cập nhật app'
              '${block.type.isNotEmpty ? ' (type: ${block.type})' : ''}',
              style: DocFonts.body(size: 14, color: Brand.unknownText),
            ),
          ),
        ],
      ),
    );
  }
}
