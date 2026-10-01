// your_pond_card.dart — IELTS Hub
//
// Card "Ao của bạn": mỗi ngày học liên tiếp thêm một chú cá koi,
// số liệu đếm từ 0 lên, chạm vào mặt nước tạo gợn sóng.
//
//   YourPondCard(streakDays: 5, savedWords: 128)                 // trong Expanded / chiều cao cố định
//   YourPondCard(streakDays: 5, savedWords: 128, pondHeight: 260) // trong ListView / Column cuộn

import 'package:flutter/material.dart';

import 'fx_common.dart';
import 'koi_pond.dart';

class YourPondCard extends StatelessWidget {
  const YourPondCard({
    super.key,
    required this.streakDays,
    required this.savedWords,
    this.primary = FxColors.primary,
    this.background = FxColors.background,
    this.pondHeight,
    this.maxFish = 12,
    this.onTap,
    this.rippleEffects = true,
  });

  final int streakDays;
  final int savedWords;
  final Color primary;
  final Color background;

  /// null = ao giãn hết chiều cao còn lại (card phải có chiều cao giới hạn).
  final double? pondHeight;
  final int maxFish;

  /// Bấm vào tiêu đề (ví dụ mở trang thống kê).
  final VoidCallback? onTap;

  /// Vệt nước sau đuôi cá, ánh nước trôi chậm, gợn tròn tự nhiên (giống màn Welcome).
  final bool rippleEffects;

  static const _border = Color(0xFFEFDCCB);
  static const _muted = Color(0xFF6B4A4F);

  @override
  Widget build(BuildContext context) {
    final fish = streakDays.clamp(0, maxFish);
    final pond = ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFF1E2D3)),
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: KoiPond(
                fishCount: fish,
                primary: primary,
                backgroundColor: background,
                wakes: rippleEffects,
                caustics: rippleEffects,
                ambientRipples: rippleEffects,
              ),
            ),
            if (fish == 0)
              const Center(
                child: IgnorePointer(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text(
                      'Học bài đầu tiên hôm nay để thả chú cá đầu tiên',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted, fontSize: 13),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return Material(
      color: Colors.white,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: _border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
        mainAxisSize: pondHeight == null ? MainAxisSize.max : MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(8),
            child: LayoutBuilder(
              builder: (context, constraints) {
                const title = Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Ao của bạn', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Color(0xFF2A1418))),
                    SizedBox(height: 2),
                    Text(
                      'Mỗi ngày học liên tiếp thêm một chú cá. Chạm vào mặt nước thử xem.',
                      style: TextStyle(fontSize: 13, color: _muted),
                    ),
                  ],
                );
                // Card hẹp (điện thoại): số liệu xuống dưới tiêu đề, căn trái.
                final narrow = constraints.maxWidth < 420;
                final align = narrow ? CrossAxisAlignment.start : CrossAxisAlignment.end;
                final stats = Wrap(
                  spacing: 20,
                  runSpacing: 8,
                  children: [
                    _CountUpStat(value: streakDays, label: 'ngày liên tiếp', color: primary, align: align),
                    _CountUpStat(value: savedWords, label: 'từ đã lưu', color: primary, align: align),
                  ],
                );
                if (narrow) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [title, const SizedBox(height: 12), stats],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [const Expanded(child: title), const SizedBox(width: 16), stats],
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          if (pondHeight == null) Expanded(child: pond) else SizedBox(height: pondHeight, child: pond),
          ],
        ),
      ),
    );
  }
}

class _CountUpStat extends StatelessWidget {
  const _CountUpStat({
    required this.value,
    required this.label,
    required this.color,
    this.align = CrossAxisAlignment.end,
  });
  final int value;
  final String label;
  final Color color;
  final CrossAxisAlignment align;

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return Column(
      crossAxisAlignment: align,
      mainAxisSize: MainAxisSize.min,
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: value.toDouble()),
          duration: reduce ? Duration.zero : const Duration(milliseconds: 1200),
          curve: Curves.easeOutCubic,
          builder: (context, v, _) => Text(
            '${v.round()}',
            style: TextStyle(fontSize: 24, height: 1, fontWeight: FontWeight.w800, color: color),
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 12, color: Color(0xFF6B4A4F))),
      ],
    );
  }
}
