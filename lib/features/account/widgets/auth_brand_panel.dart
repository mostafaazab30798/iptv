import 'package:flutter/material.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/core/constants/app_constants.dart';
import 'package:iptv/l10n/app_localizations.dart';

/// Brand and atmosphere region shown on the leading side of wide/TV/desktop
/// auth layouts, or as a compact header above the card on narrow layouts.
class AuthBrandPanel extends StatelessWidget {
  const AuthBrandPanel({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final textTheme = Theme.of(context).textTheme;

    final wordmark = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: compact ? 40 : 52,
          height: compact ? 40 : 52,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? 12 : 14),
            boxShadow: const [
              BoxShadow(
                color: AppColors.accentGlow,
                blurRadius: 18,
                spreadRadius: 1,
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(compact ? 12 : 14),
            child: Image.asset(
              AppConstants.appLogo,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => ColoredBox(
                color: AppColors.bg3,
                child: Icon(
                  Icons.live_tv_rounded,
                  size: compact ? 22 : 28,
                  color: AppColors.accent,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          'HOPE TV',
          style: (compact ? textTheme.titleLarge : textTheme.headlineSmall)
              ?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
        ),
      ],
    );

    if (compact) {
      return Semantics(header: true, child: wordmark);
    }

    return Semantics(
      container: true,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Semantics(header: true, child: wordmark),
          const SizedBox(height: AppSpacing.x3l),
          Text(
            l10n.accountBrandTagline,
            style: textTheme.displaySmall?.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w700,
              height: 1.15,
              letterSpacing: -0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          SizedBox(
            width: 400,
            child: Text(
              l10n.accountSignInSubtitle,
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
                height: 1.5,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.x3l),
          Container(
            width: 56,
            height: 2,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(2),
              gradient: const LinearGradient(
                colors: [AppColors.accent, Colors.transparent],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AppIcon(
                AppIcons.securityCheck,
                size: 18,
                color: AppColors.accent,
              ),
              const SizedBox(width: AppSpacing.sm),
              Flexible(
                child: Text(
                  l10n.accountPrivacyReassurance,
                  style: textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
