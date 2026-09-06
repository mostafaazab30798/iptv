import 'package:flutter/material.dart';
import 'package:iptv/shared/layouts/form_factor.dart';

/// Width bucket for simple responsive branches.
enum ScreenSize { compact, standard, wide }

/// Responsive breakpoints for cross-platform and multi-orientation IPTV UI.
abstract final class AppBreakpoints {
  /// Compact: phone portrait/landscape, or small window.
  static const double compact = 700.0;

  /// Medium / Standard: typical tablet, medium desktop window.
  static const double standard = 1200.0;

  // Wide: 4K TV, large desktop, wide web viewport.

  /// TV / desktop overscan inset (logical px). Applied in MaterialApp.builder.
  static const double overscan = ChromeHeights.overscanLogicalPx;

  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < compact;

  static bool isStandard(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    return w >= compact && w < standard;
  }

  static bool isWide(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= standard;

  static bool isPortrait(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.portrait;

  static bool isTooNarrow(BuildContext context) => false;

  /// Coarse width bucket used by [ResponsiveBuilder].
  static ScreenSize screenSizeOf(BuildContext context) {
    if (isCompact(context)) return ScreenSize.compact;
    if (isWide(context)) return ScreenSize.wide;
    return ScreenSize.standard;
  }

  /// Form factor from current [MediaQuery] + Android TV detection.
  static FormFactor formFactorOf(BuildContext context) =>
      FormFactorResolver.of(context);
}
