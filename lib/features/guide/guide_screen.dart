import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/data/datasources/xtream_remote_datasource.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/entities/epg_program.dart';
import 'package:iptv/features/guide/guide_controller.dart';
import 'package:iptv/player/player_controller.dart';
import 'package:iptv/player/player_source.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/widgets/empty_state.dart';
import 'package:iptv/shared/widgets/skeleton_loaders.dart';

class GuideScreen extends ConsumerWidget {
  const GuideScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guideState = ref.watch(guideControllerProvider);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go(Routes.home);
          }
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bg0,
        body: guideState.isLoading
            ? const GuideSkeleton()
            : guideState.channels.isEmpty
                ? EmptyState(
                    title: context.l10n.guideNoData,
                    subtitle: context.l10n.guideNoDataSubtitle,
                    icon: AppIcons.guide,
                  )
                : _EpgGrid(
                    channels: guideState.channels,
                    programsMap: guideState.programsByStreamId,
                    onSelectChannel: (ch) => _playChannel(context, ref, ch),
                  ),
      ),
    );
  }

  void _playChannel(BuildContext context, WidgetRef ref, Channel channel) {
    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null) return;

    final streamUrl = XtreamRemoteDataSource.buildLiveStreamUrl(
      serverUrl: session.serverUrl,
      username: session.username,
      password: session.password,
      streamId: channel.streamId,
    );

    ref.read(playerControllerProvider.notifier).load(
      PlayerSource.live(
        url: streamUrl,
        title: channel.name,
        channelId: channel.streamId,
        logoUrl: channel.streamIcon,
      ),
    );

    context.push(Routes.player);
  }
}

class _EpgGrid extends StatelessWidget {
  const _EpgGrid({
    required this.channels,
    required this.programsMap,
    required this.onSelectChannel,
  });

  final List<Channel> channels;
  final Map<int, List<EpgProgram>> programsMap;
  final ValueChanged<Channel> onSelectChannel;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: channels.length,
      itemBuilder: (context, i) {
        final ch = channels[i];
        final progs = programsMap[ch.streamId] ?? [];
        return _ChannelRow(
          channel: ch,
          programs: progs,
          onTap: () => onSelectChannel(ch),
        );
      },
    );
  }
}

class _ChannelRow extends StatelessWidget {
  const _ChannelRow({
    required this.channel,
    required this.programs,
    required this.onTap,
  });

  final Channel channel;
  final List<EpgProgram> programs;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border, width: 0.5)),
      ),
      child: Row(
        children: [
          // Channel label
          GestureDetector(
            onTap: onTap,
            child: Container(
              width: 180,
              color: AppColors.bg1,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              alignment: AlignmentDirectional.centerStart,
              child: Row(
                children: [
                  const HugeIcon(icon: AppIcons.live, color: AppColors.accent, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      channel.name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Programs
          Expanded(
            child: programs.isEmpty
                ? Container(
                    margin: const EdgeInsets.all(4),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    alignment: AlignmentDirectional.centerStart,
                    decoration: BoxDecoration(
                      color: AppColors.bg2,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      context.l10n.labelLive,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                    ),
                  )
                : Row(
                    children: programs.take(4).map((p) {
                      return Expanded(
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: p.isLive ? AppColors.bg3 : AppColors.bg2,
                            borderRadius: BorderRadius.circular(4),
                            border: p.isLive
                                ? Border.all(color: AppColors.accent.withAlpha(120))
                                : null,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                p.title,
                                style: TextStyle(
                                  color: p.isLive ? AppColors.accent : AppColors.textPrimary,
                                  fontSize: 11,
                                  fontWeight: p.isLive ? FontWeight.bold : FontWeight.normal,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (p.duration.inMinutes > 0)
                                Text(
                                  '${p.duration.inMinutes}m',
                                  style: const TextStyle(color: AppColors.textDisabled, fontSize: 10),
                                ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }
}
