import 'package:flutter/material.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_spacing.dart';

/// Elevated glass-edge surface that hosts the sign-in or OTP form.
///
/// A 1px gradient rim + soft top highlight keep the card readable on the
/// cinematic backdrop without heavy chrome.
class AuthCard extends StatelessWidget {
  const AuthCard({super.key, required this.child});

  final Widget child;

  /// Cards stay within this width band on wide/TV/desktop layouts so the
  /// form never stretches into a banner.
  static const double maxWidth = 440;
  static const double minWidth = 360;

  @override
  Widget build(BuildContext context) {
    const outerRadius = 24.0;
    const innerRadius = 22.5;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxWidth),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(outerRadius),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.accent.withValues(alpha: 0.42),
              Colors.white.withValues(alpha: 0.14),
              Colors.white.withValues(alpha: 0.04),
              AppColors.accent.withValues(alpha: 0.12),
            ],
            stops: const [0.0, 0.28, 0.72, 1.0],
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 48,
              offset: const Offset(0, 22),
            ),
            const BoxShadow(
              color: AppColors.accentGlow,
              blurRadius: 36,
              spreadRadius: -4,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(1.1),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(innerRadius),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  AppColors.bg2.withValues(alpha: 0.96),
                  AppColors.bg1.withValues(alpha: 0.98),
                ],
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(innerRadius),
              child: Stack(
                children: [
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    height: 72,
                    child: IgnorePointer(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.white.withValues(alpha: 0.06),
                              Colors.white.withValues(alpha: 0.0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xxl,
                      AppSpacing.x3l,
                      AppSpacing.xxl,
                      AppSpacing.xxl,
                    ),
                    child: child,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
