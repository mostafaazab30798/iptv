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
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/features/home/home_controller.dart';
import 'package:iptv/features/kids_mode/widgets/kids_mode_nav_button.dart';
import 'package:iptv/player/handoff/presentation/companion_scanner_modal.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/focus/remote_focus.dart';
import 'package:iptv/shared/focus/shell_focus_navigation.dart';
import 'package:iptv/shared/focus/tv_focusable.dart';
import 'package:iptv/shared/navigation/shell_focus_bridge.dart';
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
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isPortrait =
        MediaQuery.orientationOf(context) == Orientation.portrait;
    final topPadding = MediaQuery.paddingOf(context).top;
    final bannerHeight = isPortrait
        ? (470.0 + (topPadding > 0 ? topPadding : 20.0))
        : (screenWidth > 1400
              ? (screenHeight * 0.38).clamp(420.0, 560.0)
              : screenWidth > 900
              ? 420.0
              : 380.0);

    final posterFocus = _heroPosterFocusGeometry(
      isPortrait: isPortrait,
      screenWidth: screenWidth,
      bannerHeight: bannerHeight,
      topOffset: 0,
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
                    onPageChanged: (index) => _currentPage.value = index,
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
            Positioned(
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

          if (items.length > 1 && !isPortrait && screenWidth >= 600) ...[
            // Left Navigation Chevron Button
            Positioned(
              left: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: _HeroNavChevron(
                  icon: AppIcons.chevronLeft,
                  isLeft: true,
                  onTap: () => _goToPage((_currentPage.value - 1 + items.length) % items.length),
                ),
              ),
            ),

            // Right Navigation Chevron Button
            Positioned(
              right: 16,
              top: 0,
              bottom: 0,
              child: Center(
                child: _HeroNavChevron(
                  icon: AppIcons.chevronRight,
                  isLeft: false,
                  onTap: () => _goToPage((_currentPage.value + 1) % items.length),
                ),
              ),
            ),
          ],

          if (items.length > 1) ...[
            // Clickable Pagination Dots
            Positioned(
              bottom: 14,
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
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
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
  }) {
    if (!isPortrait) {
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
    final posterWidth =
        (screenWidth - horizontalInset * 2).clamp(120.0, 220.0);
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
    final meta = _formatMetadata(item);
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
              border: Border.all(
                color: const Color(0xFF00FF87).withAlpha(140),
              ),
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
                ? context.l10n.homeWatchOnChannel(item.channel!.name)
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

// ---------------------------------------------------------------------------
// Glass Actions Capsule (Search, TV Companion, Reload, Settings) — portrait Home
// ---------------------------------------------------------------------------

class _GlassActionCapsule extends StatelessWidget {
  const _GlassActionCapsule({this.onRefresh});

  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.black.withAlpha(90),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withAlpha(35), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(70),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
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
              color:
                  _hovered ? Colors.white.withAlpha(25) : Colors.transparent,
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
              color:
                  _hovered ? Colors.white.withAlpha(25) : Colors.transparent,
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

class _HeroNavChevron extends StatefulWidget {
  const _HeroNavChevron({
    required this.icon,
    required this.onTap,
    required this.isLeft,
  });

  final List<List<dynamic>> icon;
  final VoidCallback onTap;
  final bool isLeft;

  @override
  State<_HeroNavChevron> createState() => _HeroNavChevronState();
}

class _HeroNavChevronState extends State<_HeroNavChevron> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: _hovered
                ? Colors.black.withAlpha(190)
                : Colors.black.withAlpha(110),
            shape: BoxShape.circle,
            border: Border.all(
              color: _hovered ? AppColors.accent : Colors.white24,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(90),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Center(
            child: HugeIcon(
              icon: widget.icon,
              size: 20,
              color: _hovered ? AppColors.accent : Colors.white,
            ),
          ),
        ),
      ),
    );
  }
}
