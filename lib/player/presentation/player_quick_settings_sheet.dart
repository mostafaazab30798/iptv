import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/player/application/player_state.dart';
import 'package:iptv/player/domain/enums/playback_buffer_mode.dart';

typedef SleepTimerCallback = void Function(Duration? duration, [String? label]);

/// Ultra-modern, compact, and minimal glassmorphic playback settings bottom sheet.
class PlayerQuickSettingsSheet extends StatefulWidget {
  const PlayerQuickSettingsSheet({
    super.key,
    required this.playerState,
    required this.onSelectPlaybackRate,
    required this.onSelectAspectRatio,
    required this.onOpenAudioTracks,
    required this.onOpenSubtitles,
    required this.onSelectBufferMode,
    required this.onSetSleepTimer,
    this.activeSleepLabel,
    this.activeSleepDuration,
  });

  final PlayerState playerState;
  final ValueChanged<double> onSelectPlaybackRate;
  final ValueChanged<int> onSelectAspectRatio;
  final VoidCallback onOpenAudioTracks;
  final VoidCallback onOpenSubtitles;
  final ValueChanged<PlaybackBufferMode> onSelectBufferMode;
  final SleepTimerCallback onSetSleepTimer;
  final String? activeSleepLabel;
  final Duration? activeSleepDuration;

  static Future<void> show(
    BuildContext context, {
    required PlayerState playerState,
    required ValueChanged<double> onSelectPlaybackRate,
    required ValueChanged<int> onSelectAspectRatio,
    required VoidCallback onOpenAudioTracks,
    required VoidCallback onOpenSubtitles,
    required ValueChanged<PlaybackBufferMode> onSelectBufferMode,
    required SleepTimerCallback onSetSleepTimer,
    String? activeSleepLabel,
    Duration? activeSleepDuration,
  }) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => PlayerQuickSettingsSheet(
        playerState: playerState,
        onSelectPlaybackRate: onSelectPlaybackRate,
        onSelectAspectRatio: onSelectAspectRatio,
        onOpenAudioTracks: onOpenAudioTracks,
        onOpenSubtitles: onOpenSubtitles,
        onSelectBufferMode: onSelectBufferMode,
        onSetSleepTimer: onSetSleepTimer,
        activeSleepLabel: activeSleepLabel,
        activeSleepDuration: activeSleepDuration,
      ),
    );
  }

  @override
  State<PlayerQuickSettingsSheet> createState() => _PlayerQuickSettingsSheetState();
}

class _PlayerQuickSettingsSheetState extends State<PlayerQuickSettingsSheet> {
  late double _playbackRate;
  late int _aspectRatioIndex;
  late PlaybackBufferMode _bufferMode;
  Duration? _activeSleepDuration;
  String? _activeSleepLabel;

  @override
  void initState() {
    super.initState();
    _playbackRate = widget.playerState.playbackRate;
    _aspectRatioIndex = widget.playerState.aspectRatioIndex;
    _bufferMode = widget.playerState.bufferMode;
    _activeSleepDuration = widget.activeSleepDuration;
    _activeSleepLabel = widget.activeSleepLabel;
  }

  String _formatDurationText(Duration d) {
    if (d.inHours > 0) {
      final mins = d.inMinutes.remainder(60);
      return '${d.inHours}h ${mins > 0 ? '${mins}m' : ''}';
    }
    return '${d.inMinutes}m';
  }

  void _handleSelectSleepTimer(Duration? duration, [String? label]) {
    widget.onSetSleepTimer(duration, label);
    setState(() {
      _activeSleepDuration = duration;
      _activeSleepLabel = label;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLive = widget.playerState.isLive;
    final caps = widget.playerState.capabilities;
    final isRtl = Directionality.maybeOf(context) == TextDirection.rtl;

    final remaining = widget.playerState.duration > widget.playerState.position
        ? widget.playerState.duration - widget.playerState.position
        : Duration.zero;
    final hasEndOfShow = !isLive && remaining.inSeconds > 15;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.88,
          ),
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          decoration: BoxDecoration(
            color: const Color(0xF0101118),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.12),
              width: 1,
            ),
          ),
          child: SafeArea(
            top: false,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Drag Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 2. Header
                  Row(
                    children: [
                      const HugeIcon(icon: AppIcons.tune, color: AppColors.accent, size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'Playback Settings',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const HugeIcon(icon: AppIcons.close, color: Colors.white60, size: 18),
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // 3. Playback Speed (VOD / Catch-up)
                  if (!isLive) ...[
                    const _SectionLabel(title: 'PLAYBACK SPEED'),
                    const SizedBox(height: 6),
                    _SegmentedTrack(
                      children: [0.5, 0.75, 1.0, 1.25, 1.5, 2.0].map((rate) {
                        final isSelected = _playbackRate == rate;
                        return Expanded(
                          child: _SegmentPill(
                            label: '${rate}x',
                            isSelected: isSelected,
                            onTap: () {
                              setState(() => _playbackRate = rate);
                              widget.onSelectPlaybackRate(rate);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 4. Aspect Ratio
                  if (caps.aspectRatio) ...[
                    const _SectionLabel(title: 'ASPECT RATIO'),
                    const SizedBox(height: 6),
                    _SegmentedTrack(
                      children: [
                        (0, 'Fit'),
                        (1, 'Fill'),
                        (2, '16:9'),
                        (3, '4:3'),
                      ].map((item) {
                        final isSelected = _aspectRatioIndex == item.$1;
                        return Expanded(
                          child: _SegmentPill(
                            label: item.$2,
                            isSelected: isSelected,
                            onTap: () {
                              setState(() => _aspectRatioIndex = item.$1);
                              widget.onSelectAspectRatio(item.$1);
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 5. Audio & Subtitles
                  if (caps.audioTracks || caps.subtitles) ...[
                    Row(
                      children: [
                        if (caps.audioTracks)
                          Expanded(
                            child: _QuickActionCard(
                              icon: AppIcons.audioTrack,
                              label: 'Audio',
                              value: widget.playerState.currentAudioTrack?.title ?? 'Default',
                              isRtl: isRtl,
                              onTap: () {
                                Navigator.of(context).pop();
                                widget.onOpenAudioTracks();
                              },
                            ),
                          ),
                        if (caps.audioTracks && caps.subtitles) const SizedBox(width: 8),
                        if (caps.subtitles)
                          Expanded(
                            child: _QuickActionCard(
                              icon: AppIcons.subtitles,
                              label: 'Subtitles',
                              value: widget.playerState.currentSubtitleTrack?.title ?? 'Off',
                              isRtl: isRtl,
                              onTap: () {
                                Navigator.of(context).pop();
                                widget.onOpenSubtitles();
                              },
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),
                  ],

                  // 6. Buffer Mode
                  const _SectionLabel(title: 'BUFFER PROFILE'),
                  const SizedBox(height: 6),
                  _SegmentedTrack(
                    children: [
                      (PlaybackBufferMode.lowLatency, 'Low Latency'),
                      (PlaybackBufferMode.balanced, 'Balanced'),
                      (PlaybackBufferMode.stability, 'Stability'),
                    ].map((entry) {
                      final isSelected = _bufferMode == entry.$1;
                      return Expanded(
                        child: _SegmentPill(
                          label: entry.$2,
                          isSelected: isSelected,
                          onTap: () {
                            setState(() => _bufferMode = entry.$1);
                            widget.onSelectBufferMode(entry.$1);
                          },
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),

                  // 7. Sleep Timer Section (Integrated Inline)
                  Row(
                    children: [
                      const _SectionLabel(title: 'SLEEP TIMER'),
                      const Spacer(),
                      if (_activeSleepDuration != null || _activeSleepLabel != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.accent.withValues(alpha: 0.4), width: 0.8),
                          ),
                          child: Text(
                            _activeSleepLabel ?? '${_activeSleepDuration!.inMinutes}m active',
                            style: const TextStyle(
                              color: AppColors.accent,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Until End of Show Card (when VOD/Series/Movies)
                  if (hasEndOfShow) ...[
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          if (_activeSleepLabel == 'Until End of Show') {
                            _handleSelectSleepTimer(null);
                          } else {
                            _handleSelectSleepTimer(remaining, 'Until End of Show');
                          }
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                _activeSleepLabel == 'Until End of Show'
                                    ? AppColors.accent.withValues(alpha: 0.25)
                                    : AppColors.accent.withValues(alpha: 0.12),
                                Colors.white.withValues(alpha: 0.04),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _activeSleepLabel == 'Until End of Show'
                                  ? AppColors.accent
                                  : AppColors.accent.withValues(alpha: 0.3),
                              width: _activeSleepLabel == 'Until End of Show' ? 1.5 : 1.0,
                            ),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.accent.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: HugeIcon(icon: AppIcons.play, color: AppColors.accent, size: 16),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Until End of Show',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${_formatDurationText(remaining)} remaining · Closes player upon finish',
                                      style: const TextStyle(
                                        color: Colors.white60,
                                        fontSize: 10.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_activeSleepLabel == 'Until End of Show')
                                const HugeIcon(icon: AppIcons.check, color: AppColors.accent, size: 18),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],

                  // Preset Timers Grid
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      // Off Pill
                      _TimerPill(
                        label: 'Off',
                        isSelected: _activeSleepDuration == null && _activeSleepLabel == null,
                        onTap: () => _handleSelectSleepTimer(null),
                      ),
                      ...[15, 30, 45, 60, 90, 120].map((minutes) {
                        final isSelected = _activeSleepDuration?.inMinutes == minutes && _activeSleepLabel == null;
                        return _TimerPill(
                          label: minutes >= 60 && minutes % 60 == 0
                              ? '${minutes ~/ 60} ${minutes ~/ 60 == 1 ? 'hr' : 'hrs'}'
                              : '$minutes m',
                          isSelected: isSelected,
                          onTap: () => _handleSelectSleepTimer(Duration(minutes: minutes)),
                        );
                      }),
                    ],
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: Colors.white54,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.6,
      ),
    );
  }
}

class _SegmentedTrack extends StatelessWidget {
  const _SegmentedTrack({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
          width: 0.8,
        ),
      ),
      child: Row(
        children: children,
      ),
    );
  }
}

class _SegmentPill extends StatelessWidget {
  const _SegmentPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white70,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class _TimerPill extends StatelessWidget {
  const _TimerPill({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.accent
                : Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isSelected
                  ? AppColors.accent
                  : Colors.white.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.black : Colors.white,
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.isRtl = false,
  });

  final dynamic icon;
  final String label;
  final String value;
  final VoidCallback onTap;
  final bool isRtl;

  @override
  Widget build(BuildContext context) {
    Widget chevron = const HugeIcon(
      icon: AppIcons.chevronRight,
      color: Colors.white38,
      size: 16,
    );
    if (isRtl) {
      chevron = Transform.flip(flipX: true, child: chevron);
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          height: 48,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.08),
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              HugeIcon(
                icon: icon as List<List<dynamic>>,
                color: AppColors.accent,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                    ),
                    Text(
                      value,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10.5,
                        fontWeight: FontWeight.w400,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              chevron,
            ],
          ),
        ),
      ),
    );
  }
}
