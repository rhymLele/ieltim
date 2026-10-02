import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/brand_colors.dart';

/// Kiểu chữ của feature "Tài liệu theo tuần".
///
/// - Bản thân nội dung: **Manrope**.
/// - Đoạn đề thi ([PassageBlock]): **serif** (Lora).
class DocFonts {
  DocFonts._();

  static TextStyle title({double size = 26, Color? color}) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color ?? Brand.textPrimary,
        height: 1.2,
      );

  /// Heading khối: 24–34, đậm 800.
  static TextStyle heading({double size = 28}) =>
      GoogleFonts.manrope(
        fontSize: size.clamp(24, 34),
        fontWeight: FontWeight.w800,
        color: Brand.textPrimary,
        height: 1.25,
      );

  static TextStyle body({
    double size = 16,
    Color? color,
    double height = 1.6,
    FontWeight weight = FontWeight.w400,
  }) =>
      GoogleFonts.manrope(
        fontSize: size,
        color: color ?? Brand.textPrimary,
        height: height,
        fontWeight: weight,
      );

  /// Serif cho đoạn đề thi.
  static TextStyle serif({
    double size = 16,
    Color? color,
    double height = 1.7,
    FontWeight weight = FontWeight.w400,
  }) =>
      GoogleFonts.lora(
        fontSize: size,
        color: color ?? Brand.textPrimary,
        height: height,
        fontWeight: weight,
      );

  /// Nhãn nhỏ chữ hoa (kicker / label).
  static TextStyle kicker({double size = 12, Color? color}) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color ?? Brand.textSecondary,
        letterSpacing: 0.8,
      );

  static TextStyle mono({double size = 13, Color? color}) =>
      GoogleFonts.ibmPlexMono(
        fontSize: size,
        color: color ?? Brand.textPrimary,
      );
}
