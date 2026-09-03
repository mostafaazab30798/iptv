import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/player/handoff/application/companion_audio_controller.dart';
import 'package:iptv/player/handoff/presentation/companion_listening_sheet.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';

/// Minimal TV remote sheet — D-pad first; keyboard only when the user taps in.
class CompanionRemoteSheet extends ConsumerStatefulWidget {
  const CompanionRemoteSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      enableDrag: true,
      useRootNavigator: true,
      isDismissible: true,
      sheetAnimationStyle: const AnimationStyle(
        duration: Duration(milliseconds: 220),
        curve: Curves.easeOutCubic,
        reverseDuration: Duration(milliseconds: 140),
      ),
      builder: (_) => const CompanionRemoteSheet(),
    );
  }

  @override
  ConsumerState<CompanionRemoteSheet> createState() =>
      _CompanionRemoteSheetState();
}

class _CompanionRemoteSheetState extends ConsumerState<CompanionRemoteSheet> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocus = FocusNode();
  bool _keyboardOpen = false;

  @override
  void dispose() {
    _textController.dispose();
    _textFocus.dispose();
    super.dispose();
  }

  void _openKeyboard() {
    if (_keyboardOpen) return;
    setState(() => _keyboardOpen = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _textFocus.requestFocus();
    });
  }

  void _closeKeyboard() {
    _textFocus.unfocus();
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() => _keyboardOpen = false);
  }

  @override
  Widget build(BuildContext context) {
    final deviceName = ref.watch(
      companionAudioProvider.select(
        (s) => s.sessionInfo?.serverDeviceName ?? 'Connected Big Screen',
      ),
    );
    final isConnected = ref.watch(
      companionAudioProvider.select((s) => s.isConnected),
    );
    final rttMs = ref.watch(
      companionAudioProvider.select((s) => s.networkRttMs),
    );
    final controller = ref.read(companionAudioProvider.notifier);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        12,
        0,
        12,
        _keyboardOpen && bottomInset > 0
            ? bottomInset + 8
            : (bottomPadding > 0 ? bottomPadding + 6 : 12),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF0C1018),
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                _Header(
                  deviceName: deviceName,
                  isConnected: isConnected,
                  rttMs: rttMs,
                  onDisconnect: () async {
                    await HapticFeedback.mediumImpact();
                    await controller.disconnect();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
                const SizedBox(height: 18),
                _DpadPad(controller: controller),
                const SizedBox(height: 14),
                _ActionRow(controller: controller),
                const SizedBox(height: 12),
                _KeyboardSection(
                  open: _keyboardOpen,
                  controller: _textController,
                  focusNode: _textFocus,
                  hint: context.l10n.companionKeyboardHint,
                  onOpen: _openKeyboard,
                  onClose: _closeKeyboard,
                  onChanged: (text) =>
                      controller.sendTypeText(text, replace: true),
                  onEnter: () {
                    unawaited(HapticFeedback.lightImpact());
                    controller.sendKeyPress('enter');
                  },
                  onBackspace: () {
                    unawaited(HapticFeedback.lightImpact());
                    final text = _textController.text;
                    if (text.isNotEmpty) {
                      final updated = text.substring(0, text.length - 1);
                      _textController.text = updated;
                      _textController.selection =
                          TextSelection.collapsed(offset: updated.length);
                      controller.sendTypeText(updated, replace: true);
                    } else {
                      controller.sendKeyPress('backspace');
                    }
                    setState(() {});
                  },
                  onSpace: () {
                    unawaited(HapticFeedback.lightImpact());
                    final updated = '${_textController.text} ';
                    _textController.text = updated;
                    _textController.selection =
                        TextSelection.collapsed(offset: updated.length);
                    controller.sendTypeText(updated, replace: true);
                    setState(() {});
                  },
                  onClear: () {
                    _textController.clear();
                    controller.sendTypeText('', replace: true);
                    setState(() {});
                  },
                ),
                const SizedBox(height: 10),
                _AudioLink(
                  title: context.l10n.companionAudioTitle,
                  subtitle: context.l10n.companionAudioSubtitle,
                  onTap: () {
                    unawaited(HapticFeedback.selectionClick());
                    Navigator.of(context).pop();
                    unawaited(CompanionListeningSheet.show(context));
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.deviceName,
    required this.isConnected,
    required this.rttMs,
    required this.onDisconnect,
  });

  final String deviceName;
  final bool isConnected;
  final int rttMs;
  final VoidCallback onDisconnect;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const HugeIcon(
            icon: AppIcons.generalTv,
            color: AppColors.accent,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                deviceName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                isConnected ? 'Connected · ${rttMs}ms' : 'Connecting…',
                style: TextStyle(
                  color: isConnected
                      ? const Color(0xFF34D399)
                      : Colors.white.withValues(alpha: 0.45),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        IconButton(
          visualDensity: VisualDensity.compact,
          tooltip: context.l10n.disconnect,
          onPressed: onDisconnect,
          icon: Icon(
            Icons.link_off_rounded,
            size: 20,
            color: Colors.white.withValues(alpha: 0.55),
          ),
        ),
      ],
    );
  }
}

class _DpadPad extends StatelessWidget {
  const _DpadPad({required this.controller});

  final CompanionAudioController controller;

  @override
  Widget build(BuildContext context) {
    const size = 188.0;
    const btn = 52.0;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.04),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
            ),
          ),
          Positioned(
            top: 6,
            child: _DpadBtn(
              size: btn,
              icon: Icons.keyboard_arrow_up_rounded,
              onPress: () => controller.sendKeyPress('up'),
            ),
          ),
          Positioned(
            bottom: 6,
            child: _DpadBtn(
              size: btn,
              icon: Icons.keyboard_arrow_down_rounded,
              onPress: () => controller.sendKeyPress('down'),
            ),
          ),
          Positioned(
            left: 6,
            child: _DpadBtn(
              size: btn,
              icon: Icons.keyboard_arrow_left_rounded,
              onPress: () => controller.sendKeyPress('left'),
            ),
          ),
          Positioned(
            right: 6,
            child: _DpadBtn(
              size: btn,
              icon: Icons.keyboard_arrow_right_rounded,
              onPress: () => controller.sendKeyPress('right'),
            ),
          ),
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                unawaited(HapticFeedback.mediumImpact());
                controller.sendKeyPress('select');
              },
              borderRadius: BorderRadius.circular(32),
              child: Container(
                width: 64,
                height: 64,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent,
                ),
                child: const Text(
                  'OK',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  const _ActionRow({required this.controller});

  final CompanionAudioController controller;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _MiniAction(
            icon: Icons.arrow_back_rounded,
            label: context.l10n.companionBack,
            onTap: () => controller.sendKeyPress('back'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniAction(
            icon: Icons.home_rounded,
            label: context.l10n.companionHome,
            onTap: () => controller.sendKeyPress('home'),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MiniAction(
            icon: Icons.play_arrow_rounded,
            label: 'Play',
            onTap: () => controller.sendKeyPress('play_pause'),
          ),
        ),
      ],
    );
  }
}

class _KeyboardSection extends StatelessWidget {
  const _KeyboardSection({
    required this.open,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.onOpen,
    required this.onClose,
    required this.onChanged,
    required this.onEnter,
    required this.onBackspace,
    required this.onSpace,
    required this.onClear,
  });

  final bool open;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final VoidCallback onOpen;
  final VoidCallback onClose;
  final ValueChanged<String> onChanged;
  final VoidCallback onEnter;
  final VoidCallback onBackspace;
  final VoidCallback onSpace;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    if (!open) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.keyboard_outlined,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.45),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    hint,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.45),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                Icon(
                  Icons.chevron_right,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accent.withValues(alpha: 0.35)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  autofocus: false,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: hint,
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.35),
                      fontSize: 13,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: onChanged,
                  onSubmitted: (_) => onEnter(),
                ),
              ),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: controller,
                builder: (context, value, _) {
                  if (value.text.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    onPressed: onClear,
                  );
                },
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: 'Hide keyboard',
                icon: Icon(
                  Icons.keyboard_hide_outlined,
                  size: 18,
                  color: Colors.white.withValues(alpha: 0.5),
                ),
                onPressed: onClose,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _KeyChip(label: 'Enter', primary: true, onTap: onEnter),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _KeyChip(label: '⌫', onTap: onBackspace),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _KeyChip(label: 'Space', onTap: onSpace),
            ),
          ],
        ),
      ],
    );
  }
}

class _AudioLink extends StatelessWidget {
  const _AudioLink({
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            children: [
              HugeIcon(
                icon: AppIcons.headphones,
                color: Colors.white.withValues(alpha: 0.55),
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.4),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: Colors.white.withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DpadBtn extends StatefulWidget {
  const _DpadBtn({
    required this.size,
    required this.icon,
    required this.onPress,
  });

  final double size;
  final IconData icon;
  final VoidCallback onPress;

  @override
  State<_DpadBtn> createState() => _DpadBtnState();
}

class _DpadBtnState extends State<_DpadBtn> {
  Timer? _repeatTimer;
  Timer? _delayTimer;

  void _startHold() {
    unawaited(HapticFeedback.selectionClick());
    widget.onPress();
    _delayTimer = Timer(const Duration(milliseconds: 300), () {
      _repeatTimer = Timer.periodic(const Duration(milliseconds: 110), (_) {
        unawaited(HapticFeedback.selectionClick());
        widget.onPress();
      });
    });
  }

  void _stopHold() {
    _delayTimer?.cancel();
    _delayTimer = null;
    _repeatTimer?.cancel();
    _repeatTimer = null;
  }

  @override
  void dispose() {
    _stopHold();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _startHold(),
      onTapUp: (_) => _stopHold(),
      onTapCancel: _stopHold,
      child: Container(
        width: widget.size,
        height: widget.size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(widget.icon, color: Colors.white, size: 28),
      ),
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          unawaited(HapticFeedback.lightImpact());
          onTap();
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
          ),
          child: Column(
            children: [
              Icon(icon, color: Colors.white.withValues(alpha: 0.85), size: 20),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  fontSize: 10.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _KeyChip extends StatelessWidget {
  const _KeyChip({
    required this.label,
    required this.onTap,
    this.primary = false,
  });

  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          unawaited(HapticFeedback.lightImpact());
          onTap();
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: primary
                ? AppColors.accent
                : Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              color: primary ? Colors.black : Colors.white.withValues(alpha: 0.8),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
