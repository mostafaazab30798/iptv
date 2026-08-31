import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/player/domain/enums/player_error_type.dart';

import 'package:iptv/shared/extensions/context_extensions.dart';

/// User-friendly error overlay view with clear retry or back actions.
class PlayerErrorView extends StatelessWidget {
  const PlayerErrorView({
    super.key,
    required this.errorType,
    this.customMessage,
    required this.onRetry,
    required this.onClose,
  });

  final PlayerErrorType errorType;
  final String? customMessage;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final message = customMessage ?? _getDefaultMessage(context, errorType);
    const canRetry = true;

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.85),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 28),
          decoration: BoxDecoration(
            color: const Color(0xFF181824),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.6),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const HugeIcon(
                  icon: AppIcons.error,
                  color: AppColors.error,
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                _getErrorTitle(context, errorType),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 10),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 26),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: onClose,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Colors.white24),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    icon: Directionality.maybeOf(context) == TextDirection.rtl
                        ? Transform.flip(
                            flipX: true,
                            child: const HugeIcon(icon: AppIcons.arrowBack, size: 18, color: Colors.white),
                          )
                        : const HugeIcon(icon: AppIcons.arrowBack, size: 18, color: Colors.white),
                    label: Text(context.l10n.actionBack),
                  ),
                  if (canRetry) ...[
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: onRetry,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        elevation: 2,
                      ),
                      icon: const HugeIcon(icon: AppIcons.refresh, size: 18, color: Colors.black),
                      label: Text(context.l10n.actionRetry, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getErrorTitle(BuildContext context, PlayerErrorType type) => switch (type) {
        PlayerErrorType.networkUnavailable => context.l10n.errorNetwork,
        PlayerErrorType.timeout => context.l10n.errorNetwork,
        PlayerErrorType.serverUnavailable => context.l10n.errorServer,
        PlayerErrorType.unauthorized => context.l10n.errorAuth,
        PlayerErrorType.invalidSource => context.l10n.playerStreamUnavailable,
        PlayerErrorType.unsupportedFormat => context.l10n.playerStreamUnavailable,
        PlayerErrorType.codecError => context.l10n.playerStreamUnavailable,
        PlayerErrorType.playbackFailure => context.l10n.playerStreamUnavailable,
        PlayerErrorType.unknown => context.l10n.errorUnknown,
      };

  String _getDefaultMessage(BuildContext context, PlayerErrorType type) => switch (type) {
        PlayerErrorType.networkUnavailable => context.l10n.errorNetwork,
        PlayerErrorType.timeout => context.l10n.errorNetwork,
        PlayerErrorType.serverUnavailable => context.l10n.errorServer,
        PlayerErrorType.unauthorized => context.l10n.errorAuth,
        _ => context.l10n.errorPlayback,
      };
}
