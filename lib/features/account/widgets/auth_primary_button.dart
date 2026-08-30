import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_motion.dart';
import 'package:iptv/app/theme/app_radius.dart';

/// Dominant CTA on the sign-in and OTP screens.
class AuthPrimaryButton extends StatefulWidget {
  const AuthPrimaryButton({
    super.key,
    required this.label,
    required this.loadingLabel,
    required this.onPressed,
    this.loading = false,
    this.autofocus = false,
    this.focusNode,
  });

  final String label;
  final String loadingLabel;
  final VoidCallback? onPressed;
  final bool loading;
  final bool autofocus;
  final FocusNode? focusNode;

  @override
  State<AuthPrimaryButton> createState() => _AuthPrimaryButtonState();
}

class _AuthPrimaryButtonState extends State<AuthPrimaryButton> {
  bool _hovered = false;
  bool _pressed = false;
  bool _focused = false;

  bool get _enabled => widget.onPressed != null && !widget.loading;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final policy = MotionPolicy.of(context);
    final scale = _pressed && _enabled ? policy.pressScale : 1.0;
    final foreground = !_enabled
        ? AppColors.textDisabled
        : AppColors.textOnAccent;

    return Semantics(
      button: true,
      enabled: _enabled,
      label: widget.loading ? widget.loadingLabel : widget.label,
      child: Focus(
        focusNode: widget.focusNode,
        autofocus: widget.autofocus,
        onFocusChange: (f) => setState(() => _focused = f),
        onKeyEvent: (_, event) {
          if (event is KeyDownEvent &&
              _enabled &&
              (event.logicalKey == LogicalKeyboardKey.enter ||
                  event.logicalKey == LogicalKeyboardKey.select ||
                  event.logicalKey == LogicalKeyboardKey.space ||
                  event.logicalKey == LogicalKeyboardKey.gameButtonSelect)) {
            widget.onPressed?.call();
            return KeyEventResult.handled;
          }
          return KeyEventResult.ignored;
        },
        child: MouseRegion(
          cursor: _enabled
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: (_) => setState(() => _hovered = true),
          onExit: (_) {
            setState(() {
              _hovered = false;
              _pressed = false;
            });
          },
          child: GestureDetector(
            onTap: _enabled ? widget.onPressed : null,
            onTapDown: (_) => _setPressed(true),
            onTapCancel: () => _setPressed(false),
            onTapUp: (_) => _setPressed(false),
            child: AnimatedScale(
              scale: scale,
              duration: policy.press,
              curve: Curves.easeOut,
              child: AnimatedContainer(
                duration: AppMotion.focusDuration,
                curve: AppMotion.focusCurve,
                constraints: const BoxConstraints(minHeight: 56, minWidth: 48),
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  gradient: !_enabled
                      ? null
                      : LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _hovered
                              ? const [
                                  Color(0xFF33D0FF),
                                  AppColors.accentDim,
                                ]
                              : const [
                                  AppColors.accent,
                                  AppColors.accentDim,
                                ],
                        ),
                  color: !_enabled ? AppColors.bg3 : null,
                  border: Border.all(
                    color: _focused ? Colors.white : Colors.transparent,
                    width: 2,
                  ),
                  boxShadow: !_enabled
                      ? const []
                      : [
                          BoxShadow(
                            color: AppColors.accent.withValues(
                              alpha: _focused || _hovered ? 0.45 : 0.28,
                            ),
                            blurRadius: _focused || _hovered ? 28 : 18,
                            offset: const Offset(0, 8),
                          ),
                        ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: widget.loading
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: foreground,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            widget.loadingLabel,
                            style: TextStyle(
                              color: foreground,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              letterSpacing: 0.2,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        widget.label,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0.2,
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
