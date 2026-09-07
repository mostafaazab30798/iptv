import 'package:flutter/material.dart';
import 'package:iptv/core/platform/platform_service.dart';

/// Coarse device / window class used for chrome budgets and layout scaling.
///
/// Derived from logical viewport size plus [PlatformService.isAndroidTv].
/// Phase 1.1 exposes this for later consumers; phone chrome values match
/// today's fixed layouts so unused reads do not change visuals.
enum FormFactor { phone, tablet, desktop, tv }

/// Resolves [FormFactor] from geometry + Android TV capability.
abstract final class FormFactorResolver {
  /// Mirrors [AppBreakpoints.compact] (kept local to avoid import cycles).
  static const double _compactWidth = 700.0;

  /// Mirrors [AppBreakpoints.standard].
  static const double _standardWidth = 1200.0;

  /// Android TV always wins, even when the logical size looks phone-like
  /// (e.g. 1080p/tvdpi ≈ 960×540).
  static FormFactor resolve({required Size size, required bool isAndroidTv}) {
    if (isAndroidTv) return FormFactor.tv;

    final width = size.width;
    final height = size.height;
    final shortest = width < height ? width : height;

    if (width >= _standardWidth) return FormFactor.desktop;

    // Medium windows and large-shortest-side tablets.
    if (width >= _compactWidth || shortest >= 600) {
      return FormFactor.tablet;
    }

    return FormFactor.phone;
  }

  static FormFactor of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return resolve(
      size: size,
      isAndroidTv: PlatformService.instance.isAndroidTv,
    );
  }
}

/// Shared chrome / spacing budgets keyed by [FormFactor].
///
/// [overscan] is always [overscanLogicalPx] (28). Phase 1.2 applies it once in
/// `MaterialApp.builder` for TV/desktop form factors.
@immutable
class ChromeHeights {
  const ChromeHeights({
    required this.formFactor,
    required this.header,
    required this.dock,
    required this.heroFraction,
    required this.overscan,
  });

  /// Logical inset reserved for TV overscan (~5% of 540 ≈ 27).
  static const double overscanLogicalPx = 28.0;

  final FormFactor formFactor;

  /// Top nav / landscape header height.
  final double header;

  /// Portrait floating dock height (0 when unused).
  final double dock;

  /// Hero height as a fraction of viewport height (TV uses ~0.45 in Phase 1.2).
  final double heroFraction;

  /// Overscan inset in logical pixels (always [overscanLogicalPx]).
  final double overscan;

  static ChromeHeights of(BuildContext context) {
    final factor = FormFactorResolver.of(context);
    return forFactor(factor);
  }

  /// Header row plus top inset. Use [fromView] when MediaQuery top padding
  /// has been stripped (Home body) so the overlay still matches AppShell.
  static double headerExtentOf(BuildContext context, {bool fromView = false}) {
    final top = fromView
        ? MediaQueryData.fromView(View.of(context)).padding.top
        : MediaQuery.paddingOf(context).top;
    return top + of(context).header;
  }

  static ChromeHeights forFactor(FormFactor factor) {
    switch (factor) {
      case FormFactor.phone:
        // Matches current landscape header (70) and floating dock (64).
        return const ChromeHeights(
          formFactor: FormFactor.phone,
          header: 70,
          dock: 64,
          heroFraction: 0.38,
          overscan: 0.0,
        );
      case FormFactor.tablet:
        return const ChromeHeights(
          formFactor: FormFactor.tablet,
          header: 64,
          dock: 64,
          heroFraction: 0.40,
          overscan: 0.0,
        );
      case FormFactor.desktop:
        return const ChromeHeights(
          formFactor: FormFactor.desktop,
          header: 70,
          dock: 0,
          heroFraction: 0.38,
          overscan: 0.0,
        );
      case FormFactor.tv:
        return const ChromeHeights(
          formFactor: FormFactor.tv,
          header: 56,
          dock: 0,
          // Keep more of the first content rail visible on 960x540/tvdpi
          // screens. The previous 0.45 budget still felt phone-sized at a
          // typical ten-foot viewing distance.
          heroFraction: 0.40,
          overscan: overscanLogicalPx,
        );
    }
  }
}
