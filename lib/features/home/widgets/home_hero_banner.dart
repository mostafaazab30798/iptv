import 'dart:async';
import 'dart:ui';

import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_radius.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/core/sports/match_wallpaper_resolver.dart';
import 'package:iptv/core/sports/sports_localization.dart';
import 'package:iptv/domain/entities/live_fixture.dart';
import 'package:iptv/domain/entities/live_match.dart';
import 'package:iptv/features/home/home_controller.dart';
import 'package:iptv/features/home/widgets/match_poster_layout.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/focus/remote_focus.dart';
import 'package:iptv/shared/focus/shell_focus_navigation.dart';
import 'package:iptv/shared/layouts/layouts.dart';
import 'package:iptv/shared/navigation/shell_portrait_header.dart';
import 'package:iptv/shared/widgets/adaptive_glass.dart';
import 'package:iptv/shared/widgets/cached_image.dart';

part 'home_hero_slides.dart';
part 'match_poster_card.dart';

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
    final chrome = ChromeHeights.of(context);
    final isPortrait =
        MediaQuery.orientationOf(context) == Orientation.portrait;
    final topPadding = MediaQuery.paddingOf(context).top;

    // TV: viewport fraction (0.45) with a modest cap — avoids fixed 420 on ~540h.
    if (chrome.formFactor == FormFactor.tv) {
      return (size.height * chrome.heroFraction).clamp(200.0, 320.0);
    }

    if (isPortrait) {
      return 470.0 + (topPadding > 0 ? topPadding : 20.0);
    }
    if (size.width > 1400) {
      return (size.height * chrome.heroFraction).clamp(420.0, 560.0);
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
  bool _isHovered = false;

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
    final bannerHeight = HomeHeroBanner.heightOf(context);

    final currentItem = (items.isNotEmpty && _currentPage.value < items.length)
        ? items[_currentPage.value]
        : null;
    final isMatch =
        currentItem?.type == HeroItemType.live && currentItem?.match != null;
    final currentFixture = currentItem?.match?.fixture;
    final goalRows = MatchPosterCard.goalRowsForFixture(currentFixture);
    final posterFocus = _heroPosterFocusGeometry(
      isPortrait: isPortrait,
      screenWidth: screenWidth,
      bannerHeight: bannerHeight,
      topOffset: 0,
      isMatch: isMatch,
      goalRows: goalRows,
    );

    return MouseRegion(
      onEnter: (_) {
        if (!_isHovered && mounted) setState(() => _isHovered = true);
        _pauseAutoScroll();
      },
      onExit: (_) {
        if (_isHovered && mounted) setState(() => _isHovered = false);
        _resumeAutoScroll();
      },
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
                    },
                    itemBuilder: (context, index) {
                      final currentItem = items[index];
                      return RepaintBoundary(
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => widget.onPlay(currentItem),
                          child: _HeroCardSlide(
                            item: currentItem,
                            bannerHeight: bannerHeight,
                            showWideLayout: !isPortrait,
                          ),
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
                  child: ShellPortraitHeader(
                    title: context.l10n.actionWatch,
                    currentPath: Routes.home,
                    onRefresh: widget.onRefresh,
                    titleColor: AppColors.accent,
                    showBackgroundGradient: false,
                    titleShadows: const [
                      Shadow(
                        color: Colors.black54,
                        blurRadius: 10,
                        offset: Offset(0, 1),
                      ),
                    ],
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

            // Desktop / PC hover navigation arrows for seamless card transitions
            if (!isPortrait && items.length > 1) ...[
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _HeroNavChevron(
                    icon: Icons.chevron_left_rounded,
                    visible: _isHovered,
                    onTap: () => _goToPage(
                      (_currentPage.value - 1 + items.length) % items.length,
                    ),
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _HeroNavChevron(
                    icon: Icons.chevron_right_rounded,
                    visible: _isHovered,
                    onTap: () => _goToPage(
                      (_currentPage.value + 1) % items.length,
                    ),
                  ),
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
    int goalRows = 0,
  }) {
    if (!isPortrait) {
      if (isMatch) {
        final matchSize = MatchPosterCard.sizeForWidth(
          screenWidth,
          goalRows: goalRows,
        );
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


class _HeroNavChevron extends StatefulWidget {
  const _HeroNavChevron({
    required this.icon,
    required this.visible,
    required this.onTap,
  });

  final IconData icon;
  final bool visible;
  final VoidCallback onTap;

  @override
  State<_HeroNavChevron> createState() => _HeroNavChevronState();
}

class _HeroNavChevronState extends State<_HeroNavChevron> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: widget.visible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 200),
      child: IgnorePointer(
        ignoring: !widget.visible,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _isHovered = true),
          onExit: (_) => setState(() => _isHovered = false),
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isHovered
                    ? Colors.black.withValues(alpha: 0.75)
                    : Colors.black.withValues(alpha: 0.45),
                border: Border.all(
                  color: _isHovered
                      ? AppColors.accent
                      : Colors.white.withValues(alpha: 0.22),
                  width: 1.2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Icon(
                  widget.icon,
                  color: _isHovered ? AppColors.accent : Colors.white,
                  size: 26,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
