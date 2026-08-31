import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_motion.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/features/home/home_controller.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/widgets/cached_image.dart';

/// Ultra-modern cinematic Hero Banner reaching the top of the screen with a transparent gradient.
///
/// Features:
/// - Top bar integrated with "Watch" title on left, and Search, Reload & Settings glass capsule on right.
/// - Full-width high-resolution backdrop movie artwork reaching the very top edge.
/// - Top transparent-to-dark gradient and bottom blend gradient.
/// - Centered stylized title typography, metadata line, and 2-line synopsis.
/// - Bottom carousel indicators for the top 3 rated latest movies.
class HomeHeroBanner extends StatefulWidget {
  const HomeHeroBanner({
    super.key,
    this.item,
    this.items = const [],
    required this.onPlay,
    this.onRefresh,
    this.onSecondaryAction,
    this.secondaryActionLabel,
  });

  final HomeHeroItem? item;
  final List<HomeHeroItem> items;
  final void Function(HomeHeroItem item) onPlay;
  final VoidCallback? onRefresh;
  final void Function(HomeHeroItem item)? onSecondaryAction;
  final String? secondaryActionLabel;

  @override
  State<HomeHeroBanner> createState() => _HomeHeroBannerState();
}

class _HomeHeroBannerState extends State<HomeHeroBanner> {
  late final PageController _pageController;
  Timer? _autoScrollTimer;
  int _currentPage = 0;

  List<HomeHeroItem> get _effectiveItems {
    if (widget.items.isNotEmpty) return widget.items;
    if (widget.item != null) return [widget.item!];
    return const [];
  }

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _startAutoScroll();
  }

  @override
  void didUpdateWidget(covariant HomeHeroBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_effectiveItems.length != oldWidget.items.length) {
      _startAutoScroll();
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer?.cancel();
    if (_effectiveItems.length <= 1) return;

    _autoScrollTimer = Timer.periodic(const Duration(seconds: 6), (_) {
      if (!mounted || !_pageController.hasClients) return;
      final nextPage = (_currentPage + 1) % _effectiveItems.length;
      _pageController.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final items = _effectiveItems;
    if (items.isEmpty) return const SizedBox.shrink();

    final screenWidth = MediaQuery.of(context).size.width;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final topPadding = MediaQueryData.fromView(View.of(context)).padding.top;
    final topInset = topPadding > 0 ? (topPadding + 10.0) : 48.0;
    final bannerHeight = isPortrait
        ? (460.0 + (topPadding > 0 ? topPadding : 20.0))
        : (screenWidth > 1200 ? 500.0 : 440.0);

    return SizedBox(
      width: double.infinity,
      height: bannerHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full-bleed Carousel PageView extending to the very top edge
          PageView.builder(
            controller: _pageController,
            itemCount: items.length,
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemBuilder: (context, index) {
              final currentItem = items[index];
              return GestureDetector(
                onTap: () => widget.onPlay(currentItem),
                child: _HeroCardSlide(item: currentItem),
              );
            },
          ),

          // 2. Integrated Top Header: "Watch" Title (Left) + Search / Refresh / Settings (Right)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: EdgeInsets.fromLTRB(
                AppSpacing.xl,
                topInset,
                AppSpacing.xl,
                AppSpacing.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // "Watch" Title Header
                  Text(
                    context.l10n.actionWatch,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      height: 1.1,
                    ),
                  ),

                  // Glass Actions Capsule: Search, Reload, Settings
                  _GlassActionCapsule(
                    onRefresh: widget.onRefresh,
                  ),
                ],
              ),
            ),
          ),

          // 3. Bottom Carousel Page Indicators
          if (items.length > 1)
            Positioned(
              bottom: 14,
              left: 0,
              right: 0,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(items.length, (i) {
                  final isActive = i == _currentPage;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeOutCubic,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: isActive ? 22 : 6,
                    height: 5,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.white.withAlpha(80),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero Card Slide Item
// ---------------------------------------------------------------------------

class _HeroCardSlide extends StatelessWidget {
  const _HeroCardSlide({required this.item});

  final HomeHeroItem item;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Full-bleed Backdrop Image anchored to topCenter
        if (item.backdropUrl != null && item.backdropUrl!.isNotEmpty)
          CachedImage(
            imageUrl: item.backdropUrl,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            fallbackIcon: AppIcons.movies,
            memCacheWidth: 1080,
            memCacheHeight: 720,
          )
        else
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B2333), Color(0xFF0B0E14)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

        // Transparent Top Gradient - lets the movie image fill the top space while smoothly fading into the status bar
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.20, 0.50],
                colors: [
                  Color(0x6008090B),
                  Color(0x2008090B),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Bottom Fade Gradient for Text Readability & Smooth Content Blending
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
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

        // Centered Content Info
        Positioned(
          left: screenWidth > 600 ? 48.0 : 20.0,
          right: screenWidth > 600 ? 48.0 : 20.0,
          bottom: 34,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Stylized Movie Title
              Text(
                item.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFFF3C74C),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.4,
                  height: 1.15,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 14,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Metadata Line: Genre • Subtitle / Year • Rating
              Text(
                _formatMetadata(item),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white.withAlpha(210),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),

              // Synopsis / Description
              if (item.description != null && item.description!.isNotEmpty)
                Text(
                  item.description!,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white.withAlpha(155),
                    fontSize: 12.5,
                    height: 1.35,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatMetadata(HomeHeroItem item) {
    final parts = <String>[];
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
// Glass Actions Capsule (Search, Reload, Settings)
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
        border: Border.all(
          color: Colors.white.withAlpha(35),
          width: 0.8,
        ),
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
          // Search Action
          _GlassButton(
            icon: AppIcons.search,
            tooltip: context.l10n.actionSearch,
            onTap: () => context.push(Routes.search),
          ),
          const SizedBox(width: 3),

          // Reload Action
          if (onRefresh != null) ...[
            _SpinningReloadButton(
              tooltip: context.l10n.actionRefresh,
              onTap: onRefresh!,
            ),
            const SizedBox(width: 3),
          ],

          // Settings Action
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
  });

  final List<List<dynamic>> icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_GlassButton> createState() => _GlassButtonState();
}

class _GlassButtonState extends State<_GlassButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
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
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
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
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: _handleTap,
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
                CurvedAnimation(parent: _controller, curve: AppMotion.curveEnter),
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
