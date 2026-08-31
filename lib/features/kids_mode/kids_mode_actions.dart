import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/features/kids_mode/kids_mode_controller.dart';
import 'package:iptv/features/kids_mode/widgets/kids_pin_dialog.dart';
import 'package:iptv/player/player.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';

/// Maps a PIN operation result to a user-facing message.
String kidsPinResultMessage(BuildContext context, KidsPinResult result) {
  return switch (result) {
    KidsPinResult.invalidPin => context.l10n.kidsModeInvalidPin,
    KidsPinResult.invalidFormat => context.l10n.kidsModeInvalidFormat,
    KidsPinResult.lockedOut => context.l10n.kidsModeLockedOut,
    KidsPinResult.unavailable => context.l10n.kidsModeUnavailable,
    KidsPinResult.success => '',
  };
}

/// Prompts for the parent PIN, then enables or disables Kids Mode.
///
/// Enabling Kids Mode also stops any in-progress playback so adult content
/// cannot keep playing after the catalog is filtered.
Future<void> confirmKidsModeChange({
  required BuildContext context,
  required WidgetRef ref,
  required bool enable,
}) async {
  final current = ref.read(kidsModeProvider);
  if (!current.isInitialized) return;
  if (current.isLockedOut) {
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.kidsModeLockedOut)));
    }
    return;
  }

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

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(kidsPinResultMessage(context, result))),
  );
}
