import 'package:flutter/material.dart';
import 'package:iptv/app/theme/app_motion.dart';

/// Wraps [child] with a fade + gentle upward slide driven by a shared
/// [controller], staggered by [index] among [itemCount] siblings.
///
/// A single controller is shared across a screen's entrance sequence instead
/// of giving every item its own ticker, keeping rebuild/animation overhead
/// low. When the controller's total duration is [Duration.zero] (reduced
/// motion), the computed [Interval] still resolves instantly to its end
/// value, so content simply appears with no lingering offset or opacity.
class EntranceFade extends StatelessWidget {
  const EntranceFade({
    super.key,
    required this.controller,
    required this.index,
    this.itemCount = 1,
    required this.child,
  });

  final Animation<double> controller;
  final int index;
  final int itemCount;
  final Widget child;

  Interval _interval() {
    final span = AppMotion.entranceItemSpan.clamp(0.05, 1.0);
    final maxStart = (1.0 - span).clamp(0.0, 1.0);
    final step = itemCount > 1 ? maxStart / (itemCount - 1) : 0.0;
    final start = (index * step).clamp(0.0, maxStart);
    final end = (start + span).clamp(start, 1.0);
    return Interval(start, end, curve: AppMotion.curveEnter);
  }

  @override
  Widget build(BuildContext context) {
    final animation = CurvedAnimation(parent: controller, curve: _interval());
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final value = animation.value;
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, (1 - value) * AppMotion.entranceOffset),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
