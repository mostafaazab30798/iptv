import 'package:flutter/material.dart';
import 'package:iptv/app/theme/app_colors.dart';

/// Elevation shadows — subtle, dark-mode optimised.
abstract final class AppShadows {
  static List<BoxShadow> get card => const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ];

  static List<BoxShadow> get cardFocused => const [
        BoxShadow(
          color: AppColors.accentGlow,
          blurRadius: 20,
          spreadRadius: 2,
        ),
        BoxShadow(
          color: Color(0x55000000),
          blurRadius: 16,
          offset: Offset(0, 6),
        ),
      ];

  static List<BoxShadow> get dialog => const [
        BoxShadow(
          color: Color(0x66000000),
          blurRadius: 40,
          offset: Offset(0, 16),
        ),
      ];
}
