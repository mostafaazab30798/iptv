import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:iptv/app/theme/app_colors.dart';

/// Typography scale — Noto Sans for Latin, Cairo for Arabic.
/// Automatically selects the right font for the active locale.
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
    final base = isArabic
        ? GoogleFonts.cairoTextTheme(_baseTextTheme)
        : GoogleFonts.notoSansTextTheme(_baseTextTheme);

    // Apply primary text colors
    return base.apply(
      bodyColor: AppColors.textPrimary,
      displayColor: AppColors.textPrimary,
    );
  }
}
