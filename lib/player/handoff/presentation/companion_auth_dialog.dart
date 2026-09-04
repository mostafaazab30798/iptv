import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_radius.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/features/auth/auth_controller.dart';
import 'package:iptv/features/home/home_controller.dart';
import 'package:iptv/player/handoff/domain/audio_handoff_models.dart';
import 'package:iptv/player/handoff/infrastructure/companion_auth_server.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/widgets/adaptive_glass.dart';
import 'package:qr_flutter/qr_flutter.dart';

enum _PairingStatus {
  initializing,
  waiting,
  authenticating,
  success,
  error,
}

/// Dialog displayed on the target TV / Secondary device during Onboarding.
/// It spins up [CompanionAuthServer], displays a QR code & PIN code, and
/// automatically signs the device in when a companion phone transfers credentials.
class CompanionAuthDialog extends ConsumerStatefulWidget {
  const CompanionAuthDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.85),
      barrierDismissible: true,
      builder: (_) => const CompanionAuthDialog(),
    );
  }

  @override
  ConsumerState<CompanionAuthDialog> createState() =>
      _CompanionAuthDialogState();
}

class _CompanionAuthDialogState extends ConsumerState<CompanionAuthDialog>
    with SingleTickerProviderStateMixin {
  final CompanionAuthServer _authServer = CompanionAuthServer();
  CompanionAuthHandoffInfo? _sessionInfo;
  _PairingStatus _status = _PairingStatus.initializing;
  String? _errorMessage;
  String? _companionName;

  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2000),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    unawaited(_startServer());
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _authServer.stop();
    super.dispose();
  }

  Future<void> _startServer() async {
    setState(() {
      _status = _PairingStatus.initializing;
      _errorMessage = null;
    });

    try {
      final info = await _authServer.start(
        onCredentialsReceived: _handleCredentialsReceived,
      );
      if (!mounted) return;
      setState(() {
        _sessionInfo = info;
        _status = _PairingStatus.waiting;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _PairingStatus.error;
        _errorMessage = e.toString();
      });
    }
  }

  Future<void> _handleCredentialsReceived(
    CompanionAuthCredentialsPayload payload,
  ) async {
    if (!mounted) return;
    unawaited(HapticFeedback.heavyImpact());

    setState(() {
      _status = _PairingStatus.authenticating;
      _companionName = payload.companionDeviceName;
    });

    try {
      // 1. Authenticate with IPTV server credentials
      final iptvResult = await ref
          .read(authControllerProvider.notifier)
          .login(
            serverUrl: payload.serverUrl,
            username: payload.username,
            password: payload.password,
          );

      if (!mounted) return;

      if (!iptvResult.isOk) {
        setState(() {
          _status = _PairingStatus.error;
          _errorMessage = iptvResult.error.message;
        });
        return;
      }

      // 2. If app account details (email / token) were transferred, sign in to app account
      if (payload.email != null && payload.email!.isNotEmpty) {
        try {
          await ref
              .read(appAccountSessionProvider.notifier)
              .signInFromCompanion(
                email: payload.email!,
                refreshToken: payload.refreshToken,
              );
        } catch (_) {}
      }

      // 3. Load channels and content
      unawaited(ref.read(homeControllerProvider.notifier).loadData());

      if (!mounted) return;
      setState(() {
        _status = _PairingStatus.success;
      });

      await Future<void>.delayed(const Duration(milliseconds: 900));
      if (!mounted) return;

      final navigator = Navigator.of(context, rootNavigator: true);
      if (navigator.canPop()) {
        navigator.pop();
      }
      context.go(Routes.home);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _status = _PairingStatus.error;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: AdaptiveGlass(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            child: Container(
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                color: const Color(0xFF0F1522).withValues(alpha: 0.94),
                borderRadius: BorderRadius.circular(AppRadius.lg),
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.3),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.6),
                    blurRadius: 40,
                    offset: const Offset(0, 16),
                  ),
                  BoxShadow(
                    color: AppColors.accent.withValues(alpha: 0.08),
                    blurRadius: 30,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: AppSpacing.lg),
                    _buildContent(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors.accent.withValues(alpha: 0.25),
                AppColors.accent.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: const Center(
            child: HugeIcon(
              icon: AppIcons.devices,
              color: AppColors.accent,
              size: 24,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                context.l10n.companionSignInTitle,
                style: const TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                context.l10n.companionSignInSubtitle,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12.5,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context, rootNavigator: true).pop(),
          icon: const Icon(Icons.close, color: AppColors.textSecondary, size: 20),
          tooltip: context.l10n.actionCancel,
        ),
      ],
    );
  }

  Widget _buildContent() {
    switch (_status) {
      case _PairingStatus.initializing:
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 40),
          child: Center(
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
        );

      case _PairingStatus.waiting:
        return _buildWaitingState();

      case _PairingStatus.authenticating:
        return _buildAuthenticatingState();

      case _PairingStatus.success:
        return _buildSuccessState();

      case _PairingStatus.error:
        return _buildErrorState();
    }
  }

  Widget _buildWaitingState() {
    final info = _sessionInfo!;
    final qrPayload = info.toQrPayload();

    return Column(
      children: [
        // QR Container Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.md),
            boxShadow: [
              BoxShadow(
                color: AppColors.accent.withValues(alpha: 0.18),
                blurRadius: 24,
                spreadRadius: 2,
              ),
            ],
          ),
          child: QrImageView(
            data: qrPayload,
            version: QrVersions.auto,
            size: 210,
            gapless: false,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // 4-Digit Security PIN Code Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF131C2E),
            borderRadius: BorderRadius.circular(AppRadius.full),
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.35),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                context.l10n.companionPairingCodeLabel,
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                info.pinCode.split('').join(' '),
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),

        // 3-Step Guided Instructions
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.bg0.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStepRow(
                number: '1',
                text: context.l10n.companionStep1,
              ),
              const SizedBox(height: 8),
              _buildStepRow(
                number: '2',
                text: context.l10n.companionStep2,
              ),
              const SizedBox(height: 8),
              _buildStepRow(
                number: '3',
                text: context.l10n.companionStep3,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Pulsing Listener Indicator & Network Info
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedBuilder(
              animation: _pulseController,
              builder: (context, _) {
                return Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accent.withValues(
                      alpha: 0.4 + (_pulseController.value * 0.6),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.accent.withValues(
                          alpha: _pulseController.value * 0.8,
                        ),
                        blurRadius: 8,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(width: 8),
            Text(
              context.l10n.companionWaitingForScan,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (info.hostIp == '127.0.0.1')
          Container(
            margin: const EdgeInsets.only(top: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
            ),
            child: const Text(
              '⚠️ Wi-Fi not detected (127.0.0.1). Ensure TV & phone are on the same Wi-Fi network.',
              style: TextStyle(color: Colors.amber, fontSize: 11.5),
              textAlign: TextAlign.center,
            ),
          )
        else
          Text(
            'LAN: http://${info.hostIp}:${info.port}',
            style: TextStyle(
              color: AppColors.textSecondary.withValues(alpha: 0.6),
              fontSize: 11,
              fontFamily: 'monospace',
            ),
            textAlign: TextAlign.center,
          ),
      ],
    );
  }

  Widget _buildStepRow({required String number, required String text}) {
    return Row(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.15),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.4),
              width: 1,
            ),
          ),
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 12.5,
              height: 1.25,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAuthenticatingState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.l10n.companionAuthenticatingTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
            textAlign: TextAlign.center,
          ),
          if (_companionName != null) ...[
            const SizedBox(height: 6),
            Text(
              context.l10n.companionReceivedFrom(_companionName!),
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSuccessState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.success, width: 2),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.success,
              size: 38,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            context.l10n.companionSuccessTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Text(
            context.l10n.companionSuccessSubtitle,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.15),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.error, width: 1.5),
            ),
            child: const Icon(
              Icons.error_outline_rounded,
              color: AppColors.error,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            context.l10n.companionErrorTitle,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 6),
            Text(
              _errorMessage!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          FilledButton.icon(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.accent,
              foregroundColor: Colors.black,
            ),
            onPressed: _startServer,
            icon: const Icon(Icons.refresh, size: 18),
            label: Text(context.l10n.actionRetry),
          ),
        ],
      ),
    );
  }
}
