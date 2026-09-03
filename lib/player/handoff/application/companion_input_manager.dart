import 'dart:async';
import 'package:dpad/dpad.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/shared/focus/dpad_direction_dispatch.dart';
import 'package:iptv/shared/focus/remote_focus.dart';
import 'package:iptv/shared/navigation/app_back_navigation.dart';
import 'package:iptv/shared/navigation/navigator_keys.dart';

/// State of the virtual pointer on the host screen.
class CompanionInputState extends Equatable {
  const CompanionInputState({
    this.cursorPosition = Offset.zero, // Will be centered dynamically on first layout
    this.isCursorVisible = false,
    this.isMouseDown = false,
    this.lastClickEpoch = 0,
    this.lastAction = '',
    this.sensitivity = 1.0,
  });

  final Offset cursorPosition;
  final bool isCursorVisible;
  final bool isMouseDown;
  final int lastClickEpoch;
  final String lastAction;
  final double sensitivity;

  CompanionInputState copyWith({
    Offset? cursorPosition,
    bool? isCursorVisible,
    bool? isMouseDown,
    int? lastClickEpoch,
    String? lastAction,
    double? sensitivity,
  }) {
    return CompanionInputState(
      cursorPosition: cursorPosition ?? this.cursorPosition,
      isCursorVisible: isCursorVisible ?? this.isCursorVisible,
      isMouseDown: isMouseDown ?? this.isMouseDown,
      lastClickEpoch: lastClickEpoch ?? this.lastClickEpoch,
      lastAction: lastAction ?? this.lastAction,
      sensitivity: sensitivity ?? this.sensitivity,
    );
  }

  @override
  List<Object?> get props => [
        cursorPosition,
        isCursorVisible,
        isMouseDown,
        lastClickEpoch,
        lastAction,
        sensitivity,
      ];
}

/// Host-side service that translates remote companion touchpad movements,
/// taps, scroll gestures, keystrokes, and typed text into real Flutter events.
class CompanionInputManager extends StateNotifier<CompanionInputState> {
  CompanionInputManager({
    int pointerId = 99999,
  })  : _pointerId = pointerId,
        super(const CompanionInputState());

  final int _pointerId;
  Timer? _hideCursorTimer;
  Size _screenSize = const Size(1920, 1080);
  Offset _overlayOrigin = Offset.zero;
  bool _pointerAdded = false;

  int get pointerId => _pointerId;
  Offset get cursorPosition => state.cursorPosition;

  Offset get _globalCursor => state.cursorPosition + _overlayOrigin;

  /// Updates screen bounds dynamically from Flutter view or layout constraints.
  /// Also snaps the cursor to screen center if it hasn't been moved yet (prevents
  /// cursor being stuck at (0,0) which is the top-left corner off visible area).
  void updateScreenSize(Size size) {
    updateScreenGeometry(size, _overlayOrigin);
  }

  /// Syncs overlay size and its global origin so injected pointer events hit
  /// the same pixel the on-screen cursor is drawn at.
  void updateScreenGeometry(Size size, Offset origin) {
    if (size.width <= 0 || size.height <= 0) return;

    final wasDefault = _screenSize == const Size(1920, 1080) &&
        state.cursorPosition == Offset.zero;
    _screenSize = size;
    _overlayOrigin = origin;

    if (wasDefault || state.cursorPosition == Offset.zero) {
      state = state.copyWith(
        cursorPosition: Offset(size.width / 2, size.height / 2),
      );
    } else {
      state = state.copyWith(
        cursorPosition: Offset(
          state.cursorPosition.dx.clamp(0.0, size.width),
          state.cursorPosition.dy.clamp(0.0, size.height),
        ),
      );
    }
  }

  /// Sets cursor movement sensitivity multiplier.
  void setSensitivity(double sensitivity) {
    state = state.copyWith(sensitivity: sensitivity.clamp(0.2, 3.0));
  }

  /// Processes relative touchpad drag movement from companion device.
  void handleMouseMove(double dx, double dy) {
    final scaledDx = dx * state.sensitivity;
    final scaledDy = dy * state.sensitivity;

    final maxX = _screenSize.width > 0 ? _screenSize.width : 1920.0;
    final maxY = _screenSize.height > 0 ? _screenSize.height : 1080.0;

    var curX = state.cursorPosition.dx;
    var curY = state.cursorPosition.dy;
    if (curX <= 0 && curY <= 0) {
      curX = maxX / 2;
      curY = maxY / 2;
    }

    final newX = (curX + scaledDx).clamp(0.0, maxX);
    final newY = (curY + scaledDy).clamp(0.0, maxY);
    final newPosition = Offset(newX, newY);

    state = state.copyWith(
      cursorPosition: newPosition,
      isCursorVisible: true,
      lastAction: 'move',
    );

    _restartHideTimer();
    _ensurePointerAdded();
    _dispatchPointerEvent(
      PointerHoverEvent(
        position: _globalCursor,
        delta: Offset(scaledDx, scaledDy),
        device: _pointerId,
        kind: PointerDeviceKind.mouse,
      ),
    );
  }

  /// Processes a single tap on the trackpad (simulates Left Click).
  void handleMouseTap() {
    _restartHideTimer();
    final maxX = _screenSize.width > 0 ? _screenSize.width : 1920.0;
    final maxY = _screenSize.height > 0 ? _screenSize.height : 1080.0;
    final pos = state.cursorPosition == Offset.zero
        ? Offset(maxX / 2, maxY / 2)
        : state.cursorPosition;
    if (state.cursorPosition == Offset.zero) {
      state = state.copyWith(cursorPosition: pos);
    }
    final now = DateTime.now().millisecondsSinceEpoch;

    state = state.copyWith(
      isCursorVisible: true,
      isMouseDown: true,
      lastClickEpoch: now,
      lastAction: 'tap',
    );

    _ensurePointerAdded();
    final global = pos + _overlayOrigin;
    _dispatchPointerEvent(
      PointerDownEvent(
        position: global,
        device: _pointerId,
        kind: PointerDeviceKind.mouse,
        buttons: kPrimaryMouseButton,
      ),
    );

    Future.delayed(const Duration(milliseconds: 60), () {
      if (mounted) {
        state = state.copyWith(isMouseDown: false);
      }
      _dispatchPointerEvent(
        PointerUpEvent(
          position: global,
          device: _pointerId,
          kind: PointerDeviceKind.mouse,
        ),
      );
    });
  }

  /// Processes continuous mouse button down/up (e.g. for drag or long press).
  void handleMouseClick({String button = 'left', bool down = true}) {
    _restartHideTimer();
    final pos = state.cursorPosition;
    final buttonMask = button == 'right' ? kSecondaryMouseButton : kPrimaryMouseButton;

    state = state.copyWith(
      isCursorVisible: true,
      isMouseDown: down,
      lastClickEpoch: down ? DateTime.now().millisecondsSinceEpoch : state.lastClickEpoch,
      lastAction: down ? 'click_down' : 'click_up',
    );

    _ensurePointerAdded();
    final global = pos + _overlayOrigin;

    if (down) {
      _dispatchPointerEvent(
        PointerDownEvent(
          position: global,
          device: _pointerId,
          kind: PointerDeviceKind.mouse,
          buttons: buttonMask,
        ),
      );
    } else {
      _dispatchPointerEvent(
        PointerUpEvent(
          position: global,
          device: _pointerId,
          kind: PointerDeviceKind.mouse,
        ),
      );
    }
  }

  /// Processes two-finger scroll or wheel event from companion.
  void handleMouseScroll(double dx, double dy) {
    _restartHideTimer();
    state = state.copyWith(
      isCursorVisible: true,
      lastAction: 'scroll',
    );

    _ensurePointerAdded();
    _dispatchPointerEvent(
      PointerScrollEvent(
        position: _globalCursor,
        scrollDelta: Offset(dx, dy),
        device: _pointerId,
        kind: PointerDeviceKind.mouse,
      ),
    );
  }

  /// Injects typed text directly into the focused Flutter TextField / EditableText.
  void handleTypeText(String text, {bool replace = false}) {
    try {
      final primaryFocus = FocusManager.instance.primaryFocus;
      final focusContext = primaryFocus?.context;

      if (focusContext != null) {
        final editableState = _findEditableTextState(focusContext);
        if (editableState != null) {
          final curVal = editableState.textEditingValue;
          final updatedText = replace ? text : '${curVal.text}$text';
          editableState.userUpdateTextEditingValue(
            TextEditingValue(
              text: updatedText,
              selection: TextSelection.collapsed(offset: updatedText.length),
            ),
            SelectionChangedCause.keyboard,
          );
          AppLogger.debug('Injected text "$text" into focused EditableText', feature: 'companion_input');
          return;
        }
      }

      AppLogger.info('No EditableText currently focused for text: $text', feature: 'companion_input');
    } catch (e) {
      AppLogger.warning('Failed to inject text: $e', feature: 'companion_input');
    }
  }

  /// Handles D-pad and navigation keys (up, down, left, right, select, back, home, backspace).
  void handleKeyPress(String key, {VoidCallback? onPlayPauseToggle}) {
    try {
      final normalized = key.toLowerCase();
      switch (normalized) {
        case 'up':
        case 'arrowup':
        case 'down':
        case 'arrowdown':
        case 'left':
        case 'arrowleft':
        case 'right':
        case 'arrowright':
        case 'select':
        case 'ok':
        case 'enter':
        case 'back':
        case 'escape':
        case 'home':
        case 'play_pause':
          RemoteFocus.arm();
      }
      final navContext = rootNavigatorKey.currentContext;
      final dpad = navContext != null ? Dpad.maybeOf(navContext) : null;

      if (dpad != null && navContext != null) {
        switch (normalized) {
          case 'up':
          case 'arrowup':
            if (!dispatchFocusedDirection(
              navContext,
              TraversalDirection.up,
            )) {
              dpad.moveUp();
            }
            _scrollFocusedIntoView();
            return;
          case 'down':
          case 'arrowdown':
            if (!dispatchFocusedDirection(
              navContext,
              TraversalDirection.down,
            )) {
              dpad.moveDown();
            }
            _scrollFocusedIntoView();
            return;
          case 'left':
          case 'arrowleft':
            if (!dispatchFocusedDirection(
              navContext,
              TraversalDirection.left,
            )) {
              dpad.moveLeft();
            }
            _scrollFocusedIntoView();
            return;
          case 'right':
          case 'arrowright':
            if (!dispatchFocusedDirection(
              navContext,
              TraversalDirection.right,
            )) {
              dpad.moveRight();
            }
            _scrollFocusedIntoView();
            return;
          case 'select':
          case 'ok':
          case 'enter':
            _restartHideTimer();
            state = state.copyWith(
              lastClickEpoch: DateTime.now().millisecondsSinceEpoch,
              lastAction: 'select',
            );
            if (!dpad.select()) {
              _activateFocusedFallback();
            }
            return;
          case 'play_pause':
            onPlayPauseToggle?.call();
            return;
          case 'back':
          case 'escape':
            unawaited(handleRemoteBack(navContext));
            return;
          case 'home':
            handleRemoteHome(navContext);
            return;
          default:
            break;
        }
      }

      var primaryFocus = FocusManager.instance.primaryFocus;

      // If no item has focus yet, initiate focus on the active screen
      if (navContext != null &&
          (primaryFocus == null ||
              primaryFocus.context == null ||
              primaryFocus is FocusScopeNode)) {
        FocusScope.of(navContext).nextFocus();
        primaryFocus = FocusManager.instance.primaryFocus;
      }

      final context = primaryFocus?.context ?? navContext;

      switch (normalized) {
        case 'up':
        case 'arrowup':
          if (navContext != null) {
            _navigateVertically(navContext, primaryFocus, true);
          }
          break;
        case 'down':
        case 'arrowdown':
          if (navContext != null) {
            _navigateVertically(navContext, primaryFocus, false);
          }
          break;
        case 'left':
        case 'arrowleft':
          if (primaryFocus != null) {
            final moved =
                primaryFocus.focusInDirection(TraversalDirection.left);
            if (!moved && context != null) {
              FocusScope.of(context).previousFocus();
            }
          } else if (context != null) {
            FocusScope.of(context).previousFocus();
          }
          _scrollFocusedIntoView();
          break;
        case 'right':
        case 'arrowright':
          if (primaryFocus != null) {
            final moved =
                primaryFocus.focusInDirection(TraversalDirection.right);
            if (!moved && context != null) {
              FocusScope.of(context).nextFocus();
            }
          } else if (context != null) {
            FocusScope.of(context).nextFocus();
          }
          _scrollFocusedIntoView();
          break;
        case 'select':
        case 'ok':
        case 'enter':
          _restartHideTimer();
          state = state.copyWith(
            lastClickEpoch: DateTime.now().millisecondsSinceEpoch,
            lastAction: 'select',
          );
          _activateFocusedFallback();
          break;
        case 'back':
        case 'escape':
          if (navContext != null) {
            unawaited(handleRemoteBack(navContext));
          }
          break;
        case 'home':
          if (navContext != null) {
            handleRemoteHome(navContext);
          }
          break;
        case 'backspace':
          _handleBackspace();
          break;
        case 'play_pause':
          onPlayPauseToggle?.call();
          break;
      }
    } catch (e) {
      AppLogger.warning('Error handling key press "$key": $e',
          feature: 'companion_input');
    }
  }

  void _activateFocusedFallback() {
    final primaryFocus = FocusManager.instance.primaryFocus;
    final context = primaryFocus?.context;
    if (context == null) return;

    final invoked = Actions.maybeInvoke<Intent>(context, const ActivateIntent());
    if (invoked == null) {
      Actions.maybeInvoke<Intent>(context, const ButtonActivateIntent());
    }
  }

  void _handleBackspace() {
    final primaryFocus = FocusManager.instance.primaryFocus;
    final focusContext = primaryFocus?.context;
    if (focusContext != null) {
      final editableState = _findEditableTextState(focusContext);
      if (editableState != null) {
        final curVal = editableState.textEditingValue;
        if (curVal.text.isNotEmpty) {
          final newText = curVal.text.substring(0, curVal.text.length - 1);
          editableState.userUpdateTextEditingValue(
            TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(offset: newText.length),
            ),
            SelectionChangedCause.keyboard,
          );
        }
      }
    }
  }

  void _navigateVertically(
    BuildContext navContext,
    FocusNode? currentFocus,
    bool isUp,
  ) {
    bool moved = false;
    if (currentFocus != null) {
      moved = currentFocus.focusInDirection(
        isUp ? TraversalDirection.up : TraversalDirection.down,
      );
    }

    if (!moved) {
      final scope = FocusScope.of(navContext);
      final currentBox = currentFocus?.context?.findRenderObject();
      Rect? currentRect;
      if (currentBox is RenderBox && currentBox.hasSize && currentBox.attached) {
        currentRect = currentBox.localToGlobal(Offset.zero) & currentBox.size;
      }

      FocusNode? bestCandidate;
      double minDistance = double.infinity;

      for (final node in scope.traversalDescendants) {
        if (!node.canRequestFocus ||
            node == currentFocus ||
            node is FocusScopeNode) {
          continue;
        }
        final box = node.context?.findRenderObject();
        if (box is RenderBox && box.hasSize && box.attached) {
          final rect = box.localToGlobal(Offset.zero) & box.size;
          if (rect.width <= 4 ||
              rect.height <= 4 ||
              rect.width > 1800) {
            continue;
          }

          if (currentRect != null) {
            if (isUp && rect.bottom <= currentRect.top + 25) {
              final dy = currentRect.top - rect.bottom;
              final dx = (currentRect.center.dx - rect.center.dx).abs();
              final dist = (dy * 2.0) + dx;
              if (dist < minDistance) {
                minDistance = dist;
                bestCandidate = node;
              }
            } else if (!isUp && rect.top >= currentRect.bottom - 25) {
              final dy = rect.top - currentRect.bottom;
              final dx = (currentRect.center.dx - rect.center.dx).abs();
              final dist = (dy * 2.0) + dx;
              if (dist < minDistance) {
                minDistance = dist;
                bestCandidate = node;
              }
            }
          }
        }
      }

      if (bestCandidate != null) {
        bestCandidate.requestFocus();
      } else {
        final context = currentFocus?.context ?? navContext;
        final scrollable = Scrollable.maybeOf(context);
        if (scrollable != null &&
            (scrollable.axisDirection == AxisDirection.down ||
                scrollable.axisDirection == AxisDirection.up)) {
          scrollable.position.moveTo(
            (scrollable.position.pixels + (isUp ? -320 : 320))
                .clamp(0.0, scrollable.position.maxScrollExtent),
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
          );
        }
        if (isUp) {
          scope.previousFocus();
        } else {
          scope.nextFocus();
        }
      }
    }

    _scrollFocusedIntoView();
  }

  void _scrollFocusedIntoView() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final focus = FocusManager.instance.primaryFocus;
      if (focus != null && focus.context != null && focus is! FocusScopeNode) {
        try {
          Scrollable.ensureVisible(
            focus.context!,
            alignment: 0.35,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
          );
        } catch (_) {}
      }
    });
  }

  EditableTextState? _findEditableTextState(BuildContext context) {
    if (context is StatefulElement && context.state is EditableTextState) {
      return context.state as EditableTextState;
    }
    return context.findAncestorStateOfType<EditableTextState>();
  }

  void _ensurePointerAdded() {
    if (_pointerAdded) return;
    _pointerAdded = true;
    _dispatchPointerEvent(
      PointerAddedEvent(
        position: _globalCursor,
        device: _pointerId,
        kind: PointerDeviceKind.mouse,
      ),
    );
  }

  void _removePointer() {
    if (!_pointerAdded) return;
    _pointerAdded = false;
    _dispatchPointerEvent(
      PointerRemovedEvent(
        position: _globalCursor,
        device: _pointerId,
        kind: PointerDeviceKind.mouse,
      ),
    );
  }

  void _dispatchPointerEvent(PointerEvent event) {
    try {
      WidgetsBinding.instance.handlePointerEvent(event);
    } catch (e) {
      // Ignored if bindings are not ready in headless test environments
    }
  }

  void _restartHideTimer() {
    _hideCursorTimer?.cancel();
    _hideCursorTimer = Timer(const Duration(seconds: 8), () {
      if (mounted) {
        _removePointer();
        state = state.copyWith(isCursorVisible: false);
      }
    });
  }

  @override
  void dispose() {
    _hideCursorTimer?.cancel();
    _removePointer();
    super.dispose();
  }
}

/// Global provider for the Host TV Companion Input Manager.
final companionInputProvider =
    StateNotifierProvider<CompanionInputManager, CompanionInputState>((ref) {
  return CompanionInputManager();
});
