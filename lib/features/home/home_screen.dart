import 'dart:async';

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
import 'package:iptv/domain/entities/favorite.dart';
import 'package:iptv/domain/entities/movie.dart';
import 'package:iptv/domain/entities/series.dart';
import 'package:iptv/domain/entities/watch_history.dart';
import 'package:iptv/features/home/home_controller.dart';
import 'package:iptv/features/home/widgets/cards/channel_card.dart';
import 'package:iptv/features/home/widgets/cards/history_card.dart';
import 'package:iptv/features/home/widgets/cards/movie_card.dart';
import 'package:iptv/features/home/widgets/cards/series_card.dart';
import 'package:iptv/features/home/widgets/home_hero_banner.dart';
import 'package:iptv/features/home/widgets/home_section_row.dart';
import 'package:iptv/features/series/series_screen.dart';

import 'package:iptv/player/player_controller.dart';
import 'package:iptv/player/player_source.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/layouts/responsive_builder.dart';
import 'package:iptv/shared/widgets/empty_state.dart';
import 'package:iptv/shared/widgets/skeleton_loaders.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(playerControllerProvider.notifier).stop();
        ref.read(homeControllerProvider.notifier).refreshContinueWatching();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(backgroundColor: AppColors.bg0, body: _HomeContent());
  }
}

// ---------------------------------------------------------------------------
// Home Content — Scrollable cinematic rows with dynamic content loading
// ---------------------------------------------------------------------------

class _HomeContent extends ConsumerStatefulWidget {
  const _HomeContent();

  @override
  ConsumerState<_HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends ConsumerState<_HomeContent> {
  bool _heroAutoPlay = true;
  Timer? _resumeHeroTimer;

  @override
  void dispose() {
    _resumeHeroTimer?.cancel();
    super.dispose();
  }

  bool _onScrollNotification(ScrollNotification notification) {
    // Only react to the outer vertical Home scroller, not nested rows.
    if (notification.depth != 0) return false;
    if (notification.metrics.axis != Axis.vertical) return false;

    if (notification is ScrollStartNotification ||
        notification is ScrollUpdateNotification) {
      _resumeHeroTimer?.cancel();
      if (_heroAutoPlay) {
        setState(() => _heroAutoPlay = false);
      }
    } else if (notification is ScrollEndNotification) {
      _resumeHeroTimer?.cancel();
      _resumeHeroTimer = Timer(const Duration(milliseconds: 700), () {
        if (mounted && !_heroAutoPlay) {
          setState(() => _heroAutoPlay = true);
        }
      });
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final sessionAsync = ref.watch(sessionProvider);
    final kidsReady = ref.watch(
      kidsModeProvider.select((s) => s.isInitialized),
    );
    final liveRepoReady = ref.watch(liveRepositoryProvider) != null;
    final boot = ref.watch(
      homeControllerProvider.select(
        (s) => (
          isLoading: s.isLoading,
          error: s.error,
          hasContent: s.heroItem != null ||
              s.continueWatching.isNotEmpty ||
              s.liveChannels.isNotEmpty ||
              s.favorites.isNotEmpty ||
              s.featuredMovies.isNotEmpty ||
              s.popularSeries.isNotEmpty ||
              s.sportsChannels.isNotEmpty ||
              s.newsChannels.isNotEmpty,
        ),
      ),
    );

    final session = sessionAsync.valueOrNull;
    final sessionReady = session != null && session.isValid;

    // Wait for session + kids-mode (which gates catalog repos) before treating
    // an empty HomeState as a real "no media" result.
    final waitingForCatalog =
        sessionAsync.isLoading ||
        !kidsReady ||
        (sessionReady && !liveRepoReady) ||
        (boot.isLoading && !boot.hasContent);

    if (waitingForCatalog) {
      return const HomeSkeleton();
    }

    if (boot.error != null && !boot.hasContent) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const HugeIcon(
              icon: AppIcons.error,
              color: AppColors.error,
              size: 48,
            ),
            const SizedBox(height: 12),
            Text(
              context.l10n.homeEmptyPlaylist,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              context.l10n.homeCheckConnection,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => ref
                  .read(homeControllerProvider.notifier)
                  .loadData(forceRefresh: true),
              icon: const HugeIcon(
                icon: AppIcons.refresh,
                size: 18,
                color: Colors.black,
              ),
              label: Text(context.l10n.actionTryAgain),
            ),
          ],
        ),
      );
    }

    if (!boot.hasContent) {
      return EmptyState(
        title: context.l10n.homeEmptyPlaylist,
        subtitle: context.l10n.homeEmptyPlaylistSubtitle,
        icon: AppIcons.empty,
        actionLabel: context.l10n.actionRefresh,
        onAction: () => ref
            .read(homeControllerProvider.notifier)
            .loadData(forceRefresh: true),
      );
    }

    return NotificationListener<ScrollNotification>(
      onNotification: _onScrollNotification,
      child: ResponsiveBuilder(
        builder: (context, size) => RefreshIndicator(
          onRefresh: () => ref
              .read(homeControllerProvider.notifier)
              .loadData(forceRefresh: true),
          child: MediaQuery.removePadding(
            context: context,
            removeTop: true,
            child: CustomScrollView(
              // Platform-default physics; AlwaysScrollable enables pull-to-refresh.
              physics: const AlwaysScrollableScrollPhysics(),
              cacheExtent: 160,
              slivers: [
                _HomeHeroSliver(autoPlay: _heroAutoPlay),
                const _HomeContinueWatchingSliver(),
                const _HomeFeaturedMoviesSliver(),
                const _HomePopularSeriesSliver(),
                const _HomeSportsChannelsSliver(),
                const _HomeNewsChannelsSliver(),
                const _HomeFavoritesSliver(),
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.xxl),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeHeroSliver extends ConsumerWidget {
  const _HomeHeroSliver({required this.autoPlay});

  final bool autoPlay;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hero = ref.watch(
      homeControllerProvider.select(
        (s) => (item: s.heroItem, items: s.heroItems),
      ),
    );
    if (hero.item == null && hero.items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: RepaintBoundary(
        key: const ValueKey('home-hero'),
        child: HomeHeroBanner(
          item: hero.item,
          items: hero.items,
          autoPlay: autoPlay,
          onPlay: (item) => _HomePlayback.playHero(context, ref, item),
          onRefresh: () => ref
              .read(homeControllerProvider.notifier)
              .loadData(forceRefresh: true),
        ),
      ),
    );
  }
}

class _HomeContinueWatchingSliver extends ConsumerWidget {
  const _HomeContinueWatchingSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(
      homeControllerProvider.select((s) => s.continueWatching),
    );
    if (items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: RepaintBoundary(
          key: const ValueKey('home-continue-watching'),
          child: HomeSectionRow<WatchHistoryEntry>(
            title: context.l10n.labelContinueWatching,
            onSeeAll: () => context.push(Routes.history),
            items: items,
            height: 215,
            itemWidth: 120,
            itemBuilder: (context, entry, _) => HistoryCard(
              key: ValueKey('hist-${entry.itemId}-${entry.type}'),
              entry: entry,
              onTap: () => _HomePlayback.playHistory(context, ref, entry),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeFeaturedMoviesSliver extends ConsumerWidget {
  const _HomeFeaturedMoviesSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(
      homeControllerProvider.select((s) => s.featuredMovies),
    );
    if (items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: RepaintBoundary(
          key: const ValueKey('home-featured-movies'),
          child: HomeSectionRow<Movie>(
            title: context.l10n.homeFeaturedMovies,
            onSeeAll: () => context.push(Routes.movies),
            items: items,
            height: 215,
            itemWidth: 120,
            itemBuilder: (context, movie, _) => MovieCard(
              key: ValueKey('movie-${movie.streamId}'),
              movie: movie,
              onTap: () => _HomePlayback.playMovie(context, ref, movie),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomePopularSeriesSliver extends ConsumerWidget {
  const _HomePopularSeriesSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(
      homeControllerProvider.select((s) => s.popularSeries),
    );
    if (items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: RepaintBoundary(
          key: const ValueKey('home-popular-series'),
          child: HomeSectionRow<Series>(
            title: context.l10n.homePopularSeries,
            onSeeAll: () => context.push(Routes.series),
            items: items,
            height: 215,
            itemWidth: 120,
            itemBuilder: (context, series, _) => SeriesCard(
              key: ValueKey(
                'series-${series.seriesId != 0 ? series.seriesId : series.id}',
              ),
              series: series,
              onTap: () => showSeriesDetailsModal(context, series),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeSportsChannelsSliver extends ConsumerWidget {
  const _HomeSportsChannelsSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(
      homeControllerProvider.select((s) => s.sportsChannels),
    );
    if (items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: RepaintBoundary(
          key: const ValueKey('home-sports-channels'),
          child: HomeSectionRow<Channel>(
            title: context.l10n.homeSportsChannels,
            onSeeAll: () => context.push(Routes.live),
            items: items,
            height: 135,
            itemWidth: 148,
            itemBuilder: (context, channel, _) => ChannelCard(
              key: ValueKey('sports-${channel.streamId}'),
              channel: channel,
              onTap: () => _HomePlayback.playChannel(context, ref, channel),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeNewsChannelsSliver extends ConsumerWidget {
  const _HomeNewsChannelsSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(
      homeControllerProvider.select((s) => s.newsChannels),
    );
    if (items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: RepaintBoundary(
          key: const ValueKey('home-news-channels'),
          child: HomeSectionRow<Channel>(
            title: context.l10n.homeNewsChannels,
            onSeeAll: () => context.push(Routes.live),
            items: items,
            height: 135,
            itemWidth: 148,
            itemBuilder: (context, channel, _) => ChannelCard(
              key: ValueKey('news-${channel.streamId}'),
              channel: channel,
              onTap: () => _HomePlayback.playChannel(context, ref, channel),
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeFavoritesSliver extends ConsumerWidget {
  const _HomeFavoritesSliver();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(
      homeControllerProvider.select((s) => s.favorites),
    );
    if (items.isEmpty) {
      return const SliverToBoxAdapter(child: SizedBox.shrink());
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
        child: RepaintBoundary(
          key: const ValueKey('home-favorites'),
          child: HomeSectionRow<Favorite>(
            title: context.l10n.labelFavorites,
            onSeeAll: () => context.push(Routes.favorites),
            items: items,
            height: 135,
            itemWidth: 148,
            itemBuilder: (context, fav, _) => ChannelCard(
              key: ValueKey('fav-${fav.type}-${fav.itemId}'),
              channel: Channel(
                id: fav.itemId,
                serverId: 0,
                streamId: fav.itemId,
                name: fav.name,
                streamIcon: fav.imageUrl,
              ),
              showBadge: fav.type == FavoriteType.channel,
              onTap: () => _HomePlayback.playFavorite(context, ref, fav),
            ),
          ),
        ),
      ),
    );
  }
}

/// Playback helpers shared by home section slivers.
abstract final class _HomePlayback {
  static void playHero(
    BuildContext context,
    WidgetRef ref,
    HomeHeroItem hero,
  ) {
    if (hero.movie != null) {
      playMovie(context, ref, hero.movie!);
    } else if (hero.channel != null) {
      playChannel(context, ref, hero.channel!);
    }
  }

  static void playChannel(
    BuildContext context,
    WidgetRef ref,
    Channel channel,
  ) {
    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null) return;

    final streamUrl = XtreamRemoteDataSource.buildLiveStreamUrl(
      serverUrl: session.serverUrl,
      username: session.username,
      password: session.password,
      streamId: channel.streamId,
    );

    ref
        .read(playerControllerProvider.notifier)
        .load(
          LiveSource(
            channelId: channel.streamId,
            channelName: channel.name,
            url: streamUrl,
            logoUrl: channel.streamIcon,
          ),
        );

    context.push(Routes.player);
  }

  static void playMovie(BuildContext context, WidgetRef ref, Movie movie) {
    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null) return;

    final streamUrl = XtreamRemoteDataSource.buildVodStreamUrl(
      serverUrl: session.serverUrl,
      username: session.username,
      password: session.password,
      streamId: movie.streamId,
      extension: movie.containerExtension ?? 'mp4',
    );

    ref
        .read(playerControllerProvider.notifier)
        .load(
          VodSource(
            url: streamUrl,
            title: movie.name,
            movieId: movie.streamId,
            posterUrl: movie.streamIcon,
          ),
        );

    context.push(Routes.player);
  }

  static void playHistory(
    BuildContext context,
    WidgetRef ref,
    WatchHistoryEntry entry,
  ) {
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
      ref
          .read(playerControllerProvider.notifier)
          .load(
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
      ref
          .read(playerControllerProvider.notifier)
          .load(
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
      ref
          .read(playerControllerProvider.notifier)
          .load(
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

  static void playFavorite(
    BuildContext context,
    WidgetRef ref,
    Favorite fav,
  ) {
    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null) return;

    if (fav.type == FavoriteType.movie) {
      final streamUrl = XtreamRemoteDataSource.buildVodStreamUrl(
        serverUrl: session.serverUrl,
        username: session.username,
        password: session.password,
        streamId: fav.itemId,
      );
      ref
          .read(playerControllerProvider.notifier)
          .load(
            PlayerSource.vod(
              url: streamUrl,
              title: fav.name,
              movieId: fav.itemId,
              posterUrl: fav.imageUrl,
            ),
          );
      context.push(Routes.player);
    } else if (fav.type == FavoriteType.channel) {
      final streamUrl = XtreamRemoteDataSource.buildLiveStreamUrl(
        serverUrl: session.serverUrl,
        username: session.username,
        password: session.password,
        streamId: fav.itemId,
      );
      ref
          .read(playerControllerProvider.notifier)
          .load(
            PlayerSource.live(
              url: streamUrl,
              title: fav.name,
              channelId: fav.itemId,
              logoUrl: fav.imageUrl,
            ),
          );
      context.push(Routes.player);
    } else {
      context.push(Routes.series);
    }
  }
}
