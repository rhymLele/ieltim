import 'package:flutter/material.dart';

import '../../../core/app_tokens.dart';
import '../../../domain/entities/weekly_doc.dart';
import '../block_view.dart';
import '../common_widgets.dart';
import '../doc_renderers.dart';
import 'reader_chrome.dart';

/// Khung trắng bo góc của một slide (cuộn được nếu nội dung dài).
class SlideFrame extends StatelessWidget {
  const SlideFrame({super.key, required this.child, required this.radius, required this.padding, this.watermark = false});

  final Widget child;
  final double radius;
  final double padding;
  final bool watermark;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.cardSurface, borderRadius: BorderRadius.circular(radius), boxShadow: AppShadows.slide),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned.fill(child: SingleChildScrollView(padding: EdgeInsets.all(padding), child: child)),
          if (watermark)
            const Positioned(
              right: 22,
              top: 18,
              child: ExcludeSemantics(child: Text('ieltshub.', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.watermark))),
            ),
        ],
      ),
    );
  }
}

/// Nút sang slide sau; ở slide cuối thành nút "Hoàn thành".
class NextSlideButton extends StatelessWidget {
  const NextSlideButton({
    super.key,
    required this.isLast,
    required this.isPreview,
    required this.isCompleting,
    required this.onNext,
    required this.onComplete,
    this.size = 48,
  });

  final bool isLast;
  final bool isPreview;
  final bool isCompleting;
  final VoidCallback onNext;
  final VoidCallback onComplete;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (!isLast) return RoundNavButton(icon: Icons.chevron_right_rounded, tooltip: 'Slide sau', filled: true, size: size, onPressed: onNext);
    return SizedBox(height: size, child: CompleteButton(isPreview: isPreview, isCompleting: isCompleting, onPressed: onComplete, showArrow: true));
  }
}

/// Dữ liệu chung của các kiểu trình chiếu slide.
class SlideDeck {
  const SlideDeck({
    required this.controller,
    required this.slides,
    required this.index,
    required this.quiz,
    required this.isPreview,
    required this.isCompleting,
    required this.onPageChanged,
    required this.onGoTo,
    required this.onComplete,
    this.pagerKey,
    this.physics,
    this.selectable,
    this.slideOverlay,
    this.marked = const {},
  });

  final PageController? controller;
  final List<SlidePage> slides;
  final int index;
  final QuizState quiz;
  final bool isPreview;
  final bool isCompleting;
  final ValueChanged<int> onPageChanged;
  final ValueChanged<int> onGoTo;
  final VoidCallback onComplete;

  /// Key giữ nguyên PageView khi vùng bôi đen bọc ngoài dựng lại (đóng hộp thoại bôi đen = dựng lại vùng được bọc
  /// để bỏ vùng chọn); không có key thì PageView tạo mới và nhảy về slide đầu.
  final GlobalKey? pagerKey;

  /// Khoá vuốt khi đang vẽ ghi chú.
  final ScrollPhysics? physics;

  /// Bọc vùng slide để bôi đen chữ (hộp thoại sổ từ / dịch / highlight).
  final Widget Function(Widget child)? selectable;

  /// Đặt lớp ghi chú (vẽ, khoanh, chữ, ghim) đè lên khung một slide.
  final Widget Function(SlidePage page, Widget frame)? slideOverlay;

  /// Chỉ số các slide có ghi chú của tôi.
  final Set<int> marked;

  bool get isLast => index >= slides.length - 1;

  Widget wrapPages(Widget pages) => selectable?.call(pages) ?? pages;

  Widget wrapSlide(int i, Widget frame) => slideOverlay?.call(slides[i], frame) ?? frame;
}

/// Desktop: slide 16:9 rộng tối đa 1000, nút điều hướng + chấm trang bên dưới.
class DesktopSlideBody extends StatelessWidget {
  const DesktopSlideBody({super.key, required this.deck});

  final SlideDeck deck;

  @override
  Widget build(BuildContext context) {
    if (deck.slides.isEmpty) return const EmptyState(message: 'Tài liệu chưa có nội dung');
    return LayoutBuilder(builder: (context, c) {
      final width = (c.maxWidth - 64).clamp(320.0, 1000.0);
      return SingleChildScrollView(
        padding: const EdgeInsets.symmetric(vertical: AppSpace.xxl),
        child: Column(
          children: [
            SizedBox(
              width: width,
              height: width * 9 / 16,
              child: deck.wrapPages(
                PageView.builder(
                  key: deck.pagerKey,
                  controller: deck.controller,
                  physics: deck.physics,
                  onPageChanged: deck.onPageChanged,
                  itemCount: deck.slides.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: deck.wrapSlide(
                      i,
                      SlideFrame(
                        radius: AppRadius.cardLg,
                        padding: 44,
                        watermark: true,
                        child: SlideContent(page: deck.slides[i], scale: BlockScale.slideWide, quiz: deck.quiz),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpace.lg),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                RoundNavButton(
                  icon: Icons.chevron_left_rounded,
                  tooltip: 'Slide trước',
                  size: 44,
                  onPressed: deck.index == 0 ? null : () => deck.onGoTo(deck.index - 1),
                ),
                const SizedBox(width: 14),
                SlideDots(count: deck.slides.length, index: deck.index, onTap: deck.onGoTo, size: 10, marked: deck.marked),
                const SizedBox(width: 14),
                NextSlideButton(
                  size: 44,
                  isLast: deck.isLast,
                  isPreview: deck.isPreview,
                  isCompleting: deck.isCompleting,
                  onNext: () => deck.onGoTo(deck.index + 1),
                  onComplete: deck.onComplete,
                ),
                const SizedBox(width: 14),
                Text('${deck.index + 1} / ${deck.slides.length}', style: AppText.label.copyWith(color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      );
    });
  }
}

/// Điện thoại dọc: slide chiếm màn, gợi ý xoay ngang để trình chiếu.
class MobileSlideBody extends StatelessWidget {
  const MobileSlideBody({super.key, required this.deck});

  final SlideDeck deck;

  @override
  Widget build(BuildContext context) {
    if (deck.slides.isEmpty) return const EmptyState(message: 'Tài liệu chưa có nội dung');
    return Column(
      children: [
        Expanded(
          child: deck.wrapPages(
            PageView.builder(
              key: deck.pagerKey,
              controller: deck.controller,
              physics: deck.physics,
              onPageChanged: deck.onPageChanged,
              itemCount: deck.slides.length,
              itemBuilder: (_, i) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: deck.wrapSlide(
                  i,
                  SlideFrame(radius: AppRadius.slide, padding: 20, child: SlideContent(page: deck.slides[i], scale: BlockScale.slideMobile, quiz: deck.quiz)),
                ),
              ),
            ),
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.screen_rotation_outlined, size: 16, color: AppColors.textMuted),
              SizedBox(width: 6),
              Flexible(child: Text('Xoay ngang để trình chiếu toàn màn hình', style: AppText.caption, textAlign: TextAlign.center)),
            ],
          ),
        ),
      ],
    );
  }
}

/// Thanh dưới (điện thoại, kiểu Slide): trước · chấm trang · sau / Hoàn thành.
class MobileSlideFooter extends StatelessWidget {
  const MobileSlideFooter({super.key, required this.deck});

  final SlideDeck deck;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: AppColors.background, border: Border(top: BorderSide(color: AppColors.borderLight))),
      padding: EdgeInsets.fromLTRB(16, 10, 16, 18 + MediaQuery.paddingOf(context).bottom),
      child: Row(
        children: [
          RoundNavButton(icon: Icons.chevron_left_rounded, tooltip: 'Slide trước', onPressed: deck.index == 0 ? null : () => deck.onGoTo(deck.index - 1)),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SlideDots(count: deck.slides.length, index: deck.index, onTap: deck.onGoTo, marked: deck.marked),
                Text('${deck.index + 1} / ${deck.slides.length}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
              ],
            ),
          ),
          NextSlideButton(
            isLast: deck.isLast,
            isPreview: deck.isPreview,
            isCompleting: deck.isCompleting,
            onNext: () => deck.onGoTo(deck.index + 1),
            onComplete: deck.onComplete,
          ),
        ],
      ),
    );
  }
}
