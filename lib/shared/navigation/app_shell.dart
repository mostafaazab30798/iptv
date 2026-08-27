import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/core/constants/app_constants.dart';

import 'package:iptv/features/favorites/favorites_screen.dart';
import 'package:iptv/features/guide/guide_controller.dart';
import 'package:iptv/features/home/home_controller.dart';
import 'package:iptv/features/live/live_controller.dart';
import 'package:iptv/features/movies/movies_controller.dart';
import 'package:iptv/features/series/series_controller.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/widgets/landscape_gate.dart';

class ShellNavItem {
  const ShellNavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.route,
  });

  final List<List<dynamic>> icon;
  final List<List<dynamic>> activeIcon;
  final String label;
  final String route;
}

/// Universal App Shell providing persistent responsive navigation with an
/// ultra-modern Figma/Dribbble-inspired Floating Frosted Glass Dock across all devices.
class AppShell extends ConsumerWidget {
  const AppShell({
    super.key,
    required this.child,
    required this.state,
  });

  final Widget child;
  final GoRouterState state;

  static List<ShellNavItem> getNavItems(BuildContext context) => [
    ShellNavItem(icon: AppIcons.home, activeIcon: AppIcons.home, label: context.l10n.navHome, route: Routes.home),
    ShellNavItem(icon: AppIcons.live, activeIcon: AppIcons.live, label: context.l10n.navLive, route: Routes.live),
    ShellNavItem(icon: AppIcons.movies, activeIcon: AppIcons.movies, label: context.l10n.navMovies, route: Routes.movies),
    ShellNavItem(icon: AppIcons.series, activeIcon: AppIcons.series, label: context.l10n.navSeries, route: Routes.series),
    ShellNavItem(icon: AppIcons.favorites, activeIcon: AppIcons.favorites, label: context.l10n.navFavorites, route: Routes.favorites),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentPath = state.uri.path;
    final isPortrait = MediaQuery.orientationOf(context) == Orientation.portrait;
    final selectedIndex = _getSelectedIndex(currentPath);
    final navItems = getNavItems(context);

    return LandscapeGate(
      child: Scaffold(
        backgroundColor: AppColors.bg0,
        extendBody: false,
        body: Column(
          children: [
            _ShellTopNav(
              items: navItems,
              selectedIndex: selectedIndex,
              currentPath: currentPath,
              onItemTap: (index, route) => _onNavigate(context, route),
              onRefresh: () => _handleSmartRefresh(ref, currentPath),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(child: child),
          ],
        ),
        bottomNavigationBar: isPortrait
            ? _FloatingGlassDock(
                items: navItems,
                selectedIndex: selectedIndex,
                onItemTap: (index, route) => _onNavigate(context, route),
              )
            : null,
      ),
    );
  }

  int _getSelectedIndex(String path) {
    if (path.startsWith(Routes.home)) return 0;
    if (path.startsWith(Routes.live)) return 1;
    if (path.startsWith(Routes.movies)) return 2;
    if (path.startsWith(Routes.series)) return 3;
    if (path.startsWith(Routes.favorites)) return 4;
    return -1; // e.g. Settings, Guide, History
  }

  void _onNavigate(BuildContext context, String route) {
    context.go(route);
  }

  void _handleSmartRefresh(WidgetRef ref, String currentPath) {
    if (currentPath.startsWith(Routes.home)) {
      ref.read(homeControllerProvider.notifier).loadData(forceRefresh: true);
    } else if (currentPath.startsWith(Routes.live)) {
      ref.read(liveControllerProvider.notifier).loadData(forceRefresh: true);
    } else if (currentPath.startsWith(Routes.movies)) {
      ref.read(moviesControllerProvider.notifier).loadData(forceRefresh: true);
    } else if (currentPath.startsWith(Routes.series)) {
      ref.read(seriesControllerProvider.notifier).loadData(forceRefresh: true);
    } else if (currentPath.startsWith(Routes.favorites)) {
      ref.invalidate(favoritesListProvider);
    } else if (currentPath.startsWith(Routes.guide)) {
      ref.read(guideControllerProvider.notifier).loadData();
    }
  }
}

// ---------------------------------------------------------------------------
// Shell Top Navigation Bar (TV / Landscape Rail / Top Action Header)
// ---------------------------------------------------------------------------

class _ShellTopNav extends StatelessWidget {
  const _ShellTopNav({
    required this.items,
    required this.selectedIndex,
    required this.currentPath,
    required this.onItemTap,
    required this.onRefresh,
  });

  final List<ShellNavItem> items;
  final int selectedIndex;
  final String currentPath;
  final void Function(int index, String route) onItemTap;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final isPortrait = MediaQuery.orientationOf(context) == Orientation.portrait;

    if (isPortrait) {
      // Portrait Top Header with High-Performance Glass Gradient
      return Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.70, 1.0],
            colors: [
              Color(0xF5080B12),
              Color(0xDC080B12),
              Colors.transparent,
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Container(
            height: 64,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.xs,
              AppSpacing.lg,
              AppSpacing.md,
            ),
            child: Row(
              children: [
                _BrandLogo(onTap: () => context.go(Routes.home)),
                const Spacer(),
                // Modern Glass Action Capsule
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withAlpha(12),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withAlpha(22),
                      width: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(50),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _SpinningRefreshButton(
                        tooltip: context.l10n.actionRefresh,
                        onTap: onRefresh,
                      ),
                      const SizedBox(width: 3),
                      _GlassActionButton(
                        icon: AppIcons.settings,
                        activeIcon: AppIcons.settings,
                        isActive: currentPath == Routes.settings,
                        tooltip: context.l10n.navSettings,
                        onTap: () => context.go(Routes.settings),
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

    // Landscape / Desktop / TV Header with High-Performance Gradient
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.75, 1.0],
          colors: [
            Color(0xF5080B12),
            Color(0xDD080B12),
            Colors.transparent,
          ],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: 70,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.xl,
            AppSpacing.xs,
            AppSpacing.xl,
            AppSpacing.md,
          ),
          child: Row(
            children: [
              _BrandLogo(onTap: () => context.go(Routes.home)),
              const SizedBox(width: AppSpacing.xl),
              Expanded(
                child: Row(
                        children: List.generate(items.length, (i) {
                          final item = items[i];
                          final isSelected = i == selectedIndex;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _GlassHeaderNavItem(
                              item: item,
                              isSelected: isSelected,
                              onTap: () => onItemTap(i, item.route),
                            ),
                          );
                        }),
                      ),
                    ),
                    // Glass Action Capsule
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.white.withAlpha(12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withAlpha(22),
                          width: 0.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(60),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _SpinningRefreshButton(
                            tooltip: context.l10n.actionRefresh,
                            onTap: onRefresh,
                          ),
                          const SizedBox(width: 4),
                          _GlassActionButton(
                            icon: AppIcons.settings,
                            activeIcon: AppIcons.settings,
                            isActive: currentPath == Routes.settings,
                            tooltip: context.l10n.navSettings,
                            onTap: () => context.go(Routes.settings),
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

// ---------------------------------------------------------------------------
// Figma/Dribbble Floating Frosted Glass Dock (Portrait Mobile)
// ---------------------------------------------------------------------------

class _FloatingGlassDock extends StatelessWidget {
  const _FloatingGlassDock({
    required this.items,
    required this.selectedIndex,
    required this.onItemTap,
  });

  final List<ShellNavItem> items;
  final int selectedIndex;
  final void Function(int index, String route) onItemTap;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isCompact = screenWidth < 360;

    return SafeArea(
      top: false,
      maintainBottomViewPadding: true,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isCompact ? 10.0 : 16.0,
          0,
          isCompact ? 10.0 : 16.0,
          10.0,
        ),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppColors.bg1.withAlpha(245),
                AppColors.bg2.withAlpha(252),
              ],
            ),
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
              color: Colors.white.withAlpha(35),
              width: 0.9,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(130),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: AppColors.accent.withAlpha(30),
                blurRadius: 18,
                spreadRadius: -2,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(items.length, (i) {
              final item = items[i];
              final isSelected = i == selectedIndex;
              return Expanded(
                child: _DockNavItem(
                  item: item,
                  isSelected: isSelected,
                  isCompact: isCompact,
                  onTap: () => onItemTap(i, item.route),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _DockNavItem extends StatefulWidget {
  const _DockNavItem({
    required this.item,
    required this.isSelected,
    required this.isCompact,
    required this.onTap,
  });

  final ShellNavItem item;
  final bool isSelected;
  final bool isCompact;
  final VoidCallback onTap;

  @override
  State<_DockNavItem> createState() => _DockNavItemState();
}

class _DockNavItemState extends State<_DockNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: isSelected
                ? AppColors.accent.withAlpha(28)
                : _hovered
                    ? Colors.white.withAlpha(12)
                    : Colors.transparent,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.15 : (_hovered ? 1.05 : 1.0),
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeOutBack,
                child: HugeIcon(
                  icon: isSelected ? widget.item.activeIcon : widget.item.icon,
                  size: widget.isCompact ? 20 : 22,
                  color: isSelected
                      ? AppColors.accent
                      : (_hovered ? AppColors.textPrimary : AppColors.textSecondary),
                ),
              ),
              if (!widget.isCompact) ...[
                const SizedBox(height: 3),
                Text(
                  widget.item.label,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    color: isSelected
                        ? Colors.white
                        : (_hovered ? AppColors.textPrimary : AppColors.textSecondary),
                    letterSpacing: 0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _GlassHeaderNavItem extends StatefulWidget {
  const _GlassHeaderNavItem({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final ShellNavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<_GlassHeaderNavItem> createState() => _GlassHeaderNavItemState();
}

class _GlassHeaderNavItemState extends State<_GlassHeaderNavItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final isSelected = widget.isSelected;
    final isActive = isSelected || _hovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent.withAlpha(35)
                : (_hovered ? Colors.white.withAlpha(16) : Colors.transparent),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? AppColors.accent.withAlpha(110)
                  : (_hovered ? Colors.white.withAlpha(28) : Colors.transparent),
              width: 0.8,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withAlpha(40),
                      blurRadius: 10,
                      offset: const Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedScale(
                scale: isSelected ? 1.1 : 1.0,
                duration: const Duration(milliseconds: 180),
                child: HugeIcon(
                  icon: isSelected ? widget.item.activeIcon : widget.item.icon,
                  size: 17,
                  color: isSelected
                      ? AppColors.accent
                      : (isActive ? AppColors.textPrimary : AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 7),
              Text(
                widget.item.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? Colors.white
                      : (isActive ? AppColors.textPrimary : AppColors.textSecondary),
                  letterSpacing: 0.2,
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
// Header Action Components (Figma/Dribbble Spec)
// ---------------------------------------------------------------------------

class _SpinningRefreshButton extends StatefulWidget {
  const _SpinningRefreshButton({
    required this.tooltip,
    required this.onTap,
  });

  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_SpinningRefreshButton> createState() => _SpinningRefreshButtonState();
}

class _SpinningRefreshButtonState extends State<_SpinningRefreshButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!_animController.isAnimating) {
      _animController.forward(from: 0.0);
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
            duration: const Duration(milliseconds: 180),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _hovered ? Colors.white.withAlpha(22) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: _hovered ? Colors.white.withAlpha(35) : Colors.transparent,
                width: 0.8,
              ),
            ),
            child: RotationTransition(
              turns: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
              ),
              child: HugeIcon(
                icon: AppIcons.refresh,
                size: 20,
                color: _hovered ? AppColors.accent : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassActionButton extends StatefulWidget {
  const _GlassActionButton({
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.tooltip,
    required this.onTap,
  });

  final List<List<dynamic>> icon;
  final List<List<dynamic>> activeIcon;
  final bool isActive;
  final String tooltip;
  final VoidCallback onTap;

  @override
  State<_GlassActionButton> createState() => _GlassActionButtonState();
}

class _GlassActionButtonState extends State<_GlassActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: Tooltip(
        message: widget.tooltip,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.accent.withAlpha(35)
                  : _hovered
                      ? Colors.white.withAlpha(22)
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: active
                    ? AppColors.accent.withAlpha(120)
                    : (_hovered ? Colors.white.withAlpha(35) : Colors.transparent),
                width: 0.8,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withAlpha(50),
                        blurRadius: 10,
                        offset: const Offset(0, 1),
                      ),
                    ]
                  : null,
            ),
            child: AnimatedScale(
              scale: _hovered ? 1.08 : 1.0,
              duration: const Duration(milliseconds: 160),
              curve: Curves.easeOutBack,
              child: HugeIcon(
                icon: active ? widget.activeIcon : widget.icon,
                size: 20,
                color: active
                    ? AppColors.accent
                    : (_hovered ? AppColors.textPrimary : AppColors.textSecondary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandLogo extends StatefulWidget {
  const _BrandLogo({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_BrandLogo> createState() => _BrandLogoState();
}

class _BrandLogoState extends State<_BrandLogo> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedScale(
          scale: _hovered ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutBack,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Clean Logo Emblem
              Image.asset(
                AppConstants.appLogo,
                width: 44,
                height: 44,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              // Modern Dual-Row Branding Typography (HOPE on top, IPTV below)
              const Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'HOPE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2.5,
                      height: 1.05,
                    ),
                  ),
                  SizedBox(height: 1),
                  Text(
                    'IPTV',
                    style: TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 3.5,
                      height: 1.0,
                      shadows: [
                        Shadow(
                          color: Color(0x7A00E5FF),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 10),
              // Sleek 4K LIVE Pulse Badge Chip
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
                decoration: BoxDecoration(
                  color: const Color(0xFF00FF87).withAlpha(22),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: const Color(0xFF00FF87).withAlpha(80),
                    width: 0.7,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Color(0xFF00FF87),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0xFF00FF87),
                            blurRadius: 5,
                            spreadRadius: 0.5,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Text(
                      '4K LIVE',
                      style: TextStyle(
                        color: Color(0xFF00FF87),
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
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


