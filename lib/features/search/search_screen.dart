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
import 'package:iptv/domain/entities/movie.dart';
import 'package:iptv/domain/entities/series.dart';
import 'package:iptv/features/home/widgets/cards/movie_card.dart';
import 'package:iptv/features/home/widgets/cards/series_card.dart';
import 'package:iptv/features/home/widgets/home_section_row.dart';
import 'package:iptv/features/search/search_controller.dart';
import 'package:iptv/features/series/series_screen.dart';
import 'package:iptv/player/player_controller.dart';
import 'package:iptv/player/player_source.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/widgets/channel_list_tile.dart';
import 'package:iptv/shared/widgets/empty_state.dart';
import 'package:iptv/shared/widgets/skeleton_loaders.dart';

enum _SearchCategoryFilter { all, movies, series, channels }

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  _SearchCategoryFilter _selectedFilter = _SearchCategoryFilter.all;

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onSuggestionTap(String suggestion) {
    _textController.text = suggestion;
    _textController.selection = TextSelection.fromPosition(
      TextPosition(offset: suggestion.length),
    );
    ref.read(searchControllerProvider.notifier).search(suggestion);
    setState(() {});
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
        body: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // 1. Premium Glassmorphic Search Header
              _SearchHeader(
                controller: _textController,
                focusNode: _focusNode,
                onChanged: (val) {
                  setState(() {});
                  ref.read(searchControllerProvider.notifier).search(val);
                },
                onClear: () {
                  _textController.clear();
                  ref.read(searchControllerProvider.notifier).clear();
                  setState(() {});
                },
              ),

              // 2. Filter Category Pills (when results exist)
              if (!searchState.isLoading &&
                  searchState.query.isNotEmpty &&
                  searchState.totalResults > 0)
                _FilterTabs(
                  selected: _selectedFilter,
                  moviesCount: searchState.movies.length,
                  seriesCount: searchState.series.length,
                  channelsCount: searchState.channels.length,
                  onSelect: (filter) => setState(() => _selectedFilter = filter),
                ),

              // 3. Results / Loading / Empty Content View
              Expanded(
                child: searchState.isLoading
                    ? const SearchSkeleton()
                    : searchState.query.isEmpty
                        ? _SearchDiscoveryView(
                            onSuggestionTap: _onSuggestionTap,
                          )
                        : searchState.totalResults == 0
                            ? EmptyState(
                                title: context.l10n.labelNoResults,
                                subtitle:
                                    context.l10n.searchNoResults(searchState.query),
                                icon: AppIcons.searchOff,
                              )
                            : _SearchResultsView(
                                filter: _selectedFilter,
                                channels: searchState.channels,
                                movies: searchState.movies,
                                series: searchState.series,
                              ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search Header Input
// ---------------------------------------------------------------------------

class _SearchHeader extends StatelessWidget {
  const _SearchHeader({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Back Action
          IconButton(
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withAlpha(12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(10),
            ),
            icon: const HugeIcon(
              icon: AppIcons.arrowBack,
              color: Colors.white,
              size: 20,
            ),
            onPressed: () =>
                context.canPop() ? context.pop() : context.go(Routes.home),
          ),
          const SizedBox(width: AppSpacing.md),

          // Glass Search Bar
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFF141822),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: Colors.white.withAlpha(25),
                  width: 0.9,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(90),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const HugeIcon(
                    icon: AppIcons.search,
                    color: Color(0xFF00C2FF),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: controller,
                      focusNode: focusNode,
                      autofocus: true,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                      cursorColor: const Color(0xFF00C2FF),
                      decoration: InputDecoration(
                        hintText: context.l10n.searchHint,
                        hintStyle: TextStyle(
                          color: Colors.white.withAlpha(90),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w400,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onChanged: onChanged,
                    ),
                  ),
                  if (controller.text.isNotEmpty)
                    GestureDetector(
                      onTap: onClear,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.white.withAlpha(30),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: HugeIcon(
                              icon: AppIcons.close,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Segmented Filter Tabs
// ---------------------------------------------------------------------------

class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.selected,
    required this.moviesCount,
    required this.seriesCount,
    required this.channelsCount,
    required this.onSelect,
  });

  final _SearchCategoryFilter selected;
  final int moviesCount;
  final int seriesCount;
  final int channelsCount;
  final ValueChanged<_SearchCategoryFilter> onSelect;

  @override
  Widget build(BuildContext context) {
    final total = moviesCount + seriesCount + channelsCount;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: 8),
      child: Row(
        children: [
          _TabPill(
            title: 'All ($total)',
            isActive: selected == _SearchCategoryFilter.all,
            onTap: () => onSelect(_SearchCategoryFilter.all),
          ),
          const SizedBox(width: 8),
          if (moviesCount > 0) ...[
            _TabPill(
              title: '${context.l10n.navMovies} ($moviesCount)',
              isActive: selected == _SearchCategoryFilter.movies,
              onTap: () => onSelect(_SearchCategoryFilter.movies),
            ),
            const SizedBox(width: 8),
          ],
          if (seriesCount > 0) ...[
            _TabPill(
              title: '${context.l10n.navSeries} ($seriesCount)',
              isActive: selected == _SearchCategoryFilter.series,
              onTap: () => onSelect(_SearchCategoryFilter.series),
            ),
            const SizedBox(width: 8),
          ],
          if (channelsCount > 0)
            _TabPill(
              title: '${context.l10n.navLive} ($channelsCount)',
              isActive: selected == _SearchCategoryFilter.channels,
              onTap: () => onSelect(_SearchCategoryFilter.channels),
            ),
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.title,
    required this.isActive,
    required this.onTap,
  });

  final String title;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF00C2FF) : const Color(0xFF161A24),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? const Color(0xFF00C2FF) : Colors.white.withAlpha(20),
            width: 0.8,
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: isActive ? Colors.black : Colors.white70,
            fontSize: 12.5,
            fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search Discovery / Initial Suggestions View
// ---------------------------------------------------------------------------

class _SearchDiscoveryView extends StatelessWidget {
  const _SearchDiscoveryView({required this.onSuggestionTap});

  final ValueChanged<String> onSuggestionTap;

  static const _popularQueries = [
    'Action',
    'Comedy',
    'Drama',
    'Sci-Fi',
    'Animation',
    'Horror',
    'Thriller',
    'Sports',
    'News',
    'Bein',
    'MBC',
    'Netflix',
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: AppSpacing.sm),
          // Heading
          const Row(
            children: [
              HugeIcon(
                icon: AppIcons.star,
                color: Color(0xFF00C2FF),
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'QUICK SEARCH',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),

          // Suggestion Chips
          Wrap(
            spacing: 8,
            runSpacing: 10,
            children: _popularQueries.map((query) {
              return GestureDetector(
                onTap: () => onSuggestionTap(query),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF131722),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withAlpha(20),
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      HugeIcon(
                        icon: AppIcons.search,
                        color: Colors.white.withAlpha(120),
                        size: 13,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        query,
                        style: TextStyle(
                          color: Colors.white.withAlpha(210),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Search Results View (Categorized & Filterable)
// ---------------------------------------------------------------------------

class _SearchResultsView extends ConsumerWidget {
  const _SearchResultsView({
    required this.filter,
    required this.channels,
    required this.movies,
    required this.series,
  });

  final _SearchCategoryFilter filter;
  final List<Channel> channels;
  final List<Movie> movies;
  final List<Series> series;

  void _playChannel(BuildContext context, WidgetRef ref, Channel channel) {
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
  }

  void _playMovie(BuildContext context, WidgetRef ref, Movie movie) {
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
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // If specific tab is selected:
    if (filter == _SearchCategoryFilter.movies) {
      return _buildMovieGrid(context, ref, movies);
    }
    if (filter == _SearchCategoryFilter.series) {
      return _buildSeriesGrid(context, ref, series);
    }
    if (filter == _SearchCategoryFilter.channels) {
      return _buildChannelList(context, ref, channels);
    }

    // "All" view: Sectioned rows
    return ListView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      children: [
        // Movies Section
        if (movies.isNotEmpty) ...[
          HomeSectionRow<Movie>(
            title: context.l10n.homeFeaturedMovies,
            items: movies,
            height: 215,
            itemBuilder: (context, movie, _) => MovieCard(
              movie: movie,
              onTap: () => _playMovie(context, ref, movie),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Series Section
        if (series.isNotEmpty) ...[
          HomeSectionRow<Series>(
            title: context.l10n.homePopularSeries,
            items: series,
            height: 215,
            itemBuilder: (context, s, _) => SeriesCard(
              series: s,
              onTap: () => showSeriesDetailsModal(context, s),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // Live Channels Section
        if (channels.isNotEmpty) ...[
          Text(
            'LIVE CHANNELS (${channels.length})',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          ...channels.map((ch) {
            final activeChannelId = ref.watch(
              playerControllerProvider.select((s) => s.source?.channelId),
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: ChannelListTile(
                channel: ch,
                isPlaying: activeChannelId == ch.streamId,
                categoryName: 'Live TV',
                onTap: () => _playChannel(context, ref, ch),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildMovieGrid(
    BuildContext context,
    WidgetRef ref,
    List<Movie> list,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.xl),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        mainAxisExtent: 220,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final movie = list[i];
        return MovieCard(
          movie: movie,
          width: double.infinity,
          height: 175,
          onTap: () => _playMovie(context, ref, movie),
        );
      },
    );
  }

  Widget _buildSeriesGrid(
    BuildContext context,
    WidgetRef ref,
    List<Series> list,
  ) {
    return GridView.builder(
      padding: const EdgeInsets.all(AppSpacing.xl),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 140,
        mainAxisExtent: 220,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: list.length,
      itemBuilder: (context, i) {
        final s = list[i];
        return SeriesCard(
          series: s,
          width: double.infinity,
          height: 175,
          onTap: () => showSeriesDetailsModal(context, s),
        );
      },
    );
  }

  Widget _buildChannelList(
    BuildContext context,
    WidgetRef ref,
    List<Channel> list,
  ) {
    final activeChannelId = ref.watch(
      playerControllerProvider.select((s) => s.source?.channelId),
    );

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.xl),
      itemCount: list.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final ch = list[i];
        return ChannelListTile(
          channel: ch,
          isPlaying: activeChannelId == ch.streamId,
          categoryName: 'Live TV',
          onTap: () => _playChannel(context, ref, ch),
        );
      },
    );
  }
}
