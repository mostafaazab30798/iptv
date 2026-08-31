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
import 'package:iptv/features/auth/auth_controller.dart';
import 'package:iptv/features/kids_mode/kids_mode_controller.dart';
import 'package:iptv/features/kids_mode/widgets/kids_mode_card.dart';
import 'package:iptv/features/kids_mode/widgets/kids_pin_dialog.dart';
import 'package:iptv/features/updates/update_controller.dart';
import 'package:iptv/features/updates/update_dialog.dart';
import 'package:iptv/player/player.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';

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
      return state.updateAvailable
          ? l10n.updateStatusAvailable
          : l10n.updateStatusUpToDate;
  }
}

/// Redesigned Settings Screen using Modern Titanium Bento Architecture
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

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
  ) async {
    final current = ref.read(kidsModeProvider);
    final pin = await showKidsPinDialog(
      context: context,
      createPin: enable && !current.hasPin,
    );
    if (pin == null || !context.mounted) return;

    final controller = ref.read(kidsModeProvider.notifier);
    final result = enable
        ? (current.hasPin
              ? await controller.enableWithExistingPin(pin)
              : await controller.enableWithNewPin(pin))
        : await controller.disable(pin);
    if (!context.mounted) return;

    if (result == KidsPinResult.success) {
      if (enable) {
        await ref.read(playerControllerProvider.notifier).stop();
      }
      return;
    }

    final message = _pinResultMessage(context, result);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  String _pinResultMessage(BuildContext context, KidsPinResult result) {
    return switch (result) {
      KidsPinResult.invalidPin => context.l10n.kidsModeInvalidPin,
      KidsPinResult.invalidFormat => context.l10n.kidsModeInvalidFormat,
      KidsPinResult.lockedOut => context.l10n.kidsModeLockedOut,
      KidsPinResult.unavailable => context.l10n.kidsModeUnavailable,
      KidsPinResult.success => '',
    };
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
        SnackBar(content: Text(_pinResultMessage(context, result))),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.actionSave)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionProvider).valueOrNull;
    final currentLocale = ref.watch(localeProvider).languageCode;
    final kidsMode = ref.watch(kidsModeProvider);
    final updateState = ref.watch(updateProvider);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(Routes.home);
          }
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF090B0F),
        body: ListView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.lg,
          ),
          children: [
            // --- 1. Hero Server & Profile Header ---
            if (session != null) ...[
              _HeroServerBanner(session: session),
              const SizedBox(height: AppSpacing.xl),
            ],

            // --- 2. Language Segmented Bento Card ---
            _BentoCard(
              title: context.l10n.settingsLanguage,
              icon: AppIcons.language,
              child: _LanguageSegmentedControl(
                currentLocale: currentLocale,
                onLocaleSelected: (code) => _setLocale(ref, code),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // --- 3. Parental Controls (Kids Mode) ---
            _BentoCard(
              title: context.l10n.settingsParentalControls,
              icon: AppIcons.securityCheck,
              child: KidsModeCard(
                state: kidsMode,
                onToggle: (value) => _toggleKidsMode(context, ref, value),
                onChangePin: () => _changeKidsPin(context, ref),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),

            // --- 4. System & Software Bento Card ---
            _BentoCard(
              title: context.l10n.settingsAbout,
              icon: AppIcons.info,
              child: _SystemInfoCard(
                statusLabel: _updateStatusLabel(context, updateState),
                isChecking: updateState.status == UpdateFlowStatus.checking,
                onCheckUpdates: () async {
                  await ref
                      .read(updateProvider.notifier)
                      .checkForUpdates(force: true);
                  if (context.mounted) {
                    final latestState = ref.read(updateProvider);
                    if (latestState.status == UpdateFlowStatus.error &&
                        latestState.errorMessage != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(latestState.errorMessage!)),
                      );
                    } else {
                      await showUpdateDialogIfNeeded(context, ref);
                    }
                  }
                },
              ),
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
        border: Border.all(
          color: Colors.white.withAlpha(16),
          width: 0.8,
        ),
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
        border: Border.all(
          color: Colors.white.withAlpha(14),
          width: 0.8,
        ),
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
  });

  final String label;
  final String sublabel;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(12),
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
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// 4. System & Software Bento Card
// ---------------------------------------------------------------------------

class _SystemInfoCard extends StatelessWidget {
  const _SystemInfoCard({
    required this.statusLabel,
    required this.isChecking,
    this.onCheckUpdates,
  });

  final String statusLabel;
  final bool isChecking;
  final VoidCallback? onCheckUpdates;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF11141D),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withAlpha(14),
          width: 0.8,
        ),
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
                  child: const Text(
                    'v${AppConstants.appVersion}',
                    style: TextStyle(
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
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isChecking || onCheckUpdates == null ? null : () {
                  HapticFeedback.lightImpact();
                  onCheckUpdates!();
                },
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(16),
                ),
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
        border: Border.all(
          color: Colors.white.withAlpha(14),
          width: 0.8,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.lightImpact();
            onSignOutTap();
          },
          borderRadius: BorderRadius.circular(16),
          splashColor: AppColors.error.withAlpha(20),
          highlightColor: AppColors.error.withAlpha(10),
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
            border: Border.all(
              color: Colors.white.withAlpha(18),
              width: 0.8,
            ),
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
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text(
                        context.l10n.actionCancel,
                        style: const TextStyle(
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        context.l10n.actionSignOut,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
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
