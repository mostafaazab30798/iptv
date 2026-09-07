import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/router.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_motion.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/core/platform/platform_service.dart';
import 'package:iptv/features/kids_mode/widgets/kids_mode_nav_button.dart';
import 'package:iptv/player/handoff/presentation/companion_scanner_modal.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/focus/tv_focusable.dart';
import 'package:iptv/shared/navigation/shell_focus_bridge.dart';
import 'package:iptv/shared/widgets/adaptive_glass.dart';

/// Universal portrait top header providing strict visual consistency between
/// the persistent [AppShell] header and the full-bleed Home hero banner header.
class ShellPortraitHeader extends StatelessWidget {
  const ShellPortraitHeader({
    super.key,
    required this.title,
    required this.currentPath,
    this.onRefresh,
    this.titleColor,
    this.showBackgroundGradient = true,
    this.titleShadows,
    this.searchFocusNode,
  });

  final String title;
  final String currentPath;
  final VoidCallback? onRefresh;
  final Color? titleColor;
  final bool showBackgroundGradient;
  final List<Shadow>? titleShadows;
  final FocusNode? searchFocusNode;

  /// Canonical top inset calculation matching AppShell across all platforms.
  static double topInsetOf(BuildContext context) {
    final topPadding = MediaQueryData.fromView(View.of(context)).padding.top;
    return topPadding > 0 ? (topPadding + 10.0) : 48.0;
  }

  /// Total header height budget (top inset + content height 42.0 + bottom padding 8.0).
  static double heightOf(BuildContext context) {
    return topInsetOf(context) + 42.0 + AppSpacing.sm;
  }

  @override
  Widget build(BuildContext context) {
    final topInset = topInsetOf(context);

    final content = Padding(
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
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: titleColor ??
                    (currentPath == Routes.home
                        ? AppColors.accent
                        : Colors.white),
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                height: 1.1,
                shadows: titleShadows,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (!currentPath.startsWith(Routes.history)) ...[
            const SizedBox(width: 12),
            if (KidsModeNavButton.visibleFor(context)) ...[
              const KidsModeNavButton(),
              const SizedBox(width: 10),
            ],
            ShellActionCapsule(
              currentPath: currentPath,
              onRefresh: onRefresh,
              searchFocusNode: searchFocusNode,
            ),
          ],
        ],
      ),
    );

    if (!showBackgroundGradient) {
      return content;
    }

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.70, 1.0],
          colors: [Color(0xF5080B12), Color(0xDC080B12), Colors.transparent],
        ),
      ),
      child: content,
    );
  }
}

/// Unified dark frosted glass capsule containing standard header action buttons:
/// Search, Companion Remote, Smart Reload, Settings, and Fullscreen Toggle.
class ShellActionCapsule extends StatelessWidget {
  const ShellActionCapsule({
    super.key,
    required this.currentPath,
    this.onRefresh,
    this.searchFocusNode,
  });

  final String currentPath;
  final VoidCallback? onRefresh;
  final FocusNode? searchFocusNode;

  @override
  Widget build(BuildContext context) {
    return DarkGlassCapsule(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          ShellGlassActionButton(
            icon: AppIcons.search,
            activeIcon: AppIcons.search,
            isActive: currentPath == Routes.search,
            tooltip: context.l10n.actionSearch,
            onTap: () => context.push(Routes.search),
            focusNode: searchFocusNode ?? ShellFocusBridge.heroChromeEntryOf(context),
            entry: true,
          ),
          const SizedBox(width: 3),
          ShellGlassActionButton(
            icon: AppIcons.generalTv,
            activeIcon: AppIcons.generalTv,
            isActive: false,
            tooltip: context.l10n.companionScannerTitle,
            onTap: () => CompanionScannerModal.show(context),
          ),
          if (onRefresh != null) ...[
            const SizedBox(width: 3),
            ShellSpinningRefreshButton(
              tooltip: context.l10n.actionRefresh,
              onTap: onRefresh!,
            ),
          ],
          const SizedBox(width: 3),
          ShellGlassActionButton(
            icon: AppIcons.settings,
            activeIcon: AppIcons.settings,
            isActive: currentPath == Routes.settings,
            tooltip: context.l10n.navSettings,
            onTap: () => context.go(Routes.settings),
          ),
          if (PlatformService.instance.supportsFullscreen) ...[
            const SizedBox(width: 3),
            const ShellFullscreenToggleButton(),
          ],
        ],
      ),
    );
  }
}

/// Glass action button used across portrait and landscape shell headers.
class ShellGlassActionButton extends StatefulWidget {
  const ShellGlassActionButton({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.isActive,
    required this.tooltip,
    required this.onTap,
    this.focusNode,
    this.entry = false,
  });

  final List<List<dynamic>> icon;
  final List<List<dynamic>> activeIcon;
  final bool isActive;
  final String tooltip;
  final VoidCallback onTap;
  final FocusNode? focusNode;
  final bool entry;

  @override
  State<ShellGlassActionButton> createState() => _ShellGlassActionButtonState();
}

class _ShellGlassActionButtonState extends State<ShellGlassActionButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.isActive;
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
            duration: MotionPolicy.of(context).focus,
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: active
                  ? AppColors.accent.withAlpha(35)
                  : (_hovered
                      ? Colors.white.withAlpha(25)
                      : Colors.transparent),
              borderRadius: BorderRadius.circular(10),
              border: active
                  ? Border.all(
                      color: AppColors.accent.withAlpha(120),
                      width: 0.8,
                    )
                  : null,
            ),
            child: Center(
              child: HugeIcon(
                icon: active ? widget.activeIcon : widget.icon,
                size: 19,
                color: active
                    ? AppColors.accent
                    : (_hovered ? Colors.white : Colors.white70),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Action button with rotating refresh animation.
class ShellSpinningRefreshButton extends StatefulWidget {
  const ShellSpinningRefreshButton({
    super.key,
    required this.tooltip,
    required this.onTap,
  });

  final String tooltip;
  final VoidCallback onTap;

  @override
  State<ShellSpinningRefreshButton> createState() =>
      _ShellSpinningRefreshButtonState();
}

class _ShellSpinningRefreshButtonState extends State<ShellSpinningRefreshButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: AppMotion.slow,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  void _handleClick() {
    if (!MediaQuery.disableAnimationsOf(context) &&
        !_animController.isAnimating) {
      _animController.forward(from: 0.0);
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    return TvFocusable(
      onSelect: _handleClick,
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: Tooltip(
          message: widget.tooltip,
          child: AnimatedContainer(
            duration: MotionPolicy.of(context).focus,
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: _hovered ? Colors.white.withAlpha(25) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: RotationTransition(
              turns: Tween<double>(begin: 0.0, end: 1.0).animate(
                CurvedAnimation(
                  parent: _animController,
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

/// Fullscreen toggle button for desktop/supported platforms.
class ShellFullscreenToggleButton extends StatelessWidget {
  const ShellFullscreenToggleButton({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: PlatformService.instance.isFullScreenNotifier,
      builder: (context, isFullScreen, _) {
        return ShellGlassActionButton(
          icon: isFullScreen ? AppIcons.exitFullscreen : AppIcons.fullscreen,
          activeIcon: isFullScreen ? AppIcons.exitFullscreen : AppIcons.fullscreen,
          isActive: isFullScreen,
          tooltip: isFullScreen ? 'Exit Fullscreen (F11 / Esc)' : 'Fullscreen (F11)',
          onTap: () async {
            await PlatformService.instance.setFullScreen(!isFullScreen);
          },
        );
      },
    );
  }
}
