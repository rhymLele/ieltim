// app_tokens.dart — Design tokens IELTS Hub (theo 5_ai_rules_FE_flutter.md).
// Mọi màu / cỡ chữ / khoảng cách trong feature lấy từ đây, không hard-code.

import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF800020);
  static const onPrimary = Color(0xFFFFF9F2);
  static const background = Color(0xFFFFF9F2);
  static const surface = Color(0xFFFFFFFF);
  static const sidebar = Color(0xFFF3E5D5);
  static const border = Color(0xFFEFDCCB);
  static const borderStrong = Color(0xFFE5D2BF);
  static const navActive = Color(0xFFE7C9BC);
  static const text = Color(0xFF2A1418);
  static const textMuted = Color(0xFF6B4A4F);
  static const textDisabled = Color(0xFFB9958C);
  static const gold = Color(0xFFE7A23B);
  static const goldLight = Color(0xFFF2C06B);
  static const softOnPrimary = Color(0xFFF3D9C4);
  static const success = Color(0xFF2F7A4B);
  static const successBg = Color(0xFFE6F3EA);
  static const errorBg = Color(0xFFFBEAEC);
  static const errorBorder = Color(0xFFF1C9CF);
  static const tipBg = Color(0xFFFDF1DE);
  static const tipText = Color(0xFF5A3A10);
  static const tipIcon = Color(0xFFB7791F);
  static const warnText = Color(0xFF8A5A12);
  static const water = Color(0xFFE4EDF0);
  static const readerBg = Color(0xFFF6EEE5);
  static const previewBg = Color(0xFFFBF4EC);
  static const hover = Color(0xFFFBF1E6);
  static const locked = Color(0xFFF6EEE5);
  static const codeBg = Color(0xFF1F1214);
  static const codeBorder = Color(0xFF3A2226);
  static const codeText = Color(0xFFF3D9C4);
  static const archived = Color(0xFF9A8A86);
  static const archivedBg = Color(0xFFF1ECE8);
  static const disabledButton = Color(0xFFC9A9A3);
}

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
  static const display = TextStyle(fontFamily: _f, fontSize: 30, height: 1.2, fontWeight: FontWeight.w800, letterSpacing: -0.6, color: AppColors.text);
  static const title = TextStyle(fontFamily: _f, fontSize: 24, height: 1.2, fontWeight: FontWeight.w800, letterSpacing: -0.4, color: AppColors.text);
  static const heading = TextStyle(fontFamily: _f, fontSize: 18, height: 1.25, fontWeight: FontWeight.w800, color: AppColors.text);
  static const body = TextStyle(fontFamily: _f, fontSize: 15, height: 1.55, fontWeight: FontWeight.w400, color: AppColors.text);
  static const label = TextStyle(fontFamily: _f, fontSize: 13, height: 1.3, fontWeight: FontWeight.w700, color: AppColors.text);
  static const caption = TextStyle(fontFamily: _f, fontSize: 12, height: 1.4, fontWeight: FontWeight.w500, color: AppColors.textMuted);
  static const eyebrow = TextStyle(fontFamily: _f, fontSize: 12, height: 1.3, fontWeight: FontWeight.w800, letterSpacing: 1.4, color: AppColors.textMuted);
  static const mono = TextStyle(fontFamily: 'monospace', fontSize: 12.5, height: 1.6, color: AppColors.codeText);
  static const serif = 'Georgia';
}

abstract final class AppShadows {
  static const slide = [BoxShadow(color: Color(0x1A800020), blurRadius: 30, offset: Offset(0, 14))];
  static const preview = [BoxShadow(color: Color(0x1F800020), blurRadius: 28, offset: Offset(0, 12))];
}

/// ThemeData dùng chung. Thêm font Manrope vào pubspec (assets hoặc google_fonts).
ThemeData buildIeltsHubTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    primary: AppColors.primary,
    onPrimary: AppColors.onPrimary,
    surface: AppColors.surface,
  );
  final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md));
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Manrope',
    scaffoldBackgroundColor: AppColors.background,
    dividerColor: AppColors.border,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.background,
      foregroundColor: AppColors.text,
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.onPrimary,
        disabledBackgroundColor: AppColors.disabledButton,
        disabledForegroundColor: AppColors.onPrimary,
        minimumSize: const Size(44, 44),
        shape: shape,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.primary,
        backgroundColor: AppColors.surface,
        minimumSize: const Size(44, 44),
        side: const BorderSide(color: AppColors.borderStrong),
        shape: shape,
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.textMuted,
        minimumSize: const Size(44, 44),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.borderStrong)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.borderStrong)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md), borderSide: const BorderSide(color: AppColors.primary)),
      hintStyle: const TextStyle(color: AppColors.textDisabled, fontSize: 14),
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}

bool reduceMotionOf(BuildContext context) => MediaQuery.maybeDisableAnimationsOf(context) ?? false;

Duration motion(BuildContext context, int ms) => reduceMotionOf(context) ? Duration.zero : Duration(milliseconds: ms);
