import 'package:flutter/material.dart';

class GridBackgroundPainter extends CustomPainter {
  final double spacing;
  final Color lineColor;

  GridBackgroundPainter({
    required this.spacing,
    required this.lineColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 0.5;

    double x = 0;
    while (x < size.width) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      x += spacing;
    }

    double y = 0;
    while (y < size.height) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      y += spacing;
    }
  }

  @override
  bool shouldRepaint(GridBackgroundPainter oldDelegate) =>
      oldDelegate.spacing != spacing || oldDelegate.lineColor != lineColor;
}

class GridBackgroundContainer extends StatelessWidget {
  final Widget child;

  const GridBackgroundContainer({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFF9F2),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: GridBackgroundPainter(
                spacing: 32,
                lineColor: const Color(0xFF800020).withValues(alpha: 0.06),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
