import 'package:dpad/dpad.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/core/platform/platform_service.dart';

/// Session flag: on touch/desktop platforms, TV focus chrome stays hidden until
/// a real remote / D-pad key is pressed. On Android TV, focus chrome is armed
/// immediately so the user always sees where the remote is pointing on launch.
abstract final class RemoteFocus {
  static final ValueNotifier<bool> armed = ValueNotifier<bool>(
    PlatformService.instance.isAndroidTv,
  );

  /// Comprehensive remote key set for Android TV, Fire TV, Google TV, and gamepads.
  static const DpadKeySet keySet = DpadKeySet(
    select: [
      ...DpadKeySet.defaultSelect,
      LogicalKeyboardKey.gameButtonSelect,
      LogicalKeyboardKey.open,
    ],
    back: [
      ...DpadKeySet.defaultBack,
      LogicalKeyboardKey.browserBack,
    ],
    menu: [
      ...DpadKeySet.defaultMenu,
      LogicalKeyboardKey.info,
      LogicalKeyboardKey.guide,
      LogicalKeyboardKey.settings,
      LogicalKeyboardKey.tvContentsMenu,
      LogicalKeyboardKey.mediaTopMenu,
    ],
  );

  static bool watch(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_RemoteFocus>()?.armed ??
        PlatformService.instance.isAndroidTv;
  }

  static void arm() {
    if (!armed.value) {
      armed.value = true;
    }
  }

  static void reset() {
    armed.value = PlatformService.instance.isAndroidTv;
  }

  static bool isRemoteKey(LogicalKeyboardKey key) {
    return keySet.directionOf(key) != null ||
        keySet.isSelect(key) ||
        keySet.isBack(key) ||
        keySet.isMenu(key) ||
        key == LogicalKeyboardKey.mediaPlayPause ||
        key == LogicalKeyboardKey.mediaPlay ||
        key == LogicalKeyboardKey.mediaPause ||
        key == LogicalKeyboardKey.mediaStop ||
        key == LogicalKeyboardKey.mediaFastForward ||
        key == LogicalKeyboardKey.mediaRewind ||
        key == LogicalKeyboardKey.mediaTrackNext ||
        key == LogicalKeyboardKey.mediaTrackPrevious ||
        key == LogicalKeyboardKey.channelUp ||
        key == LogicalKeyboardKey.channelDown ||
        key == LogicalKeyboardKey.pageUp ||
        key == LogicalKeyboardKey.pageDown;
  }

  /// Visual state for D-pad widgets: idle until a remote key has been used
  /// (or immediately armed on Android TV).
  static DpadFocusState visualOf(BuildContext context, DpadFocusState state) {
    if (watch(context)) return state;
    return const DpadFocusState(focused: false, pressed: false);
  }
}

/// Listens for remote keys and rebuilds the tree when focus chrome should
/// become visible.
class RemoteFocusScope extends StatefulWidget {
  const RemoteFocusScope({required this.child, super.key});

  final Widget child;

  @override
  State<RemoteFocusScope> createState() => _RemoteFocusScopeState();
}

class _RemoteFocusScopeState extends State<RemoteFocusScope> {
  @override
  void initState() {
    super.initState();
    if (PlatformService.instance.isAndroidTv) {
      RemoteFocus.arm();
    }
    HardwareKeyboard.instance.addHandler(_onKey);
    RemoteFocus.armed.addListener(_onArmedChanged);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    RemoteFocus.armed.removeListener(_onArmedChanged);
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is KeyDownEvent || event is KeyRepeatEvent) {
      if (RemoteFocus.isRemoteKey(event.logicalKey)) {
        RemoteFocus.arm();
      }
    }
    return false;
  }

  void _onArmedChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return _RemoteFocus(
      armed: RemoteFocus.armed.value,
      child: widget.child,
    );
  }
}

class _RemoteFocus extends InheritedWidget {
  const _RemoteFocus({required this.armed, required super.child});

  final bool armed;

  @override
  bool updateShouldNotify(_RemoteFocus oldWidget) => armed != oldWidget.armed;
}

/// Theme-level D-pad effects that stay inert until [RemoteFocus] is armed.
class ArmedDpadEffects extends DpadEffect {
  const ArmedDpadEffects();

  static const _effects = <DpadEffect>[
    DpadScaleEffect(scale: 1.06),
    DpadGlowEffect(
      color: AppColors.accent,
      blurRadius: 16,
      spreadRadius: 1.2,
      opacity: 0.5,
    ),
    DpadBorderEffect(
      color: AppColors.accent,
      width: 2.5,
    ),
  ];

  @override
  Widget build(BuildContext context, DpadFocusState state, Widget child) {
    final visual = RemoteFocus.visualOf(context, state);
    if (!visual.focused && !visual.pressed) return child;
    return DpadEffect.wrap(context, _effects, visual, child);
  }
}
