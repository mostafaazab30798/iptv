import 'dart:async';
import 'dart:ui';

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_motion.dart';
import 'package:iptv/app/theme/app_radius.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/core/sports/match_wallpaper_resolver.dart';
import 'package:iptv/core/sports/sports_localization.dart';
import 'package:iptv/domain/entities/live_fixture.dart';
import 'package:iptv/domain/entities/live_match.dart';
import 'package:iptv/features/home/home_controller.dart';
import 'package:iptv/features/kids_mode/widgets/kids_mode_nav_button.dart';
import 'package:iptv/player/handoff/presentation/companion_scanner_modal.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/focus/remote_focus.dart';
import 'package:iptv/shared/focus/shell_focus_navigation.dart';
import 'package:iptv/shared/focus/tv_focusable.dart';
import 'package:iptv/shared/navigation/shell_focus_bridge.dart';
import 'package:iptv/shared/widgets/adaptive_glass.dart';
import 'package:iptv/shared/widgets/cached_image.dart';

/// Cinematic Home hero carousel.
///
/// On portrait small screens, the hero image extends higher with a transparent,
/// subtly blurred top bar under the title and actions, scrolling naturally with the hero card.

class HomeHeroBanner extends StatefulWidget {
  const HomeHeroBanner({
    super.key,
    this.item,
    this.items = const [],
    required this.onPlay,
    this.onRefresh,
    this.autoPlay = true,
  });

  final HomeHeroItem? item;
  final List<HomeHeroItem> items;
  final void Function(HomeHeroItem item) onPlay;
  final VoidCallback? onRefresh;

  /// When false (e.g. parent list is scrolling), carousel timers/animations pause.
  final bool autoPlay;

  /// Shared hero footprint so the pending skeleton matches the real banner.
  static double heightOf(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isPortrait =
        MediaQuery.orientationOf(context) == Orientation.portrait;
    final topPadding = MediaQuery.paddingOf(context).top;
    if (isPortrait) {
      return 470.0 + (topPadding > 0 ? topPadding : 20.0);
    }
    if (size.width > 1400) {
      return (size.height * 0.38).clamp(420.0, 560.0);
    }
    return size.width > 900 ? 420.0 : 380.0;
  }

  @override
  State<HomeHeroBanner> createState() => _HomeHeroBannerState();
}

class _HomeHeroBannerState extends State<HomeHeroBanner> {
  late final PageController _pageController;
  late final ValueNotifier<int> _currentPage;
  Timer? _autoScrollTimer;

  List<HomeHeroItem> get _effectiveItems {
    if (widget.items.isNotEmpty) return widget.items;
    if (widget.item != null) return [widget.item!];
    return const [];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _currentPage = ValueNotifier<int>(0);
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant HomeHeroBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_effectiveItems.length != oldWidget.items.length ||
        widget.autoPlay != oldWidget.autoPlay) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (!widget.autoPlay || _effectiveItems.length <= 1) return;

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !widget.autoPlay || !_pageController.hasClients) return;
      final nextPage = (_currentPage.value + 1) % _effectiveItems.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  void _pauseAutoScroll() {
    _autoScrollTimer?.cancel();
  }

  void _resumeAutoScroll() {
    _startAutoScroll();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _currentPage.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _goToPage(int page) {
    if (!_pageController.hasClients) return;
    _currentPage.value = page;
    setState(() {});
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
    );
    _startAutoScroll();
  }

  bool _focusUp(BuildContext context) => focusUpToShell(context);

  bool _handleHeroDirection(
    BuildContext context,
    TraversalDirection direction,
    int itemCount,
  ) {
    if (direction == TraversalDirection.up) {
      return _focusUp(context);
    }
    if (itemCount <= 1) return false;
    if (direction == TraversalDirection.left) {
      _goToPage((_currentPage.value - 1 + itemCount) % itemCount);
      return true;
    }
    if (direction == TraversalDirection.right) {
      _goToPage((_currentPage.value + 1) % itemCount);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final items = _effectiveItems;
    if (items.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.sizeOf(context).width;
    final isPortrait =
        MediaQuery.orientationOf(context) == Orientation.portrait;
    final topPadding = MediaQuery.paddingOf(context).top;
    final bannerHeight = HomeHeroBanner.heightOf(context);

    final currentItem = (items.isNotEmpty && _currentPage.value < items.length)
        ? items[_currentPage.value]
        : null;
    final isMatch =
        currentItem?.type == HeroItemType.live && currentItem?.match != null;
    final posterFocus = _heroPosterFocusGeometry(
      isPortrait: isPortrait,
      screenWidth: screenWidth,
      bannerHeight: bannerHeight,
      topOffset: 0,
      isMatch: isMatch,
    );

    return MouseRegion(
      onEnter: (_) => _pauseAutoScroll(),
      onExit: (_) => _resumeAutoScroll(),
      child: SizedBox(
        width: double.infinity,
        height: bannerHeight,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Continuous, seamless full-bleed hero banner with multi-platform scroll support
            Positioned.fill(
              child: RepaintBoundary(
                child: ScrollConfiguration(
                  behavior: ScrollConfiguration.of(context).copyWith(
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                      PointerDeviceKind.trackpad,
                      PointerDeviceKind.stylus,
                    },
                    scrollbars: false,
                  ),
                  child: PageView.builder(
                    controller: _pageController,
                    physics: const BouncingScrollPhysics(),
                    itemCount: items.length,
                    allowImplicitScrolling: true,
                    onPageChanged: (index) {
                      _currentPage.value = index;
                      setState(() {});
                    },
                    itemBuilder: (context, index) {
                      final currentItem = items[index];
                      return GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => widget.onPlay(currentItem),
                        child: _HeroCardSlide(
                          item: currentItem,
                          bannerHeight: bannerHeight,
                          showWideLayout: !isPortrait,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Title & App Shell Chrome floating seamlessly at the top
            if (isPortrait)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: DpadRegion(
                  memoryKey: 'home/hero-chrome',
                  debugLabel: 'home-hero-chrome',
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(
                      AppSpacing.xl,
                      topPadding > 0 ? (topPadding + 2.0) : 18.0,
                      AppSpacing.xl,
                      AppSpacing.xs,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Text(
                          context.l10n.actionWatch,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                            height: 1.1,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 10,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (KidsModeNavButton.visibleFor(context)) ...[
                              const KidsModeNavButton(),
                              const SizedBox(width: 10),
                            ],
                            _GlassActionCapsule(onRefresh: widget.onRefresh),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Landscape TV focus target only (never rendered on portrait mobile)
            if (!isPortrait)
              AnimatedPositioned(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutCubic,
                left: posterFocus.left,
                top: posterFocus.top,
                width: posterFocus.width,
                height: posterFocus.height,
                child: DpadFocusable(
                  autofocus: true,
                  debugLabel: 'hero-entry',
                  onSelect: () => widget.onPlay(items[_currentPage.value]),
                  onDirection: (direction) =>
                      _handleHeroDirection(context, direction, items.length),
                  builder: (context, state, child) {
                    final visual = RemoteFocus.visualOf(context, state);
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 140),
                      decoration: visual.focused
                          ? BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.accent,
                                width: 2,
                              ),
                            )
                          : null,
                      child: child,
                    );
                  },
                  child: const SizedBox.expand(),
                ),
              ),

            if (items.length > 1) ...[
              // Clickable Pagination Dots
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: ValueListenableBuilder<int>(
                  valueListenable: _currentPage,
                  builder: (context, page, _) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(items.length, (i) {
                        final isActive = i == page;
                        return GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _goToPage(i),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 8,
                            ),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeOutCubic,
                              width: isActive ? 24 : 6,
                              height: 5,
                              decoration: BoxDecoration(
                                color: isActive
                                    ? AppColors.accent
                                    : Colors.white.withAlpha(80),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  ({double left, double top, double width, double height})
  _heroPosterFocusGeometry({
    required bool isPortrait,
    required double screenWidth,
    required double bannerHeight,
    required double topOffset,
    bool isMatch = false,
  }) {
    if (!isPortrait) {
      if (isMatch) {
        final matchSize = MatchPosterCard.sizeForWidth(screenWidth);
        return (
          left: AppSpacing.x3l,
          top: bannerHeight - AppSpacing.xxl - matchSize.height,
          width: matchSize.width,
          height: matchSize.height,
        );
      }
      final posterHeight = (bannerHeight * 0.78).clamp(200.0, 400.0);
      final posterWidth = posterHeight * (2 / 3);
      return (
        left: 40,
        top: bannerHeight - 36 - posterHeight,
        width: posterWidth,
        height: posterHeight,
      );
    }

    // Portrait: 2:3 poster avatar centered in the complete hero card.
    final horizontalInset = screenWidth > 600 ? 48.0 : 20.0;
    final posterWidth = (screenWidth - horizontalInset * 2).clamp(120.0, 220.0);
    final posterHeight = posterWidth * 1.5;
    return (
      left: (screenWidth - posterWidth) / 2,
      top: topOffset + 14.0,
      width: posterWidth,
      height: posterHeight,
    );
  }
}

// ---------------------------------------------------------------------------
// Hero Card Slide Item
// ---------------------------------------------------------------------------

class _HeroCardSlide extends StatelessWidget {
  const _HeroCardSlide({
    required this.item,
    required this.bannerHeight,
    required this.showWideLayout,
  });

  final HomeHeroItem item;
  final double bannerHeight;
  final bool showWideLayout;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final hasArt = item.backdropUrl != null && item.backdropUrl!.isNotEmpty;
    // Decode on a single axis so portrait panel posters keep full resolution
    // instead of being crushed into a short landscape mem-cache box.
    final blurCacheWidth = (screenWidth * dpr).round().clamp(720, 1920);
    final posterCacheHeight = (bannerHeight * dpr * 0.92).round().clamp(
      640,
      1600,
    );

    if (showWideLayout) {
      return _WideHeroSlide(
        item: item,
        bannerHeight: bannerHeight,
        hasArt: hasArt,
        blurCacheWidth: blurCacheWidth,
        posterCacheHeight: posterCacheHeight,
      );
    }

    if (item.type == HeroItemType.live && item.match != null) {
      return _PortraitMatchSlide(item: item);
    }

    final topPadding = MediaQuery.paddingOf(context).top;
    final blurAreaHeight = (topPadding > 0 ? topPadding : 20.0) + 75.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Continuous full-bleed cover (top-anchored poster crop).
        if (hasArt)
          CachedImage(
            imageUrl: item.backdropUrl,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            fallbackIcon: item.type == HeroItemType.live
                ? AppIcons.live
                : AppIcons.movies,
            memCacheWidth: 1080,
            memCacheHeight: 720,
          )
        else
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B2333), Color(0xFF0B0E14)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

        // Buttery gradient blur at top of image under title & app shell
        if (hasArt)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: blurAreaHeight,
            child: ClipRect(
              child: ShaderMask(
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.40, 0.75, 1.0],
                    colors: [
                      Colors.black,
                      Colors.black87,
                      Colors.black26,
                      Colors.transparent,
                    ],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Transform.scale(
                    scale: 1.10,
                    child: CachedImage(
                      imageUrl: item.backdropUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      memCacheWidth: 400,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Soft contrast veil over the top region
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: blurAreaHeight + 15.0,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.50, 0.85, 1.0],
                colors: [
                  Color(0x6008090B),
                  Color(0x3008090B),
                  Color(0x1008090B),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Bottom fade gradient (original)
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.3, 0.62, 0.88, 1.0],
                colors: [
                  Colors.transparent,
                  Color(0x7508090B),
                  Color(0xF008090B),
                  AppColors.bg0,
                ],
              ),
            ),
          ),
        ),

        Positioned(
          left: screenWidth > 600 ? 48.0 : 20.0,
          right: screenWidth > 600 ? 48.0 : 20.0,
          bottom: 34,
          child: _HeroCopy(item: item, wide: false),
        ),
      ],
    );
  }
}

class _WideHeroSlide extends StatelessWidget {
  const _WideHeroSlide({
    required this.item,
    required this.bannerHeight,
    required this.hasArt,
    required this.blurCacheWidth,
    required this.posterCacheHeight,
  });

  final HomeHeroItem item;
  final double bannerHeight;
  final bool hasArt;
  final int blurCacheWidth;
  final int posterCacheHeight;

  @override
  Widget build(BuildContext context) {
    final posterHeight = (bannerHeight * 0.78).clamp(200.0, 400.0);
    final posterWidth = posterHeight * (2 / 3);

    if (item.type == HeroItemType.live && item.match != null) {
      final screenWidth = MediaQuery.sizeOf(context).width;
      final matchSize = MatchPosterCard.sizeForWidth(screenWidth);

      return Stack(
        fit: StackFit.expand,
        children: [
          _MatchStadiumBackdrop(match: item.match!),
          const Positioned.fill(child: _MatchHeroScrim()),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x3l,
              AppSpacing.xl,
              AppSpacing.x4l,
              AppSpacing.xxl,
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: MatchPosterCard(
                match: item.match!,
                item: item,
                width: matchSize.width,
                height: matchSize.height,
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasArt)
          // Avoid ImageFiltered blur during scroll — it forces expensive
          // per-frame rasterization of a full-bleed bitmap. A darkened cover
          // + scrim reads similarly and scrolls smoothly.
          Stack(
            fit: StackFit.expand,
            children: [
              CachedImage(
                imageUrl: item.backdropUrl,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                fallbackIcon: item.type == HeroItemType.live
                    ? AppIcons.live
                    : AppIcons.movies,
                memCacheWidth: blurCacheWidth.clamp(480, 960),
              ),
              const ColoredBox(color: Color(0xA008090B)),
            ],
          )
        else
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B2333), Color(0xFF0B0E14)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        const ColoredBox(color: Color(0x6608090B)),
        const Positioned.fill(child: _HeroScrim()),
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 28, 48, 36),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (hasArt)
                SizedBox(
                  width: posterWidth,
                  height: posterHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: CachedImage(
                      imageUrl: item.posterUrl ?? item.backdropUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      borderRadius: BorderRadius.circular(12),
                      fallbackIcon: item.type == HeroItemType.live
                          ? AppIcons.live
                          : AppIcons.movies,
                      memCacheHeight: posterCacheHeight,
                    ),
                  ),
                ),
              if (hasArt) const SizedBox(width: 28),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: posterHeight * 0.06),
                  child: _HeroCopy(item: item, wide: true),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroScrim extends StatelessWidget {
  const _HeroScrim();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.18, 0.45, 0.72, 1.0],
          colors: [
            Color(0x9008090B),
            Color(0x3008090B),
            Colors.transparent,
            Color(0xD008090B),
            AppColors.bg0,
          ],
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.item, required this.wide});

  final HomeHeroItem item;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    if (item.type == HeroItemType.live && item.match != null) {
      return _MatchHeroCopy(match: item.match!, item: item, wide: wide);
    }

    final meta = _formatMetadata(item);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final localizedChannel = item.channel != null
        ? SportsLocalization.localizeChannel(
            item.channel!.name,
            isArabic: isArabic,
          )
        : '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: wide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        if (item.type == HeroItemType.live) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF87).withAlpha(36),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF00FF87).withAlpha(140)),
            ),
            child: Text(
              context.l10n.homeLiveMatch,
              style: const TextStyle(
                color: Color(0xFF00FF87),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          item.title,
          textAlign: wide ? TextAlign.start : TextAlign.center,
          style: TextStyle(
            color: const Color(0xFFF3C74C),
            fontSize: wide ? 32 : 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            height: 1.15,
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 14, offset: Offset(0, 3)),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (meta.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            meta,
            textAlign: wide ? TextAlign.start : TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(210),
              fontSize: wide ? 15 : 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (item.description != null && item.description!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            item.type == HeroItemType.live && item.channel != null
                ? context.l10n.homeWatchOnChannel(localizedChannel)
                : item.description!,
            textAlign: wide ? TextAlign.start : TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(155),
              fontSize: wide ? 14 : 12.5,
              height: 1.35,
              letterSpacing: -0.1,
            ),
            maxLines: wide ? 3 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  String _formatMetadata(HomeHeroItem item) {
    final parts = <String>[];
    if (item.type == HeroItemType.live) {
      if (item.badge != null && item.badge!.isNotEmpty) {
        parts.add(item.badge!);
      }
      if (item.subtitle.isNotEmpty) parts.add(item.subtitle);
      return parts.join(' • ');
    }
    if (item.genre != null && item.genre!.isNotEmpty) {
      parts.add(item.genre!);
    }
    if (item.subtitle.isNotEmpty) {
      parts.add(item.subtitle);
    } else if (item.badge != null && item.badge!.isNotEmpty) {
      parts.add(item.badge!);
    }
    return parts.join(' • ');
  }
}

class _MatchHeroCopy extends StatelessWidget {
  const _MatchHeroCopy({
    required this.match,
    required this.item,
    required this.wide,
  });

  final LiveMatch match;
  final HomeHeroItem item;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final fixture = match.fixture;
    final isLive = fixture?.isLive ?? false;
    final scheduledTime = fixture?.scheduledTime ?? fixture?.clock ?? '';
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final rawChannel =
        fixture?.broadcastChannel ?? item.channel?.name ?? match.channel.name;
    final channel = SportsLocalization.localizeChannel(
      rawChannel,
      isArabic: isArabic,
    );
    final rawLeague = fixture?.league;
    final league = SportsLocalization.localizeLeague(
      rawLeague,
      isArabic: isArabic,
    );
    final timeLabel = isLive
        ? (fixture?.clock ?? (isArabic ? 'مباشر' : 'LIVE'))
        : (scheduledTime.isNotEmpty ? scheduledTime : '—');

    final metaParts = <String>[
      if (league != null && league.isNotEmpty) league,
      if (channel.isNotEmpty) channel,
      if (item.badge != null && item.badge!.isNotEmpty) item.badge!,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: wide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        if (isLive) ...[
          const _MatchStatusChip(),
          SizedBox(height: wide ? AppSpacing.sm : AppSpacing.xs),
        ],
        _MatchKickoffDisplay(
          timeLabel: timeLabel,
          isLive: isLive,
          isArabic: isArabic,
          large: wide,
          alignStart: wide,
        ),
        if (metaParts.isNotEmpty) ...[
          SizedBox(height: wide ? AppSpacing.sm : AppSpacing.xs),
          Text(
            metaParts.join('  ·  '),
            textAlign: wide ? TextAlign.start : TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary.withValues(alpha: 0.78),
              fontSize: wide ? 14 : 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
              height: 1.3,
              shadows: const [
                Shadow(
                  color: Color(0xCC000000),
                  blurRadius: 10,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        SizedBox(height: wide ? AppSpacing.md : AppSpacing.sm),
        _MatchWatchCue(isLive: isLive, isArabic: isArabic),
      ],
    );
  }
}

class _MatchStadiumBackdrop extends StatelessWidget {
  const _MatchStadiumBackdrop({required this.match});

  final LiveMatch match;

  @override
  Widget build(BuildContext context) {
    final isLive = match.fixture?.isLive ?? false;
    final wallpaperAsset = MatchWallpaperResolver.resolveWallpaper(match);

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildDefaultGradients(isLive),
        if (wallpaperAsset != null) ...[
          Positioned.fill(
            child: Image.asset(
              wallpaperAsset,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.15),
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.shrink();
              },
            ),
          ),
          // Soft edge vignette — keeps wallpaper visible in the center.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.1),
                  radius: 1.15,
                  colors: [
                    Color(0x0808090B),
                    Color(0x4808090B),
                    Color(0x9808090B),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
        ],
        // Glossy sheen layer (no blur — cheap during carousel scroll).
        const Positioned.fill(child: _MatchGlossOverlay()),
      ],
    );
  }

  Widget _buildDefaultGradients(bool isLive) {
    final glow = isLive ? AppColors.live : AppColors.accent;
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF101622), AppColors.bg0],
            ),
          ),
        ),
        Positioned(
          left: -60,
          top: -20,
          width: 280,
          height: 280,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [glow.withValues(alpha: 0.14), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          right: -40,
          bottom: -30,
          width: 260,
          height: 260,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Lighter scrim so branded wallpapers stay visible while copy stays legible.
class _MatchHeroScrim extends StatelessWidget {
  const _MatchHeroScrim();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.22, 0.52, 0.78, 1.0],
          colors: [
            Color(0x7008090B),
            Color(0x2008090B),
            Colors.transparent,
            Color(0xA008090B),
            AppColors.bg0,
          ],
        ),
      ),
    );
  }
}

/// Cinema gloss: rim light + diagonal specular streak over the wallpaper.
class _MatchGlossOverlay extends StatelessWidget {
  const _MatchGlossOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Soft top rim highlight (stadium floodlight feel).
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.18, 0.42],
                colors: [
                  Color(0x38FFFFFF),
                  Color(0x12FFFFFF),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Diagonal specular sheen.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment(-0.95, -1.0),
                end: Alignment(0.85, 0.7),
                stops: [0.0, 0.28, 0.42, 0.56, 1.0],
                colors: [
                  Colors.transparent,
                  Color(0x22FFFFFF),
                  Color(0x38FFFFFF),
                  Color(0x14FFFFFF),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Cool accent glint (brand cyan, very subtle).
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: const Alignment(-1.0, -0.4),
                end: const Alignment(0.6, 0.9),
                stops: const [0.0, 0.35, 0.55, 1.0],
                colors: [
                  Colors.transparent,
                  AppColors.accent.withValues(alpha: 0.07),
                  AppColors.accent.withValues(alpha: 0.03),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Bottom glass reflection fade into app bg.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.center,
                stops: [0.0, 0.35, 1.0],
                colors: [
                  Color(0x2800C2FF),
                  Color(0x0800C2FF),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class MatchPosterCard extends StatelessWidget {
  const MatchPosterCard({
    super.key,
    required this.match,
    this.item,
    required this.width,
    required this.height,
  });

  final LiveMatch match;
  final HomeHeroItem? item;
  final double width;
  final double height;

  /// Responsive card footprint for landscape / TV heroes.
  static ({double width, double height}) sizeForWidth(double screenWidth) {
    if (screenWidth >= 1600) {
      return (width: 640.0, height: 248.0);
    }
    if (screenWidth >= 1200) {
      return (width: 560.0, height: 228.0);
    }
    if (screenWidth >= 900) {
      return (width: 480.0, height: 208.0);
    }
    return (width: 420.0, height: 196.0);
  }

  @override
  Widget build(BuildContext context) {
    final fixture = match.fixture;
    final isLive = fixture?.isLive ?? false;
    final scheduledTime = fixture?.scheduledTime ?? fixture?.clock ?? '';
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final rawChannel =
        fixture?.broadcastChannel ?? item?.channel?.name ?? match.channel.name;
    final channel = SportsLocalization.localizeChannel(
      rawChannel,
      isArabic: isArabic,
    );
    final rawLeague = fixture?.league;
    final league = SportsLocalization.localizeLeague(
      rawLeague,
      isArabic: isArabic,
    );
    final homeName = SportsLocalization.localizeTeam(
      fixture?.homeName ?? 'Home',
      isArabic: isArabic,
    );
    final awayName = SportsLocalization.localizeTeam(
      fixture?.awayName ?? 'Away',
      isArabic: isArabic,
    );
    final timeLabel = isLive
        ? (fixture?.clock ?? (isArabic ? 'مباشر' : 'LIVE'))
        : (scheduledTime.isNotEmpty ? scheduledTime : '');

    final isExpanded = width >= 520;
    final gutter = isExpanded ? 12.0 : 10.0;
    final outerRadius = isExpanded ? 28.0 : 24.0;
    final cellRadius = isExpanded ? 18.0 : 16.0;
    final topRowHeight = isExpanded ? 44.0 : 40.0;
    final footerHeight = isExpanded ? 42.0 : 38.0;
    final arenaPadV = isExpanded ? 8.0 : 6.0;
    final teamFont = isExpanded ? 12.5 : 11.5;
    // Keep emblems inside the arena: card chrome + rows leave a fixed budget.
    final arenaBudget =
        height -
        (gutter * 2) -
        topRowHeight -
        gutter -
        footerHeight -
        gutter -
        (arenaPadV * 2);
    final logoSize = (arenaBudget - 6 - teamFont * 1.25)
        .clamp(28.0, isExpanded ? 48.0 : 40.0)
        .toDouble();

    return SizedBox(
      width: width,
      height: height,
      child: SilverGlassCapsule(
        borderRadius: outerRadius,
        padding: EdgeInsets.zero,
        sigma: 24,
        highlightHeight: isExpanded ? 36 : 28,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
        child: SizedBox(
          width: width,
          height: height,
          child: Padding(
            padding: EdgeInsets.all(gutter),
            child: Column(
              children: [
                // Top bento row: league + status/time compartments
                SizedBox(
                  height: topRowHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: isExpanded ? 5 : 4,
                        child: _MatchBentoCell(
                          radius: cellRadius,
                          padding: EdgeInsets.symmetric(
                            horizontal: isExpanded ? 14 : 12,
                          ),
                          child: Row(
                            children: [
                              SilverGlassCapsule(
                                borderRadius: 10,
                                enableBlur: false,
                                highlightHeight: 8,
                                padding: EdgeInsets.all(isExpanded ? 7 : 6),
                                child: Icon(
                                  Icons.emoji_events_rounded,
                                  size: isExpanded ? 16 : 14,
                                  color: const Color(0xFFF7F8FA),
                                  shadows: const [
                                    Shadow(
                                      color: Color(0x73000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 0.5),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: isExpanded ? 10 : 8),
                              Expanded(
                                child: Text(
                                  (league != null && league.isNotEmpty)
                                      ? league
                                      : (isArabic ? 'مباراة' : 'Match'),
                                  style: TextStyle(
                                    color: AppColors.textPrimary.withValues(
                                      alpha: 0.9,
                                    ),
                                    fontSize: isExpanded ? 13 : 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.1,
                                    height: 1.15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: gutter),
                      Expanded(
                        flex: 3,
                        child: SilverGlassCapsule(
                          borderRadius: AppRadius.full,
                          enableBlur: false,
                          highlightHeight: 10,
                          padding: EdgeInsets.symmetric(
                            horizontal: isExpanded ? 14 : 12,
                          ),
                          child: Center(
                            child: isLive
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const _MatchStatusChip(compact: true),
                                      if (fixture?.clock != null &&
                                          fixture!.clock!.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          fixture.clock!,
                                          style: TextStyle(
                                            color: const Color(0xFFF7F8FA),
                                            fontSize: isExpanded ? 14 : 13,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                            height: 1,
                                            shadows: const [
                                              Shadow(
                                                color: Color(0x73000000),
                                                blurRadius: 4,
                                                offset: Offset(0, 0.5),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          timeLabel.isNotEmpty
                                              ? timeLabel
                                              : (isArabic ? 'اليوم' : 'TODAY'),
                                          style: TextStyle(
                                            color: const Color(0xFFF7F8FA),
                                            fontSize: isExpanded ? 14 : 13,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                            height: 1,
                                            shadows: const [
                                              Shadow(
                                                color: Color(0x73000000),
                                                blurRadius: 4,
                                                offset: Offset(0, 0.5),
                                              ),
                                            ],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (timeLabel.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          isArabic ? 'اليوم' : 'TODAY',
                                          style: TextStyle(
                                            color: const Color(0xCCF7F8FA),
                                            fontSize: isExpanded ? 10 : 9,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.8,
                                            height: 1,
                                            shadows: const [
                                              Shadow(
                                                color: Color(0x73000000),
                                                blurRadius: 4,
                                                offset: Offset(0, 0.5),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: gutter),
                // Main arena: teams + score
                Expanded(
                  child: _MatchBentoCell(
                    radius: cellRadius,
                    padding: EdgeInsets.symmetric(
                      horizontal: isExpanded ? 14 : 10,
                      vertical: arenaPadV,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: _TeamEmblemColumn(
                            name: homeName,
                            logoUrl: fixture?.homeLogoUrl,
                            logoSize: logoSize,
                            fontSize: teamFont,
                            elevated: true,
                            maxNameLines: 1,
                          ),
                        ),
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isExpanded ? 12 : 8,
                          ),
                          child: _VersusOrScoreBadge(
                            fixture: fixture,
                            large: isExpanded,
                          ),
                        ),
                        Expanded(
                          child: _TeamEmblemColumn(
                            name: awayName,
                            logoUrl: fixture?.awayLogoUrl,
                            logoSize: logoSize,
                            fontSize: teamFont,
                            elevated: true,
                            maxNameLines: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: gutter),
                // Footer bento: channel + CTA
                SizedBox(
                  height: footerHeight,
                  child: Row(
                    children: [
                      Expanded(
                        child: _MatchBentoCell(
                          radius: cellRadius,
                          padding: EdgeInsets.symmetric(
                            horizontal: isExpanded ? 14 : 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.tv_rounded,
                                size: isExpanded ? 16 : 14,
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                              SizedBox(width: isExpanded ? 8 : 6),
                              Expanded(
                                child: Text(
                                  channel.isNotEmpty
                                      ? channel
                                      : (isArabic ? 'القناة' : 'Channel'),
                                  style: TextStyle(
                                    color: AppColors.textPrimary.withValues(
                                      alpha: 0.78,
                                    ),
                                    fontSize: isExpanded ? 12.5 : 11.5,
                                    fontWeight: FontWeight.w500,
                                    height: 1.15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: gutter),
                      SilverGlassCapsule(
                        borderRadius: AppRadius.full,
                        enableBlur: false,
                        highlightHeight: 10,
                        padding: EdgeInsets.symmetric(
                          horizontal: isExpanded ? 16 : 12,
                          vertical: 8,
                        ),
                        child: _MatchWatchCue(
                          isLive: isLive,
                          isArabic: isArabic,
                          compact: !isExpanded,
                          silver: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft glass compartment used inside the wide match bento card.
class _MatchBentoCell extends StatelessWidget {
  const _MatchBentoCell({
    required this.child,
    required this.radius,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0x40FFFFFF), width: 0.75),
      ),
      child: Padding(
        padding: padding,
        child: Align(alignment: Alignment.center, child: child),
      ),
    );
  }
}

class _PortraitMatchSlide extends StatelessWidget {
  const _PortraitMatchSlide({required this.item});

  final HomeHeroItem item;

  @override
  Widget build(BuildContext context) {
    final match = item.match!;
    final fixture = match.fixture;
    final isLive = fixture?.isLive ?? false;
    final scheduledTime = fixture?.scheduledTime ?? fixture?.clock ?? '';
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final topPadding = MediaQuery.paddingOf(context).top;
    final rawChannel = fixture?.broadcastChannel ?? match.channel.name;
    final channel = SportsLocalization.localizeChannel(
      rawChannel,
      isArabic: isArabic,
    );
    final rawLeague = fixture?.league;
    final league = SportsLocalization.localizeLeague(
      rawLeague,
      isArabic: isArabic,
    );
    final homeName = SportsLocalization.localizeTeam(
      fixture?.homeName ?? 'Home',
      isArabic: isArabic,
    );
    final awayName = SportsLocalization.localizeTeam(
      fixture?.awayName ?? 'Away',
      isArabic: isArabic,
    );
    final timeLabel = isLive
        ? (fixture?.clock ?? (isArabic ? 'مباشر' : 'LIVE'))
        : (scheduledTime.isNotEmpty ? scheduledTime : '—');

    return Stack(
      fit: StackFit.expand,
      children: [
        _MatchStadiumBackdrop(match: match),
        const Positioned.fill(child: _MatchHeroScrim()),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            (topPadding > 0 ? topPadding : 20.0) + 56.0,
            AppSpacing.lg,
            AppSpacing.x4l,
          ),
          child: Column(
            children: [
              if (isLive) const _MatchStatusChip(),
              const Spacer(flex: 2),
              _MatchKickoffDisplay(
                timeLabel: timeLabel,
                isLive: isLive,
                isArabic: isArabic,
              ),
              const Spacer(flex: 2),
              Row(
                children: [
                  Expanded(
                    child: _TeamEmblemColumn(
                      name: homeName,
                      logoUrl: fixture?.homeLogoUrl,
                      logoSize: 64,
                      fontSize: 13,
                      elevated: true,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: _VersusOrScoreBadge(fixture: fixture, large: true),
                  ),
                  Expanded(
                    child: _TeamEmblemColumn(
                      name: awayName,
                      logoUrl: fixture?.awayLogoUrl,
                      logoSize: 64,
                      fontSize: 13,
                      elevated: true,
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 3),
              _MatchMetaLine(
                league: league,
                channel: channel,
                centered: true,
                prominent: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              _MatchWatchCue(isLive: isLive, isArabic: isArabic),
            ],
          ),
        ),
      ],
    );
  }
}

class _MatchStatusChip extends StatelessWidget {
  const _MatchStatusChip({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    const color = AppColors.live;
    final label = isArabic ? 'مباشر' : 'LIVE';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 5 : 6,
            height: compact ? 5 : 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 6),
              ],
            ),
          ),
          SizedBox(width: compact ? 5 : 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kickoff / clock chronograph — compact horizontal pill on small screens,
/// roomier plate on wide heroes.
class _MatchKickoffDisplay extends StatelessWidget {
  const _MatchKickoffDisplay({
    required this.timeLabel,
    required this.isLive,
    required this.isArabic,
    this.large = false,
    this.alignStart = false,
  });

  final String timeLabel;
  final bool isLive;
  final bool isArabic;
  final bool large;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    final accent = isLive ? AppColors.live : AppColors.accent;
    final dayLabel = isArabic ? 'اليوم' : 'TODAY';

    if (!large) {
      return Align(
        alignment: alignStart ? Alignment.centerLeft : Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: SilverGlassCapsule(
            borderRadius: AppRadius.full,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: alignStart
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                Text(
                  isLive ? (isArabic ? 'مباشر الآن' : 'LIVE NOW') : dayLabel,
                  style: TextStyle(
                    color: isLive ? AppColors.live : const Color(0xE6F7F8FA),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    height: 1,
                    shadows: const [
                      Shadow(
                        color: Color(0x73000000),
                        blurRadius: 4,
                        offset: Offset(0, 0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeLabel,
                  style: TextStyle(
                    color: isLive ? AppColors.live : const Color(0xFFF7F8FA),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    height: 1.05,
                    shadows: const [
                      Shadow(
                        color: Color(0x73000000),
                        blurRadius: 4,
                        offset: Offset(0, 0.5),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: alignStart ? Alignment.centerLeft : Alignment.center,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: accent.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xF0121620),
                        const Color(0xE608090B),
                        Color.lerp(const Color(0xE608090B), accent, 0.08) ??
                            const Color(0xE608090B),
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 22,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x28FFFFFF), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: alignStart
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    if (!isLive) ...[
                      Text(
                        dayLabel,
                        style: TextStyle(
                          color: accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      timeLabel,
                      style: TextStyle(
                        color: isLive ? AppColors.live : AppColors.textPrimary,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MatchMetaLine extends StatelessWidget {
  const _MatchMetaLine({
    required this.league,
    required this.channel,
    this.centered = false,
    this.prominent = false,
  });

  final String? league;
  final String channel;
  final bool centered;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (league != null && league!.isNotEmpty) league!,
      if (channel.isNotEmpty) channel,
    ];
    if (parts.isEmpty) return const SizedBox.shrink();

    final text = Text(
      parts.join('  ·  '),
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        color: AppColors.textPrimary.withValues(alpha: prominent ? 0.78 : 0.62),
        fontSize: prominent ? 12.5 : 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 1.25,
        shadows: prominent
            ? const [
                Shadow(
                  color: Color(0x88000000),
                  blurRadius: 10,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (!prominent) return text;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.border),
      ),
      child: text,
    );
  }
}

class _MatchWatchCue extends StatelessWidget {
  const _MatchWatchCue({
    required this.isLive,
    required this.isArabic,
    this.compact = false,
    this.silver = false,
  });

  final bool isLive;
  final bool isArabic;
  final bool compact;
  final bool silver;

  @override
  Widget build(BuildContext context) {
    final label = isLive
        ? (isArabic ? 'شاهد الآن' : 'Watch now')
        : (isArabic ? 'انتقل للقناة' : 'Go to channel');
    const silverColor = Color(0xFFF7F8FA);
    const silverShadows = [
      Shadow(color: Color(0x73000000), blurRadius: 4, offset: Offset(0, 0.5)),
    ];
    final color = silver ? silverColor : AppColors.accent;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isLive ? Icons.play_arrow_rounded : Icons.tv_rounded,
          size: compact ? 15 : 16,
          color: color,
          shadows: silver ? silverShadows : null,
        ),
        SizedBox(width: compact ? 4 : 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            height: 1,
            shadows: silver ? silverShadows : null,
          ),
        ),
      ],
    );
  }
}

class _TeamEmblemColumn extends StatelessWidget {
  const _TeamEmblemColumn({
    required this.name,
    required this.logoUrl,
    this.logoSize = 48,
    this.fontSize = 12,
    this.elevated = false,
    this.maxNameLines = 2,
  });

  final String name;
  final String? logoUrl;
  final double logoSize;
  final double fontSize;
  final bool elevated;
  final int maxNameLines;

  @override
  Widget build(BuildContext context) {
    final gap = elevated ? 6.0 : 4.0;
    final column = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: logoSize,
          height: logoSize,
          child: logoUrl != null && logoUrl!.isNotEmpty
              ? CachedImage(
                  imageUrl: logoUrl,
                  fit: BoxFit.contain,
                  fallbackIcon: AppIcons.live,
                )
              : Icon(
                  Icons.sports_soccer,
                  color: AppColors.textSecondary,
                  size: logoSize * 0.55,
                ),
        ),
        SizedBox(height: gap),
        Text(
          name,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.15,
            height: 1.2,
            shadows: elevated
                ? const [
                    Shadow(
                      color: Color(0x99000000),
                      blurRadius: 8,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          textAlign: TextAlign.center,
          maxLines: maxNameLines,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.maxHeight.isFinite) return column;
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: column,
          ),
        );
      },
    );
  }
}

class _VersusOrScoreBadge extends StatelessWidget {
  const _VersusOrScoreBadge({required this.fixture, this.large = false});

  final LiveFixture? fixture;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final hasScores = fixture?.homeScore != null && fixture?.awayScore != null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.full),
            // Apple silver glass: cool translucent fill + hairline rim.
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x73FFFFFF), Color(0x3DF2F4F7), Color(0x33A8B0BC)],
              stops: [0.0, 0.5, 1.0],
            ),
            border: Border.all(color: const Color(0x66FFFFFF), width: 0.75),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: large ? 12 : 9,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: large
                      ? (hasScores ? 14 : 16)
                      : (hasScores ? 12 : 14),
                  vertical: large ? 9 : 7,
                ),
                child: Text(
                  hasScores
                      ? '${fixture!.homeScore}–${fixture!.awayScore}'
                      : 'VS',
                  style: TextStyle(
                    color: const Color(0xFFF7F8FA),
                    fontSize: hasScores ? (large ? 22 : 15) : (large ? 12 : 11),
                    fontWeight: FontWeight.w700,
                    letterSpacing: hasScores ? -0.4 : 1.0,
                    height: 1,
                    shadows: const [
                      Shadow(
                        color: Color(0x73000000),
                        blurRadius: 4,
                        offset: Offset(0, 0.5),
                      ),
                    ],
                  ),
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
// Glass Actions Capsule (Search, TV Companion, Reload, Settings) — portrait Home
// ---------------------------------------------------------------------------

class _GlassActionCapsule extends StatelessWidget {
  const _GlassActionCapsule({this.onRefresh});

  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return DarkGlassCapsule(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _GlassButton(
            icon: AppIcons.search,
            tooltip: context.l10n.actionSearch,
            onTap: () => context.push(Routes.search),
            focusNode: ShellFocusBridge.heroChromeEntryOf(context),
            entry: true,
          ),
          const SizedBox(width: 3),
          _GlassButton(
            icon: AppIcons.generalTv,
            tooltip: context.l10n.companionScannerTitle,
            onTap: () => CompanionScannerModal.show(context),
          ),
          const SizedBox(width: 3),
          if (onRefresh != null) ...[
            _SpinningReloadButton(
              tooltip: context.l10n.actionRefresh,
              onTap: onRefresh!,
            ),
            const SizedBox(width: 3),
          ],
          _GlassButton(
            icon: AppIcons.settings,
            tooltip: context.l10n.navSettings,
            onTap: () => context.go(Routes.settings),
          ),
        ],
      ),
    );
  }
}

class _GlassButton extends StatefulWidget {
  const _GlassButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.focusNode,
    this.entry = false,
  });

  final List<List<dynamic>> icon;
  final String tooltip;
  final VoidCallback onTap;
  final FocusNode? focusNode;
  final bool entry;

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      focusNode: widget.focusNode,
      entry: widget.entry,
      onSelect: widget.onTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: widget.tooltip,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _hovered ? Colors.white.withAlpha(25) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: HugeIcon(
                icon: widget.icon,
                size: 19,
                color: _hovered ? Colors.white : Colors.white70,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpinningReloadButton extends StatefulWidget {
  const _SpinningReloadButton({required this.tooltip, required this.onTap});

  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_SpinningReloadButton> createState() => _SpinningReloadButtonState();
}

class _SpinningReloadButtonState extends State<_SpinningReloadButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.slow);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!MediaQuery.disableAnimationsOf(context) && !_controller.isAnimating) {
      _controller.forward(from: 0.0);
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      onSelect: _handleTap,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: widget.tooltip,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _hovered ? Colors.white.withAlpha(25) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: RotationTransition(
              turns: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _controller,
                  curve: AppMotion.curveEnter,
                ),
              ),
              child: Center(
                child: HugeIcon(
                  icon: AppIcons.refresh,
                  size: 19,
                  color: _hovered ? AppColors.accent : Colors.white70,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
