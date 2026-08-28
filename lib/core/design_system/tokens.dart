import 'package:flutter/material.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_motion.dart';
import 'package:iptv/app/theme/app_radius.dart';
import 'package:iptv/app/theme/app_spacing.dart';

/// Compatibility facade for product-wide visual tokens.
abstract final class DesignTokens {
  static const Color primary = AppColors.accent;
  static const Color accentWarm = Color(0xFFFFB547);
  static const Color accentCool = Color(0xFF6FE7C8);

  static const Color neutral0 = AppColors.bg0;
  static const Color neutral10 = AppColors.bg1;
  static const Color neutral20 = AppColors.bg2;
  static const Color neutral30 = AppColors.bg3;
  static const Color neutral40 = AppColors.bg4;
  static const Color neutral50 = AppColors.textDisabled;
  static const Color neutral70 = AppColors.textSecondary;
  static const Color neutral95 = AppColors.textPrimary;

  static const Color success = AppColors.success;
  static const Color warning = Color(0xFFF3B33D);
  static const Color error = Color(0xFFE75A5A);
  static const Color info = Color(0xFF64B5F6);
  static const Color glassFill = Color(0xD90E1014);
  static const Color glassBorder = Color(0x24FFFFFF);

  static const double space4 = AppSpacing.xxs;
  static const double space8 = AppSpacing.xs;
  static const double space12 = AppSpacing.sm;
  static const double space16 = AppSpacing.md;
  static const double space24 = AppSpacing.xl;
  static const double space32 = AppSpacing.xxl;

  static const double radius4 = AppRadius.xs;
  static const double radius8 = AppRadius.sm;

  static const Duration motionFast = AppMotion.fast;
  static const Duration motionStandard = AppMotion.medium;
  static const Duration motionSlow = AppMotion.slow;
  static const Curve motionCurve = Curves.easeOutCubic;

  static const List<BoxShadow> surfaceShadow = [
    BoxShadow(color: Color(0x40001624), blurRadius: 16, offset: Offset(0, 6)),
  ];
}
