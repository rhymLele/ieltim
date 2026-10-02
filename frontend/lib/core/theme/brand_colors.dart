import 'package:flutter/material.dart';

/// Bộ màu thương hiệu cho feature "Tài liệu theo tuần".
///
/// Tách riêng khỏi [AppColors] (đang dùng ở các màn cũ) để không làm lệch UI
/// hiện có khi thay đổi token. Khớp bảng màu trong spec.
class Brand {
  Brand._();

  // Bảng màu nền tảng
  static const primary = Color(0xFF800020);
  static const background = Color(0xFFFFF9F2);
  static const sidebar = Color(0xFFF3E5D5);
  static const border = Color(0xFFEFDCCB);
  static const textPrimary = Color(0xFF2A1418);
  static const textSecondary = Color(0xFF6B4A4F);
  static const gold = Color(0xFFE7A23B);
  static const goldLight = Color(0xFFF2C06B);
  static const surface = Color(0xFFFFFFFF);

  // Semantic
  static const calloutBackground = Color(0xFFFDF1DE); // callout "Mẹo"
  static const stepBox = Color(0xFFF3E5D5); // ô số của steps
  static const passageBackground = Color(0xFFFDF6EC); // khung passage nền kem
  static const success = Color(0xFF2F7A4B); // quiz chọn đúng
  static const error = primary; // quiz chọn sai dùng primary
  static const unknownBackground = Color(0xFFEDE6DE); // UnknownBlock
  static const unknownText = Color(0xFF6B4A4F);
  static const disabled = Color(0xFFB9A79F);
  static const shadow = Color(0x142A1418);

  static const _goldDark = Color(0xFFB97A1E);
  static Color get goldDark => _goldDark;
}
