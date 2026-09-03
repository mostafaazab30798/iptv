import 'package:flutter/material.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_motion.dart';
import 'package:iptv/core/platform/device_memory.dart';
import 'package:iptv/core/platform/platform_service.dart';

/// The "cinematic midnight" backdrop shared by the sign-in and OTP screens.
///
/// A near-black base is lit by two restrained radial glows — cool teal/cyan
/// leading, a faint warm counterpoint trailing — that drift a few percent
/// over a very long cycle. The motion is intentionally almost imperceptible;
/// it exists so the screen doesn't feel static, never to decorate or compete
/// with the form. Under reduced motion / TV / low-RAM the gradients hold still.
class AmbientBackground extends StatefulWidget {
  const AmbientBackground({super.key, required this.child});

  final Widget child;

  @override
  State<AmbientBackground> createState() => _AmbientBackgroundState();
}

class _AmbientBackgroundState extends State<AmbientBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  bool _started = false;
  bool _staticOnly = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppMotion.ambientDrift,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final platform = PlatformService.instance;
    _staticOnly = reduceMotion ||
        DeviceMemory.isLowRamDevice ||
        platform.isAndroidTv;
    if (_staticOnly) return;
    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildGlows({required double t}) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Align(
          alignment: Alignment(-0.85 + t * 0.14, -1.0 + t * 0.1),
          child: _Glow(
            color: AppColors.accent.withValues(alpha: 0.14),
            diameter: 520,
          ),
        ),
        Align(
          alignment: Alignment(0.2 - t * 0.08, -0.15 + t * 0.05),
          child: _Glow(
            color: const Color(0xFF5B8CFF).withValues(alpha: 0.05),
            diameter: 340,
          ),
        ),
        Align(
          alignment: Alignment(1.05 - t * 0.10, 1.1 - t * 0.06),
          child: _Glow(
            color: const Color(0xFFB98A55).withValues(alpha: 0.055),
            diameter: 440,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppColors.bg0),
      child: Stack(
        fit: StackFit.expand,
        children: [
          RepaintBoundary(
            child: _staticOnly
                ? _buildGlows(t: 0.35)
                : AnimatedBuilder(
                    animation: _controller,
                    builder: (context, _) {
                      final t =
                          Curves.easeInOut.transform(_controller.value);
                      return _buildGlows(t: t);
                    },
                  ),
          ),
          // Faint top-to-bottom vignette keeps the form region readable.
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0x00000000), Color(0x33000000)],
              ),
            ),
          ),
          widget.child,
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  const _Glow({required this.color, required this.diameter});

  final Color color;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}
