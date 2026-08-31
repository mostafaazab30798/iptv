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
import 'package:iptv/domain/entities/watch_history.dart';
import 'package:iptv/player/player_controller.dart';
import 'package:iptv/player/player_source.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/focus/focusable_card.dart';
import 'package:iptv/shared/widgets/cached_image.dart';
import 'package:iptv/shared/widgets/empty_state.dart';
import 'package:iptv/shared/widgets/skeleton_loaders.dart';

final historyListProvider = FutureProvider.autoDispose<List<WatchHistoryEntry>>((ref) async {
  final repo = ref.watch(historyRepositoryProvider);
  final allowed = await ref.watch(kidsAllowedContentProvider.future);
  final res = await repo.getHistory(limit: 100);
  return res.when(
    ok: (list) => list.where(allowed.allowsHistory).toList(),
    err: (_) => [],
  );
});

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<WatchHistoryEntry>? _localItems;

  @override
  Widget build(BuildContext context) {
    ref.listen<AsyncValue<List<WatchHistoryEntry>>>(historyListProvider, (_, next) {
      next.whenData((items) {
        if (mounted) {
          setState(() {
            _localItems = List.of(items);
          });
        }
      });
    });

    final historyAsync = ref.watch(historyListProvider);
    final items = _localItems ?? historyAsync.valueOrNull;

    return PopScope(
      canPop: false,
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
        body: Builder(
          builder: (context) {
            if (historyAsync.isLoading && items == null) {
              return const HistorySkeleton();
            }
            if (historyAsync.hasError && items == null) {
              return Center(
                child: Text(
                  'Error: ${historyAsync.error}',
                  style: const TextStyle(color: AppColors.error),
                ),
              );
            }
            if (items == null || items.isEmpty) {
              return EmptyState(
                title: context.l10n.historyEmptyTitle,
                subtitle: context.l10n.historyEmptySubtitle,
                icon: AppIcons.history,
              );
            }

            return CustomScrollView(
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      AppSpacing.lg,
                      AppSpacing.xl,
                      AppSpacing.sm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const HugeIcon(
                              icon: AppIcons.history,
                              color: AppColors.accent,
                              size: 22,
                            ),
                            const SizedBox(width: 10),
                            Text(
                              context.l10n.historyTitle,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        TextButton.icon(
                          onPressed: () => _confirmClearHistory(context),
                          icon: const HugeIcon(
                            icon: AppIcons.deleteSweep,
                            color: AppColors.textSecondary,
                            size: 18,
                          ),
                          label: Text(
                            context.l10n.historyClearTooltip,
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xl,
                    vertical: AppSpacing.sm,
                  ),
                  sliver: SliverList.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, index) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final item = items[i];
                      final progress = item.progressFraction;

                      return Dismissible(
                        key: ValueKey('history_${item.id}'),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          decoration: BoxDecoration(
                            color: AppColors.error.withAlpha(200),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const HugeIcon(icon: AppIcons.delete, color: Colors.white, size: 22),
                        ),
                        onDismissed: (_) {
                          final id = item.id;
                          setState(() {
                            _localItems ??= List.of(items);
                            _localItems!.removeWhere((x) => x.id == id);
                          });
                          ref.read(historyRepositoryProvider).deleteEntry(id);
                        },
                        child: FocusableCard(
                          onTap: () => _playHistoryItem(context, item),
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Stack(
                                children: [
                                  Container(
                                    width: 56,
                                    height: 56,
                                    decoration: BoxDecoration(
                                      color: AppColors.bg2,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: CachedImage(
                                      imageUrl: item.imageUrl,
                                      fallbackIcon: AppIcons.play,
                                      fit: BoxFit.cover,
                                      borderRadius: BorderRadius.circular(8),
                                      memCacheWidth: 64,
                                      memCacheHeight: 64,
                                    ),
                                  ),
                                  if (progress > 0)
                                    Positioned(
                                      bottom: 4,
                                      left: 4,
                                      right: 4,
                                      child: Container(
                                        height: 3.5,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(100),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withAlpha(120),
                                              blurRadius: 2,
                                            ),
                                          ],
                                        ),
                                        child: Directionality(
                                          textDirection: TextDirection.ltr,
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(100),
                                            child: LinearProgressIndicator(
                                              value: progress.clamp(0.0, 1.0),
                                              backgroundColor: Colors.white.withAlpha(60),
                                              valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                                              minHeight: 3.5,
                                              borderRadius: BorderRadius.circular(100),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        color: AppColors.textPrimary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.bg2,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            _typeLabel(context, item.type),
                                            style: const TextStyle(
                                              color: AppColors.accent,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        if (item.durationSecs != null && item.durationSecs! > 0) ...[
                                          const SizedBox(width: 8),
                                          Text(
                                            '${(progress * 100).round()}%',
                                            style: TextStyle(
                                              color: progress >= 0.9 ? AppColors.accent : AppColors.textSecondary,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _buildSubtitle(context, item),
                                      style: const TextStyle(
                                        color: AppColors.textSecondary,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const HugeIcon(icon: AppIcons.play, color: AppColors.accent, size: 24),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  String _buildSubtitle(BuildContext context, WatchHistoryEntry item) {
    final dateStr = '\u200E${item.watchedAt.year}-${item.watchedAt.month.toString().padLeft(2, '0')}-${item.watchedAt.day.toString().padLeft(2, '0')}\u200E';
    if (item.durationSecs != null && item.durationSecs! > 0) {
      final posMin = (item.positionSecs / 60).floor();
      final durMin = (item.durationSecs! / 60).floor();
      return context.l10n.historyProgressSubtitle(posMin, durMin, dateStr);
    }
    return context.l10n.historyWatchedOn(dateStr);
  }

  String _typeLabel(BuildContext context, WatchHistoryType type) {
    switch (type) {
      case WatchHistoryType.channel:
        return context.l10n.historyTypeLive;
      case WatchHistoryType.movie:
        return context.l10n.historyTypeMovie;
      case WatchHistoryType.episode:
        return context.l10n.historyTypeSeries;
    }
  }

  void _playHistoryItem(BuildContext context, WatchHistoryEntry entry) {
    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null) return;

    final startAt = entry.positionSecs > 0 && !entry.isFinished
        ? Duration(seconds: entry.positionSecs)
        : Duration.zero;

    if (entry.type == WatchHistoryType.movie) {
      final streamUrl = XtreamRemoteDataSource.buildVodStreamUrl(
        serverUrl: session.serverUrl,
        username: session.username,
        password: session.password,
        streamId: entry.itemId,
      );
      ref.read(playerControllerProvider.notifier).load(
        VodSource(
          url: streamUrl,
          title: entry.name,
          movieId: entry.itemId,
          posterUrl: entry.imageUrl,
          startAt: startAt,
        ),
      );
    } else if (entry.type == WatchHistoryType.episode) {
      final streamUrl = XtreamRemoteDataSource.buildSeriesStreamUrl(
        serverUrl: session.serverUrl,
        username: session.username,
        password: session.password,
        streamId: entry.itemId,
      );
      ref.read(playerControllerProvider.notifier).load(
        EpisodeSource(
          url: streamUrl,
          title: entry.name,
          episodeId: entry.itemId,
          posterUrl: entry.imageUrl,
          startAt: startAt,
        ),
      );
    } else {
      final streamUrl = XtreamRemoteDataSource.buildLiveStreamUrl(
        serverUrl: session.serverUrl,
        username: session.username,
        password: session.password,
        streamId: entry.itemId,
      );
      ref.read(playerControllerProvider.notifier).load(
        LiveSource(
          url: streamUrl,
          channelName: entry.name,
          channelId: entry.itemId,
          logoUrl: entry.imageUrl,
        ),
      );
    }

    context.push(Routes.player);
  }

  Future<void> _confirmClearHistory(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.bg1,
        title: Text(context.l10n.historyClearDialogTitle),
        content: Text(context.l10n.historyClearDialogContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(context.l10n.actionCancel, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
            child: Text(context.l10n.actionClearAll),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(historyRepositoryProvider).clearHistory();
      if (mounted) {
        setState(() {
          _localItems = [];
        });
      }
      ref.invalidate(historyListProvider);
    }
  }
}
