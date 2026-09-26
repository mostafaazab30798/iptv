import 'dart:async';

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:intl/intl.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/entities/epg_program.dart';
import 'package:iptv/features/catch_up/catch_up_controller.dart';
import 'package:iptv/player/player.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/focus/focusable_card.dart';
import 'package:iptv/shared/widgets/empty_state.dart';
import 'package:iptv/shared/widgets/error_view.dart';
import 'package:iptv/shared/widgets/smart_channel_logo.dart';

class CatchUpScreen extends ConsumerWidget {
  const CatchUpScreen({super.key, required this.channel});

  final Channel channel;

  Future<void> _play(
    BuildContext context,
    WidgetRef ref,
    EpgProgram program,
  ) async {
    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null) return;
    final url = ref
        .read(streamUrlBuilderProvider)
        .catchUpForSession(
          session,
          streamId: channel.streamId,
          start: program.start,
          duration: program.duration,
        );
    final controller = ref.read(playerControllerProvider.notifier);
    await controller.load(
      PlayerSource.catchUp(
        url: url,
        title: program.title,
        channelTitle: channel.name,
        logoUrl: channel.streamIcon,
        epgProgramId: program.epgId,
        metadata: const {'timeshift': true},
      ),
    );
    if (!context.mounted) return;
    controller.setPlayerRouteActive(true);
    unawaited(context.push(Routes.player));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(catchUpControllerProvider(channel));
    return Scaffold(
      backgroundColor: AppColors.bg0,
      appBar: AppBar(
        backgroundColor: AppColors.bg1,
        titleSpacing: 8,
        title: Row(
          children: [
            SmartChannelLogo(
              channel: channel,
              width: 36,
              height: 36,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.l10n.catchUpTitle,
                    style: const TextStyle(fontSize: 16),
                  ),
                  Text(
                    channel.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => ErrorView(
          message: context.l10n.catchUpLoadError,
          onRetry: () =>
              ref.read(catchUpControllerProvider(channel).notifier).load(),
        ),
        data: (programs) => programs.isEmpty
            ? EmptyState(
                title: context.l10n.catchUpEmpty,
                subtitle: context.l10n.catchUpEmptySubtitle,
                icon: AppIcons.history,
              )
            : DpadRegion(
                memoryKey: 'catch-up/${channel.streamId}',
                debugLabel: 'catch-up-programs',
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: programs.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _ArchivedProgramCard(
                    program: programs[index],
                    onPlay: () => _play(context, ref, programs[index]),
                  ),
                ),
              ),
      ),
    );
  }
}

class _ArchivedProgramCard extends StatelessWidget {
  const _ArchivedProgramCard({required this.program, required this.onPlay});

  final EpgProgram program;
  final VoidCallback onPlay;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final date = DateFormat.MMMEd(locale).format(program.start.toLocal());
    final start = DateFormat.Hm(locale).format(program.start.toLocal());
    final end = DateFormat.Hm(locale).format(program.end.toLocal());
    return FocusableCard(
      onTap: onPlay,
      borderRadius: BorderRadius.circular(16),
      backgroundColor: AppColors.bg1,
      borderColor: AppColors.border,
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.accent.withAlpha(24),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: HugeIcon(
                icon: AppIcons.replay,
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
                  program.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '$date · $start–$end',
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const HugeIcon(
            icon: AppIcons.play,
            color: AppColors.accent,
            size: 22,
          ),
        ],
      ),
    );
  }
}
