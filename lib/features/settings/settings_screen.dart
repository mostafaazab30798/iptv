import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/core/constants/app_constants.dart';
import 'package:iptv/domain/entities/server_config.dart';
import 'package:iptv/domain/entities/app_entitlement.dart';
import 'package:iptv/features/auth/auth_controller.dart';
import 'package:iptv/features/kids_mode/kids_mode_actions.dart';
import 'package:iptv/features/kids_mode/kids_mode_controller.dart';
import 'package:iptv/features/kids_mode/widgets/kids_mode_card.dart';
import 'package:iptv/features/kids_mode/widgets/kids_pin_dialog.dart';
import 'package:iptv/features/updates/update_controller.dart';
import 'package:iptv/features/updates/update_dialog.dart';
import 'package:iptv/player/handoff/application/companion_audio_controller.dart';
import 'package:iptv/player/handoff/presentation/companion_listening_sheet.dart';
import 'package:iptv/player/handoff/presentation/companion_scanner_modal.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/focus/shell_focus_navigation.dart';
import 'package:iptv/shared/focus/tv_focusable.dart';

String _updateStatusLabel(BuildContext context, UpdateState state) {
  final l10n = context.l10n;
  switch (state.status) {
    case UpdateFlowStatus.checking:
      return l10n.updateStatusChecking;
    case UpdateFlowStatus.available:
      return l10n.updateStatusAvailable;
    case UpdateFlowStatus.upToDate:
      return l10n.updateStatusUpToDate;
    case UpdateFlowStatus.unsupported:
      return l10n.updateStatusUnsupported;
    case UpdateFlowStatus.notConfigured:
      return l10n.updateStatusNotConfigured;
    case UpdateFlowStatus.error:
      return l10n.updateStatusError;
    case UpdateFlowStatus.idle:
      return l10n.updateStatusReady;
    case UpdateFlowStatus.launching:
    case UpdateFlowStatus.downloading:
    case UpdateFlowStatus.installing:
      return state.updateAvailable
          ? l10n.updateStatusAvailable
          : l10n.updateStatusUpToDate;
  }
}

/// Redesigned Settings Screen using Modern Titanium Bento Architecture
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshExpirations());
  }

  Future<void> _refreshExpirations() async {
    await Future.wait([
      ref.read(sessionProvider.notifier).refreshServerMetadata(),
      ref
          .read(entitlementProvider.notifier)
          .refresh(allowOfflineFallback: true),
    ]);
  }

  Future<void> _signOut(BuildContext context, WidgetRef ref) async {
    final confirmed = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'SignOutDialog',
      barrierColor: Colors.black.withAlpha(190),
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (ctx, anim1, anim2) => const _SignOutConfirmDialog(),
      transitionBuilder: (ctx, anim1, anim2, child) {
        final curved = CurvedAnimation(
          parent: anim1,
          curve: Curves.easeOutCubic,
        );
        return ScaleTransition(
          scale: Tween<double>(begin: 0.94, end: 1.0).animate(curved),
          child: FadeTransition(opacity: curved, child: child),
        );
      },
    );

    if (confirmed == true && context.mounted) {
      await ref.read(authControllerProvider.notifier).logout();
      if (context.mounted) {
        context.go(Routes.onboarding);
      }
    }
  }

  void _setLocale(WidgetRef ref, String code) {
    ref.read(localeProvider.notifier).setLocale(code);
  }

  Future<void> _toggleKidsMode(
    BuildContext context,
    WidgetRef ref,
    bool enable,
  ) {
    return confirmKidsModeChange(context: context, ref: ref, enable: enable);
  }

  Future<void> _changeKidsPin(BuildContext context, WidgetRef ref) async {
    final data = await showKidsChangePinDialog(context: context);
    if (data == null || !context.mounted) return;

    final controller = ref.read(kidsModeProvider.notifier);
    final result = await controller.changePin(
      currentPin: data.currentPin,
      newPin: data.newPin,
    );
    if (!context.mounted) return;
    if (result != KidsPinResult.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(kidsPinResultMessage(context, result))),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.actionSave)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF090B0F),
      body: DpadRegion(
        memoryKey: 'settings/list',
        debugLabel: 'settings-list',
        child: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          children: [
            // --- 1. Hero Server & Profile Header ---
            Consumer(
              builder: (context, ref, _) {
                final session = ref.watch(
                  sessionProvider.select((s) => s.valueOrNull),
                );
                if (session == null) return const SizedBox.shrink();
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _HeroServerBanner(session: session),
                    const SizedBox(height: AppSpacing.xl),
                  ],
                );
              },
            ),

            // --- 2. Language Segmented Bento Card ---
            Consumer(
              builder: (context, ref, _) {
                final currentLocale = ref.watch(
                  localeProvider.select((l) => l.languageCode),
                );
                return _BentoCard(
                  title: context.l10n.settingsLanguage,
                  icon: AppIcons.language,
                  child: _LanguageSegmentedControl(
                    currentLocale: currentLocale,
                    onLocaleSelected: (code) => _setLocale(ref, code),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // --- Companion Listening (Audio Handoff) Bento Card ---
            Consumer(
              builder: (context, ref, _) {
                final isConnected = ref.watch(
                  companionAudioProvider.select((s) => s.isConnected),
                );
                return _BentoCard(
                  title: context.l10n.settingsHandoffTitle,
                  icon: AppIcons.headphones,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF11141D),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withAlpha(14),
                        width: 0.8,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withAlpha(20),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.accent.withAlpha(45),
                              width: 0.8,
                            ),
                          ),
                          child: const HugeIcon(
                            icon: AppIcons.headphones,
                            color: AppColors.accent,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                context.l10n.handoffTvDialogTitle,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                context.l10n.settingsHandoffSubtitle,
                                style: const TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 11.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        TvFocusable(
                          onSelect: () {
                            if (isConnected) {
                              CompanionListeningSheet.show(context);
                            } else {
                              CompanionScannerModal.show(context);
                            }
                          },
                          child: IgnorePointer(
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                              onPressed: () {},
                              child: Text(
                                isConnected
                                    ? context.l10n.settingsHandoffActiveHud
                                    : context.l10n.handoffConnect,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // --- 2. Access expiry dates ---
            Consumer(
              builder: (context, ref, _) {
                final entitlementState = ref.watch(
                  entitlementProvider.select(
                    (s) => (entitlement: s.entitlement, loading: s.loading),
                  ),
                );
                final serverExpiresAt = ref.watch(
                  sessionProvider.select((s) => s.valueOrNull?.expiresAt),
                );
                return _BentoCard(
                  title: context.l10n.settingsAccessExpiry,
                  icon: AppIcons.time,
                  child: _ExpiryCard(
                    entitlement: entitlementState.entitlement,
                    entitlementLoading: entitlementState.loading,
                    serverExpiresAt: serverExpiresAt,
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // --- 3. Parental Controls (Kids Mode) ---
            Consumer(
              builder: (context, ref, _) {
                final kidsMode = ref.watch(kidsModeProvider);
                return _BentoCard(
                  title: context.l10n.settingsParentalControls,
                  icon: AppIcons.securityCheck,
                  child: KidsModeCard(
                    state: kidsMode,
                    onToggle: (value) => _toggleKidsMode(context, ref, value),
                    onChangePin: () => _changeKidsPin(context, ref),
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // --- 4. System & Software Bento Card ---
            Consumer(
              builder: (context, ref, _) {
                final updateSlice = ref.watch(
                  updateProvider.select(
                    (s) => (
                      status: s.status,
                      updateAvailable: s.updateAvailable,
                    ),
                  ),
                );
                final statusLabel = _updateStatusLabel(
                  context,
                  UpdateState(
                    status: updateSlice.status,
                    updateAvailable: updateSlice.updateAvailable,
                  ),
                );
                return _BentoCard(
                  title: context.l10n.settingsAbout,
                  icon: AppIcons.info,
                  child: _SystemInfoCard(
                    statusLabel: statusLabel,
                    isChecking:
                        updateSlice.status == UpdateFlowStatus.checking,
                    onCheckUpdates: () async {
                      await ref
                          .read(updateProvider.notifier)
                          .checkForUpdates(force: true);
                      if (context.mounted) {
                        final latestState = ref.read(updateProvider);
                        if (latestState.status == UpdateFlowStatus.error &&
                            latestState.errorMessage != null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(latestState.errorMessage!),
                            ),
                          );
                        } else {
                          await showUpdateDialogIfNeeded(context, ref);
                        }
                      }
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),

            // --- 5. Session & Sign Out Bento Card ---
            _BentoCard(
              title: context.l10n.settingsAccount,
              icon: AppIcons.logout,
              child: _SignOutActionTile(
                onSignOutTap: () => _signOut(context, ref),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

String _formatExpiry(BuildContext context, DateTime? value) {
  if (value == null) return context.l10n.settingsExpiryUnavailable;
  final local = value.toLocal();
  final material = MaterialLocalizations.of(context);
  final date = material.formatFullDate(local);
  final time = material.formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  return '$date · $time';
}

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
// 2. Language Segmented Control (Sliding Capsule Architecture)
// ---------------------------------------------------------------------------

class _LanguageSegmentedControl extends StatelessWidget {
  const _LanguageSegmentedControl({
    required this.currentLocale,
    required this.onLocaleSelected,
  });

  final String currentLocale;
  final ValueChanged<String> onLocaleSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF11141D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(14), width: 0.8),
      ),
      padding: const EdgeInsets.all(5),
      child: Row(
        children: [
          Expanded(
            child: _SegmentItem(
              label: 'English',
              sublabel: 'EN',
              isSelected: currentLocale == 'en',
              onTap: () => onLocaleSelected('en'),
              entry: true,
              autofocus: true,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _SegmentItem(
              label: 'العربية',
              sublabel: 'AR',
              isSelected: currentLocale == 'ar',
              onTap: () => onLocaleSelected('ar'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentItem extends StatelessWidget {
  const _SegmentItem({
    required this.label,
    required this.sublabel,
    required this.isSelected,
    required this.onTap,
    this.entry = false,
    this.autofocus = false,
  });

  final String label;
  final String sublabel;
  final bool isSelected;
  final VoidCallback onTap;
  final bool entry;
  final bool autofocus;

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      entry: entry,
      autofocus: autofocus,
      onSelect: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      onDirection: entry
          ? (direction) {
              if (direction == TraversalDirection.up) {
                return focusUpToShell(context);
              }
              return false;
            }
          : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF1E2536) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppColors.accent.withAlpha(70)
                : Colors.transparent,
            width: 0.8,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withAlpha(40),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: TextStyle(
                color: isSelected
                    ? AppColors.textPrimary
                    : AppColors.textSecondary,
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 5,
                vertical: 1.5,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.accent.withAlpha(25)
                    : Colors.white.withAlpha(10),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                sublabel,
                style: TextStyle(
                  color: isSelected
                      ? AppColors.accent
                      : AppColors.textDisabled,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
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

class _SignOutActionTile extends StatelessWidget {
  const _SignOutActionTile({required this.onSignOutTap});

  final VoidCallback onSignOutTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF11141D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(14), width: 0.8),
      ),
      child: TvFocusable(
        onSelect: () {
          HapticFeedback.lightImpact();
          onSignOutTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: 14,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: AppColors.error.withAlpha(18),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.error.withAlpha(45),
                    width: 0.8,
                  ),
                ),
                child: const HugeIcon(
                  icon: AppIcons.logout,
                  color: AppColors.error,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.actionSignOut,
                      style: const TextStyle(
                        color: AppColors.error,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      context.l10n.settingsSignOutIptvHint,
                      style: TextStyle(
                        color: AppColors.textSecondary.withAlpha(190),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Sign Out Confirmation Dialog
// ---------------------------------------------------------------------------

class _SignOutConfirmDialog extends StatelessWidget {
  const _SignOutConfirmDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xl,
          vertical: AppSpacing.lg,
        ),
        child: Container(
          width: 340,
          decoration: BoxDecoration(
            color: const Color(0xFF11141D),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withAlpha(18), width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(140),
                blurRadius: 28,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.error.withAlpha(20),
                  border: Border.all(
                    color: AppColors.error.withAlpha(50),
                    width: 0.8,
                  ),
                ),
                child: const Center(
                  child: HugeIcon(
                    icon: AppIcons.logout,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                context.l10n.settingsConfirmSignOut,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                context.l10n.settingsConfirmSignOutMessage,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondary.withAlpha(200),
                  fontSize: 12.5,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: TvFocusable(
                      autofocus: true,
                      onSelect: () => Navigator.of(context).pop(false),
                      child: IgnorePointer(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(
                              color: Colors.white.withAlpha(20),
                              width: 0.8,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {},
                          child: Text(
                            context.l10n.actionCancel,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TvFocusable(
                      onSelect: () => Navigator.of(context).pop(true),
                      child: IgnorePointer(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.error,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          onPressed: () {},
                          child: Text(
                            context.l10n.actionSignOut,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
