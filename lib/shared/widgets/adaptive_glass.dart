import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iptv/core/platform/platform_service.dart';

/// Frosted glass on desktop/TV; solid fill on phones (BackdropFilter is expensive).
class AdaptiveGlass extends StatelessWidget {
  const AdaptiveGlass({
    super.key,
    required this.child,
    this.sigma = 20,
    this.color,
    this.borderRadius,
  });

  final Widget child;
  final double sigma;
  final Color? color;
  final BorderRadius? borderRadius;

  static bool get useBlur {
    final platform = PlatformService.instance;
    return platform.isWindows || platform.isWeb || platform.isAndroidTv;
  }

  @override
  Widget build(BuildContext context) {
    if (!useBlur) return child;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: child,
    );
  }
}
