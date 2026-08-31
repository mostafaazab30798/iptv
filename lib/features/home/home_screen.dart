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

class _HomeContent extends ConsumerWidget {
  const _HomeContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(sessionProvider);
    final homeState = ref.watch(homeControllerProvider);

    final hasContent =
        homeState.heroItem != null ||
        homeState.continueWatching.isNotEmpty ||
        homeState.liveChannels.isNotEmpty ||
        homeState.favorites.isNotEmpty ||
        homeState.featuredMovies.isNotEmpty ||
        homeState.popularSeries.isNotEmpty;

    if (sessionAsync.isLoading || (homeState.isLoading && !hasContent)) {
      return const HomeSkeleton();
    }

    if (homeState.error != null && !hasContent) {
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

    if (!hasContent) {
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

    return ResponsiveBuilder(
      builder: (context, size) => RefreshIndicator(
        onRefresh: () => ref
            .read(homeControllerProvider.notifier)
            .loadData(forceRefresh: true),
        child: MediaQuery.removePadding(
          context: context,
          removeTop: true,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(
              parent: AlwaysScrollableScrollPhysics(),
            ),
            cacheExtent: 350,
            slivers: [
              // 1. Full-Width Cinematic Hero Banner
              if (homeState.heroItem != null || homeState.heroItems.isNotEmpty)
                SliverToBoxAdapter(
                  child: RepaintBoundary(
                    key: const ValueKey('home-hero'),
                    child: HomeHeroBanner(
                      item: homeState.heroItem,
                      items: homeState.heroItems,
                      onPlay: (hero) => _playHero(context, ref, hero),
                      onRefresh: () => ref
                          .read(homeControllerProvider.notifier)
                          .loadData(forceRefresh: true),
                    ),
                  ),
                ),

              if (homeState.continueWatching.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: RepaintBoundary(
                      key: const ValueKey('home-continue-watching'),
                      child: HomeSectionRow<WatchHistoryEntry>(
                        title: context.l10n.labelContinueWatching,
                        onSeeAll: () => context.push(Routes.history),
                        items: homeState.continueWatching,
                        height: 215,
                        itemBuilder: (context, entry, _) => HistoryCard(
                          entry: entry,
                          onTap: () => _playHistory(context, ref, entry),
                        ),
                      ),
                    ),
                  ),
                ),
              if (homeState.continueWatching.isNotEmpty)
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.md),
                ),

              if (homeState.featuredMovies.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: RepaintBoundary(
                      key: const ValueKey('home-featured-movies'),
                      child: HomeSectionRow<Movie>(
                        title: context.l10n.homeFeaturedMovies,
                        onSeeAll: () => context.push(Routes.movies),
                        items: homeState.featuredMovies,
                        height: 215,
                        itemBuilder: (context, movie, _) => MovieCard(
                          movie: movie,
                          onTap: () => _playMovie(context, ref, movie),
                        ),
                      ),
                    ),
                  ),
                ),
              if (homeState.featuredMovies.isNotEmpty)
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.md),
                ),

              if (homeState.popularSeries.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: RepaintBoundary(
                      key: const ValueKey('home-popular-series'),
                      child: HomeSectionRow<Series>(
                        title: context.l10n.homePopularSeries,
                        onSeeAll: () => context.push(Routes.series),
                        items: homeState.popularSeries,
                        height: 215,
                        itemBuilder: (context, series, _) => SeriesCard(
                          series: series,
                          onTap: () => showSeriesDetailsModal(context, series),
                        ),
                      ),
                    ),
                  ),
                ),
              if (homeState.popularSeries.isNotEmpty)
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.md),
                ),

              if (homeState.sportsChannels.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: RepaintBoundary(
                      key: const ValueKey('home-sports-channels'),
                      child: HomeSectionRow<Channel>(
                        title: context.l10n.homeSportsChannels,
                        onSeeAll: () => context.push(Routes.live),
                        items: homeState.sportsChannels,
                        height: 135,
                        itemBuilder: (context, channel, _) => ChannelCard(
                          channel: channel,
                          onTap: () => _playChannel(context, ref, channel),
                        ),
                      ),
                    ),
                  ),
                ),
              if (homeState.sportsChannels.isNotEmpty)
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.md),
                ),

              if (homeState.newsChannels.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: RepaintBoundary(
                      key: const ValueKey('home-news-channels'),
                      child: HomeSectionRow<Channel>(
                        title: context.l10n.homeNewsChannels,
                        onSeeAll: () => context.push(Routes.live),
                        items: homeState.newsChannels,
                        height: 135,
                        itemBuilder: (context, channel, _) => ChannelCard(
                          channel: channel,
                          onTap: () => _playChannel(context, ref, channel),
                        ),
                      ),
                    ),
                  ),
                ),
              if (homeState.newsChannels.isNotEmpty)
                const SliverToBoxAdapter(
                  child: SizedBox(height: AppSpacing.md),
                ),

              if (homeState.favorites.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: RepaintBoundary(
                      key: const ValueKey('home-favorites'),
                      child: HomeSectionRow<Favorite>(
                        title: context.l10n.labelFavorites,
                        onSeeAll: () => context.push(Routes.favorites),
                        items: homeState.favorites,
                        height: 135,
                        itemBuilder: (context, fav, _) => ChannelCard(
                          channel: Channel(
                            id: fav.itemId,
                            serverId: 0,
                            streamId: fav.itemId,
                            name: fav.name,
                            streamIcon: fav.imageUrl,
                          ),
                          showBadge: fav.type == FavoriteType.channel,
                          onTap: () => _playFavorite(context, ref, fav),
                        ),
                      ),
                    ),
                  ),
                ),

              const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xxl)),
            ],
          ),
        ),
      ),
    );
  }

  void _playHero(BuildContext context, WidgetRef ref, HomeHeroItem hero) {
    if (hero.movie != null) {
      _playMovie(context, ref, hero.movie!);
    } else if (hero.channel != null) {
      _playChannel(context, ref, hero.channel!);
    }
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

  void _playMovie(BuildContext context, WidgetRef ref, Movie movie) {
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

  void _playHistory(
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

  void _playFavorite(BuildContext context, WidgetRef ref, Favorite fav) {
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
