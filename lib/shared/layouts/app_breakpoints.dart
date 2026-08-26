import 'package:flutter/material.dart';

/// Responsive breakpoints for cross-platform and multi-orientation IPTV UI.
abstract final class AppBreakpoints {
  /// Compact: phone portrait/landscape, or small window.
  static const double compact = 700.0;

  /// Medium / Standard: typical tablet, medium desktop window.
  static const double standard = 1200.0;

  // Wide: 4K TV, large desktop, wide web viewport.

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
}
