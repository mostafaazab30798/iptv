import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/player/handoff/application/audio_handoff_server_controller.dart';
import 'package:iptv/player/player.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/widgets/adaptive_glass.dart';
import 'package:qr_flutter/qr_flutter.dart';

/// Modal dialog presented on the TV / Big Screen to display the pairing QR code
/// and live connection status for Companion Listening (Audio Handoff).
class AudioHandoffTvDialog extends ConsumerStatefulWidget {
  const AudioHandoffTvDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => const AudioHandoffTvDialog(),
    );
  }

  @override
  ConsumerState<AudioHandoffTvDialog> createState() =>
      _AudioHandoffTvDialogState();
}

class _AudioHandoffTvDialogState extends ConsumerState<AudioHandoffTvDialog> {
  final bool _autoMuteOnConnect = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startOrUpdateHosting();
    });
  }

  Future<void> _startOrUpdateHosting() async {
    final playerState = ref.read(playerControllerProvider);
    final serverController =
        ref.read(audioHandoffServerProvider.notifier);

    if (playerState.source != null) {
      await serverController.startHosting(
        source: playerState.source,
        playerController: ref.read(playerControllerProvider.notifier),
        autoMuteTv: _autoMuteOnConnect,
      );
    }

  }

  @override
  Widget build(BuildContext context) {
    final serverState = ref.watch(audioHandoffServerProvider);
    final playerController =
        ref.read(playerControllerProvider.notifier);
    final serverController =
        ref.read(audioHandoffServerProvider.notifier);
    final session = serverState.sessionInfo;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 620),
          child: AdaptiveGlass(
            borderRadius: BorderRadius.circular(20),
            enableBlur: false,
            child: Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white12),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: const HugeIcon(
                          icon: AppIcons.headphones,
                          color: AppColors.accent,
                          size: 24,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.handoffTvDialogTitle,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              context.l10n.handoffTvDialogSubtitle,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 12.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    IconButton(
                      icon: const HugeIcon(
                        icon: AppIcons.close,
                        color: Colors.white70,
                        size: 20,
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 22),

                // Main Content Body: QR Code + Connection details
                if (session != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // QR Code container
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 16,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: session.toQrPayload(),
                          version: QrVersions.auto,
                          size: 160,
                          backgroundColor: Colors.white,
                          eyeStyle: const QrEyeStyle(
                            eyeShape: QrEyeShape.square,
                            color: Color(0xFF0F172A),
                          ),
                          dataModuleStyle: const QrDataModuleStyle(
                            dataModuleShape: QrDataModuleShape.square,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 22),

                      // Info Panel
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Connection status pill
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: serverState.connectedClientCount > 0
                                    ? Colors.greenAccent.withValues(alpha: 0.15)
                                    : Colors.amberAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: serverState.connectedClientCount > 0
                                      ? Colors.greenAccent
                                          .withValues(alpha: 0.4)
                                      : Colors.amberAccent
                                          .withValues(alpha: 0.4),
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: serverState.connectedClientCount >
                                              0
                                          ? Colors.greenAccent
                                          : Colors.amberAccent,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    serverState.connectedClientCount > 0
                                        ? '${serverState.connectedClientCount} Phone(s) Connected'
                                        : 'Waiting for phone to connect...',
                                    style: TextStyle(
                                      color: serverState.connectedClientCount >
                                              0
                                          ? Colors.greenAccent
                                          : Colors.amberAccent,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),

                            // Stream Title
                            Text(
                              session.source.title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),

                            // Local IP & PIN Info
                            Text(
                              'IP: ${session.hostIp}:${session.port}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'PIN: ${session.pinCode}',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 12,
                                fontFamily: 'monospace',
                              ),
                            ),
                            if (serverState.availableIps.length > 1) ...[
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 4,
                                children: serverState.availableIps.map((ip) {
                                  final isSelected = ip == session.hostIp;
                                  return InkWell(
                                    onTap: () => serverController.changeHostIp(ip),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 6,
                                        vertical: 2,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? AppColors.accent.withValues(alpha: 0.25)
                                            : Colors.white10,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(
                                          color: isSelected
                                              ? AppColors.accent
                                              : Colors.white12,
                                        ),
                                      ),
                                      child: Text(
                                        ip,
                                        style: TextStyle(
                                          color: isSelected ? AppColors.accent : Colors.white70,
                                          fontSize: 10,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ] else ...[
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(),
                    ),
                  ),
                ],

                const SizedBox(height: 22),
                const Divider(color: Colors.white12, height: 1),
                const SizedBox(height: 16),

                // Controls & Toggles
                Row(
                  children: [
                    // Mute TV speaker toggle
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          unawaited(
                            serverController.toggleTvMute(playerController),
                          );
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: serverState.isTvMuted
                                ? Colors.redAccent.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: serverState.isTvMuted
                                  ? Colors.redAccent.withValues(alpha: 0.4)
                                  : Colors.white12,
                            ),
                          ),
                          child: Row(
                            children: [
                              HugeIcon(
                                icon: serverState.isTvMuted
                                    ? AppIcons.volumeMute
                                    : AppIcons.volumeHigh,
                                color: serverState.isTvMuted
                                    ? Colors.redAccent
                                    : Colors.white70,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  serverState.isTvMuted
                                      ? 'TV Speakers: MUTED'
                                      : 'TV Speakers: AUDIBLE',
                                  style: TextStyle(
                                    color: serverState.isTvMuted
                                        ? Colors.redAccent
                                        : Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Stop Handoff button
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(color: Colors.redAccent),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        await serverController.stopHosting(playerController);
                        if (context.mounted) {
                          Navigator.of(context).pop();
                        }
                      },
                      child: const Text('Stop Handoff'),
                    ),
                    const SizedBox(width: 10),

                    // Done / Keep running in background
                    FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Keep Playing',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
}
