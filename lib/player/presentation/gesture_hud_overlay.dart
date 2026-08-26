import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';

/// Glassmorphic HUD overlay for Volume and Brightness vertical swipe gestures.
class GestureLevelHud extends StatelessWidget {
  const GestureLevelHud({
    super.key,
    required this.icon,
    required this.value, // 0.0 to 1.0
    required this.label,
  });

  final dynamic icon;
  final double value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final percentage = (clamped * 100).round();

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.15),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HugeIcon(icon: icon as List<List<dynamic>>, color: Colors.white, size: 36),
                const SizedBox(height: 12),
                SizedBox(
                  width: 140,
                  height: 6,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: LinearProgressIndicator(
                        value: clamped,
                        backgroundColor: Colors.white24,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$percentage%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Glassmorphic HUD overlay for Horizontal Seek Scrub gesture.
class SeekScrubHud extends StatelessWidget {
  const SeekScrubHud({
    super.key,
    required this.targetPosition,
    required this.totalDuration,
    required this.offsetSeconds,
  });

  final Duration targetPosition;
  final Duration totalDuration;
  final int offsetSeconds;

  String _formatDuration(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  @override
  Widget build(BuildContext context) {
    final isForward = offsetSeconds >= 0;
    final offsetStr = '${isForward ? '+' : ''}${offsetSeconds}s';

    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.75),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.5),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.accent.withValues(alpha: 0.25),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    HugeIcon(
                      icon: isForward ? AppIcons.fastForward : AppIcons.fastRewind,
                      color: AppColors.accent,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      offsetStr,
                      style: TextStyle(
                        color: isForward ? AppColors.accent : Colors.orangeAccent,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${_formatDuration(targetPosition)} / ${_formatDuration(totalDuration)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
