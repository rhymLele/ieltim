// preview_pane.dart — Cột "Xem trước" của A2 (rộng 500). Bố cục: file 6 mục A2.4.

import 'package:flutter/material.dart';

import '../../core/app_tokens.dart';
import '../../domain/weekly_doc.dart';
import '../widgets/block_view.dart';
import '../widgets/common_widgets.dart';
import '../widgets/doc_renderers.dart';
import '../widgets/html_frame.dart';

class PreviewPane extends StatelessWidget {
  const PreviewPane({
    super.key,
    required this.doc,
    required this.view,
    required this.slideIndex,
    required this.onViewChanged,
    required this.onSlideChanged,
    this.highlightKey,
  });

  final WeeklyDoc doc;
  final DocViewMode view;
  final int slideIndex;
  final ValueChanged<DocViewMode> onViewChanged;
  final ValueChanged<int> onSlideChanged;
  final String? highlightKey;

  @override
  Widget build(BuildContext context) {
    if (doc.isHtml) return _html();
    final slides = buildSlides(doc);
    final idx = slides.isEmpty ? 0 : slideIndex.clamp(0, slides.length - 1);
    final isSlide = view == DocViewMode.slide;
    const quiz = QuizState(revealAnswer: true);
    return Container(
      color: AppColors.previewBg,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Eyebrow('Xem trước')),
              ViewModeToggle(value: view, onChanged: onViewChanged, compact: true),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Flexible(
            child: LayoutBuilder(builder: (context, c) {
              final w = c.maxWidth.clamp(0.0, 460.0);
              return Container(
                width: w,
                height: isSlide ? w * 9 / 16 : (c.maxHeight.isFinite ? c.maxHeight.clamp(0.0, 520.0) : 520.0),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.border),
                  boxShadow: isSlide ? AppShadows.preview : null,
                ),
                clipBehavior: Clip.antiAlias,
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(isSlide ? 20 : 22),
                  child: isSlide
                      ? (slides.isEmpty
                          ? const Text('Chưa có nội dung', style: AppText.caption)
                          : SlideContent(page: slides[idx], scale: BlockScale.previewSlide, quiz: quiz, highlightKey: highlightKey))
                      : DocContent(doc: doc, scale: BlockScale.previewDoc, quiz: quiz, showTitle: true, highlightKey: highlightKey, sectionGap: 22),
                ),
              );
            }),
          ),
          if (isSlide && slides.isNotEmpty) ...[
            const SizedBox(height: AppSpace.md),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RoundNavButton(icon: Icons.chevron_left_rounded, tooltip: 'Slide trước', size: 36, onPressed: idx == 0 ? null : () => onSlideChanged(idx - 1)),
                const SizedBox(width: AppSpace.md),
                Text('Slide ${idx + 1} / ${slides.length}', style: AppText.label.copyWith(color: AppColors.textMuted)),
                const SizedBox(width: AppSpace.md),
                RoundNavButton(icon: Icons.chevron_right_rounded, tooltip: 'Slide sau', size: 36, filled: true, onPressed: idx >= slides.length - 1 ? null : () => onSlideChanged(idx + 1)),
              ],
            ),
          ],
          const SizedBox(height: AppSpace.md),
          Text(
            isSlide ? 'Slide: mỗi section là một slide 16:9. Nội dung dài thì tách thêm section.' : 'Doc: các section nối liền thành một trang cuộn dọc.',
            style: AppText.caption,
          ),
        ],
      ),
    );
  }

  /// Tài liệu HTML: chạy nguyên file, không có công tắc Slide / Doc.
  Widget _html() {
    final html = doc.html ?? '';
    return Container(
      color: AppColors.previewBg,
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Eyebrow('Xem trước'),
          const SizedBox(height: AppSpace.md),
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.border),
                boxShadow: AppShadows.preview,
              ),
              clipBehavior: Clip.antiAlias,
              child: html.isEmpty ? const Center(child: Text('Chưa tải file HTML', style: AppText.caption)) : HtmlFrame(html: html),
            ),
          ),
          const SizedBox(height: AppSpace.md),
          const Text('HTML: hiển thị nguyên file, file tự lo trình chiếu và điều hướng.', style: AppText.caption),
        ],
      ),
    );
  }
}
