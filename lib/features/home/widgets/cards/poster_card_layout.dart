import 'package:flutter/material.dart';
import 'package:iptv/shared/layouts/form_factor.dart';

/// Shared poster geometry for [MovieCard] / [SeriesCard] / [HistoryCard] and
/// Pattern-B grids (favorites / search). Cards scale from the cell or row size
/// instead of assuming phone-tuned fixed pixel heights.
abstract final class PosterCardLayout {
  static const double defaultWidth = 120;
  static const double defaultPosterHeight = 175;
  static const double titleGap = 7;

  /// Approximate single-line title strip (12sp + leading).
  static const double titleLineExtent = 16;

  static double get titleStrip => titleGap + titleLineExtent;

  /// `width / fullCardHeight` for [SliverGridDelegateWithMaxCrossAxisExtent].
  /// Full card ≈ poster (2:3) + [titleStrip].
  static const double gridChildAspectRatio = 0.62;

  static double posterHeightForWidth(double width) =>
      width * (defaultPosterHeight / defaultWidth);

  /// Fit a poster + title into the given bounds (grid cell or home row slot).
  static ({double width, double posterHeight}) fit({
    required double maxWidth,
    double? maxHeight,
  }) {
    final width = maxWidth.isFinite && maxWidth > 0 ? maxWidth : defaultWidth;
    var posterHeight = posterHeightForWidth(width);
    if (maxHeight != null && maxHeight.isFinite) {
      final available = maxHeight - titleStrip;
      if (available > 0 && posterHeight > available) {
        posterHeight = available;
      }
    }
    if (posterHeight < 1) posterHeight = 1;
    return (width: width, posterHeight: posterHeight);
  }

  /// Home / search horizontal poster row metrics by [FormFactor].
  static ({double height, double itemWidth}) posterRowMetrics(
    FormFactor factor,
  ) {
    switch (factor) {
      case FormFactor.tv:
        // Slightly denser than the phone-derived TV pass so more of Home is
        // visible without making the poster titles hard to read.
        return (height: 200, itemWidth: 120);
      case FormFactor.tablet:
        return (height: 200, itemWidth: 112);
      case FormFactor.desktop:
      case FormFactor.phone:
        return (height: 215, itemWidth: 120);
    }
  }

  static ({double height, double itemWidth}) posterRowMetricsOf(
    BuildContext context,
  ) => posterRowMetrics(FormFactorResolver.of(context));
}
