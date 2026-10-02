import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/brand_colors.dart';
import '../../domain/block_key.dart';
import '../../domain/models/weekly_doc.dart';
import '../../domain/slide_splitter.dart';
import '../blocks/block_context.dart';
import '../blocks/block_registry.dart';
import '../doc_theme.dart';

/// Kiểu "Slide" — tách theo section + slideBreak, xem bằng [PageView].
///
/// - Mobile dọc: thẻ bo 20 có bóng, nội dung dài cuộn trong thẻ.
/// - Ngang / desktop: khung 16:9 bọc [FittedBox].
/// - Điều khiển: trước/sau, chấm trang (trang hiện tại kéo dài), "n / N",
///   vuốt, phím ← → Space (web/desktop). Slide cuối: "Tiếp" → "Hoàn thành".
class SlideView extends StatefulWidget {
  const SlideView({
    super.key,
    required this.doc,
    required this.base,
    required this.currentSlide,
    required this.onSlideChanged,
    required this.onComplete,
    required this.isLandscape,
    this.enableKeyboard = true,
  });

  final WeeklyDoc doc;
  final BlockContext base;
  final int currentSlide;
  final ValueChanged<int> onSlideChanged;
  final VoidCallback onComplete;
  final bool isLandscape;

  /// Bật phím tắt (web/desktop). Tắt khi dùng trong preview admin.
  final bool enableKeyboard;

  @override
  State<SlideView> createState() => _SlideViewState();
}

class _SlideViewState extends State<SlideView> {
  late final PageController _pc;
  late final FocusNode _focus;

  List<Slide> get _slides => splitSlides(widget.doc);

  @override
  void initState() {
    super.initState();
    final n = _slides.length;
    _pc = PageController(
        initialPage: n == 0 ? 0 : widget.currentSlide.clamp(0, n - 1));
    _focus = FocusNode();
  }

  @override
  void didUpdateWidget(covariant SlideView old) {
    super.didUpdateWidget(old);
    if (old.doc != widget.doc) {
      final n = _slides.length;
      _pc.jumpToPage(
          n == 0 ? 0 : widget.currentSlide.clamp(0, n - 1));
      return;
    }
    if (old.currentSlide != widget.currentSlide &&
        (_pc.page == null || _pc.page!.round() != widget.currentSlide)) {
      final reduce =
          MediaQuery.maybeOf(context)?.disableAnimations ?? false;
      if (reduce) {
        _pc.jumpToPage(widget.currentSlide);
      } else {
        _pc.animateToPage(
          widget.currentSlide,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  @override
  void dispose() {
    _pc.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final n = _slides.length;
    final cur = widget.currentSlide;
    final next = cur + delta;
    if (next >= 0 && next < n) widget.onSlideChanged(next);
  }

  void _nextOrComplete() {
    final n = _slides.length;
    if (widget.currentSlide + 1 < n) {
      widget.onSlideChanged(widget.currentSlide + 1);
    } else {
      widget.onComplete();
    }
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final k = event.logicalKey;
    if (k == LogicalKeyboardKey.arrowLeft || k == LogicalKeyboardKey.arrowUp) {
      _go(-1);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.arrowRight ||
        k == LogicalKeyboardKey.arrowDown) {
      _go(1);
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.space) {
      _nextOrComplete();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final slides = _slides;
    final n = slides.length;
    final cur = widget.currentSlide.clamp(0, n == 0 ? 0 : n - 1);

    return Column(
      key: const Key('slide_view'),
      children: [
        Expanded(
          child: Focus(
            focusNode: _focus,
            autofocus: widget.enableKeyboard,
            onKeyEvent: _onKey,
            child: PageView.builder(
              controller: _pc,
              onPageChanged: (i) {
                if (i != widget.currentSlide) widget.onSlideChanged(i);
              },
              itemCount: n,
              itemBuilder: (context, i) {
                final slide = slides[i];
                final section = widget.doc.sections[slide.sectionIndex];
                return _SlideCard(
                  isLandscape: widget.isLandscape,
                  number: section.number ?? (slide.sectionIndex + 1),
                  title: section.title,
                  sectionIndex: slide.sectionIndex,
                  blockStartIndex: slide.blockStartIndex,
                  blocks: slide.blocks,
                  base: widget.base,
                  doc: widget.doc,
                );
              },
            ),
          ),
        ),
        _SlideControls(
          index: cur,
          total: n,
          onPrev: () => _go(-1),
          onNextOrComplete: _nextOrComplete,
          onComplete: widget.onComplete,
        ),
      ],
    );
  }
}

class _SlideCard extends StatelessWidget {
  const _SlideCard({
    required this.isLandscape,
    required this.number,
    required this.title,
    required this.sectionIndex,
    required this.blockStartIndex,
    required this.blocks,
    required this.base,
    required this.doc,
  });

  final bool isLandscape;
  final int number;
  final String title;
  final int sectionIndex;
  final int blockStartIndex;
  final List<DocBlock> blocks;
  final BlockContext base;
  final WeeklyDoc doc;

  @override
  Widget build(BuildContext context) {
    if (isLandscape) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: FittedBox(
            fit: BoxFit.contain,
            child: SizedBox(
              width: _SlideViewDesign.width,
              height: _SlideViewDesign.height,
              child: _Card(
                padding: const EdgeInsets.all(40),
                child: _content(context),
              ),
            ),
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _Card(
        padding: const EdgeInsets.all(20),
        child: _content(context),
      ),
    );
  }

  Widget _content(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                    color: Color(0xFF800020), shape: BoxShape.circle),
                alignment: Alignment.center,
                child: Text(
                  '$number',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 14),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: DocFonts.title(size: 22),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          for (var b = 0; b < blocks.length; b++)
            BlockRegistry.build(
              context,
              blocks[b],
              base.copyWith(
                blockKey:
                    blockKey(sectionIndex, blockStartIndex + b, blocks[b]),
              ),
            ),
        ],
      ),
    );
  }
}

class _SlideViewDesign {
  static const double width = 900;
  static const double height = 506;
}

class _Card extends StatelessWidget {
  const _Card({required this.padding, required this.child});

  final EdgeInsetsGeometry padding;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 3,
      shadowColor: Brand.shadow,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class _SlideControls extends StatelessWidget {
  const _SlideControls({
    required this.index,
    required this.total,
    required this.onPrev,
    required this.onNextOrComplete,
    required this.onComplete,
  });

  final int index;
  final int total;
  final VoidCallback onPrev;
  final VoidCallback onNextOrComplete;
  final VoidCallback onComplete;

  bool get _isLast => index >= total - 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Brand.background,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          IconButton(
            key: const Key('slide_prev'),
            tooltip: 'Trang trước',
            icon: const Icon(Icons.chevron_left, size: 28),
            color: Brand.textPrimary,
            onPressed: index > 0 ? onPrev : null,
          ),
          Expanded(
            child: Center(
              child: SizedBox(
                height: 12,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (var i = 0; i < total; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeOut,
                        width: i == index ? 20 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: i == index ? Brand.primary : Brand.border,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Text(
            '${index + 1} / $total',
            key: const Key('slide_counter'),
            style: DocFonts.body(
                size: 13, weight: FontWeight.w600, color: Brand.textSecondary),
          ),
          const SizedBox(width: 12),
          if (_isLast)
            SizedBox(
              key: const Key('slide_complete'),
              height: 44,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Brand.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: total > 0 ? onComplete : null,
                child: const Text(
                  'Hoàn thành',
                  style: TextStyle(
                      fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            )
          else
            IconButton(
              key: const Key('slide_next'),
              tooltip: 'Trang sau',
              icon: const Icon(Icons.chevron_right, size: 28),
              color: Brand.primary,
              onPressed: onNextOrComplete,
            ),
        ],
      ),
    );
  }
}
