import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iptv/core/platform/device_memory.dart';
import 'package:iptv/core/platform/platform_service.dart';

/// Frosted glass on capable desktop/web surfaces; solid fill elsewhere.
///
/// Blur is expensive over live video — pass [enableBlur] `false` for player HUDs.
/// Low-RAM and Android TV skip blur globally; static auth/settings on Windows/Web
/// can still use it when [enableBlur] is true.
class AdaptiveGlass extends StatelessWidget {
  const AdaptiveGlass({
    super.key,
    required this.child,
    this.sigma = 20,
    this.color,
    this.borderRadius,
    this.enableBlur = true,
  });

  final Widget child;
  final double sigma;
  final Color? color;
  final BorderRadius? borderRadius;

  /// When false, never applies [BackdropFilter] (player overlays over video).
  final bool enableBlur;

  /// Platform-level gate: blur only where it is cheap enough.
  static bool get useBlur {
    if (DeviceMemory.isLowRamDevice) return false;
    final platform = PlatformService.instance;
    if (platform.isAndroidTv) return false;
    return platform.isWindows || platform.isWeb;
  }

  @override
  Widget build(BuildContext context) {
    if (!enableBlur || !useBlur) return child;
    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: sigma, sigmaY: sigma),
      child: child,
    );
  }
}
