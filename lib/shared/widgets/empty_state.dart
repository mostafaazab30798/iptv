import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_spacing.dart';

/// Reusable empty state view.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.eyebrow,
    this.illustration,
    this.icon = AppIcons.empty,
    this.actionLabel,
    this.onAction,
    this.secondaryAction,
  });

  final String title;
  final String? subtitle;
  final String? eyebrow;
  final Widget? illustration;
  final dynamic icon;
  final String? actionLabel;
  final VoidCallback? onAction;
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
                    ? Icon(
                        icon as IconData,
                        size: 56,
                        color: AppColors.textDisabled,
                      )
                    : HugeIcon(
                        icon: icon as List<List<dynamic>>,
                        size: 56,
                        color: AppColors.textDisabled,
                      )),
            const SizedBox(height: AppSpacing.md),
            if (eyebrow != null) ...[
              Text(
                eyebrow!,
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
            ],
            Text(
              title,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                subtitle!,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppSpacing.lg),
              ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
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
