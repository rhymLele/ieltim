import 'package:flutter/material.dart';

import '../../../core/app_tokens.dart';
import '../../../domain/entities/week_info.dart';

/// Ô viền nét đứt cuối danh sách: tài liệu mới sẽ hiện khi admin xuất bản, tuần kế tiếp mở khi nào.
class NewDocsHint extends StatelessWidget {
  const NewDocsHint({super.key, this.nextWeek});

  final WeekInfo? nextWeek;

  @override
  Widget build(BuildContext context) {
    final next = nextWeek;
    return CustomPaint(
      painter: const _DashedBorderPainter(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Text(
          'Tài liệu mới của tuần sẽ hiện ở đây khi admin xuất bản.${next == null ? '' : ' Tuần ${next.number} ${next.opensLabel.toLowerCase()}.'}',
          style: AppText.caption.copyWith(fontSize: 13, height: 1.5),
        ),
      ),
    );
  }
}

class _DashedBorderPainter extends CustomPainter {
  const _DashedBorderPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rrect = RRect.fromRectAndRadius(Offset.zero & size, const Radius.circular(AppRadius.lg));
    final path = Path()..addRRect(rrect);
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = AppColors.borderStrong;
    for (final metric in path.computeMetrics()) {
      var distance = 0.0;
      while (distance < metric.length) {
        canvas.drawPath(metric.extractPath(distance, (distance + 6).clamp(0, metric.length)), paint);
        distance += 11;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
