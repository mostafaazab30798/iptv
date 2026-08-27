import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/player/application/player_state.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/widgets/adaptive_glass.dart';
import 'package:iptv/shared/widgets/smart_channel_logo.dart';

/// Compact, non-interfering interactive playback controls overlay.
/// Positioned neatly at the top, center, and bottom to allow background gestures
/// on left/right screen edges without any interference, clutter, or layout overflow.
class PlayerControls extends StatelessWidget {
  const PlayerControls({
    super.key,
    required this.playerState,
    required this.onPlayPause,
    required this.onSeek,
    required this.onSeekRelative,
    required this.onVolumeChanged,
    required this.onToggleMute,
    required this.onNextChannel,
    required this.onPreviousChannel,
    required this.onCycleAspectRatio,
    required this.onSelectPlaybackRate,
    required this.onOpenAudioTracks,
    required this.onOpenSubtitles,
    required this.onToggleLock,
    required this.onOpenQuickSettings,
    required this.onToggleFullscreen,
    required this.onClose,
  });

  final PlayerState playerState;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<Duration> onSeekRelative;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onToggleMute;
  final VoidCallback onNextChannel;
  final VoidCallback onPreviousChannel;
  final VoidCallback onCycleAspectRatio;
  final ValueChanged<double> onSelectPlaybackRate;
  final VoidCallback onOpenAudioTracks;
  final VoidCallback onOpenSubtitles;
  final VoidCallback onToggleLock;
  final VoidCallback onOpenQuickSettings;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onClose;

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
  }

  String _getAspectRatioLabel(int index) => switch (index) {
        1 => 'Fill',
        2 => '16:9',
        3 => '4:3',
        _ => 'Fit',
      };

  @override
  Widget build(BuildContext context) {
    final isLive = playerState.isLive;
    final caps = playerState.capabilities;
    final source = playerState.source;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isNarrow = constraints.maxWidth < 600;
        final isWide = constraints.maxWidth >= 720;

        return Stack(
          fit: StackFit.expand,
          children: [
            // ── Compact Top Bar ──────────────────────────────────────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xD9000000), Colors.transparent],
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Row(
                    children: [
                      // Back button
                      _CompactGlassButton(
                        icon: AppIcons.arrowBack,
                        tooltip: 'Back',
                        size: 36,
                        iconSize: 17,
                        matchTextDirection: true,
                        onPressed: onClose,
                      ),
                      const SizedBox(width: 10),

                      // Channel Logo (if present)
                      if (source != null) ...[
                        SmartChannelLogo(
                          channelName: source.title,
                          logoUrl: source.logoUrl,
                          width: 32,
                          height: 32,
                          borderRadius: BorderRadius.circular(6),
                          fit: BoxFit.contain,
                        ),
                        const SizedBox(width: 8),
                      ],

                      // Title + Program Subtitle
                      if (source != null)
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                source.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                source.currentProgramTitle ??
                                    (playerState.metrics.videoParams ?? (isLive ? 'Live Broadcast' : 'Video on Demand')),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        )
                      else
                        const Spacer(),

                      const SizedBox(width: 6),

                      // Playback Speed (Only shown on wider screens in header, always in quick settings)
                      if (!isLive && isWide) ...[
                        _CompactGlassActionButton(
                          icon: AppIcons.speed,
                          label: '${playerState.playbackRate}x',
                          tooltip: 'Playback Speed',
                          onPressed: () {
                            final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
                            final nextIdx = (speeds.indexOf(playerState.playbackRate) + 1) % speeds.length;
                            onSelectPlaybackRate(speeds[nextIdx]);
                          },
                        ),
                        const SizedBox(width: 6),
                      ],

                      // Aspect Ratio (Only shown on wider screens in header, always in quick settings)
                      if (caps.aspectRatio && isWide) ...[
                        _CompactGlassActionButton(
                          icon: AppIcons.aspectRatio,
                          label: _getAspectRatioLabel(playerState.aspectRatioIndex),
                          tooltip: 'Aspect Ratio',
                          onPressed: onCycleAspectRatio,
                        ),
                        const SizedBox(width: 6),
                      ],

                      // Screen Lock Button
                      _CompactGlassButton(
                        icon: AppIcons.lock,
                        tooltip: 'Lock Screen',
                        size: 36,
                        iconSize: 17,
                        onPressed: onToggleLock,
                      ),
                      const SizedBox(width: 6),

                      // Quick Settings Button (Houses Speed, Ratio, Audio, Subtitles, Sleep timer)
                      _CompactGlassButton(
                        icon: AppIcons.tune,
                        tooltip: 'Quick Settings',
                        size: 36,
                        iconSize: 17,
                        onPressed: onOpenQuickSettings,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ── Compact Center Playback Toolbar ────────────────────────────
            Align(
              alignment: Alignment.center,
              child: Directionality(
                textDirection: TextDirection.ltr,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Replay 10s
                    _CompactGlassButton(
                      icon: AppIcons.replay10,
                      tooltip: context.l10n.playerReplay10,
                      size: 46,
                      iconSize: 24,
                      onPressed: () => onSeekRelative(const Duration(seconds: -10)),
                    ),
                    const SizedBox(width: 16),

                    // Main Play / Pause Button
                    GestureDetector(
                      onTap: onPlayPause,
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.accent,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.accent.withValues(alpha: 0.4),
                              blurRadius: 18,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: Center(
                          child: HugeIcon(
                            icon: playerState.isPlaying ? AppIcons.pause : AppIcons.play,
                            color: Colors.black,
                            size: 32,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),

                    // Forward 10s
                    _CompactGlassButton(
                      icon: AppIcons.forward10,
                      tooltip: context.l10n.playerForward10,
                      size: 46,
                      iconSize: 24,
                      onPressed: () => onSeekRelative(const Duration(seconds: 10)),
                    ),
                  ],
                ),
              ),
            ),

            // ── Compact Bottom Bar ─────────────────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.fromLTRB(14, 4, 14, 10),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xEB000000), Colors.transparent],
                  ),
                ),
                child: SafeArea(
                  top: false,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Timeline progress bar (if VOD)
                      if (!isLive && playerState.duration > Duration.zero) ...[
                        Builder(
                          builder: (context) {
                            final maxSecs = playerState.duration.inSeconds.toDouble();
                            final posSecs = playerState.position.inSeconds.toDouble().clamp(0.0, maxSecs);
                            final bufSecs = (playerState.bufferedFraction * maxSecs).clamp(0.0, maxSecs);

                            return Directionality(
                              textDirection: TextDirection.ltr,
                              child: Row(
                                children: [
                                  // Elapsed Time Glass Chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.09),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.14), width: 0.6),
                                    ),
                                    child: Text(
                                      _formatDuration(playerState.position),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        fontFeatures: [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Sleek Modern Scrubbing Bar
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        trackShape: const _ModernPlayerSliderTrackShape(),
                                        thumbShape: const _ModernPlayerSliderThumbShape(),
                                        overlayShape: SliderComponentShape.noOverlay,
                                        activeTrackColor: AppColors.accent,
                                        secondaryActiveTrackColor: Colors.white.withValues(alpha: 0.35),
                                        inactiveTrackColor: Colors.white.withValues(alpha: 0.16),
                                        thumbColor: AppColors.accent,
                                        trackHeight: 4.5,
                                      ),
                                      child: Slider(
                                        value: posSecs,
                                        secondaryTrackValue: bufSecs,
                                        max: maxSecs,
                                        onChanged: (v) => onSeek(Duration(seconds: v.toInt())),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),

                                  // Total Duration Glass Chip
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.09),
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.white.withValues(alpha: 0.14), width: 0.6),
                                    ),
                                    child: Text(
                                      _formatDuration(playerState.duration),
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.75),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        fontFeatures: const [FontFeature.tabularFigures()],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],

                      // Bottom utility controls row
                      Row(
                        children: [
                          if (isLive) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                borderRadius: BorderRadius.circular(4),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.redAccent.withValues(alpha: 0.4),
                                    blurRadius: 5,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  const Text(
                                    'LIVE',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 9.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],

                          if (caps.audioTracks && playerState.availableAudioTracks.isNotEmpty)
                            _CompactGlassButton(
                              icon: AppIcons.audioTrack,
                              tooltip: 'Audio Tracks',
                              size: 32,
                              iconSize: 16,
                              onPressed: onOpenAudioTracks,
                            ),
                          if (caps.subtitles && playerState.availableSubtitleTracks.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            _CompactGlassButton(
                              icon: AppIcons.subtitles,
                              tooltip: 'Subtitles',
                              size: 32,
                              iconSize: 16,
                              onPressed: onOpenSubtitles,
                            ),
                          ],

                          const Spacer(),

                          // Previous Channel / Episode
                          _CompactGlassButton(
                            icon: AppIcons.previous,
                            flipIcon: context.isRtl,
                            tooltip: context.l10n.playerPreviousChannel,
                            size: 32,
                            iconSize: 16,
                            onPressed: onPreviousChannel,
                          ),
                          const SizedBox(width: 6),

                          // Next Channel / Episode
                          _CompactGlassButton(
                            icon: AppIcons.next,
                            flipIcon: context.isRtl,
                            tooltip: context.l10n.playerNextChannel,
                            size: 32,
                            iconSize: 16,
                            onPressed: onNextChannel,
                          ),
                          const SizedBox(width: 6),

                          // Volume (slider shown when screen is not extremely narrow)
                          if (caps.volume) ...[
                            IconButton(
                              icon: HugeIcon(
                                icon: playerState.isMuted || playerState.volume == 0.0
                                    ? AppIcons.volumeMute
                                    : AppIcons.volumeHigh,
                                color: Colors.white,
                                size: 19,
                              ),
                              tooltip: playerState.isMuted ? 'Unmute' : 'Mute',
                              onPressed: onToggleMute,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                            ),
                            if (!isNarrow)
                              SizedBox(
                                width: 75,
                                child: Directionality(
                                  textDirection: TextDirection.ltr,
                                  child: SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      activeTrackColor: Colors.white,
                                      inactiveTrackColor: Colors.white24,
                                      thumbColor: Colors.white,
                                      thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 4),
                                      trackHeight: 2.5,
                                    ),
                                    child: Slider(
                                      value: playerState.isMuted ? 0.0 : playerState.volume,
                                      onChanged: onVolumeChanged,
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(width: 4),
                          ],

                          // Fullscreen — icon follows controller flag only (not orientation).
                          if (caps.fullscreen) ...[
                            _CompactGlassButton(
                              icon: playerState.isFullscreen
                                  ? AppIcons.exitFullscreen
                                  : AppIcons.fullscreen,
                              tooltip: playerState.isFullscreen
                                  ? 'Exit Fullscreen'
                                  : 'Fullscreen',
                              size: 32,
                              iconSize: 18,
                              onPressed: onToggleFullscreen,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CompactGlassButton extends StatelessWidget {
  const _CompactGlassButton({
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 36,
    this.iconSize = 17,
    this.flipIcon = false,
    this.matchTextDirection = false,
  });

  final dynamic icon;
  final VoidCallback onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;
  final bool flipIcon;
  final bool matchTextDirection;

  @override
  Widget build(BuildContext context) {
    final isRtl = Directionality.maybeOf(context) == TextDirection.rtl;
    final shouldFlip = flipIcon || (matchTextDirection && isRtl);

    Widget iconWidget = HugeIcon(icon: icon as List<List<dynamic>>, color: Colors.white, size: iconSize);
    if (shouldFlip) {
      iconWidget = Transform.flip(flipX: true, child: iconWidget);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(size / 2),
      child: AdaptiveGlass(
        sigma: 8,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.16), width: 0.8),
          ),
          child: IconButton(
            icon: iconWidget,
            tooltip: tooltip,
            onPressed: onPressed,
            padding: EdgeInsets.zero,
            constraints: BoxConstraints(minWidth: size, minHeight: size),
          ),
        ),
      ),
    );
  }
}

class _CompactGlassActionButton extends StatelessWidget {
  const _CompactGlassActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.tooltip,
  });

  final dynamic icon;
  final String label;
  final VoidCallback onPressed;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: AdaptiveGlass(
        sigma: 8,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.white.withValues(alpha: 0.16), width: 0.8),
          ),
          child: InkWell(
            onTap: onPressed,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  HugeIcon(icon: icon as List<List<dynamic>>, color: Colors.white, size: 13),
                  const SizedBox(width: 4),
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
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

/// Modern custom slider track shape that draws rounded inactive, buffered, and active tracks.
class _ModernPlayerSliderTrackShape extends SliderTrackShape with BaseSliderTrackShape {
  const _ModernPlayerSliderTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final trackHeight = sliderTheme.trackHeight ?? 4.5;
    final trackLeft = offset.dx;
    final trackTop = offset.dy + (parentBox.size.height - trackHeight) / 2;
    final trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required TextDirection textDirection,
    required Offset thumbCenter,
    Offset? secondaryOffset,
    bool isDiscrete = false,
    bool isEnabled = false,
    double additionalActiveTrackHeight = 0,
  }) {
    final trackRect = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );

    final radius = Radius.circular(trackRect.height / 2);

    // 1. Inactive background track
    final inactivePaint = Paint()
      ..color = sliderTheme.inactiveTrackColor ?? const Color(0x29FFFFFF);
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(trackRect, radius),
      inactivePaint,
    );

    // 2. Buffered / Secondary track
    if (secondaryOffset != null && secondaryOffset.dx > trackRect.left) {
      final bufferWidth = (secondaryOffset.dx - trackRect.left).clamp(0.0, trackRect.width);
      final bufferRect = Rect.fromLTWH(trackRect.left, trackRect.top, bufferWidth, trackRect.height);
      final bufferPaint = Paint()
        ..color = sliderTheme.secondaryActiveTrackColor ?? const Color(0x59FFFFFF);
      context.canvas.drawRRect(
        RRect.fromRectAndRadius(bufferRect, radius),
        bufferPaint,
      );
    }

    // 3. Active played track
    final activeWidth = (thumbCenter.dx - trackRect.left).clamp(0.0, trackRect.width);
    if (activeWidth > 0) {
      final activeRect = Rect.fromLTWH(trackRect.left, trackRect.top, activeWidth, trackRect.height);
      final activePaint = Paint()
        ..color = sliderTheme.activeTrackColor ?? AppColors.accent;
      context.canvas.drawRRect(
        RRect.fromRectAndRadius(activeRect, radius),
        activePaint,
      );
    }
  }
}

/// Sleek modern glowing thumb with radiant aura, vibrant core, and white center pin.
class _ModernPlayerSliderThumbShape extends SliderComponentShape {
  const _ModernPlayerSliderThumbShape();

  static const double thumbRadius = 6.0;
  static const double glowRadius = 10.0;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => const Size.fromRadius(glowRadius);

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;
    final accentColor = sliderTheme.thumbColor ?? AppColors.accent;

    // 1. Subtle Outer Glow Aura
    final glowPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, glowRadius, glowPaint);

    // 2. Main Thumb Circle (Accent Color)
    final mainPaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, thumbRadius, mainPaint);

    // 3. White Center Pin Dot for crisp contrast
    final centerDotPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, thumbRadius * 0.42, centerDotPaint);
  }
}
