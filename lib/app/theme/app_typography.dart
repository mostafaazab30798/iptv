import 'package:flutter/material.dart';
import 'package:iptv/app/theme/app_colors.dart';

/// Typography scale — bundled Noto Sans for Latin, Cairo for Arabic.
///
/// Fonts are declared in pubspec.yaml as static weight files (no runtime
/// google_fonts fetch, no variable-font weight mapping). Cairo ships Regular /
/// Medium / SemiBold / Bold to match [FontWeight] w400–w700 used below.
abstract final class AppTypography {
  static const _baseTextTheme = TextTheme(
    // Display
    displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.w700),
    displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.w700),
    displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.w600),
    // Headline
    headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.w600),
    headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
    headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w500),
    // Title
    titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
    titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
    titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    // Body
    bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w400),
    bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w400),
    bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
    // Label
    labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
    labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
  );

  static TextTheme get textTheme => textThemeForLocale(const Locale('en'));

  static TextTheme textThemeForLocale(Locale? locale) {
    final isArabic = locale?.languageCode == 'ar';
    final family = isArabic ? 'Cairo' : 'NotoSans';
    final base = _baseTextTheme.apply(
      fontFamily: family,
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );
    return base;
  }
}
