import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/features/account/account_auth_errors.dart';
import 'package:iptv/features/account/account_controller.dart';
import 'package:iptv/l10n/app_localizations.dart';

class VerifyCodeScreen extends ConsumerStatefulWidget {
  const VerifyCodeScreen({super.key});

  @override
  ConsumerState<VerifyCodeScreen> createState() => _VerifyCodeScreenState();
}

class _VerifyCodeScreenState extends ConsumerState<VerifyCodeScreen> {
  final _codeController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  static const _resendCooldownSeconds = 60;
  int _resendSecondsRemaining = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensurePendingEmail());
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
    _codeController.dispose();
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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref
          .read(appAccountSessionProvider.notifier)
          .verifyOtp(_codeController.text);
      if (!mounted) return;
      final iptv = ref.read(sessionProvider).valueOrNull;
      if (iptv != null && iptv.isValid) {
        context.go(Routes.home);
      } else {
        context.go(Routes.onboarding);
      }
    } catch (e) {
      if (!mounted) return;
      final message = accountAuthErrorMessage(
        l10n,
        e,
        fallback: l10n.accountOtpVerifyFailed,
      );
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _resend() async {
    if (_resendSecondsRemaining > 0) return;
    final l10n = AppLocalizations.of(context)!;
    try {
      await ref.read(appAccountSessionProvider.notifier).resendOtp();
      if (!mounted) return;
      _startResendCooldown();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(l10n.accountOtpResent)));
    } catch (e) {
      if (!mounted) return;
      final message = accountAuthErrorMessage(
        l10n,
        e,
        fallback: l10n.accountOtpSendFailed,
      );
      if (e is StateError) {
        context.go(Routes.signIn);
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

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
    final canResend = !session.loading && _resendSecondsRemaining == 0;

    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        title: Text(l10n.accountVerifyTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(Routes.signIn),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      email.isEmpty
                          ? l10n.accountOtpSessionExpired
                          : l10n.accountVerifySubtitle(email),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _codeController,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      textAlign: TextAlign.center,
                      style: Theme.of(
                        context,
                      ).textTheme.headlineSmall?.copyWith(letterSpacing: 8),
                      decoration: InputDecoration(
                        labelText: l10n.accountCodeLabel,
                        counterText: '',
                      ),
                      validator: (value) {
                        if (!isValidEmailOtpCode(value ?? '')) {
                          return l10n.accountCodeInvalid;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 24),
                    FilledButton(
                      onPressed: session.loading ? null : _submit,
                      child: session.loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(l10n.accountVerifyAction),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: canResend ? _resend : null,
                      child: Text(
                        _resendSecondsRemaining > 0
                            ? l10n.accountResendCooldown(
                                _resendSecondsRemaining,
                              )
                            : l10n.accountResendCode,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
