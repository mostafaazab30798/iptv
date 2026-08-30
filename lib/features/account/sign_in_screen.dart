import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_motion.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/features/account/account_auth_errors.dart';
import 'package:iptv/features/account/account_controller.dart';
import 'package:iptv/features/account/widgets/auth_announcer.dart';
import 'package:iptv/features/account/widgets/auth_card.dart';
import 'package:iptv/features/account/widgets/auth_email_field.dart';
import 'package:iptv/features/account/widgets/auth_header.dart';
import 'package:iptv/features/account/widgets/auth_language_switcher.dart';
import 'package:iptv/features/account/widgets/auth_primary_button.dart';
import 'package:iptv/features/account/widgets/auth_shell.dart';
import 'package:iptv/features/account/widgets/auth_status_message.dart';
import 'package:iptv/features/account/widgets/entrance_fade.dart';
import 'package:iptv/l10n/app_localizations.dart';

/// Email entry step of the HOPE TV passwordless sign-in journey.
class SignInScreen extends ConsumerStatefulWidget {
  const SignInScreen({super.key});

  @override
  ConsumerState<SignInScreen> createState() => _SignInScreenState();
}

class _SignInScreenState extends ConsumerState<SignInScreen>
    with SingleTickerProviderStateMixin {
  final _emailController = TextEditingController();
  final _emailFocusNode = FocusNode();
  final _formKey = GlobalKey<FormState>();

  late final AnimationController _entrance = AnimationController(
    vsync: this,
    duration: AppMotion.entrance,
  );

  bool _submitting = false;
  bool _extendedWait = false;
  bool _entranceStarted = false;
  String? _statusMessage;
  AuthStatusTone _statusTone = AuthStatusTone.error;
  Timer? _extendedWaitTimer;

  @override
  void initState() {
    super.initState();

    final pendingEmail = ref.read(appAccountSessionProvider).pendingEmail;
    if (pendingEmail != null && pendingEmail.isNotEmpty) {
      _emailController.text = pendingEmail;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_entranceStarted) return;
    _entranceStarted = true;
    _entrance.duration = MotionPolicy.of(context).entrance;
    _entrance.forward();
  }

  @override
  void dispose() {
    _extendedWaitTimer?.cancel();
    _entrance.dispose();
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;

    setState(() {
      _submitting = true;
      _extendedWait = false;
      _statusMessage = null;
    });

    _extendedWaitTimer?.cancel();
    _extendedWaitTimer = Timer(AppMotion.extendedWaitThreshold, () {
      if (mounted && _submitting) setState(() => _extendedWait = true);
    });

    try {
      final email = _emailController.text;
      await ref.read(appAccountSessionProvider.notifier).requestOtp(email);
      _extendedWaitTimer?.cancel();
      if (!mounted) return;
      announceForAccessibility(
        context,
        l10n.accountVerifySubtitle(email.trim().toLowerCase()),
      );
      context.go(Routes.verifyCode);
    } catch (e) {
      _extendedWaitTimer?.cancel();
      if (!mounted) return;
      final message = accountAuthErrorMessage(
        l10n,
        e,
        fallback: l10n.accountOtpSendFailed,
      );
      setState(() {
        _submitting = false;
        _extendedWait = false;
        _statusMessage = message;
        _statusTone = AuthStatusTone.error;
      });
      announceForAccessibility(context, message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final session = ref.watch(appAccountSessionProvider);
    final configured = session.configured;
    final textTheme = Theme.of(context).textTheme;

    final children = <Widget>[
      AuthHeader(
        eyebrow: l10n.accountSignInStep,
        title: l10n.accountSignInTitle,
        subtitle: l10n.accountSignInSubtitle,
      ),
      if (debugEmailOtpPreviewEnabled) ...[
        const SizedBox(height: AppSpacing.md),
        AuthStatusMessage(
          message: l10n.accountDebugOtpPreview,
          tone: AuthStatusTone.info,
        ),
      ],
      const SizedBox(height: AppSpacing.xxl),
      if (!configured)
        Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.lg),
          child: AuthStatusMessage(
            message: l10n.accountNotConfigured,
            tone: AuthStatusTone.error,
          ),
        ),
      AuthEmailField(
        controller: _emailController,
        focusNode: _emailFocusNode,
        enabled: !_submitting && configured,
        autofocus: true,
        onSubmitted: (_) => _submit(),
      ),
      const SizedBox(height: AppSpacing.xl),
      AuthPrimaryButton(
        label: l10n.accountSendCode,
        loadingLabel: l10n.accountSendingCode,
        loading: _submitting,
        onPressed: configured ? _submit : null,
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
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const AppIcon(
            AppIcons.securityCheck,
            size: 16,
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              l10n.accountPrivacyReassurance,
              style: textTheme.bodySmall?.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    ];

    return Scaffold(
      body: AuthShell(
        topTrailing: const AuthLanguageSwitcher(),
        formCard: AuthCard(
          child: Form(
            key: _formKey,
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
      ),
    );
  }
}
