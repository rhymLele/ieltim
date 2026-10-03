// doc_renderers.dart — Nội dung tài liệu dạng Doc (tất cả section) và dạng Slide (một trang).

import 'package:flutter/material.dart';

import '../../core/app_tokens.dart';
import '../../domain/weekly_doc.dart';
import 'block_view.dart';
import 'common_widgets.dart';

/// Toàn bộ section nối liền (kiểu Doc). Không tự cuộn: đặt trong ListView/SingleChildScrollView.
class DocContent extends StatelessWidget {
  const DocContent({
    super.key,
    required this.doc,
    required this.scale,
    this.quiz = const QuizState(),
    this.showTitle = false,
    this.highlightKey,
    this.sectionKeys,
    this.sectionGap = 28,
  });

  final WeeklyDoc doc;
  final BlockScale scale;
  final QuizState quiz;
  final bool showTitle;
  final String? highlightKey;

  /// GlobalKey cho từng section (để cuộn tới / đo tiến độ).
  final List<GlobalKey>? sectionKeys;
  final double sectionGap;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    if (showTitle) {
      children.add(Text(doc.title, style: TextStyle(fontSize: scale.heading + 4, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: AppColors.text)));
    }
    for (var si = 0; si < doc.sections.length; si++) {
      if (children.isNotEmpty) children.add(SizedBox(height: sectionGap));
      final s = doc.sections[si];
      children.add(KeyedSubtree(
        key: sectionKeys != null && si < sectionKeys!.length ? sectionKeys![si] : null,
        child: SectionBlocks(
          number: si + 1,
          title: s.title,
          blocks: [for (var bi = 0; bi < s.blocks.length; bi++) (bi, s.blocks[bi])],
          sectionIndex: si,
          scale: scale,
          quiz: quiz,
          highlightKey: highlightKey,
        ),
      ));
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: children);
  }
}

/// Một section (hoặc một phần section khi slide bị ngắt): nhãn + các khối.
class SectionBlocks extends StatelessWidget {
  const SectionBlocks({
    super.key,
    required this.number,
    required this.title,
    required this.blocks,
    required this.sectionIndex,
    required this.scale,
    this.quiz = const QuizState(),
    this.highlightKey,
  });

  final int number;
  final String title;
  final List<(int, DocBlock)> blocks;
  final int sectionIndex;
  final BlockScale scale;
  final QuizState quiz;
  final String? highlightKey;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionLabel(number: number, title: title, size: scale.eyebrow * 2.2, fontSize: scale.eyebrow),
        for (final (bi, b) in blocks)
          if (b is! SlideBreakBlock)
            Padding(
              padding: EdgeInsets.only(top: scale.gap),
              child: BlockView(
                block: b,
                blockKey: blockKey(sectionIndex, bi, b),
                scale: scale,
                quiz: quiz,
                highlighted: highlightKey != null && highlightKey == blockKey(sectionIndex, bi, b),
              ),
            ),
      ],
    );
  }
}

/// Nội dung của một slide (không có khung).
class SlideContent extends StatelessWidget {
  const SlideContent({super.key, required this.page, required this.scale, this.quiz = const QuizState(), this.highlightKey});
  final SlidePage page;
  final BlockScale scale;
  final QuizState quiz;
  final String? highlightKey;

  @override
  Widget build(BuildContext context) => SectionBlocks(
        number: page.sectionIndex + 1,
        title: page.partIndex == 0 ? page.title : '${page.title} (tiếp)',
        blocks: page.blocks,
        sectionIndex: page.sectionIndex,
        scale: scale,
        quiz: quiz,
        highlightKey: highlightKey,
      );
}

/// Dãy chấm chỉ trang slide (trang hiện tại kéo dài).
class SlideDots extends StatelessWidget {
  const SlideDots({super.key, required this.count, required this.index, required this.onTap, this.size = 8});
  final int count;
  final int index;
  final ValueChanged<int> onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      children: [
        for (var i = 0; i < count; i++)
          Semantics(
            button: true,
            label: 'Đến slide ${i + 1}',
            selected: i == index,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: AnimatedContainer(
                  duration: motion(context, 250),
                  width: i == index ? size * 3 : size,
                  height: size,
                  decoration: BoxDecoration(color: i == index ? AppColors.primary : AppColors.navActive, borderRadius: BorderRadius.circular(AppRadius.pill)),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Nút tròn trước/sau.
class RoundNavButton extends StatelessWidget {
  const RoundNavButton({super.key, required this.icon, required this.tooltip, this.onPressed, this.filled = false, this.size = 48});
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final bool filled;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Opacity(
        opacity: onPressed == null ? 0.4 : 1,
        child: Material(
          color: filled ? AppColors.primary : AppColors.surface,
          shape: CircleBorder(side: filled ? BorderSide.none : const BorderSide(color: AppColors.border)),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onPressed,
            child: SizedBox(width: size, height: size, child: Icon(icon, size: 22, color: filled ? AppColors.onPrimary : AppColors.primary)),
          ),
        ),
      ),
    );
  }
}
