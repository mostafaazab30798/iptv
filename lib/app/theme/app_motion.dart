import 'package:flutter/widgets.dart';
import 'package:iptv/core/constants/app_constants.dart';

/// Animation duration and curve tokens.
abstract final class AppMotion {
  static const Duration fast = AppConstants.animationFast;
  static const Duration medium = AppConstants.animationMedium;
  static const Duration slow = AppConstants.animationSlow;

  // Standard easing — Material Design 3 inspired.
  static const curve = Curves.easeOutCubic;
  static const curveEnter = Curves.easeOutCubic;
  static const curveExit = Curves.easeInCubic;
  static const curveBounce = Curves.elasticOut;

  // Focus transition — fast to feel snappy on TV remotes.
  static const focusDuration = Duration(milliseconds: 120);
  static const focusCurve = Curves.easeOut;
}

final class MotionPolicy {
  const MotionPolicy._({required this.reduceMotion});

  final bool reduceMotion;

  static MotionPolicy of(BuildContext context) {
    return MotionPolicy._(
      reduceMotion: MediaQuery.disableAnimationsOf(context),
    );
  }

  Duration get fast => reduceMotion ? Duration.zero : AppMotion.fast;
  Duration get standard => reduceMotion ? Duration.zero : AppMotion.medium;
  Duration get slow => reduceMotion ? Duration.zero : AppMotion.slow;
  Duration get focus => reduceMotion ? Duration.zero : AppMotion.focusDuration;
}
