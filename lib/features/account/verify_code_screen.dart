import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_motion.dart';
import 'package:iptv/app/theme/app_radius.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/features/account/account_auth_errors.dart';
import 'package:iptv/features/account/account_controller.dart';
import 'package:iptv/features/account/widgets/auth_announcer.dart';
import 'package:iptv/features/account/widgets/auth_card.dart';
import 'package:iptv/features/account/widgets/auth_header.dart';
import 'package:iptv/features/account/widgets/auth_primary_button.dart';
import 'package:iptv/features/account/widgets/auth_shell.dart';
import 'package:iptv/features/account/widgets/auth_status_message.dart';
import 'package:iptv/features/account/widgets/entrance_fade.dart';
import 'package:iptv/features/account/widgets/otp_code_field.dart';
import 'package:iptv/features/account/widgets/resend_code_action.dart';
import 'package:iptv/l10n/app_localizations.dart';

/// Six-digit verification step of the HOPE TV passwordless sign-in journey.
class VerifyCodeScreen extends ConsumerStatefulWidget {
  const VerifyCodeScreen({super.key});

  @override
  ConsumerState<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends ConsumerState<VerifyCodeScreen>
    with SingleTickerProviderStateMixin {
  final _codeController = TextEditingController();
  final _codeFocusNode = FocusNode();
  final _resendFocusNode = FocusNode();
  final _shakeSignal = ValueNotifier<int>(0);

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: AppMotion.entrance,
  );

  static const _resendCooldownSeconds = 60;
  int _resendSecondsRemaining = 0;
  Timer? _resendTimer;
  Timer? _extendedWaitTimer;

  bool _submitting = false;
  bool _extendedWait = false;
  bool _success = false;
  bool _hasError = false;
  bool _entranceStarted = false;
  String? _statusMessage;
  AuthStatusTone _statusTone = AuthStatusTone.error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensurePendingEmail());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entranceStarted) return;
    _entranceStarted = true;
    _entrance.duration = MotionPolicy.of(context).entrance;
    _entrance.forward();
  }

  void _ensurePendingEmail() {
    final session = ref.read(appAccountSessionProvider);
    if (shouldLeaveOtpVerification(session)) {
      if (mounted) context.go(Routes.signIn);
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _extendedWaitTimer?.cancel();
    _entrance.dispose();
    _codeController.dispose();
    _codeFocusNode.dispose();
    _resendFocusNode.dispose();
    _shakeSignal.dispose();
    super.dispose();
  }

  void _startResendCooldown() {
    _resendTimer?.cancel();
    setState(() => _resendSecondsRemaining = _resendCooldownSeconds);
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSecondsRemaining <= 1) {
        timer.cancel();
        setState(() => _resendSecondsRemaining = 0);
      } else {
        setState(() => _resendSecondsRemaining -= 1);
      }
    });
  }

  Future<void> _submit([String? _]) async {
    if (_submitting || _success) return;
    final l10n = AppLocalizations.of(context)!;
    final code = _codeController.text.trim();

    if (!isValidEmailOtpCode(code)) {
      setState(() {
        _hasError = true;
        _statusMessage = l10n.accountCodeInvalid;
        _statusTone = AuthStatusTone.error;
      });
      _shakeSignal.value++;
      announceForAccessibility(context, l10n.accountCodeInvalid);
      return;
    }

    setState(() {
      _submitting = true;
      _extendedWait = false;
      _hasError = false;
      _statusMessage = null;
    });

    _extendedWaitTimer?.cancel();
    _extendedWaitTimer = Timer(AppMotion.extendedWaitThreshold, () {
      if (mounted && _submitting) setState(() => _extendedWait = true);
    });

    try {
      await ref.read(appAccountSessionProvider.notifier).verifyOtp(code);
      _extendedWaitTimer?.cancel();
      if (!mounted) return;

      final policy = MotionPolicy.of(context);
      setState(() {
        _submitting = false;
        _extendedWait = false;
        _success = true;
      });
      announceForAccessibility(context, l10n.accountOtpVerifiedConfirmation);
      if (policy.success > Duration.zero) {
        await Future<void>.delayed(policy.success);
      }
      if (!mounted) return;

      final iptv = ref.read(sessionProvider).valueOrNull;
      if (iptv != null && iptv.isValid) {
        context.go(Routes.home);
      } else {
        context.go(Routes.onboarding);
      }
    } catch (e) {
      _extendedWaitTimer?.cancel();
      if (!mounted) return;
      final message = accountAuthErrorMessage(
        l10n,
        e,
        fallback: l10n.accountOtpVerifyFailed,
      );
      setState(() {
        _submitting = false;
        _extendedWait = false;
        _hasError = true;
        _statusMessage = message;
        _statusTone = AuthStatusTone.error;
      });
      _shakeSignal.value++;
      announceForAccessibility(context, message);
      if (e is StateError) {
        context.go(Routes.signIn);
      }
    }
  }

  Future<void> _resend() async {
    if (_resendSecondsRemaining > 0 || _submitting) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(appAccountSessionProvider.notifier).resendOtp();
      if (!mounted) return;
      _startResendCooldown();
      setState(() {
        _hasError = false;
        _statusMessage = l10n.accountOtpResent;
        _statusTone = AuthStatusTone.success;
      });
      announceForAccessibility(context, l10n.accountOtpResent);
    } catch (e) {
      if (!mounted) return;
      final message = accountAuthErrorMessage(
        l10n,
        e,
        fallback: l10n.accountOtpSendFailed,
      );
      if (e is StateError) {
        context.go(Routes.signIn);
        return;
      }
      setState(() {
        _statusMessage = message;
        _statusTone = AuthStatusTone.error;
      });
      announceForAccessibility(context, message);
    }
  }

  void _editEmail() => context.go(Routes.signIn);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(appAccountSessionProvider);
    ref.listen(appAccountSessionProvider, (previous, next) {
      if (previous?.loading == true && !next.loading) {
        _ensurePendingEmail();
      }
    });
    final email = session.pendingEmail ?? '';
    final canResend = !session.loading && !_submitting;

    final children = <Widget>[
      AuthHeader(
        eyebrow: l10n.accountVerifyStep,
        title: l10n.accountVerifyTitle,
        subtitle: email.isEmpty ? l10n.accountOtpSessionExpired : null,
      ),
      if (email.isNotEmpty) ...[
        const SizedBox(height: AppSpacing.lg),
        _EmailChip(
          email: email,
          editLabel: l10n.accountEditEmail,
          onEdit: _submitting ? null : _editEmail,
        ),
      ],
      if (debugEmailOtpPreviewEnabled) ...[
        const SizedBox(height: AppSpacing.md),
        AuthStatusMessage(
          message: l10n.accountDebugOtpPreview,
          tone: AuthStatusTone.info,
        ),
      ],
      const SizedBox(height: AppSpacing.xxl),
      OtpCodeField(
        controller: _codeController,
        focusNode: _codeFocusNode,
        enabled: !_submitting && !_success,
        autofocus: true,
        hasError: _hasError,
        shakeSignal: _shakeSignal,
        onSubmitted: _submit,
        onChanged: (_) {
          if (_hasError) setState(() => _hasError = false);
        },
      ),
      const SizedBox(height: AppSpacing.md),
      Text(
        l10n.accountOtpNewestCodeHint,
        textAlign: TextAlign.start,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          height: 1.4,
        ),
      ),
      const SizedBox(height: AppSpacing.xl),
      AnimatedSwitcher(
        duration: MotionPolicy.of(context).press,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1.0).animate(animation),
            child: child,
          ),
        ),
        child: _success
            ? _VerifiedConfirmation(
                key: const ValueKey('verified'),
                label: l10n.accountOtpVerifiedConfirmation,
              )
            : AuthPrimaryButton(
                key: const ValueKey('verify-button'),
                label: l10n.accountVerifyAction,
                loadingLabel: l10n.accountVerifyingCode,
                loading: _submitting,
                onPressed: _submit,
              ),
      ),
      AnimatedSwitcher(
        duration: MotionPolicy.of(context).fast,
        child: _extendedWait && _submitting
            ? Padding(
                key: const ValueKey('extended-wait'),
                padding: const EdgeInsets.only(top: AppSpacing.md),
                child: AuthStatusMessage(
                  message: l10n.accountSlowNetworkHint,
                  tone: AuthStatusTone.info,
                ),
              )
            : const SizedBox(key: ValueKey('no-wait')),
      ),
      AuthStatusMessage(message: _statusMessage, tone: _statusTone),
      const SizedBox(height: AppSpacing.xl),
      Column(
        children: [
          ResendCodeAction(
            secondsRemaining: _resendSecondsRemaining,
            enabled: canResend,
            focusNode: _resendFocusNode,
            onPressed: _resend,
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            l10n.accountResendHint,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textDisabled,
            ),
          ),
        ],
      ),
    ];

    return Scaffold(
      body: AuthShell(
        formCard: AuthCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (var i = 0; i < children.length; i++)
                EntranceFade(
                  controller: _entrance,
                  index: i,
                  itemCount: children.length,
                  child: children[i],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmailChip extends StatelessWidget {
  const _EmailChip({
    required this.email,
    required this.editLabel,
    required this.onEdit,
  });

  final String email;
  final String editLabel;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final enabled = onEdit != null;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: Ink(
          decoration: BoxDecoration(
            color: AppColors.bg3.withValues(alpha: 0.85),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(color: AppColors.border),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 10, 8),
            child: Row(
              children: [
                const AppIcon(
                  AppIcons.mail,
                  size: 16,
                  color: AppColors.accent,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    email,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                AppIcon(
                  AppIcons.edit,
                  size: 14,
                  color: enabled ? AppColors.accent : AppColors.textDisabled,
                  semanticLabel: editLabel,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _VerifiedConfirmation extends StatelessWidget {
  const _VerifiedConfirmation({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.7)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.check_circle_rounded,
            color: AppColors.success,
            size: 22,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.success,
              fontWeight: FontWeight.w700,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }
}
