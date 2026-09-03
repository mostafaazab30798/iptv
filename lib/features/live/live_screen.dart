import 'dart:async';
import 'package:dpad/dpad.dart';
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
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/features/home/widgets/cards/channel_card.dart';
import 'package:iptv/features/live/live_controller.dart';
import 'package:iptv/features/live/widgets/live_mini_preview.dart';
import 'package:iptv/player/player.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/navigation/app_back_navigation.dart';
import 'package:iptv/shared/widgets/category_card.dart';
import 'package:iptv/shared/widgets/channel_list_tile.dart';
import 'package:iptv/shared/widgets/empty_state.dart';
import 'package:iptv/shared/widgets/skeleton_loaders.dart';

class LiveScreen extends ConsumerStatefulWidget {
  const LiveScreen({super.key});

  @override
  ConsumerState<LiveScreen> createState() => _LiveScreenState();
}

class _LiveScreenState extends ConsumerState<LiveScreen> {
  final _channelSearchController = TextEditingController();
  Category? _selectedCategory;
  bool _isAllChannelsSelected = false;
  Channel? _selectedChannel;
  bool _isGridView = false;
  PlayerController? _playerController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _playerController = ref.read(playerControllerProvider.notifier);
  }

  @override
  void dispose() {
    _channelSearchController.dispose();
    // Leaving Live tab/route: free decoder RAM/CPU. Keep playback if fullscreen
    // player is open (PlayerScreen owns lifecycle; mini-preview resumes on return).
    // Use addPostFrameCallback (not Future) so widget tests can flush via pump.
    final player = _playerController;
    if (player != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        player.stopWhenLeavingLiveRoute();
      });
    }
    super.dispose();
  }

  void _selectCategory(Category? category, {bool isAll = false}) {
    setState(() {
      _selectedCategory = category;
      _isAllChannelsSelected = isAll;
      _channelSearchController.clear();
      _selectedChannel = null;
    });

    final notifier = ref.read(liveControllerProvider.notifier);
    if (isAll) {
      notifier.showAllChannels();
    } else if (category != null) {
      notifier.selectCategory(category.id);
    } else {
      notifier.showCategoriesHub();
    }
  }

  void _onBack() {
    setState(() {
      _selectedCategory = null;
      _isAllChannelsSelected = false;
      _channelSearchController.clear();
      _selectedChannel = null;
    });
    final notifier = ref.read(liveControllerProvider.notifier);
    notifier.showCategoriesHub();

    // Tear down live preview when leaving the channel list for categories.
    final player = ref.read(playerControllerProvider.notifier);
    unawaited(player.stop());
  }

  void _playChannel(Channel channel, {bool openFullscreen = false}) {
    final session = ref.read(sessionProvider).valueOrNull;
    if (session == null) return;

    setState(() => _selectedChannel = channel);

    final liveState = ref.read(liveControllerProvider);
    final channels = liveState.filteredChannels;
    final initialIndex = channels.indexWhere(
      (c) => c.streamId == channel.streamId,
    );

    String urlFor(Channel c) => XtreamRemoteDataSource.buildLiveStreamUrl(
      serverUrl: session.serverUrl,
      username: session.username,
      password: session.password,
      streamId: c.streamId,
    );

    final playerNotifier = ref.read(playerControllerProvider.notifier);
    playerNotifier.setLazyLivePlaylist(
      channels: channels,
      initialIndex: initialIndex >= 0 ? initialIndex : 0,
      urlFor: urlFor,
    );
    playerNotifier.load(
      PlayerSource.live(
        url: urlFor(channel),
        title: channel.name,
        channelId: channel.streamId,
        logoUrl: channel.streamIcon,
      ),
    );

    if (openFullscreen) {
      context.push(Routes.player);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(
      liveControllerProvider.select((s) => s.isLoading),
    );
    final categories = ref.watch(
      liveControllerProvider.select((s) => s.categories),
    );
    final inChannelsView = _selectedCategory != null || _isAllChannelsSelected;

    return InnerBackScope(
      onBack: () {
        final inChannelsView =
            _selectedCategory != null || _isAllChannelsSelected;
        if (!inChannelsView) return false;
        _onBack();
        return true;
      },
      child: Scaffold(
        backgroundColor: AppColors.bg0,
        body: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: inChannelsView
              ? _buildChannelsView()
              : _buildCategoriesHub(
                  isLoading: isLoading,
                  categories: categories,
                ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stage 1: Categories Hub Showcase
  // ---------------------------------------------------------------------------

  Widget _buildCategoriesHub({
    required bool isLoading,
    required List<Category> categories,
  }) {
    if (isLoading && categories.isEmpty) {
      return const CategoryListSkeleton();
    }

    final totalCount = ref.watch(
      liveControllerProvider.select((s) => s.totalChannelCount),
    );
    final categoryCounts = ref.watch(
      liveControllerProvider.select((s) => s.categoryCounts),
    );
    final leading = ref.watch(
      liveControllerProvider.select((s) => s.categoryLeadingChannels),
    );

    return KeyedSubtree(
      key: const ValueKey('categories_hub'),
      child: categories.isEmpty
          ? EmptyState(
              title: context.l10n.labelNoResults,
              subtitle: context.l10n.homeCheckConnection,
              icon: AppIcons.empty,
            )
          : DpadRegion(
              memoryKey: 'live/categories',
              debugLabel: 'live-categories',
              child: ListView.separated(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.md,
              ),
              cacheExtent: 350,
              itemCount: categories.length + 1,
              separatorBuilder: (_, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                if (index == 0) {
                  return CategoryCard(
                    title: context.l10n.labelAllChannels,
                    itemCount: totalCount,
                    itemCountLabel: context.l10n.labelChannels,
                    isAllCard: true,
                    onTap: () => _selectCategory(null, isAll: true),
                  );
                }

                final category = categories[index - 1];
                final count = categoryCounts[category.id] ?? 0;
                final leadingChannel = leading[category.id];

                return CategoryCard(
                  title: category.name,
                  itemCount: count,
                  itemCountLabel: context.l10n.labelChannels,
                  leadingChannel: leadingChannel,
                  onTap: () => _selectCategory(category),
                );
              },
            ),
            ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stage 2: Category Channels View
  // ---------------------------------------------------------------------------

  Widget _buildChannelsView() {
    final filteredChannels = ref.watch(
      liveControllerProvider.select((s) => s.filteredChannels),
    );
    final isLoading = ref.watch(
      liveControllerProvider.select((s) => s.isLoading),
    );
    final categoryNames = ref.watch(
      liveControllerProvider.select((s) => s.categoryNames),
    );
    final activeChannelId = ref.watch(
      playerControllerProvider.select((s) => s.source?.channelId),
    );
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final categoryTitle = _isAllChannelsSelected
        ? context.l10n.labelAllChannels
        : (_selectedCategory?.name ?? context.l10n.navLive);

    final backIcon = isRtl ? AppIcons.chevronRight : AppIcons.chevronLeft;

    return Column(
      key: const ValueKey('category_channels_view'),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 600;
            return Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              decoration: const BoxDecoration(
                color: AppColors.bg1,
                border: Border(
                  bottom: BorderSide(color: AppColors.border, width: 0.8),
                ),
              ),
              child: Row(
                children: [
                  if (isCompact)
                    IconButton(
                      onPressed: _onBack,
                      tooltip: context.l10n.labelCategories,
                      icon: HugeIcon(
                        icon: backIcon,
                        size: 14,
                        color: AppColors.accent,
                      ),
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.accent.withAlpha(25),
                        padding: const EdgeInsets.all(8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    )
                  else
                    TextButton.icon(
                      onPressed: _onBack,
                      icon: HugeIcon(
                        icon: backIcon,
                        size: 14,
                        color: AppColors.accent,
                      ),
                      label: Text(
                        context.l10n.labelCategories,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        backgroundColor: AppColors.accent.withAlpha(25),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Flexible(
                          child: Text(
                            categoryTitle,
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.bg3,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '${filteredChannels.length}',
                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 4),
                  IconButton(
                    key: const ValueKey('live_view_mode_toggle'),
                    icon: HugeIcon(
                      icon: _isGridView ? AppIcons.listView : AppIcons.gridView,
                      size: 20,
                      color: AppColors.textSecondary,
                    ),
                    tooltip: _isGridView
                        ? 'Switch to List View'
                        : 'Switch to Grid View',
                    onPressed: () => setState(() => _isGridView = !_isGridView),
                  ),
                ],
              ),
            );
          },
        ),

        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isPortrait =
                  MediaQuery.orientationOf(context) == Orientation.portrait ||
                  constraints.maxWidth < 750;

              if (isPortrait) {
                return Column(
                  children: [
                    if (activeChannelId != null || _selectedChannel != null)
                      Container(
                        color: AppColors.bg0,
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        child: LiveMiniPreview(
                          selectedChannel: _selectedChannel,
                          onExpandFullscreen: () => context.push(Routes.player),
                        ),
                      ),

                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      child: SizedBox(
                        height: 38,
                        child: _LiveSearchField(
                          controller: _channelSearchController,
                          hintText: context.l10n.liveSearchHint,
                          onChanged: (q) {
                            ref.read(liveControllerProvider.notifier).search(q);
                          },
                          onClear: () {
                            _channelSearchController.clear();
                            ref
                                .read(liveControllerProvider.notifier)
                                .search('');
                          },
                        ),
                      ),
                    ),

                    Expanded(
                      child: _buildChannelList(
                        filteredChannels: filteredChannels,
                        isLoading: isLoading,
                        categoryNames: categoryNames,
                        activeChannelId: activeChannelId,
                      ),
                    ),
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.md,
                            AppSpacing.sm,
                            AppSpacing.md,
                            0,
                          ),
                          child: SizedBox(
                            height: 38,
                            child: _LiveSearchField(
                              controller: _channelSearchController,
                              hintText: context.l10n.liveSearchHint,
                              onChanged: (q) {
                                ref
                                    .read(liveControllerProvider.notifier)
                                    .search(q);
                              },
                              onClear: () {
                                _channelSearchController.clear();
                                ref
                                    .read(liveControllerProvider.notifier)
                                    .search('');
                              },
                            ),
                          ),
                        ),
                        Expanded(
                          child: _buildChannelList(
                            filteredChannels: filteredChannels,
                            isLoading: isLoading,
                            categoryNames: categoryNames,
                            activeChannelId: activeChannelId,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const VerticalDivider(width: 1, color: AppColors.border),
                  SizedBox(
                    width: 360,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: LiveMiniPreview(
                        selectedChannel: _selectedChannel,
                        onExpandFullscreen: () => context.push(Routes.player),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChannelList({
    required List<Channel> filteredChannels,
    required bool isLoading,
    required Map<int, String> categoryNames,
    required int? activeChannelId,
  }) {
    if (isLoading && filteredChannels.isEmpty) {
      return const ChannelListSkeleton();
    }

    if (filteredChannels.isEmpty) {
      return EmptyState(
        title: context.l10n.liveNoChannelsFound,
        subtitle: context.l10n.searchNoResultsSubtitle,
        icon: AppIcons.empty,
      );
    }

    if (_isGridView) {
      return GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        cacheExtent: 350,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 155,
          childAspectRatio: 1.15,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
        ),
        itemCount: filteredChannels.length,
        itemBuilder: (context, i) {
          final channel = filteredChannels[i];
          final isPlaying = activeChannelId == channel.streamId;
          return ChannelCard(
            channel: channel,
            isPlaying: isPlaying,
            showBadge: isPlaying,
            onTap: () => _playChannel(channel),
          );
        },
      );
    }

    // Fixed extent: tile padding (10*2) + logo row (~44) ≈ 72 + separator 8 via
    // prototypeItem would need separated; use itemExtent on plain ListView.
    return ListView.builder(
      padding: const EdgeInsets.all(AppSpacing.md),
      cacheExtent: 350,
      itemExtent: 80,
      itemCount: filteredChannels.length,
      itemBuilder: (context, i) {
        final channel = filteredChannels[i];
        final isPlaying = activeChannelId == channel.streamId;
        final catName =
            categoryNames[channel.categoryId] ?? context.l10n.navLive;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: ChannelListTile(
            channel: channel,
            isPlaying: isPlaying,
            categoryName: catName,
            onTap: () => _playChannel(channel),
          ),
        );
      },
    );
  }
}

/// Search field with local suffix rebuilds (avoids setState on the whole Live screen).
class _LiveSearchField extends StatelessWidget {
  const _LiveSearchField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
    required this.onClear,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        return TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hintText,
            prefixIcon: const HugeIcon(
              icon: AppIcons.search,
              size: 18,
              color: AppColors.textSecondary,
            ),
            suffixIcon: value.text.isNotEmpty
                ? IconButton(
                    icon: const HugeIcon(
                      icon: AppIcons.close,
                      size: 16,
                      color: AppColors.textSecondary,
                    ),
                    onPressed: onClear,
                  )
                : null,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 0,
            ),
          ),
        );
      },
    );
  }
}
