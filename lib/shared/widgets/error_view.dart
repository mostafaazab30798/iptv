import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_spacing.dart';

import 'package:iptv/shared/extensions/context_extensions.dart';

/// Reusable error view with retry action.
class ErrorView extends StatelessWidget {
  const ErrorView({
    super.key,
    required this.message,
    this.onRetry,
    this.eyebrow,
    this.illustration,
    this.icon = AppIcons.error,
    this.secondaryAction,
  });

  final String message;
  final VoidCallback? onRetry;
  final String? eyebrow;
  final Widget? illustration;
  final dynamic icon;
  final Widget? secondaryAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            illustration ??
                (icon is IconData
                    ? Icon(icon as IconData, size: 48, color: AppColors.error)
                    : HugeIcon(
                        icon: icon as List<List<dynamic>>,
                        size: 48,
                        color: AppColors.error,
                      )),
            const SizedBox(height: AppSpacing.md),
            if (eyebrow != null) ...[
              Text(
                eyebrow!,
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            Text(
              message,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: AppSpacing.xl),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const HugeIcon(
                  icon: AppIcons.refresh,
                  size: 18,
                  color: Colors.white,
                ),
                label: Text(context.l10n.actionTryAgain),
              ),
            ],
            if (secondaryAction != null) ...[
              const SizedBox(height: AppSpacing.sm),
              secondaryAction!,
            ],
          ],
        ),
      ),
    );
  }
}
