import 'dart:async';
import 'package:flutter/material.dart';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/player/handoff/application/companion_audio_controller.dart';
import 'package:iptv/player/handoff/infrastructure/audio_handoff_discovery.dart';
import 'package:iptv/player/handoff/presentation/companion_remote_sheet.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';

/// Floating or embedded auto-discovery pill shown on mobile phone when
/// a TV / Big Screen host is active and discovered on the local Wi-Fi.
class HomeTvDiscoveryBadge extends ConsumerWidget {
  const HomeTvDiscoveryBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final discoveredAsync = ref.watch(discoveredTvSessionsProvider);
    final isConnected = ref.watch(
      companionAudioProvider.select((s) => s.isConnected),
    );
    final connectedDeviceName = ref.watch(
      companionAudioProvider.select(
        (s) => s.sessionInfo?.serverDeviceName,
      ),
    );

    return discoveredAsync.maybeWhen(
      data: (sessions) {
        if (sessions.isEmpty && !isConnected) return const SizedBox.shrink();

        final tv = isConnected
            ? null
            : (sessions.isNotEmpty ? sessions.first : null);
        final devName = isConnected
            ? (connectedDeviceName ?? 'Big Screen')
            : (tv?.sessionInfo.serverDeviceName ?? '');

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: InkWell(
            onTap: () async {
              if (isConnected) {
                // Already connected — open the remote sheet
                unawaited(HapticFeedback.selectionClick());
                unawaited(CompanionRemoteSheet.show(context));
              } else if (tv != null) {
                unawaited(HapticFeedback.mediumImpact());
                final controller = ref.read(companionAudioProvider.notifier);
                final success = await controller.connect(tv.sessionInfo);
                if (success && context.mounted) {
                  unawaited(CompanionRemoteSheet.show(context));
                }
              }
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isConnected
                      ? [
                          const Color(0xFF10B981).withValues(alpha: 0.18),
                          const Color(0xFF0F172A).withValues(alpha: 0.95),
                        ]
                      : [
                          AppColors.accent.withValues(alpha: 0.22),
                          const Color(0xFF0F172A).withValues(alpha: 0.95),
                        ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isConnected
                      ? const Color(0xFF10B981).withValues(alpha: 0.5)
                      : AppColors.accent.withValues(alpha: 0.5),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isConnected
                        ? const Color(0xFF10B981).withValues(alpha: 0.2)
                        : AppColors.accent.withValues(alpha: 0.25),
                    blurRadius: 14,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isConnected
                          ? const Color(0xFF10B981)
                          : AppColors.accent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      isConnected
                          ? Icons.mouse_rounded
                          : _getDeviceIcon(devName),
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 7,
                              height: 7,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isConnected
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFF10B981),
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              isConnected
                                  ? context.l10n.companionConnected
                                  : context.l10n.companionDeviceDetected,
                              style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          isConnected
                              ? '$devName • ${context.l10n.companionTapToControl}'
                              : '$devName • ${context.l10n.companionTapToControl}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  // Action button: Disconnect (red) if connected, Connect (accent) if not
                  if (isConnected)
                    GestureDetector(
                      onTap: () async {
                        unawaited(HapticFeedback.mediumImpact());
                        await ref
                            .read(companionAudioProvider.notifier)
                            .disconnect();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          context.l10n.disconnect,
                          style: const TextStyle(
                            color: Color(0xFFEF4444),
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        context.l10n.companionTapToControl,
                        style: const TextStyle(
                          color: Colors.black,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        );
      },
      orElse: () => const SizedBox.shrink(),
    );

  }

  static IconData _getDeviceIcon(String devName) {
    final lower = devName.toLowerCase();
    if (lower.contains('pc') ||
        lower.contains('windows') ||
        lower.contains('mac') ||
        lower.contains('linux') ||
        lower.contains('desktop') ||
        lower.contains('laptop')) {
      return Icons.laptop_chromebook;
    }
    if (lower.contains('tablet') || lower.contains('pad')) {
      return Icons.tablet_android;
    }
    if (lower.contains('phone') || lower.contains('mobile')) {
      return Icons.smartphone;
    }
    return Icons.tv;
  }
}

