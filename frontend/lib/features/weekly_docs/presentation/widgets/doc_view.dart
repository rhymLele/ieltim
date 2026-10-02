import 'package:flutter/material.dart';

import '../../../../core/theme/brand_colors.dart';
import '../../domain/block_key.dart';
import '../../domain/models/weekly_doc.dart';
import '../blocks/block_context.dart';
import '../blocks/block_registry.dart';
import '../doc_theme.dart';

/// Kiểu "Doc" — trang dài cuộn: tiêu đề → các section → các khối → nút hoàn thành.
///
/// Padding 16 (mobile) / 40 (desktop). Dùng chung [BlockContext] với [SlideView]
/// nên đổi view không mất đáp án quiz.
class DocView extends StatelessWidget {
  const DocView({
    super.key,
    required this.doc,
    required this.base,
    required this.isMobile,
    this.completed = false,
    this.onComplete,
  });

  final WeeklyDoc doc;
  final BlockContext base;
  final bool isMobile;
  final bool completed;
  final VoidCallback? onComplete;

  @override
  Widget build(BuildContext context) {
    final pad = isMobile ? 16.0 : 40.0;
    return ListView(
      key: const Key('doc_view'),
      padding: EdgeInsets.all(pad),
      children: [
        if (doc.meta.title.trim().isNotEmpty) ...[
          Text(
            doc.meta.title,
            style: DocFonts.title(size: isMobile ? 24 : 30),
          ),
          const SizedBox(height: 24),
        ],
        for (var s = 0; s < doc.sections.length; s++) ...[
          _SectionHeader(
            number: doc.sections[s].number ?? (s + 1),
            title: doc.sections[s].title,
            isMobile: isMobile,
          ),
          const SizedBox(height: 12),
          for (var b = 0; b < doc.sections[s].blocks.length; b++)
            BlockRegistry.build(
              context,
              doc.sections[s].blocks[b],
              base.copyWith(
                blockKey: blockKey(s, b, doc.sections[s].blocks[b]),
              ),
            ),
          const SizedBox(height: 12),
        ],
        if (onComplete != null) ...[
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Brand.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Brand.disabled,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: const Icon(Icons.check_circle_outline),
              label: Text(
                completed ? 'Đã học xong' : 'Đánh dấu đã học xong',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              onPressed: completed ? null : onComplete,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.number,
    required this.title,
    required this.isMobile,
  });

  final int number;
  final String title;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Container(
            width: isMobile ? 26 : 32,
            height: isMobile ? 26 : 32,
            decoration: const BoxDecoration(
              color: Brand.primary,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: DocFonts.title(size: isMobile ? 19 : 22),
            ),
          ),
        ],
      ),
    );
  }
}
