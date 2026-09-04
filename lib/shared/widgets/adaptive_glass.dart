import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:iptv/app/theme/app_colors.dart';
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

/// Apple-style silver glass capsule — cool translucent fill, hairline rim,
/// and a soft top specular highlight. Used for shell chrome, match badges,
/// and the landscape match details card.
class SilverGlassCapsule extends StatelessWidget {
  const SilverGlassCapsule({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    this.borderRadius = 16,
    this.enableBlur = true,
    this.sigma = 18,
    this.highlightHeight = 12,
    this.boxShadow,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final bool enableBlur;
  final double sigma;
  final double highlightHeight;
  final List<BoxShadow>? boxShadow;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    final surface = ClipRRect(
      borderRadius: radius,
      child: AdaptiveGlass(
        sigma: sigma,
        enableBlur: enableBlur,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x73FFFFFF), Color(0x3DF2F4F7), Color(0x33A8B0BC)],
              stops: [0.0, 0.5, 1.0],
            ),
            border: Border.all(color: const Color(0x66FFFFFF), width: 0.75),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: highlightHeight,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
                    ),
                  ),
                ),
              ),
              Padding(padding: padding, child: child),
            ],
          ),
        ),
      ),
    );

    return Container(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow:
            boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.32),
                blurRadius: 14,
                offset: const Offset(0, 5),
              ),
            ],
      ),
      child: surface,
    );
  }
}

/// Dark glass capsule matching the portrait floating nav dock.
class DarkGlassCapsule extends StatelessWidget {
  const DarkGlassCapsule({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    this.borderRadius = 16,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(borderRadius);

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [AppColors.bg1.withAlpha(245), AppColors.bg2.withAlpha(252)],
        ),
        borderRadius: radius,
        border: Border.all(color: Colors.white.withAlpha(35), width: 0.9),
      ),
      child: child,
    );
  }
}
