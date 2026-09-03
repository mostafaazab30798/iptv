import 'package:dpad/dpad.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Session flag: TV focus chrome stays hidden until a real remote / D-pad
/// key is pressed. Touch, mouse, and startup autofocus must not light it up.
abstract final class RemoteFocus {
  static final ValueNotifier<bool> armed = ValueNotifier<bool>(false);

  static const DpadKeySet _keys = DpadKeySet(
    select: [
      ...DpadKeySet.defaultSelect,
      LogicalKeyboardKey.gameButtonSelect,
    ],
  );

  static bool watch(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<_RemoteFocus>()?.armed ??
        false;
  }

  static void arm() {
    if (!armed.value) {
      armed.value = true;
    }
  }

  static void reset() {
    armed.value = false;
  }

  static bool isRemoteKey(LogicalKeyboardKey key) {
    return _keys.directionOf(key) != null ||
        _keys.isSelect(key) ||
        _keys.isBack(key) ||
        _keys.isMenu(key) ||
        key == LogicalKeyboardKey.mediaPlayPause ||
        key == LogicalKeyboardKey.mediaPlay ||
        key == LogicalKeyboardKey.mediaPause ||
        key == LogicalKeyboardKey.mediaTrackNext ||
        key == LogicalKeyboardKey.mediaTrackPrevious ||
        key == LogicalKeyboardKey.channelUp ||
        key == LogicalKeyboardKey.channelDown;
  }

  /// Visual state for D-pad widgets: idle until a remote key has been used.
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
      color: Color(0xFF00C2FF),
      blurRadius: 16,
      spreadRadius: 1.2,
      opacity: 0.5,
    ),
    DpadBorderEffect(
      color: Color(0xFF00C2FF),
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
