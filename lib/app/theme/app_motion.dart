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

  // ---------------------------------------------------------------------------
  // Authentication journey — screen entrance, stagger, and micro-interactions.
  // ---------------------------------------------------------------------------

  /// Total run length of a screen's staggered entrance sequence. Individual
  /// items fade over [entranceItemSpan] of this duration, offset from one
  /// another so later items start slightly after earlier ones.
  static const Duration entrance = Duration(milliseconds: 550);

  /// Fraction of [entrance] that a single staggered item spends fading in
  /// (≈280–420ms depending on item count), per the 280–420ms entrance spec.
  static const double entranceItemSpan = 0.62;

  /// Vertical translation (logical px) an entrance item travels while fading in.
  static const double entranceOffset = 16.0;

  /// Shared-axis transition between the email and OTP steps.
  static const Duration sharedAxis = Duration(milliseconds: 340);

  /// Button press feedback — scale down then spring back.
  static const Duration press = Duration(milliseconds: 120);
  static const double pressScale = 0.98;

  /// Invalid-code shake feedback.
  static const Duration shake = Duration(milliseconds: 420);

  /// Success checkmark confirmation before navigating away.
  static const Duration success = Duration(milliseconds: 550);

  /// How long a network request must run before supporting text switches to
  /// the "taking longer than usual" hint.
  static const Duration extendedWaitThreshold = Duration(seconds: 3);

  /// One full cycle of the very slow ambient background drift.
  static const Duration ambientDrift = Duration(seconds: 26);
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

  Duration get entrance => reduceMotion ? Duration.zero : AppMotion.entrance;
  Duration get sharedAxis =>
      reduceMotion ? Duration.zero : AppMotion.sharedAxis;
  Duration get press => reduceMotion ? Duration.zero : AppMotion.press;
  Duration get shake => reduceMotion ? Duration.zero : AppMotion.shake;
  Duration get success => reduceMotion ? Duration.zero : AppMotion.success;
  Duration get ambient => reduceMotion ? Duration.zero : AppMotion.ambientDrift;

  /// Vertical entrance translation — collapses to zero under reduced motion
  /// so no layout-affecting offset ever lingers.
  double get entranceOffset => reduceMotion ? 0.0 : AppMotion.entranceOffset;

  /// Scale applied while a button/control is pressed.
  double get pressScale => reduceMotion ? 1.0 : AppMotion.pressScale;
}
