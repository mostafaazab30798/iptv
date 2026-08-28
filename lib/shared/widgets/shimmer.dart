import 'package:flutter/material.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/core/platform/device_memory.dart';

/// Premium animated Shimmer container that drives a synchronized gradient sweep.
/// Wraps any skeleton widgets (like [ShimmerBox]) to give them a modern shimmering effect.
class Shimmer extends StatefulWidget {
  const Shimmer({
    super.key,
    required this.child,
    this.baseColor = const Color(0xFF14171D), // AppColors.bg2
    this.highlightColor = const Color(0xFF282F3E), // elevated lighter surface
    this.duration = const Duration(milliseconds: 1500),
    this.enabled = true,
  });

  final Widget child;
  final Color baseColor;
  final Color highlightColor;
  final Duration duration;
  final bool enabled;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (!widget.enabled || reduceMotion || DeviceMemory.isLowRamDevice) {
      return widget.child;
    }

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return ShaderMask(
            blendMode: BlendMode.srcATop,
            shaderCallback: (bounds) {
              return LinearGradient(
                begin: const Alignment(-1.0, -0.3),
                end: const Alignment(1.0, 0.3),
                colors: [
                  widget.baseColor,
                  widget.highlightColor,
                  widget.baseColor,
                ],
                stops: const [0.0, 0.5, 1.0],
                transform: _SlidingGradientTransform(
                  slidePercent: _controller.value,
                ),
              ).createShader(bounds);
            },
            child: child,
          );
        },
        child: widget.child,
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({required this.slidePercent});

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    final translation = bounds.width * (slidePercent * 3 - 1.5);
    return Matrix4.translationValues(translation, 0.0, 0.0);
  }
}

/// Primitive building block for constructing skeleton UI elements.
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 8,
    this.shape = BoxShape.rectangle,
    this.color,
    this.margin,
  });

  final double? width;
  final double? height;
  final double borderRadius;
  final BoxShape shape;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.bg2,
        shape: shape,
        borderRadius: shape == BoxShape.circle
            ? null
            : BorderRadius.circular(borderRadius),
      ),
    );
  }
}
