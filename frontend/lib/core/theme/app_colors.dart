import 'package:flutter/material.dart';

/// Nơi DUY NHẤT khai báo giá trị màu của app (FLUTTER_STANDARDS mục 17).
/// Page / Widget chỉ tham chiếu `AppColors.xxx`, không viết `Color(0x…)` / `Colors.xxx`.
class AppColors {
  const AppColors._();

  // ── Màu dùng chung (các màn cũ) ──
  static const Color primary = Color(0xFF800020);
  static const Color secondary = Color(0xFFD45060);
  static const Color surface = Color(0xFFF3E6D5);
  static const Color background = Color(0xFFFFF9F2);
  static const Color textPrimary = Color(0xFF2D2D2D);
  static const Color textSecondary = Color(0xFF6B6B6B);
  static const Color border = Color(0xFFE8DDD3);
  static const Color white = Colors.white;
  static const Color transparent = Colors.transparent;

  // ── Bảng màu thương hiệu (Tài liệu theo tuần, spec file 5 & 6) ──
  static const Color onPrimary = Color(0xFFFFF9F2);

  /// Nền card / slide (trắng). Khác [surface] (kem) của các màn cũ.
  static const Color cardSurface = Color(0xFFFFFFFF);
  static const Color sidebar = Color(0xFFF3E5D5);

  /// Viền mảnh của card, đường kẻ. Khác [border] của các màn cũ.
  static const Color borderLight = Color(0xFFEFDCCB);
  static const Color borderStrong = Color(0xFFE5D2BF);
  static const Color navActive = Color(0xFFE7C9BC);

  /// Chữ chính (nâu đậm). Khác [textPrimary] (xám) của các màn cũ.
  static const Color textInk = Color(0xFF2A1418);
  static const Color textMuted = Color(0xFF6B4A4F);
  static const Color textDisabled = Color(0xFFB9958C);
  static const Color gold = Color(0xFFE7A23B);
  static const Color goldLight = Color(0xFFF2C06B);
  static const Color softOnPrimary = Color(0xFFF3D9C4);
  static const Color success = Color(0xFF2F7A4B);
  static const Color successBg = Color(0xFFE6F3EA);
  static const Color errorBg = Color(0xFFFBEAEC);
  static const Color errorBorder = Color(0xFFF1C9CF);
  static const Color tipBg = Color(0xFFFDF1DE);
  static const Color tipText = Color(0xFF5A3A10);
  static const Color tipIcon = Color(0xFFB7791F);
  static const Color warnText = Color(0xFF8A5A12);
  static const Color water = Color(0xFFE4EDF0);
  static const Color readerBg = Color(0xFFF6EEE5);
  static const Color previewBg = Color(0xFFFBF4EC);
  static const Color hover = Color(0xFFFBF1E6);
  static const Color locked = Color(0xFFF6EEE5);
  static const Color codeBg = Color(0xFF1F1214);
  static const Color codeBorder = Color(0xFF3A2226);
  static const Color codeText = Color(0xFFF3D9C4);
  static const Color archived = Color(0xFF9A8A86);
  static const Color archivedBg = Color(0xFFF1ECE8);
  static const Color disabledButton = Color(0xFFC9A9A3);

  /// Chữ "ieltshub." mờ góc slide.
  static const Color watermark = Color(0xFFE9D0C8);

  /// Viền vàng tô khối đang sửa trong khung xem trước.
  static const Color highlightRing = Color(0xE6E7A23B);
  static const Color highlightGlow = Color(0x2EE7A23B);

  /// Minh hoạ lá sen ở trạng thái rỗng.
  static const Color lilyPad = Color(0xFF9FB08F);
  static const Color lilyFlower = Color(0xFFF4C7CF);

  /// Bóng đổ của slide / khung xem trước.
  static const Color shadowSlide = Color(0x1A800020);
  static const Color shadowPreview = Color(0x1F800020);
}
