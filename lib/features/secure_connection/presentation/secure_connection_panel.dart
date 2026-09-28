import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/features/secure_connection/domain/secure_connection_state.dart';
import 'package:iptv/features/secure_connection/secure_connection_providers.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';

/// Focused guidance shown while HOPE hands connection setup to WARP.
final class SecureConnectionPanel extends ConsumerWidget {
  const SecureConnectionPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(secureConnectionControllerProvider);
    if (!state.isVisible) return const SizedBox.shrink();

    final controller = ref.read(secureConnectionControllerProvider.notifier);
    final content = _contentFor(context, state.phase);
    final busy = switch (state.phase) {
      SecureConnectionPhase.checkingWarp ||
      SecureConnectionPhase.openingWarp ||
      SecureConnectionPhase.checkingVpn ||
      SecureConnectionPhase.testingSecureRoute => true,
      _ => false,
    };

    return ColoredBox(
      color: Colors.black.withValues(alpha: 0.88),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 460),
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: const Color(0xFF181824),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                busy ? Icons.shield_outlined : Icons.shield_rounded,
                size: 50,
                color: AppColors.accent,
              ),
              const SizedBox(height: 18),
              Text(
                content.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                content.body,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              if (busy)
                const CircularProgressIndicator(color: AppColors.accent)
              else
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 12,
                  runSpacing: 10,
                  children: [
                    OutlinedButton(
                      onPressed: controller.cancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                      ),
                      child: Text(context.l10n.actionCancel),
                    ),
                    FilledButton(
                      onPressed: switch (state.phase) {
                        SecureConnectionPhase.warpNotInstalled ||
                        SecureConnectionPhase.waitingForInstallation =>
                          controller.installWarp,
                        SecureConnectionPhase.warpInstalled =>
                          controller.openWarp,
                        SecureConnectionPhase.secureRouteFailed =>
                          controller.verifyAgain,
                        _ => null,
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                      ),
                      child: Text(content.actionLabel),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  ({String title, String body, String actionLabel}) _contentFor(
    BuildContext context,
    SecureConnectionPhase phase,
  ) {
    return switch (phase) {
      SecureConnectionPhase.warpNotInstalled ||
      SecureConnectionPhase.waitingForInstallation => (
        title: context.l10n.secureConnectionWarpRequired,
        body: context.l10n.secureConnectionInstallBody,
        actionLabel: context.l10n.secureConnectionInstallAction,
      ),
      SecureConnectionPhase.warpInstalled ||
      SecureConnectionPhase.waitingForWarp => (
        title: context.l10n.secureConnectionAlmostReady,
        body: context.l10n.secureConnectionEnableBody,
        actionLabel: context.l10n.secureConnectionOpenWarp,
      ),
      SecureConnectionPhase.secureRouteFailed => (
        title: context.l10n.secureConnectionFailedTitle,
        body: context.l10n.secureConnectionFailedBody,
        actionLabel: context.l10n.actionTryAgain,
      ),
      _ => (
        title: context.l10n.secureConnectionCheckingTitle,
        body: context.l10n.secureConnectionCheckingBody,
        actionLabel: context.l10n.actionContinue,
      ),
    };
  }
}
