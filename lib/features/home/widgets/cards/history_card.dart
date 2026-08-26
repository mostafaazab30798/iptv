import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_radius.dart';
import 'package:iptv/domain/entities/watch_history.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/focus/focusable_card.dart';
import 'package:iptv/shared/widgets/cached_image.dart';

class HistoryCard extends StatelessWidget {
  const HistoryCard({
    super.key,
    required this.entry,
    required this.onTap,
    this.width = 190,
    this.height = 140,
  });

  final WatchHistoryEntry entry;
  final VoidCallback onTap;
  final double width;
  final double height;

  String _formatRemaining(BuildContext context) {
    if (entry.durationSecs == null || entry.durationSecs! <= 0) {
      if (entry.positionSecs > 0) {
        final m = (entry.positionSecs / 60).floor();
        final s = entry.positionSecs % 60;
        final timeStr = '\u200E${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}\u200E';
        return context.l10n.historyResumeAt(timeStr);
      }
      return context.l10n.historyResumePlayback;
    }

    final remainingSecs = entry.durationSecs! - entry.positionSecs;
    if (remainingSecs <= 0) {
      return context.l10n.historyCompleted;
    }

    final m = (remainingSecs / 60).floor();
    if (m >= 60) {
      final h = (m / 60).floor();
      final remM = m % 60;
      return context.l10n.historyTimeLeftHoursMinutes(h, remM);
    }
    return context.l10n.historyTimeLeftMinutes(m);
  }

  String _typeLabel(BuildContext context) {
    switch (entry.type) {
      case WatchHistoryType.channel:
        return context.l10n.historyTypeLive;
      case WatchHistoryType.movie:
        return context.l10n.historyTypeMovie;
      case WatchHistoryType.episode:
        return context.l10n.historyTypeSeries;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = entry.progressFraction;

    return SizedBox(
      width: width,
      height: height,
      child: FocusableCard(
        onTap: onTap,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedImage(
                    imageUrl: entry.imageUrl,
                    fit: BoxFit.cover,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
                    fallbackIcon: AppIcons.play,
                  ),
                  // Gradient shadow
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.card)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withAlpha(80),
                          Colors.transparent,
                          Colors.black.withAlpha(120),
                        ],
                      ),
                    ),
                  ),
                  // Type badge (top left)
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(190),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(
                          color: entry.type == WatchHistoryType.episode
                              ? AppColors.accentDim
                              : (entry.type == WatchHistoryType.movie ? AppColors.accent : AppColors.warning),
                          width: 0.7,
                        ),
                      ),
                      child: Text(
                        _typeLabel(context),
                        style: TextStyle(
                          color: entry.type == WatchHistoryType.episode
                              ? AppColors.accentDim
                              : (entry.type == WatchHistoryType.movie ? AppColors.accent : AppColors.warning),
                          fontSize: 8.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  // Center play button
                  Center(
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withAlpha(220),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withAlpha(100),
                            blurRadius: 8,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: HugeIcon(
                          icon: AppIcons.play,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Progress Bar
            if (progress > 0)
              Directionality(
                textDirection: TextDirection.ltr,
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: AppColors.bg3,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.accent),
                  minHeight: 3.5,
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    entry.name,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const HugeIcon(icon: AppIcons.time, size: 10, color: AppColors.textSecondary),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          _formatRemaining(context),
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

