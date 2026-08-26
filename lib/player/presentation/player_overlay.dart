import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_volume_controller/flutter_volume_controller.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/player/application/player_state.dart';
import 'package:iptv/player/domain/entities/player_track.dart';
import 'package:iptv/player/domain/enums/playback_buffer_mode.dart';
import 'package:iptv/player/presentation/audio_track_selector.dart';
import 'package:iptv/player/presentation/diagnostics_overlay.dart';
import 'package:iptv/player/presentation/double_tap_seek_overlay.dart';
import 'package:iptv/player/presentation/gesture_hud_overlay.dart';
import 'package:iptv/player/presentation/player_controls.dart';
import 'package:iptv/player/presentation/player_quick_settings_sheet.dart';
import 'package:iptv/player/presentation/software_decode_badge.dart';
import 'package:iptv/player/presentation/subtitle_selector.dart';
import 'package:iptv/core/platform/platform_service.dart';
import 'package:screen_brightness/screen_brightness.dart';

/// Clean and compact overlay shell managing touch gestures (double-tap 10s seek, vertical/horizontal drags),
/// screen lock, diagnostics HUD, quick settings, and keyboard / D-pad inputs.
class PlayerOverlay extends StatefulWidget {
  const PlayerOverlay({
    super.key,
    required this.playerState,
    required this.onPlayPause,
    required this.onSeek,
    required this.onSeekRelative,
    required this.onSelectPlaybackRate,
    required this.onVolumeChanged,
    required this.onToggleMute,
    required this.onNextChannel,
    required this.onPreviousChannel,
    required this.onCycleAspectRatio,
    required this.onSelectAspectRatio,
    required this.onSelectAudioTrack,
    required this.onSelectSubtitleTrack,
    required this.onSelectBufferMode,
    required this.onToggleLock,
    required this.onToggleFullscreen,
    required this.onClose,
  });

  final PlayerState playerState;
  final VoidCallback onPlayPause;
  final ValueChanged<Duration> onSeek;
  final ValueChanged<Duration> onSeekRelative;
  final ValueChanged<double> onSelectPlaybackRate;
  final ValueChanged<double> onVolumeChanged;
  final VoidCallback onToggleMute;
  final VoidCallback onNextChannel;
  final VoidCallback onPreviousChannel;
  final VoidCallback onCycleAspectRatio;
  final ValueChanged<int> onSelectAspectRatio;
  final ValueChanged<PlayerAudioTrack> onSelectAudioTrack;
  final ValueChanged<PlayerSubtitleTrack> onSelectSubtitleTrack;
  final ValueChanged<PlaybackBufferMode> onSelectBufferMode;
  final VoidCallback onToggleLock;
  final VoidCallback onToggleFullscreen;
  final VoidCallback onClose;

  @override
  State<PlayerOverlay> createState() => _PlayerOverlayState();
}

class _PlayerOverlayState extends State<PlayerOverlay> {
  Timer? _hideControlsTimer;
  Timer? _tapDebounceTimer;
  bool _controlsVisible = true;
  bool _showDiagnostics = false;
  final FocusNode _focusNode = FocusNode();

  // Double-tap seek state
  DoubleTapSeekSide? _activeSeekSide;
  int _seekCumulativeSeconds = 0;
  Timer? _seekResetTimer;

  // Gesture HUD states
  bool _isDragging = false;
  bool _isVolumeDrag = false;
  bool _isBrightnessDrag = false;
  bool _isScrubDrag = false;
  double _brightnessLevel = 1.0;
  double _currentVolume = 1.0;
  Duration _scrubStartPosition = Duration.zero;
  int _scrubOffsetSeconds = 0;
  Timer? _hudDismissTimer;

  // Sleep timer
  Timer? _activeSleepTimer;
  Duration? _activeSleepDuration;
  String? _activeSleepLabel;

  @override
  void initState() {
    super.initState();
    _currentVolume = widget.playerState.volume;
    _scheduleHide();
    _initDeviceLevels();
  }

  Future<void> _initDeviceLevels() async {
    final isMobile = !PlatformService.instance.isWindows && !PlatformService.instance.isWeb;
    if (isMobile) {
      try {
        final brightness = await ScreenBrightness.instance.application;
        if (mounted) {
          setState(() => _brightnessLevel = brightness.clamp(0.01, 1.0));
        }
      } catch (_) {}
    }

    try {
      final vol = await FlutterVolumeController.getVolume();
      if (vol != null && mounted) {
        setState(() => _currentVolume = vol.clamp(0.0, 1.0));
      }
    } catch (_) {}
  }

  @override
  void didUpdateWidget(PlayerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_isDragging) {
      _currentVolume = widget.playerState.volume;
    }
  }

  void _scheduleHide() {
    _hideControlsTimer?.cancel();
    _hideControlsTimer = Timer(const Duration(seconds: 4), () {
      if (mounted && !widget.playerState.isLocked) {
        setState(() => _controlsVisible = false);
      }
    });
  }

  void _showOverlay() {
    if (mounted && !widget.playerState.isLocked) {
      setState(() => _controlsVisible = true);
      _scheduleHide();
    }
  }

  void _toggleOverlay() {
    if (widget.playerState.isLocked) return;
    if (_controlsVisible) {
      _hideControlsTimer?.cancel();
      setState(() => _controlsVisible = false);
    } else {
      _showOverlay();
    }
  }

  void _showSeekRippleOnly(DoubleTapSeekSide side) {
    if (widget.playerState.isLive) return;

    _seekResetTimer?.cancel();
    final step = side == DoubleTapSeekSide.left ? -10 : 10;

    setState(() {
      _activeSeekSide = side;
      _seekCumulativeSeconds = step;
    });

    _seekResetTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _activeSeekSide = null;
          _seekCumulativeSeconds = 0;
        });
      }
    });
  }

  void _triggerSeekRipple(DoubleTapSeekSide side) {
    if (widget.playerState.isLive) return;

    _seekResetTimer?.cancel();
    final step = side == DoubleTapSeekSide.left ? -10 : 10;

    setState(() {
      if (_activeSeekSide == side) {
        _seekCumulativeSeconds += step;
      } else {
        _activeSeekSide = side;
        _seekCumulativeSeconds = step;
      }
    });

    widget.onSeekRelative(Duration(seconds: step));

    _seekResetTimer = Timer(const Duration(milliseconds: 900), () {
      if (mounted) {
        setState(() {
          _activeSeekSide = null;
          _seekCumulativeSeconds = 0;
        });
      }
    });
  }

  void _handleTapUp(TapUpDetails details, BoxConstraints constraints) {
    if (widget.playerState.isLocked) return;

    // Debounce single tap slightly so double-tap takes precedence
    _tapDebounceTimer?.cancel();
    _tapDebounceTimer = Timer(const Duration(milliseconds: 220), () {
      if (mounted) {
        _toggleOverlay();
      }
    });
  }

  void _handleDoubleTapDown(TapDownDetails details, BoxConstraints constraints) {
    if (widget.playerState.isLocked) return;
    _tapDebounceTimer?.cancel();

    // On Desktop (Windows / Linux / macOS), double click anywhere toggles fullscreen (standard player UX)
    final isDesktop = Theme.of(context).platform == TargetPlatform.windows ||
        Theme.of(context).platform == TargetPlatform.linux ||
        Theme.of(context).platform == TargetPlatform.macOS;
    if (isDesktop) {
      widget.onToggleFullscreen();
      return;
    }

    final screenWidth = constraints.maxWidth;
    final tapX = details.localPosition.dx;
    final xRatio = tapX / screenWidth;

    if (xRatio < 0.35) {
      // Left 35% -> Rewind 10s
      _triggerSeekRipple(DoubleTapSeekSide.left);
    } else if (xRatio > 0.65) {
      // Right 35% -> Forward 10s
      _triggerSeekRipple(DoubleTapSeekSide.right);
    } else {
      // Center -> Play/Pause
      widget.onPlayPause();
      _showOverlay();
    }
  }

  // ── Drag Gestures (Vertical = Volume/Brightness, Horizontal = Seek Scrub) ──

  void _handleVerticalDragStart(DragStartDetails details, BoxConstraints constraints) {
    if (widget.playerState.isLocked) return;
    _hudDismissTimer?.cancel();
    _isDragging = true;

    final isMobile = !PlatformService.instance.isWindows && !PlatformService.instance.isWeb;
    final xRatio = details.localPosition.dx / constraints.maxWidth;
    if (xRatio < 0.5 && isMobile) {
      _isBrightnessDrag = true;
      _isVolumeDrag = false;
      ScreenBrightness.instance.application.then((b) {
        if (mounted) {
          _brightnessLevel = b.clamp(0.01, 1.0);
        }
      }).catchError((_) {});
    } else {
      _isVolumeDrag = true;
      _isBrightnessDrag = false;
      FlutterVolumeController.getVolume().then((v) {
        if (v != null && mounted) {
          _currentVolume = v.clamp(0.0, 1.0);
        }
      }).catchError((_) {});
    }
  }

  void _handleVerticalDragUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (!_isDragging || widget.playerState.isLocked) return;

    final dy = details.delta.dy;
    if (_isBrightnessDrag) {
      final delta = -dy / (constraints.maxHeight * 0.65);
      final newLevel = (_brightnessLevel + delta).clamp(0.01, 1.0);
      setState(() => _brightnessLevel = newLevel);
      ScreenBrightness.instance.setApplicationScreenBrightness(newLevel).catchError((_) {});
    } else if (_isVolumeDrag) {
      final delta = -dy / (constraints.maxHeight * 0.65);
      _currentVolume = (_currentVolume + delta).clamp(0.0, 1.0);
      setState(() {});
      FlutterVolumeController.setVolume(_currentVolume).catchError((_) {});
      widget.onVolumeChanged(_currentVolume);
    }
  }

  void _handleVerticalDragEnd(DragEndDetails details) {
    if (!_isDragging || widget.playerState.isLocked) return;
    _isDragging = false;
    _hudDismissTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isVolumeDrag = false;
          _isBrightnessDrag = false;
        });
      }
    });
  }

  void _handleHorizontalDragStart(DragStartDetails details, BoxConstraints constraints) {
    if (widget.playerState.isLocked || widget.playerState.isLive) return;
    _hudDismissTimer?.cancel();
    _isDragging = true;
    _isScrubDrag = true;
    _scrubStartPosition = widget.playerState.position;
    _scrubOffsetSeconds = 0;
  }

  void _handleHorizontalDragUpdate(DragUpdateDetails details, BoxConstraints constraints) {
    if (!_isDragging || widget.playerState.isLocked || !_isScrubDrag) return;
    final dx = details.delta.dx;
    final deltaSecs = (dx / (constraints.maxWidth * 0.3) * 60).toInt();
    setState(() {
      _scrubOffsetSeconds += deltaSecs;
    });
  }

  void _handleHorizontalDragEnd(DragEndDetails details) {
    if (!_isDragging || widget.playerState.isLocked || !_isScrubDrag) return;

    if (_scrubOffsetSeconds != 0) {
      final target = _scrubStartPosition + Duration(seconds: _scrubOffsetSeconds);
      final maxDur = widget.playerState.duration;
      final clampedTarget = _clampDuration(target, Duration.zero, maxDur);
      widget.onSeek(clampedTarget);
    }

    _isDragging = false;
    _hudDismissTimer = Timer(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _isScrubDrag = false;
        });
      }
    });
  }

  void _setSleepTimer(Duration? duration, [String? label]) {
    _activeSleepTimer?.cancel();
    _activeSleepTimer = null;
    _activeSleepDuration = duration;
    _activeSleepLabel = label;

    if (duration != null) {
      _activeSleepTimer = Timer(duration, () {
        if (mounted) {
          widget.onClose();
        }
      });
      final message = label != null
          ? 'Sleep timer set: $label'
          : 'Sleep timer set for ${duration.inMinutes} minutes';
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(
          content: Text(message),
          duration: const Duration(seconds: 2),
        ),
      );
    } else {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        const SnackBar(
          content: Text('Sleep timer turned off'),
          duration: Duration(seconds: 2),
        ),
      );
    }
    setState(() {});
  }

  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.space || key == LogicalKeyboardKey.select) {
      widget.onPlayPause();
      _showOverlay();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowLeft) {
      widget.onSeekRelative(const Duration(seconds: -10));
      _showSeekRippleOnly(DoubleTapSeekSide.left);
      _showOverlay();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowRight) {
      widget.onSeekRelative(const Duration(seconds: 10));
      _showSeekRippleOnly(DoubleTapSeekSide.right);
      _showOverlay();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyM) {
      widget.onToggleMute();
      _showOverlay();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.keyF || key == LogicalKeyboardKey.f11) {
      widget.onToggleFullscreen();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowUp) {
      widget.onNextChannel();
      _showOverlay();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.arrowDown) {
      widget.onPreviousChannel();
      _showOverlay();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.escape || key == LogicalKeyboardKey.goBack) {
      if (widget.playerState.isLocked) {
        widget.onToggleLock();
        return KeyEventResult.handled;
      }
      if (_showDiagnostics) {
        setState(() => _showDiagnostics = false);
        return KeyEventResult.handled;
      }
      if (_controlsVisible) {
        setState(() => _controlsVisible = false);
        return KeyEventResult.handled;
      }
      widget.onClose();
      return KeyEventResult.handled;
    }

    _showOverlay();
    return KeyEventResult.ignored;
  }

  Duration _clampDuration(Duration val, Duration min, Duration max) {
    if (val < min) return min;
    if (val > max) return max;
    return val;
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _tapDebounceTimer?.cancel();
    _seekResetTimer?.cancel();
    _hudDismissTimer?.cancel();
    _activeSleepTimer?.cancel();
    _focusNode.dispose();
    if (!PlatformService.instance.isWindows && !PlatformService.instance.isWeb) {
      ScreenBrightness.instance.resetApplicationScreenBrightness().catchError((_) {});
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLocked = widget.playerState.isLocked;

    return Focus(
      focusNode: _focusNode,
      autofocus: true,
      onKeyEvent: _handleKeyEvent,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return MouseRegion(
            onHover: (_) => _showOverlay(),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // 1. Full-Screen Background Gesture Surface
                Positioned.fill(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTapUp: (d) => _handleTapUp(d, constraints),
                    onDoubleTapDown: (d) => _handleDoubleTapDown(d, constraints),
                    onDoubleTap: () {},
                    onVerticalDragStart: (d) => _handleVerticalDragStart(d, constraints),
                    onVerticalDragUpdate: (d) => _handleVerticalDragUpdate(d, constraints),
                    onVerticalDragEnd: _handleVerticalDragEnd,
                    onHorizontalDragStart: (d) => _handleHorizontalDragStart(d, constraints),
                    onHorizontalDragUpdate: (d) => _handleHorizontalDragUpdate(d, constraints),
                    onHorizontalDragEnd: _handleHorizontalDragEnd,
                  ),
                ),

                // 2. Compact Interactive Controls Overlay (Consolidated Top Bar, Center, Bottom)
                if (!isLocked)
                  AnimatedOpacity(
                    opacity: _controlsVisible ? 1.0 : 0.0,
                    duration: const Duration(milliseconds: 250),
                    child: IgnorePointer(
                      ignoring: !_controlsVisible,
                      child: PlayerControls(
                        playerState: widget.playerState,
                        onPlayPause: widget.onPlayPause,
                        onSeek: widget.onSeek,
                        onSeekRelative: (offset) {
                          widget.onSeekRelative(offset);
                          _showSeekRippleOnly(
                            offset.isNegative ? DoubleTapSeekSide.left : DoubleTapSeekSide.right,
                          );
                        },
                        onVolumeChanged: widget.onVolumeChanged,
                        onToggleMute: widget.onToggleMute,
                        onNextChannel: widget.onNextChannel,
                        onPreviousChannel: widget.onPreviousChannel,
                        onCycleAspectRatio: widget.onCycleAspectRatio,
                        onSelectPlaybackRate: widget.onSelectPlaybackRate,
                        onOpenAudioTracks: () {
                          _hideControlsTimer?.cancel();
                          AudioTrackSelectorModal.show(
                            context,
                            tracks: widget.playerState.availableAudioTracks,
                            currentTrack: widget.playerState.currentAudioTrack,
                            onSelect: widget.onSelectAudioTrack,
                          ).then((_) => _scheduleHide());
                        },
                        onOpenSubtitles: () {
                          _hideControlsTimer?.cancel();
                          SubtitleSelectorModal.show(
                            context,
                            tracks: widget.playerState.availableSubtitleTracks,
                            currentTrack: widget.playerState.currentSubtitleTrack,
                            onSelect: widget.onSelectSubtitleTrack,
                          ).then((_) => _scheduleHide());
                        },
                        onToggleLock: widget.onToggleLock,
                        onOpenQuickSettings: () {
                          _hideControlsTimer?.cancel();
                          PlayerQuickSettingsSheet.show(
                            context,
                            playerState: widget.playerState,
                            onSelectPlaybackRate: widget.onSelectPlaybackRate,
                            onSelectAspectRatio: widget.onSelectAspectRatio,
                            onOpenAudioTracks: () {
                              AudioTrackSelectorModal.show(
                                context,
                                tracks: widget.playerState.availableAudioTracks,
                                currentTrack: widget.playerState.currentAudioTrack,
                                onSelect: widget.onSelectAudioTrack,
                              );
                            },
                            onOpenSubtitles: () {
                              SubtitleSelectorModal.show(
                                context,
                                tracks: widget.playerState.availableSubtitleTracks,
                                currentTrack: widget.playerState.currentSubtitleTrack,
                                onSelect: widget.onSelectSubtitleTrack,
                              );
                            },
                            onSelectBufferMode: widget.onSelectBufferMode,
                            activeSleepLabel: _activeSleepLabel,
                            activeSleepDuration: _activeSleepDuration,
                            onSetSleepTimer: _setSleepTimer,
                          ).then((_) => _scheduleHide());
                        },
                        onToggleFullscreen: widget.onToggleFullscreen,
                        onClose: widget.onClose,
                      ),
                    ),
                  ),

                // 3. Double-Tap Seek Ripple Overlay
                if (_activeSeekSide != null && !isLocked)
                  DoubleTapSeekOverlay(
                    side: _activeSeekSide!,
                    seconds: _seekCumulativeSeconds,
                    onAnimationComplete: () {
                      if (mounted && _activeSeekSide != null) {
                        setState(() {
                          _activeSeekSide = null;
                          _seekCumulativeSeconds = 0;
                        });
                      }
                    },
                  ),

                // 4. Gesture HUD Overlays (Volume / Brightness / Seek Scrub)
                if (_isVolumeDrag)
                  GestureLevelHud(
                    icon: (widget.playerState.isMuted && _currentVolume == 0) || _currentVolume == 0
                        ? AppIcons.volumeMute
                        : _currentVolume < 0.5
                            ? AppIcons.volumeLow
                            : AppIcons.volumeHigh,
                    value: _currentVolume,
                    label: 'Volume',
                  ),
                if (_isBrightnessDrag)
                  GestureLevelHud(
                    icon: AppIcons.brightness,
                    value: _brightnessLevel,
                    label: 'Brightness',
                  ),
                if (_isScrubDrag && !widget.playerState.isLive)
                  SeekScrubHud(
                    targetPosition: _clampDuration(
                      _scrubStartPosition + Duration(seconds: _scrubOffsetSeconds),
                      Duration.zero,
                      widget.playerState.duration,
                    ),
                    totalDuration: widget.playerState.duration,
                    offsetSeconds: _scrubOffsetSeconds,
                  ),

                // 5. Floating Screen Unlock Button (When Locked)
                if (isLocked)
                  Positioned(
                    left: 28,
                    top: MediaQuery.of(context).size.height * 0.45,
                    child: ClipOval(
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withValues(alpha: 0.65),
                            border: Border.all(
                              color: AppColors.accent.withValues(alpha: 0.8),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.accent.withValues(alpha: 0.3),
                                blurRadius: 16,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: IconButton(
                            iconSize: 28,
                            icon: const HugeIcon(icon: AppIcons.lock, color: AppColors.accent, size: 24),
                            tooltip: 'Tap to unlock screen',
                            onPressed: widget.onToggleLock,
                          ),
                        ),
                      ),
                    ),
                  ),

                // 6. Persistent software-decode badge (Top Left, compact)
                if (widget.playerState.metrics.showSoftwareDecodeBadge && !isLocked)
                  Positioned(
                    top: 60,
                    left: 16,
                    child: SoftwareDecodeBadge(
                      tier: widget.playerState.metrics.swDecodeTier,
                      onTap: () => setState(() => _showDiagnostics = true),
                    ),
                  ),

                // 7. Diagnostics HUD
                if (_showDiagnostics && !isLocked)
                  DiagnosticsOverlay(
                    playerState: widget.playerState,
                    onClose: () => setState(() => _showDiagnostics = false),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
