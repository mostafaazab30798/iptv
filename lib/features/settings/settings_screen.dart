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
import 'package:iptv/shared/focus/tv_focusable.dart';
import 'package:iptv/shared/widgets/language_picker.dart';

part 'settings_cards.dart';
part 'settings_sign_out.dart';

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
                return _BentoCard(
                  title: context.l10n.settingsLanguage,
                  icon: AppIcons.language,
                  child: LanguagePicker(
                    style: LanguagePickerStyle.segmented,
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

