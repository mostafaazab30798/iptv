import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_motion.dart';
import 'package:iptv/app/theme/app_radius.dart';
import 'package:iptv/l10n/app_localizations.dart';

/// Six-digit verification code entry.
///
/// Visually renders six cells, but underneath there is exactly one real
/// [TextField] stretched invisibly over the whole row.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.enabled,
    required this.onSubmitted,
    this.onChanged,
    this.autofocus = false,
    this.hasError = false,
    this.shakeSignal,
    this.length = 6,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool enabled;
  final ValueChanged<String> onSubmitted;
  final ValueChanged<String>? onChanged;
  final bool autofocus;
  final bool hasError;
  final Listenable? shakeSignal;
  final int length;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shakeController = AnimationController(
    vsync: this,
    duration: AppMotion.shake,
  );

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_handleTextChanged);
    widget.focusNode.addListener(_handleFocusChanged);
    widget.shakeSignal?.addListener(_playShake);
  }

  @override
  void didUpdateWidget(OtpCodeField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.shakeSignal != widget.shakeSignal) {
      oldWidget.shakeSignal?.removeListener(_playShake);
      widget.shakeSignal?.addListener(_playShake);
    }
  }

  void _handleTextChanged() {
    setState(() {});
    widget.onChanged?.call(widget.controller.text);
  }

  void _handleFocusChanged() => setState(() {});

  void _playShake() {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (reduceMotion) return;
    _shakeController.forward(from: 0);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_handleTextChanged);
    widget.focusNode.removeListener(_handleFocusChanged);
    widget.shakeSignal?.removeListener(_playShake);
    _shakeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final text = widget.controller.text;
    final activeIndex = math.min(text.length, widget.length - 1);
    final focused = widget.focusNode.hasFocus;

    return Semantics(
      textField: true,
      label: l10n.accountCodeLabel,
      hint: l10n.accountCodeFieldHint,
      value: text,
      child: SizedBox(
        height: 64,
        width: double.infinity,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AnimatedBuilder(
              animation: _shakeController,
              builder: (context, child) {
                final t = _shakeController.value;
                final dx = math.sin(t * math.pi * 6) * 8 * (1 - t);
                return Transform.translate(offset: Offset(dx, 0), child: child);
              },
              child: ExcludeSemantics(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(widget.length, (i) {
                      final char = i < text.length ? text[i] : '';
                      final isActive =
                          widget.enabled && focused && i == activeIndex;
                      final isFilled = i < text.length;
                      return Padding(
                        padding: EdgeInsets.only(left: i == 0 ? 0 : 8),
                        child: _OtpCell(
                          char: char,
                          active: isActive,
                          filled: isFilled,
                          error: widget.hasError,
                          enabled: widget.enabled,
                        ),
                      );
                    }),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: Opacity(
                opacity: 0.0,
                child: TextField(
                  controller: widget.controller,
                  focusNode: widget.focusNode,
                  enabled: widget.enabled,
                  autofocus: widget.autofocus,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(widget.length),
                  ],
                  showCursor: false,
                  enableInteractiveSelection: true,
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    counterText: '',
                    contentPadding: EdgeInsets.zero,
                    isDense: true,
                  ),
                  onSubmitted: widget.onSubmitted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OtpCell extends StatelessWidget {
  const _OtpCell({
    required this.char,
    required this.active,
    required this.filled,
    required this.error,
    required this.enabled,
  });

  final String char;
  final bool active;
  final bool filled;
  final bool error;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final borderColor = !enabled
        ? AppColors.border
        : error
        ? AppColors.error
        : active
        ? AppColors.focusRing
        : (filled ? AppColors.accent.withValues(alpha: 0.55) : AppColors.border);
    final background = !enabled
        ? AppColors.bg1.withValues(alpha: 0.5)
        : (filled || active ? AppColors.bg3 : AppColors.bg2);

    return AnimatedContainer(
      duration: AppMotion.focusDuration,
      curve: AppMotion.focusCurve,
      width: 48,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: borderColor, width: active || error ? 2 : 1),
        boxShadow: active
            ? const [
                BoxShadow(
                  color: AppColors.accentGlow,
                  blurRadius: 16,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: AnimatedSwitcher(
        duration: AppMotion.focusDuration,
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.85, end: 1.0).animate(animation),
            child: child,
          ),
        ),
        child: Text(
          char,
          key: ValueKey<String>('$char-${char.isEmpty}'),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: enabled ? AppColors.textPrimary : AppColors.textDisabled,
          ),
        ),
      ),
    );
  }
}
