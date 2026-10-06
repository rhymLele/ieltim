// annotate_theme.dart — Màu dùng trong module bôi đen & ghi chú.
// Nếu app đã có AppColors (weekly_docs/core/app_tokens.dart) thì trỏ các hằng số này sang đó.
import 'package:flutter/material.dart';

abstract final class AnnColors {
  static const primary = Color(0xFF800020);
  static const onPrimary = Color(0xFFFFF9F2);
  static const background = Color(0xFFFFF9F2);
  static const surface = Colors.white;
  static const soft = Color(0xFFFBF4EC);
  static const text = Color(0xFF2A1418);
  static const textMuted = Color(0xFF6B4A4F);
  static const textHint = Color(0xFFB9958C);
  static const border = Color(0xFFEFDCCB);
  static const borderStrong = Color(0xFFE5D2BF);
  static const toolOn = Color(0xFFF3E5D5);
  static const pinInactive = Color(0xFFB07A85);
  static const scrim = Color(0x732A1418);
}

/// 4 màu highlight.
enum HighlightColor {
  yellow('Vàng', Color(0xFFFBE3A6)),
  green('Xanh lá', Color(0xFFCDEBD6)),
  blue('Xanh dương', Color(0xFFCFE3F2)),
  pink('Hồng', Color(0xFFF7D0D8));

  const HighlightColor(this.label, this.color);
  final String label;
  final Color color;

  static HighlightColor fromName(String? n) =>
      HighlightColor.values.firstWhere((c) => c.name == n, orElse: () => HighlightColor.yellow);
}

/// 4 màu bút.
const kPenColors = <Color>[Color(0xFF800020), Color(0xFFE7A23B), Color(0xFF2F6FB0), Color(0xFF2F7A4B)];
const kPenColorNames = <String>['đỏ đô', 'vàng', 'xanh dương', 'xanh lá'];
