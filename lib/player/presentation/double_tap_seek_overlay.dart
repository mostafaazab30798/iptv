import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';

enum DoubleTapSeekSide { left, right }

/// Animated YouTube/Netflix-style double-tap seek ripple and badge overlay.
class DoubleTapSeekOverlay extends StatefulWidget {
  const DoubleTapSeekOverlay({
    super.key,
    required this.side,
    required this.seconds,
    required this.onAnimationComplete,
  });

  final DoubleTapSeekSide side;
  final int seconds;
  final VoidCallback onAnimationComplete;

  @override
  State<DoubleTapSeekOverlay> createState() => _DoubleTapSeekOverlayState();
}

class _DoubleTapSeekOverlayState extends State<DoubleTapSeekOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 650),
    );

    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 30),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _scale = Tween<double>(begin: 0.8, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _controller.forward().then((_) {
      if (mounted) widget.onAnimationComplete();
    });
  }

  @override
  void didUpdateWidget(covariant DoubleTapSeekOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.seconds != widget.seconds) {
      _controller.reset();
      _controller.forward().then((_) {
        if (mounted) widget.onAnimationComplete();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLeft = widget.side == DoubleTapSeekSide.left;
    final prefix = isLeft ? '-' : '+';

    return Align(
      alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
      child: FractionallySizedBox(
        widthFactor: 0.38,
        heightFactor: 0.85,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _opacity.value,
              child: Transform.scale(
                scale: _scale.value,
                child: child,
              ),
            );
          },
          child: CustomPaint(
            painter: _SeekArcPainter(
              isLeft: isLeft,
              color: AppColors.accent.withValues(alpha: 0.18),
              borderColor: AppColors.accent.withValues(alpha: 0.4),
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Chevron Wave
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: isLeft
                        ? [
                            const HugeIcon(icon: AppIcons.fastRewind, color: Colors.white, size: 36),
                          ]
                        : [
                            const HugeIcon(icon: AppIcons.fastForward, color: Colors.white, size: 36),
                          ],
                  ),
                  const SizedBox(height: 8),
                  // Glowing Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.8),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Text(
                      '$prefix${widget.seconds.abs()}s',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SeekArcPainter extends CustomPainter {
  _SeekArcPainter({
    required this.isLeft,
    required this.color,
    required this.borderColor,
  });

  final bool isLeft;
  final Color color;
  final Color borderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    if (isLeft) {
      path.moveTo(0, 0);
      path.lineTo(0, size.height);
      path.quadraticBezierTo(size.width * 1.0, size.height * 0.5, 0, 0);
    } else {
      path.moveTo(size.width, 0);
      path.lineTo(size.width, size.height);
      path.quadraticBezierTo(0, size.height * 0.5, size.width, 0);
    }

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant _SeekArcPainter oldDelegate) =>
      oldDelegate.isLeft != isLeft ||
      oldDelegate.color != color ||
      oldDelegate.borderColor != borderColor;
}
