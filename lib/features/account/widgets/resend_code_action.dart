import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_motion.dart';
import 'package:iptv/l10n/app_localizations.dart';

/// "Resend code" action, kept visually and semantically separate from the
/// primary verify button so the two never compete for the user's tap/click.
///
/// Shows a countdown while a resend cooldown is active, and a clearly
/// enabled label once it lifts. Handles Enter/Space/D-pad-select explicitly
/// (matching the rest of the app's focus widgets) so it is reachable without
/// touch on TV and desktop.
class ResendCodeAction extends StatefulWidget {
  const ResendCodeAction({
    super.key,
    required this.secondsRemaining,
    required this.onPressed,
    this.enabled = true,
    this.focusNode,
  });

  final int secondsRemaining;
  final VoidCallback onPressed;

  /// External interactivity gate (e.g. while another request is in flight),
  /// independent of the countdown shown in [secondsRemaining].
  final bool enabled;
  final FocusNode? focusNode;

  @override
  State<ResendCodeAction> createState() => _ResendCodeActionState();
}

class _ResendCodeActionState extends State<ResendCodeAction> {
  bool _hovered = false;
  bool _focused = false;

  bool get _enabled => widget.enabled && widget.secondsRemaining <= 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final label = widget.secondsRemaining > 0
        ? l10n.accountResendCooldown(widget.secondsRemaining)
        : l10n.accountResendCode;
    final color = !_enabled
        ? AppColors.textDisabled
        : (_focused || _hovered ? AppColors.accent : AppColors.textPrimary);

    return Semantics(
      button: true,
      enabled: _enabled,
      label: label,
      child: Focus(
        focusNode: widget.focusNode,
        onFocusChange: (f) => setState(() => _focused = f),
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              _enabled &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.select ||
                  event.logicalKey == LogicalKeyboardKey.space ||
                  event.logicalKey == LogicalKeyboardKey.gameButtonSelect)) {
            widget.onPressed();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: MouseRegion(
          cursor: _enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) => setState(() => _hovered = false),
          child: GestureDetector(
            onTap: _enabled ? widget.onPressed : null,
            child: AnimatedContainer(
              duration: AppMotion.focusDuration,
              curve: AppMotion.focusCurve,
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _focused ? AppColors.focusRing : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
