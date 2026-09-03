import 'package:dpad/dpad.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Dispatches a directional key to the currently focused node so
/// [DpadFocusable.onDirection] handlers run.
///
/// Companion remotes call [DpadController.move] directly, which skips
/// `onDirection`. This restores that path before falling back to geometric
/// traversal.
bool dispatchFocusedDirection(
  BuildContext navContext,
  TraversalDirection direction,
) {
  final primary = FocusManager.instance.primaryFocus;
  if (primary == null || primary.context == null) {
    return false;
  }

  final keys = Dpad.keySetOf(navContext);
  final List<LogicalKeyboardKey> keyList = switch (direction) {
    TraversalDirection.up => keys.up,
    TraversalDirection.down => keys.down,
    TraversalDirection.left => keys.left,
    TraversalDirection.right => keys.right,
  };
  if (keyList.isEmpty) {
    return false;
  }
  final logicalKey = keyList.first;
  final physicalKey = _physicalKeyFor(logicalKey);
  if (physicalKey == null) {
    return false;
  }

  final event = KeyDownEvent(
    physicalKey: physicalKey,
    logicalKey: logicalKey,
    timeStamp: Duration.zero,
  );

  final result = primary.onKeyEvent?.call(primary, event);
  return result == KeyEventResult.handled;
}

PhysicalKeyboardKey? _physicalKeyFor(LogicalKeyboardKey logical) {
  if (logical == LogicalKeyboardKey.arrowUp) {
    return PhysicalKeyboardKey.arrowUp;
  }
  if (logical == LogicalKeyboardKey.arrowDown) {
    return PhysicalKeyboardKey.arrowDown;
  }
  if (logical == LogicalKeyboardKey.arrowLeft) {
    return PhysicalKeyboardKey.arrowLeft;
  }
  if (logical == LogicalKeyboardKey.arrowRight) {
    return PhysicalKeyboardKey.arrowRight;
  }
  return null;
}
