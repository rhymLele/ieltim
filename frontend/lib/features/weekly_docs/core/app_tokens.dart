// app_tokens.dart — Design tokens của feature (khoảng cách, bo góc, chữ, bóng) theo 5_ai_rules_FE_flutter.md.
// Màu lấy từ core/theme/app_colors.dart (FLUTTER_STANDARDS mục 17: một nguồn màu duy nhất).

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

export '../../../core/theme/app_colors.dart';

abstract final class AppSpace {
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 20.0;
  static const xxl = 24.0;
  static const xxxl = 32.0;
}

abstract final class AppRadius {
  static const sm = 8.0;
  static const md = 10.0;
  static const lg = 12.0;
  static const card = 14.0;
  static const cardLg = 16.0;
  static const slide = 20.0;
  static const pill = 999.0;
}

abstract final class AppBreakpoints {
  static const tablet = 600.0;
  static const desktop = 840.0;
  static const adminWide = 1024.0;
}

abstract final class AppText {
  static const _f = 'Manrope';
  static const display = TextStyle(fontFamily: _f, fontSize: 30, height: 1.2, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: AppColors.textInk);
  static const title = TextStyle(fontFamily: _f, fontSize: 24, height: 1.2, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: AppColors.textInk);
  static const heading = TextStyle(fontFamily: _f, fontSize: 18, height: 1.25, fontWeight: FontWeight.w800, color: AppColors.textInk);
  static const body = TextStyle(fontFamily: _f, fontSize: 15, height: 1.55, fontWeight: FontWeight.w400, color: AppColors.textInk);
  static const label = TextStyle(fontFamily: _f, fontSize: 13, height: 1.3, fontWeight: FontWeight.w700, color: AppColors.textInk);
  static const caption = TextStyle(fontFamily: _f, fontSize: 12, height: 1.4, fontWeight: FontWeight.w500, color: AppColors.textMuted);
  static const eyebrow = TextStyle(fontFamily: _f, fontSize: 12, height: 1.3, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: AppColors.textMuted);
  static const mono = TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.6, color: AppColors.codeText);
  static const serif = 'Georgia';
}

abstract final class AppShadows {
  static const slide = [BoxShadow(color: AppColors.shadowSlide, blurRadius: 30, offset: Offset(0, 14))];
  static const preview = [BoxShadow(color: AppColors.shadowPreview, blurRadius: 28, offset: Offset(0, 12))];
}

bool reduceMotionOf(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

Duration motion(BuildContext context, int ms) => reduceMotionOf(context) ? Duration.zero : Duration(milliseconds: ms);
