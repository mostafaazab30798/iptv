import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/player/handoff/application/companion_input_manager.dart';

/// Global overlay that draws the companion trackpad cursor on the host TV.
///
/// D-pad focus visuals live on the focused widget itself (via `dpad`). This
/// overlay only shows the mouse cursor and a click ripple at the exact
/// injected pointer position.
///
/// Cursor ticks rebuild only [_CompanionCursorLayer]; [child] (the routed app)
/// is not rebuilt on trackpad move.
class CompanionPointerOverlay extends StatelessWidget {
  const CompanionPointerOverlay({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.hardEdge,
      textDirection: TextDirection.ltr,
      children: [
        child,
        const Positioned.fill(child: _CompanionCursorLayer()),
      ],
    );
  }
}

/// Overlay leaf: geometry sync + cursor/ripple paints.
///
/// Selects only visibility, position, and click epoch so high-frequency cursor
/// updates never dirty the host app tree.
class _CompanionCursorLayer extends ConsumerStatefulWidget {
  const _CompanionCursorLayer();

  @override
  ConsumerState<_CompanionCursorLayer> createState() =>
      _CompanionCursorLayerState();
}

class _CompanionCursorLayerState extends ConsumerState<_CompanionCursorLayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _clickRippleController;

  @override
  void initState() {
    super.initState();
    _clickRippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
  }

  @override
  void dispose() {
    _clickRippleController.dispose();
    super.dispose();
  }

  void _syncGeometry(BoxConstraints constraints) {
    final box = context.findRenderObject();
    final origin = box is RenderBox && box.hasSize && box.attached
        ? box.localToGlobal(Offset.zero)
        : Offset.zero;
    ref.read(companionInputProvider.notifier).updateScreenGeometry(
          constraints.biggest,
          origin,
        );
  }

  @override
  Widget build(BuildContext context) {
    final showCursor = ref.watch(
      companionInputProvider.select((s) => s.isCursorVisible),
    );
    final cursor = ref.watch(
      companionInputProvider.select((s) => s.cursorPosition),
    );
    final clickEpoch = ref.watch(
      companionInputProvider.select((s) => s.lastClickEpoch),
    );

    ref.listen(
      companionInputProvider.select((s) => s.lastClickEpoch),
      (prev, next) {
        if (next != prev && next > 0) {
          _clickRippleController.forward(from: 0.0);
        }
      },
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _syncGeometry(constraints);
        });

        if (!showCursor) return const SizedBox.shrink();

        final maxX = constraints.maxWidth;
        final maxY = constraints.maxHeight;
        final cursorLeft = cursor.dx.clamp(0.0, maxX);
        final cursorTop = cursor.dy.clamp(0.0, maxY);

        return Stack(
          clipBehavior: Clip.none,
          textDirection: TextDirection.ltr,
          children: [
            if (clickEpoch > 0)
              Positioned(
                left: (cursorLeft - 40).clamp(0.0, maxX),
                top: (cursorTop - 40).clamp(0.0, maxY),
                width: 80,
                height: 80,
                child: IgnorePointer(
                  child: AnimatedBuilder(
                    animation: _clickRippleController,
                    builder: (context, _) {
                      if (!_clickRippleController.isAnimating &&
                          _clickRippleController.value == 0) {
                        return const SizedBox.shrink();
                      }
                      final t = _clickRippleController.value;
                      final radius = 12.0 + (t * 28.0);
                      final opacity = (1.0 - t).clamp(0.0, 1.0);
                      return Center(
                        child: SizedBox(
                          width: radius * 2,
                          height: radius * 2,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: opacity),
                                width: 2.5,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF00F0FF)
                                      .withValues(alpha: opacity * 0.7),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            Positioned(
              left: cursorLeft,
              top: cursorTop,
              child: const IgnorePointer(
                child: _CompanionCursor(),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Arrow cursor whose tip sits at the [Positioned] origin (the injected
/// pointer hotspot).
class _CompanionCursor extends ConsumerWidget {
  const _CompanionCursor();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pressed = ref.watch(
      companionInputProvider.select((s) => s.isMouseDown),
    );
    return SizedBox(
      width: 28,
      height: 28,
      child: CustomPaint(
        painter: _CursorPainter(pressed: pressed),
      ),
    );
  }
}

class _CursorPainter extends CustomPainter {
  const _CursorPainter({required this.pressed});

  final bool pressed;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(1, 1)
      ..lineTo(1, size.height * 0.92)
      ..lineTo(size.width * 0.38, size.height * 0.68)
      ..lineTo(size.width * 0.58, size.height * 0.98)
      ..lineTo(size.width * 0.70, size.height * 0.90)
      ..lineTo(size.width * 0.50, size.height * 0.60)
      ..lineTo(size.width * 0.88, size.height * 0.60)
      ..close();

    final glow = Paint()
      ..color = const Color(0xFF00F0FF).withValues(alpha: pressed ? 0.7 : 0.45)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawPath(path, glow);

    final fill = Paint()
      ..color = pressed ? const Color(0xFF00F0FF) : Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawPath(path, fill);

    final stroke = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(path, stroke);
  }

  @override
  bool shouldRepaint(covariant _CursorPainter oldDelegate) =>
      oldDelegate.pressed != pressed;
}
