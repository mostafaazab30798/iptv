part of 'settings_screen.dart';

class _ExpiryCard extends StatelessWidget {
  const _ExpiryCard({
    required this.entitlement,
    required this.entitlementLoading,
    required this.serverExpiresAt,
  });

  final AppEntitlement? entitlement;
  final bool entitlementLoading;
  final DateTime? serverExpiresAt;

  @override
  Widget build(BuildContext context) {
    final appLabel = entitlement?.accessStatus == AccessStatus.trialing
        ? context.l10n.settingsTrialExpiry
        : context.l10n.settingsSubscriptionExpiry;
    final appValue = entitlementLoading && entitlement == null
        ? context.l10n.settingsExpiryChecking
        : _formatExpiry(context, entitlement?.validUntil);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF11141D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(14), width: 0.8),
      ),
      child: Column(
        children: [
          _ExpiryRow(
            icon: AppIcons.timer,
            label: appLabel,
            value: appValue,
          ),
          const Divider(color: AppColors.border, height: 1),
          _ExpiryRow(
            icon: AppIcons.server,
            label: context.l10n.settingsIptvServerExpiry,
            value: _formatExpiry(context, serverExpiresAt),
          ),
        ],
      ),
    );
  }
}

class _ExpiryRow extends StatelessWidget {
  const _ExpiryRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final List<List<dynamic>> icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: 14,
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(18),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.accent.withAlpha(45),
                width: 0.8,
              ),
            ),
            child: HugeIcon(icon: icon, color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 1. Hero Server & Connection Banner (Modern Linear Architecture)
// ---------------------------------------------------------------------------

class _HeroServerBanner extends StatelessWidget {
  const _HeroServerBanner({required this.session});

  final ServerConfig session;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF11141D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withAlpha(16), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(40),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          // Server Avatar
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF181E2B),
              border: Border.all(
                color: AppColors.accent.withAlpha(60),
                width: 1.0,
              ),
            ),
            child: const Center(
              child: HugeIcon(
                icon: AppIcons.dns,
                color: AppColors.accent,
                size: 22,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),

          // Server URL & Username
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.serverUrl,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2.5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(10),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: Colors.white.withAlpha(16),
                          width: 0.6,
                        ),
                      ),
                      child: Text(
                        '${context.l10n.settingsUser}: ${session.username}',
                        style: TextStyle(
                          color: AppColors.textSecondary.withAlpha(220),
                          fontSize: 11.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),

          // Online Status Dot Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withAlpha(18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.success.withAlpha(60),
                width: 0.8,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'ONLINE',
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Bento Card Wrapper
// ---------------------------------------------------------------------------

class _BentoCard extends StatelessWidget {
  const _BentoCard({
    required this.title,
    required this.icon,
    required this.child,
  });

  final String title;
  final List<List<dynamic>> icon;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 4, bottom: 8),
          child: Row(
            children: [
              HugeIcon(
                icon: icon,
                color: AppColors.textSecondary.withAlpha(160),
                size: 13.5,
              ),
              const SizedBox(width: 6),
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  color: AppColors.textSecondary.withAlpha(180),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
        ),
        child,
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// 4. System & Software Bento Card
// ---------------------------------------------------------------------------

class _SystemInfoCard extends ConsumerWidget {
  const _SystemInfoCard({
    required this.statusLabel,
    required this.isChecking,
    this.onCheckUpdates,
  });

  final String statusLabel;
  final bool isChecking;
  final VoidCallback? onCheckUpdates;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final versionAsync = ref.watch(appVersionStringProvider);
    final versionText = versionAsync.valueOrNull ??
        'v${AppConstants.appVersion} (${AppConstants.appBuildNumber})';

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF11141D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(14), width: 0.8),
      ),
      child: Column(
        children: [
          // App Logo & Version Info
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.asset(
                    AppConstants.appLogo,
                    width: 38,
                    height: 38,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'HOPE TV Media Client',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Cross-Platform IPTV Player',
                        style: TextStyle(
                          color: AppColors.textSecondary.withAlpha(190),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 9,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(10),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withAlpha(18),
                      width: 0.6,
                    ),
                  ),
                  child: Text(
                    versionText,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // App Updates Trigger
          ...[
            const Divider(color: AppColors.border, height: 1),
            TvFocusable(
              enabled: !isChecking && onCheckUpdates != null,
              onSelect: () {
                HapticFeedback.lightImpact();
                onCheckUpdates!();
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    if (isChecking)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.accent,
                        ),
                      )
                    else
                      const HugeIcon(
                        icon: AppIcons.refresh,
                        color: AppColors.accent,
                        size: 16,
                      ),
                    const SizedBox(width: 10),
                    Text(
                      context.l10n.updateCheckAction,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      statusLabel,
                      style: TextStyle(
                        color: AppColors.textSecondary.withAlpha(190),
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 5. Session & Sign Out Bento Card
// ---------------------------------------------------------------------------

