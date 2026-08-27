import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_radius.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/data/datasources/xtream_remote_datasource.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/entities/movie.dart';
import 'package:iptv/domain/entities/series.dart';
import 'package:iptv/features/search/search_controller.dart';
import 'package:iptv/features/series/series_screen.dart';
import 'package:iptv/player/player_controller.dart';
import 'package:iptv/player/player_source.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/focus/focusable_card.dart';
import 'package:iptv/shared/widgets/cached_image.dart';
import 'package:iptv/shared/widgets/channel_list_tile.dart';
import 'package:iptv/shared/widgets/empty_state.dart';
import 'package:iptv/shared/widgets/skeleton_loaders.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final searchState = ref.watch(searchControllerProvider);

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
        body: Column(
          children: [
              // Search header
              Container(
                color: AppColors.bg1,
                child: SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    child: Row(
                      children: [
                    BackButton(
                      color: AppColors.textSecondary,
                      onPressed: () => context.canPop() ? context.pop() : context.go(Routes.home),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        autofocus: true,
                        decoration: InputDecoration(
                          hintText: context.l10n.searchHint,
                          prefixIcon: const HugeIcon(icon: AppIcons.search, color: AppColors.textSecondary, size: 20),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          fillColor: Colors.transparent,
                        ),
                        onChanged: (v) {
                          // Clear-button visibility only — search is debounced in the controller.
                          setState(() {});
                          ref.read(searchControllerProvider.notifier).search(v);
                        },
                      ),
                    ),
                    if (_controller.text.isNotEmpty)
                      IconButton(
                        icon: const HugeIcon(icon: AppIcons.close, color: AppColors.textSecondary, size: 18),
                        onPressed: () {
                          _controller.clear();
                          ref.read(searchControllerProvider.notifier).clear();
                          setState(() {});
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
              const Divider(color: AppColors.border, height: 1),
              // Results
              Expanded(
                child: searchState.isLoading
                    ? const SearchSkeleton()
                    : searchState.query.isEmpty
                        ? const _SearchEmptyState()
                        : searchState.totalResults == 0
                            ? EmptyState(
                                title: context.l10n.labelNoResults,
                                subtitle: context.l10n.searchNoResults(searchState.query),
                                icon: AppIcons.searchOff,
                              )
                            : _SearchResultsView(
                                channels: searchState.channels,
                                movies: searchState.movies,
                                series: searchState.series,
                              ),
              ),
            ],
          ),
        ),
    );
  }
}

class _SearchEmptyState extends StatelessWidget {
  const _SearchEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const HugeIcon(icon: AppIcons.search, size: 64, color: AppColors.textDisabled),
          const SizedBox(height: 16),
          Text(
            context.l10n.searchTypeToFind,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 15),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SearchResultsView extends ConsumerWidget {
  const _SearchResultsView({
    required this.channels,
    required this.movies,
    required this.series,
  });

  final List<Channel> channels;
  final List<Movie> movies;
  final List<Series> series;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      children: [
        if (channels.isNotEmpty) ...[
          _SectionTitle(title: context.l10n.searchLiveTab(channels.length)),
          const SizedBox(height: AppSpacing.sm),
          ...channels.map((ch) => _ChannelResultTile(channel: ch)),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (movies.isNotEmpty) ...[
          _SectionTitle(title: context.l10n.searchMoviesTab(movies.length)),
          const SizedBox(height: AppSpacing.sm),
          _MovieResultRow(movies: movies),
          const SizedBox(height: AppSpacing.xl),
        ],
        if (series.isNotEmpty) ...[
          _SectionTitle(title: context.l10n.searchSeriesTab(series.length)),
          const SizedBox(height: AppSpacing.sm),
          _SeriesResultRow(seriesList: series),
        ],
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _ChannelResultTile extends ConsumerWidget {
  const _ChannelResultTile({required this.channel});
  final Channel channel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeChannelId = ref.watch(
      playerControllerProvider.select((s) => s.source?.channelId),
    );
    final isPlaying = activeChannelId == channel.streamId;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ChannelListTile(
        channel: channel,
        isPlaying: isPlaying,
        categoryName: 'Live TV',
        onTap: () {
          final session = ref.read(sessionProvider).valueOrNull;
          if (session == null) return;

          final url = XtreamRemoteDataSource.buildLiveStreamUrl(
            serverUrl: session.serverUrl,
            username: session.username,
            password: session.password,
            streamId: channel.streamId,
          );

          ref.read(playerControllerProvider.notifier).load(
            LiveSource(
              url: url,
              channelName: channel.name,
              channelId: channel.streamId,
              logoUrl: channel.streamIcon,
            ),
          );

          context.push(Routes.player);
        },
      ),
    );
  }
}

class _MovieResultRow extends StatelessWidget {
  const _MovieResultRow({required this.movies});
  final List<Movie> movies;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: movies.length,
        separatorBuilder: (_, index) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final movie = movies[i];
          return SizedBox(
            width: 100,
            child: Consumer(
              builder: (context, ref, _) => FocusableCard(
                onTap: () {
                  final session = ref.read(sessionProvider).valueOrNull;
                  if (session == null) return;

                  final url = XtreamRemoteDataSource.buildVodStreamUrl(
                    serverUrl: session.serverUrl,
                    username: session.username,
                    password: session.password,
                    streamId: movie.streamId,
                    extension: movie.containerExtension ?? 'mp4',
                  );

                  ref.read(playerControllerProvider.notifier).load(
                    VodSource(
                      movieId: movie.streamId,
                      title: movie.name,
                      url: url,
                      posterUrl: movie.streamIcon,
                    ),
                  );

                  context.push(Routes.player);
                },
                padding: EdgeInsets.zero,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedImage(
                      imageUrl: movie.streamIcon,
                      fit: BoxFit.cover,
                      borderRadius: BorderRadius.circular(AppRadius.card),
                      fallbackIcon: AppIcons.movies,
                      memCacheWidth: 100,
                      memCacheHeight: 150,
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        color: Colors.black87,
                        child: Text(
                          movie.name,
                          style: const TextStyle(color: Colors.white, fontSize: 10),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _SeriesResultRow extends StatelessWidget {
  const _SeriesResultRow({required this.seriesList});
  final List<Series> seriesList;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 150,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: seriesList.length,
        separatorBuilder: (_, index) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, i) {
          final series = seriesList[i];
          return SizedBox(
            width: 100,
            child: FocusableCard(
              onTap: () => showSeriesDetailsModal(context, series),
              padding: EdgeInsets.zero,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedImage(
                    imageUrl: series.cover,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(AppRadius.card),
                    fallbackIcon: AppIcons.series,
                    memCacheWidth: 100,
                    memCacheHeight: 150,
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      color: Colors.black87,
                      child: Text(
                        series.name,
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
