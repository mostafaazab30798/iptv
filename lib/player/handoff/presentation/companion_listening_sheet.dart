import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/player/domain/entities/player_source.dart';
import 'package:iptv/player/handoff/application/companion_audio_controller.dart';
import 'package:iptv/player/handoff/domain/audio_handoff_models.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/widgets/smart_channel_logo.dart';

enum _CompanionTab { audio, trackpad, keyboard }

/// Full interactive companion modal on the mobile device during Companion mode.
/// Provides 3 distinct tools:
/// 1. 🎧 Low-latency headphone audio streaming & Bluetooth calibration
/// 2. 🖱️ High-precision trackpad for TV mouse cursor control
/// 3. ⌨️ Live keyboard text injection & D-pad remote navigation
class CompanionListeningSheet extends ConsumerStatefulWidget {
  const CompanionListeningSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: false,
      useRootNavigator: true,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        reverseDuration: Duration(milliseconds: 140),
      ),
      builder: (_) => const CompanionListeningSheet(),
    );
  }

  @override
  ConsumerState<CompanionListeningSheet> createState() =>
      _CompanionListeningSheetState();
}

class _CompanionListeningSheetState
    extends ConsumerState<CompanionListeningSheet> {
  _CompanionTab _selectedTab = _CompanionTab.audio;
  final TextEditingController _textController = TextEditingController();
  double _trackpadSensitivity = 1.2;

  // Trackpad gesture state
  DateTime? _panStartTime;
  bool _panMoved = false;

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Exclude high-frequency position/duration so ticks do not rebuild the sheet.
    final state = ref.watch(
      companionAudioProvider.select(_CompanionAudioUiSlice.fromState),
    );
    final controller = ref.read(companionAudioProvider.notifier);
    final source = state.currentSource;

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        14,
        0,
        14,
        bottomInset > 0
            ? bottomInset + 12
            : (bottomPadding > 0 ? bottomPadding + 8 : 16),
      ),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.12),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.5),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header: Channel Info & Device
              Row(
                children: [
                  if (source != null)
                    SmartChannelLogo(
                      channelName: source.title,
                      logoUrl: source.logoUrl,
                      width: 44,
                      height: 44,
                      borderRadius: BorderRadius.circular(10),
                    )
                  else
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const HugeIcon(
                        icon: AppIcons.headphones,
                        color: AppColors.accent,
                        size: 22,
                      ),
                    ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'COMPANION',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                state.sessionInfo?.serverDeviceName ??
                                    'Connected TV',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          source?.title ?? 'Companion Controller',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const HugeIcon(
                      icon: AppIcons.close,
                      color: Colors.white70,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              // Segmented Tab Switcher (Audio, Trackpad, Remote)
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    _buildTabButton(
                      tab: _CompanionTab.audio,
                      icon: AppIcons.headphones,
                      label: 'Audio',
                    ),
                    _buildTabButton(
                      tab: _CompanionTab.trackpad,
                      icon: AppIcons.play,
                      label: 'Trackpad',
                    ),
                    _buildTabButton(
                      tab: _CompanionTab.keyboard,
                      icon: AppIcons.search,
                      label: 'Remote',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              // Tab View Content
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 200),
                child: switch (_selectedTab) {
                  _CompanionTab.audio => _buildAudioTab(state, controller),
                  _CompanionTab.trackpad =>
                    _buildTrackpadTab(state, controller),
                  _CompanionTab.keyboard =>
                    _buildKeyboardTab(state, controller),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton({
    required _CompanionTab tab,
    required List<List<dynamic>> icon,
    required String label,
  }) {
    final isSelected = _selectedTab == tab;
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedTab = tab);
        },
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.accent : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.accent.withValues(alpha: 0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HugeIcon(
                icon: icon,
                color: isSelected ? Colors.black : Colors.white60,
                size: 15,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.black : Colors.white70,
                  fontSize: 12.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 1: AUDIO STREAMING & BLUETOOTH COMPENSATION
  // ---------------------------------------------------------------------------
  Widget _buildAudioTab(
      _CompanionAudioUiSlice state, CompanionAudioController controller) {
    return Column(
      key: const ValueKey('audio_tab'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Live Sync Status HUD
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: state.isInSync
                  ? Colors.greenAccent.withValues(alpha: 0.3)
                  : Colors.amberAccent.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color:
                      state.isInSync ? Colors.greenAccent : Colors.amberAccent,
                  boxShadow: [
                    BoxShadow(
                      color: (state.isInSync
                              ? Colors.greenAccent
                              : Colors.amberAccent)
                          .withValues(alpha: 0.5),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      state.isInSync
                          ? 'In Perfect Sync (Drift: ${state.driftMs >= 0 ? '+' : ''}${state.driftMs}ms)'
                          : 'Realigning Audio (${state.driftMs >= 0 ? '+' : ''}${state.driftMs}ms)',
                      style: TextStyle(
                        color: state.isInSync
                            ? Colors.greenAccent
                            : Colors.amberAccent,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'LAN RTT: ${state.networkRttMs}ms • Dual-Client Audio-Engine',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 14),

        // Bluetooth Latency Offset Slider Card
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white10),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const HugeIcon(
                        icon: AppIcons.headphones,
                        color: AppColors.accent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        context.l10n.handoffBtDelayTitle,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      '${state.bluetoothOffsetMs >= 0 ? '+' : ''}${state.bluetoothOffsetMs} ms',
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.accent,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: AppColors.accent,
                  trackHeight: 3,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
                  value: state.bluetoothOffsetMs.toDouble(),
                  min: -500,
                  max: 500,
                  divisions: 40,
                  onChanged: (val) {
                    controller.setBluetoothOffset(val.round());
                  },
                ),
              ),

              // Nudge buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _NudgeButton(
                    label: '-50ms',
                    onTap: () => controller
                        .setBluetoothOffset(state.bluetoothOffsetMs - 50),
                  ),
                  const SizedBox(width: 8),
                  _NudgeButton(
                    label: '0ms',
                    isPrimary: state.bluetoothOffsetMs != 0,
                    onTap: () => controller.setBluetoothOffset(0),
                  ),
                  const SizedBox(width: 8),
                  _NudgeButton(
                    label: '+50ms',
                    onTap: () => controller
                        .setBluetoothOffset(state.bluetoothOffsetMs + 50),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Volume & Mute Row
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white10),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: HugeIcon(
                        icon: state.isMuted
                            ? AppIcons.volumeMute
                            : AppIcons.volumeHigh,
                        color: Colors.white,
                        size: 18,
                      ),
                      onPressed: controller.toggleMute,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white24,
                          thumbColor: Colors.white,
                          trackHeight: 2.5,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 5,
                          ),
                        ),
                        child: Slider(
                          value: state.isMuted ? 0.0 : state.volume,
                          onChanged: controller.setVolume,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            InkWell(
              onTap: controller.toggleTvMute,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: state.isTvMuted
                      ? Colors.redAccent.withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: state.isTvMuted
                        ? Colors.redAccent.withValues(alpha: 0.5)
                        : Colors.white12,
                  ),
                ),
                child: Row(
                  children: [
                    HugeIcon(
                      icon: state.isTvMuted
                          ? AppIcons.volumeMute
                          : AppIcons.volumeHigh,
                      color: state.isTvMuted ? Colors.redAccent : Colors.white70,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      state.isTvMuted ? 'TV Muted' : 'Mute TV',
                      style: TextStyle(
                        color:
                            state.isTvMuted ? Colors.redAccent : Colors.white,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 14),

        // Disconnect
        FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: Colors.redAccent.withValues(alpha: 0.85),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          icon: const HugeIcon(
            icon: AppIcons.close,
            color: Colors.white,
            size: 18,
          ),
          label: Text(
            context.l10n.handoffDisconnect,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          onPressed: () async {
            await controller.disconnect();
            if (mounted) {
              Navigator.of(context).pop();
            }
          },
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 2: TOUCHPAD MOUSE CONTROLLER
  // ---------------------------------------------------------------------------
  Widget _buildTrackpadTab(
      _CompanionAudioUiSlice state, CompanionAudioController controller) {
    return Column(
      key: const ValueKey('trackpad_tab'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Trackpad Surface
        Listener(
          behavior: HitTestBehavior.opaque,
          onPointerDown: (event) {
            _panStartTime = DateTime.now();
            _panMoved = false;
          },
          onPointerMove: (event) {
            final dx = event.delta.dx * _trackpadSensitivity;
            final dy = event.delta.dy * _trackpadSensitivity;

            if (dx.abs() > 0.05 || dy.abs() > 0.05) {
              _panMoved = true;
              controller.sendMouseMove(dx, dy);
            }
          },
          onPointerUp: (event) {
            final durationMs = _panStartTime != null
                ? DateTime.now().difference(_panStartTime!).inMilliseconds
                : 999;
            if (!_panMoved && durationMs < 300) {
              unawaited(HapticFeedback.lightImpact());
              controller.sendMouseTap('left');
            }
          },
          child: Container(
            height: 210,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.9,
                colors: [
                  const Color(0xFF1E293B).withValues(alpha: 0.9),
                  const Color(0xFF0F172A),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: AppColors.accent.withValues(alpha: 0.35),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.5),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withValues(alpha: 0.1),
                    ),
                    child: const HugeIcon(
                      icon: AppIcons.play,
                      color: AppColors.accent,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Slide to Move TV Cursor',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tap to Click • 2-Finger Drag to Scroll',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Physical Click Buttons (Left Click / Back)
        Row(
          children: [
            Expanded(
              flex: 2,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  controller.sendMouseTap('left');
                },
                child: const Text(
                  'Left Click',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white24),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  controller.sendKeyPress('back');
                },
                child: const Text(
                  'Back (Esc)',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Sensitivity Slider
        Row(
          children: [
            Text(
              'Speed',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7),
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
            ),
            Expanded(
              child: SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: AppColors.accent,
                  inactiveTrackColor: Colors.white24,
                  thumbColor: AppColors.accent,
                  trackHeight: 2,
                  thumbShape:
                      const RoundSliderThumbShape(enabledThumbRadius: 5),
                ),
                child: Slider(
                  value: _trackpadSensitivity,
                  min: 0.4,
                  max: 2.5,
                  onChanged: (val) {
                    setState(() => _trackpadSensitivity = val);
                  },
                ),
              ),
            ),
            Text(
              '${_trackpadSensitivity.toStringAsFixed(1)}x',
              style: const TextStyle(
                color: AppColors.accent,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // TAB 3: KEYBOARD & REMOTE D-PAD CONTROLLER
  // ---------------------------------------------------------------------------
  Widget _buildKeyboardTab(
      _CompanionAudioUiSlice state, CompanionAudioController controller) {
    return Column(
      key: const ValueKey('keyboard_tab'),
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Live Text Input Field
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.06),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white12),
                ),
                child: TextField(
                  controller: _textController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Type to send text to TV...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 13,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (text) {
                    if (text.isNotEmpty) {
                      HapticFeedback.lightImpact();
                      controller.sendTypeText(text);
                      _textController.clear();
                    }
                  },
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.accent,
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                final text = _textController.text;
                if (text.isNotEmpty) {
                  HapticFeedback.lightImpact();
                  controller.sendTypeText(text);
                  _textController.clear();
                }
              },
              child: const Text('Send',
                  style: TextStyle(fontWeight: FontWeight.w800)),
            ),
          ],
        ),

        const SizedBox(height: 6),

        // Quick Input Actions (Backspace, Enter, Clear)
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            _NudgeButton(
              label: '⌫ Backspace',
              onTap: () {
                HapticFeedback.lightImpact();
                controller.sendKeyPress('backspace');
              },
            ),
            const SizedBox(width: 6),
            _NudgeButton(
              label: '↵ Enter',
              onTap: () {
                HapticFeedback.lightImpact();
                controller.sendKeyPress('enter');
              },
            ),
            const SizedBox(width: 6),
            _NudgeButton(
              label: 'Clear',
              onTap: _textController.clear,
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Circular D-Pad
        Center(
          child: SizedBox(
            width: 170,
            height: 170,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background disc
                Container(
                  width: 170,
                  height: 170,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.04),
                    border: Border.all(color: Colors.white12),
                  ),
                ),

                // Up Button
                Positioned(
                  top: 4,
                  child: _DpadArrowButton(
                    icon: Icons.keyboard_arrow_up,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.sendKeyPress('up');
                    },
                  ),
                ),

                // Down Button
                Positioned(
                  bottom: 4,
                  child: _DpadArrowButton(
                    icon: Icons.keyboard_arrow_down,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.sendKeyPress('down');
                    },
                  ),
                ),

                // Left Button
                Positioned(
                  left: 4,
                  child: _DpadArrowButton(
                    icon: Icons.keyboard_arrow_left,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.sendKeyPress('left');
                    },
                  ),
                ),

                // Right Button
                Positioned(
                  right: 4,
                  child: _DpadArrowButton(
                    icon: Icons.keyboard_arrow_right,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      controller.sendKeyPress('right');
                    },
                  ),
                ),

                // Center OK / Select Button
                InkWell(
                  onTap: () {
                    HapticFeedback.mediumImpact();
                    controller.sendKeyPress('select');
                  },
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accent.withValues(alpha: 0.2),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.5),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Text(
                        'OK',
                        style: TextStyle(
                          color: AppColors.accent,
                          fontSize: 15,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Navigation Actions Row (Back, Home, Play, Mute)
        Row(
          children: [
            Expanded(
              child: _QuickNavButton(
                label: 'Back',
                icon: Icons.arrow_back,
                onTap: () => controller.sendKeyPress('back'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickNavButton(
                label: 'Home',
                icon: Icons.home,
                onTap: () => controller.sendKeyPress('home'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickNavButton(
                label: 'Play',
                icon: Icons.play_arrow,
                onTap: () => controller.sendKeyPress('play_pause'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _QuickNavButton(
                label: 'Mute',
                icon: Icons.volume_off,
                onTap: controller.toggleTvMute,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DpadArrowButton extends StatelessWidget {
  const _DpadArrowButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }
}

class _QuickNavButton extends StatelessWidget {
  const _QuickNavButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 18),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NudgeButton extends StatelessWidget {
  const _NudgeButton({
    required this.label,
    required this.onTap,
    this.isPrimary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isPrimary
              ? AppColors.accent.withValues(alpha: 0.2)
              : Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: isPrimary
                ? AppColors.accent.withValues(alpha: 0.4)
                : Colors.transparent,
            width: 0.8,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isPrimary ? AppColors.accent : Colors.white70,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

/// Connection / metadata / audio controls without [CompanionAudioState.position]
/// or duration — position ticks must not rebuild the companion sheet.
class _CompanionAudioUiSlice {
  const _CompanionAudioUiSlice({
    required this.sessionInfo,
    required this.currentSource,
    required this.driftMs,
    required this.isInSync,
    required this.bluetoothOffsetMs,
    required this.volume,
    required this.isMuted,
    required this.isTvMuted,
    required this.networkRttMs,
  });

  factory _CompanionAudioUiSlice.fromState(CompanionAudioState s) {
    return _CompanionAudioUiSlice(
      sessionInfo: s.sessionInfo,
      currentSource: s.currentSource,
      driftMs: s.driftMs,
      isInSync: s.isInSync,
      bluetoothOffsetMs: s.bluetoothOffsetMs,
      volume: s.volume,
      isMuted: s.isMuted,
      isTvMuted: s.isTvMuted,
      networkRttMs: s.networkRttMs,
    );
  }

  final HandoffSessionInfo? sessionInfo;
  final PlayerSource? currentSource;
  final int driftMs;
  final bool isInSync;
  final int bluetoothOffsetMs;
  final double volume;
  final bool isMuted;
  final bool isTvMuted;
  final int networkRttMs;

  @override
  bool operator ==(Object other) {
    return other is _CompanionAudioUiSlice &&
        other.sessionInfo == sessionInfo &&
        other.currentSource == currentSource &&
        other.driftMs == driftMs &&
        other.isInSync == isInSync &&
        other.bluetoothOffsetMs == bluetoothOffsetMs &&
        other.volume == volume &&
        other.isMuted == isMuted &&
        other.isTvMuted == isTvMuted &&
        other.networkRttMs == networkRttMs;
  }

  @override
  int get hashCode => Object.hash(
        sessionInfo,
        currentSource,
        driftMs,
        isInSync,
        bluetoothOffsetMs,
        volume,
        isMuted,
        isTvMuted,
        networkRttMs,
      );
}
