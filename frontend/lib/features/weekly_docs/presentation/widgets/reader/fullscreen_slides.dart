import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/app_tokens.dart';
import '../block_view.dart';
import '../doc_renderers.dart';
import 'slide_views.dart';

/// Điện thoại xoay ngang: slide 16:9 toàn màn, chạm cạnh để chuyển, chạm giữa để hiện điều khiển 3 giây.
class FullscreenSlides extends StatefulWidget {
  const FullscreenSlides({super.key, required this.deck, required this.onExit});

  final SlideDeck deck;

  /// Thoát trình chiếu (chuyển sang kiểu Doc).
  final VoidCallback onExit;

  @override
  State<FullscreenSlides> createState() => _FullscreenSlidesState();
}

class _FullscreenSlidesState extends State<FullscreenSlides> {
  bool _chromeVisible = true;
  Timer? _chromeTimer;

  @override
  void dispose() {
    _chromeTimer?.cancel();
    super.dispose();
  }

  void _showChrome() {
    setState(() => _chromeVisible = true);
    _chromeTimer?.cancel();
    _chromeTimer = Timer(const Duration(seconds: 3), () {
      if (mounted) setState(() => _chromeVisible = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final deck = widget.deck;
    return Scaffold(
      backgroundColor: AppColors.textInk,
      body: Stack(
        children: [
          Center(
            child: AspectRatio(
              aspectRatio: 16 / 9,
              child: PageView.builder(
                controller: deck.controller,
                onPageChanged: deck.onPageChanged,
                itemCount: deck.slides.length,
                itemBuilder: (_, i) => SlideFrame(radius: 0, padding: 28, child: SlideContent(page: deck.slides[i], scale: BlockScale.slideMobile, quiz: deck.quiz)),
              ),
            ),
          ),
          Positioned.fill(
            child: Row(
              children: [
                SizedBox(width: 64, child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: () => deck.onGoTo(deck.index - 1))),
                Expanded(child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: _showChrome)),
                SizedBox(width: 64, child: GestureDetector(behavior: HitTestBehavior.translucent, onTap: () => deck.onGoTo(deck.index + 1))),
              ],
            ),
          ),
          if (_chromeVisible)
            Positioned(
              left: 12,
              top: 12,
              child: SafeArea(child: RoundNavButton(icon: Icons.close_rounded, tooltip: 'Thoát trình chiếu', size: 44, onPressed: widget.onExit)),
            ),
          if (_chromeVisible)
            Positioned(
              right: 16,
              bottom: 12,
              child: SafeArea(
                child: Text('${deck.index + 1} / ${deck.slides.length}', style: const TextStyle(color: AppColors.onPrimary, fontWeight: FontWeight.w700)),
              ),
            ),
        ],
      ),
    );
  }
}
