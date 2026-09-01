import 'dart:async';
import 'dart:ui' show ImageFilter;

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
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/widgets/cached_image.dart';

/// Cinematic Home hero carousel.
///
/// On portrait phones the banner owns the top chrome (Watch + search/refresh/
/// settings) because [AppShell] hides its top nav. On landscape / large screens
/// the shell already shows those actions — the banner only renders artwork.
class HomeHeroBanner extends StatefulWidget {
  const HomeHeroBanner({
    super.key,
    this.item,
    this.items = const [],
    required this.onPlay,
    this.onRefresh,
  });

  final HomeHeroItem? item;
  final List<HomeHeroItem> items;
  final void Function(HomeHeroItem item) onPlay;
  final VoidCallback? onRefresh;

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

    final screenWidth = MediaQuery.sizeOf(context).width;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final isPortrait =
        MediaQuery.orientationOf(context) == Orientation.portrait;
    // AppShell only hides its top nav on portrait Home — that is the only time
    // the banner should own search / refresh / settings.
    final showBannerChrome = isPortrait;
    final topPadding = MediaQuery.paddingOf(context).top;
    final topInset = topPadding > 0 ? (topPadding + 10.0) : 48.0;
    // Portrait keeps the original phone hero height; landscape uses the
    // large-screen layout separately.
    final bannerHeight = isPortrait
        ? (460.0 + (topPadding > 0 ? topPadding : 20.0))
        : (screenWidth > 1400
              ? (screenHeight * 0.38).clamp(420.0, 560.0)
              : screenWidth > 900
              ? 420.0
              : 380.0);

    return SizedBox(
      width: double.infinity,
      height: bannerHeight,
      child: Stack(
        fit: StackFit.expand,
        children: [
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
                child: _HeroCardSlide(
                  item: currentItem,
                  bannerHeight: bannerHeight,
                  // Wide poster+blur layout is landscape / TV only.
                  showWideLayout: !isPortrait,
                ),
              );
            },
          ),

          if (showBannerChrome)
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
                    Text(
                      context.l10n.actionWatch,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.5,
                        height: 1.1,
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
                      color: isActive
                          ? Colors.white
                          : Colors.white.withAlpha(80),
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

    return Stack(
      fit: StackFit.expand,
      children: [
        // Original mobile full-bleed cover (top-anchored poster crop).
        if (hasArt)
          CachedImage(
            imageUrl: item.backdropUrl,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            fallbackIcon: AppIcons.movies,
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

        // Transparent top gradient (original)
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
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
          ImageFiltered(
            imageFilter: ImageFilter.blur(sigmaX: 28, sigmaY: 28),
            child: Transform.scale(
              scale: 1.15,
              child: CachedImage(
                imageUrl: item.backdropUrl,
                fit: BoxFit.cover,
                alignment: Alignment.center,
                fallbackIcon: AppIcons.movies,
                memCacheWidth: blurCacheWidth,
              ),
            ),
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
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: CachedImage(
                        imageUrl: item.backdropUrl,
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                        borderRadius: BorderRadius.circular(12),
                        fallbackIcon: AppIcons.movies,
                        memCacheHeight: posterCacheHeight,
                      ),
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
            item.description!,
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
// Glass Actions Capsule (Search, Reload, Settings) — portrait Home only
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
