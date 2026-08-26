import 'package:flutter/material.dart';

/// Standard layout constants and padding helpers for the IPTV app.
abstract final class AppLayout {
  static const double topNavHeight = 56.0;
  static const double bottomRailHeight = 48.0;
  static const double sideRailWidth = 220.0;
  static const double compactSideRailWidth = 72.0;

  static const double cardAspectRatio16x9 = 16 / 9;
  static const double cardAspectRatio4x3 = 4 / 3;
  static const double cardAspectRatioPoster = 2 / 3;

  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: 24.0,
    vertical: 16.0,
  );
}
