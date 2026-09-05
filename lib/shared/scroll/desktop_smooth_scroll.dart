import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// App-wide custom scroll behavior tailored for desktop and multi-device interaction.
class AppScrollBehavior extends MaterialScrollBehavior {
  const AppScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    // On desktop, clamping scroll prevents weird rubber-banding on mouse pointers.
    // On mobile, keep default platform physics.
    switch (defaultTargetPlatform) {
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
        return const ClampingScrollPhysics();
      default:
        return super.getScrollPhysics(context);
    }
  }
}

/// A specialized [ScrollController] that provides silky-smooth mouse wheel scrolling on desktop platforms
/// by intercepting [pointerScroll] directly in its [ScrollPosition], avoiding the default jarring jumps.
class DesktopSmoothScrollController extends ScrollController {
  DesktopSmoothScrollController({
    super.initialScrollOffset,
    super.keepScrollOffset,
    super.debugLabel,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeOutCubic,
    this.scrollSpeedMultiplier = 1.25,
  });

  final Duration animationDuration;
  final Curve animationCurve;
  final double scrollSpeedMultiplier;

  @override
  ScrollPosition createScrollPosition(
    ScrollPhysics physics,
    ScrollContext context,
    ScrollPosition? oldPosition,
  ) {
    return _DesktopSmoothScrollPosition(
      physics: physics,
      context: context,
      initialPixels: initialScrollOffset,
      keepScrollOffset: keepScrollOffset,
      oldPosition: oldPosition,
      debugLabel: debugLabel,
      animationDuration: animationDuration,
      animationCurve: animationCurve,
      scrollSpeedMultiplier: scrollSpeedMultiplier,
    );
  }
}

class _DesktopSmoothScrollPosition extends ScrollPositionWithSingleContext {
  _DesktopSmoothScrollPosition({
    required super.physics,
    required super.context,
    super.initialPixels,
    super.keepScrollOffset,
    super.oldPosition,
    super.debugLabel,
    required this.animationDuration,
    required this.animationCurve,
    required this.scrollSpeedMultiplier,
  });

  final Duration animationDuration;
  final Curve animationCurve;
  final double scrollSpeedMultiplier;

  double? _targetPixels;

  bool get _isDesktop {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  @override
  void pointerScroll(double delta) {
    if (!_isDesktop) {
      super.pointerScroll(delta);
      return;
    }

    assert(delta != 0.0);

    // Trackpads emit continuous micro-deltas (often < 14px with fractional values).
    // Let trackpads scroll with native 1:1 precision.
    final isTrackpad = delta.abs() < 14.0 && delta != delta.roundToDouble();
    if (isTrackpad) {
      _targetPixels = null;
      super.pointerScroll(delta);
      return;
    }

    // Discrete mouse wheel notch: glide smoothly to target without default jump.
    final currentTarget = _targetPixels ?? pixels;
    final newTarget = (currentTarget + delta * scrollSpeedMultiplier)
        .clamp(minScrollExtent, maxScrollExtent);

    if ((newTarget - pixels).abs() < 0.5) return;

    _targetPixels = newTarget;

    animateTo(
      newTarget,
      duration: animationDuration,
      curve: animationCurve,
    ).then((_) {
      if (_targetPixels == newTarget) {
        _targetPixels = null;
      }
    });
  }

  @override
  void jumpTo(double value) {
    _targetPixels = null;
    super.jumpTo(value);
  }

  @override
  void applyNewDimensions() {
    super.applyNewDimensions();
    if (_targetPixels != null) {
      _targetPixels = _targetPixels!.clamp(minScrollExtent, maxScrollExtent);
    }
  }
}

/// A wrapper for scrollable widgets on Desktop that ensures mouse wheel scrolling
/// runs with smooth continuous interpolation.
class DesktopSmoothScrollView extends StatefulWidget {
  const DesktopSmoothScrollView({
    super.key,
    required this.controller,
    required this.child,
    this.animationDuration = const Duration(milliseconds: 200),
    this.animationCurve = Curves.easeOutCubic,
    this.scrollSpeedMultiplier = 1.25,
  });

  final ScrollController controller;
  final Widget child;
  final Duration animationDuration;
  final Curve animationCurve;
  final double scrollSpeedMultiplier;

  @override
  State<DesktopSmoothScrollView> createState() => _DesktopSmoothScrollViewState();
}

class _DesktopSmoothScrollViewState extends State<DesktopSmoothScrollView> {
  double? _targetOffset;

  bool get _isDesktop {
    if (kIsWeb) return false;
    return defaultTargetPlatform == TargetPlatform.windows ||
        defaultTargetPlatform == TargetPlatform.linux ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  void _onPointerSignal(PointerSignalEvent event) {
    // If the controller is already a DesktopSmoothScrollController,
    // its internal ScrollPosition handles pointerScroll smoothly without jump.
    if (widget.controller is DesktopSmoothScrollController) return;

    if (!_isDesktop) return;
    if (event is! PointerScrollEvent) return;
    if (!widget.controller.hasClients) return;

    final dy = event.scrollDelta.dy;
    final isTrackpad = dy.abs() < 14.0 && dy != dy.roundToDouble();
    if (isTrackpad) {
      _targetOffset = null;
      return;
    }

    final position = widget.controller.position;
    final minExtent = position.minScrollExtent;
    final maxExtent = position.maxScrollExtent;

    final currentTarget = _targetOffset ?? position.pixels;
    final newTarget = (currentTarget + dy * widget.scrollSpeedMultiplier)
        .clamp(minExtent, maxExtent);

    if ((newTarget - position.pixels).abs() < 0.5) return;

    _targetOffset = newTarget;

    widget.controller
        .animateTo(
      newTarget,
      duration: widget.animationDuration,
      curve: widget.animationCurve,
    )
        .then((_) {
      if (_targetOffset == newTarget) {
        _targetOffset = null;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_isDesktop) {
      return widget.child;
    }

    // If using DesktopSmoothScrollController, no outer listener is needed.
    if (widget.controller is DesktopSmoothScrollController) {
      return widget.child;
    }

    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerSignal: _onPointerSignal,
      onPointerDown: (_) {
        _targetOffset = null;
      },
      child: widget.child,
    );
  }
}
