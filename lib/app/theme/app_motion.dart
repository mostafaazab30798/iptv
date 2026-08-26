import 'package:flutter/animation.dart';
import 'package:iptv/core/constants/app_constants.dart';

/// Animation duration and curve tokens.
abstract final class AppMotion {
  static const Duration fast   = AppConstants.animationFast;
  static const Duration medium = AppConstants.animationMedium;
  static const Duration slow   = AppConstants.animationSlow;

  // Standard easing — Material Design 3 inspired.
  static const curve = Curves.easeInOut;
  static const curveEnter = Curves.easeOut;
  static const curveExit = Curves.easeIn;
  static const curveBounce = Curves.elasticOut;

  // Focus transition — fast to feel snappy on TV remotes.
  static const focusDuration = Duration(milliseconds: 120);
  static const focusCurve = Curves.easeOut;
}
