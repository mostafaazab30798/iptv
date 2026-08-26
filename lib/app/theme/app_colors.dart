import 'package:flutter/material.dart';

/// Premium dark media-center color palette.
abstract final class AppColors {
  // ---------------------------------------------------------------------------
  // Brand
  // ---------------------------------------------------------------------------

  /// Primary accent — electric cyan-blue, vivid but not garish.
  static const Color accent = Color(0xFF00C2FF);
  static const Color accentDim = Color(0xFF0091BF);
  static const Color accentGlow = Color(0x2600C2FF);

  // ---------------------------------------------------------------------------
  // Backgrounds (darkest → lightest)
  // ---------------------------------------------------------------------------

  static const Color bg0 = Color(0xFF08090B); // deepest background
  static const Color bg1 = Color(0xFF0E1014); // card base
  static const Color bg2 = Color(0xFF14171D); // elevated surfaces
  static const Color bg3 = Color(0xFF1B1F28); // hover / focused surface
  static const Color bg4 = Color(0xFF242938); // selected / active surface

  // ---------------------------------------------------------------------------
  // Borders & separators
  // ---------------------------------------------------------------------------

  static const Color border = Color(0x1FFFFFFF); // subtle 12% white
  static const Color borderFocused = Color(0x4D00C2FF); // 30% accent

  // ---------------------------------------------------------------------------
  // Text
  // ---------------------------------------------------------------------------

  static const Color textPrimary = Color(0xFFF0F2F5);
  static const Color textSecondary = Color(0xFF8E96A8);
  static const Color textDisabled = Color(0xFF4A5060);
  static const Color textOnAccent = Color(0xFF001822);

  // ---------------------------------------------------------------------------
  // Semantic
  // ---------------------------------------------------------------------------

  static const Color live = Color(0xFFFF3B3B);   // live badge
  static const Color success = Color(0xFF2ECC71);
  static const Color warning = Color(0xFFF39C12);
  static const Color error = Color(0xFFE74C3C);

  // ---------------------------------------------------------------------------
  // Overlays
  // ---------------------------------------------------------------------------

  static const Color scrimLight = Color(0x26000000); // 15%
  static const Color scrimDark = Color(0xCC000000);  // 80%

  // ---------------------------------------------------------------------------
  // Focus ring
  // ---------------------------------------------------------------------------

  static const Color focusRing = accent;
  static const Color focusRingDim = accentDim;
}
