import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_motion.dart';
import 'package:iptv/app/theme/app_radius.dart';
import 'package:iptv/app/theme/app_shadows.dart';

/// A card that shows a visible focus ring and accent glow on TV/keyboard focus.
/// Use this as the base for any focusable card in the UI.
class FocusableCard extends StatefulWidget {
  const FocusableCard({
    super.key,
    required this.child,
    this.onTap,
    this.onFocusChange,
    this.autofocus = false,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.padding,
    this.focusNode,
  });

  final Widget child;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onFocusChange;
  final bool autofocus;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsets? padding;
  final FocusNode? focusNode;

  @override
  State<FocusableCard> createState() => _FocusableCardState();
}

class _FocusableCardState extends State<FocusableCard> {
  bool _focused = false;
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final radius =
        widget.borderRadius ?? BorderRadius.circular(AppRadius.card);
    final isActive = _focused || _hovered;

    return Focus(
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      onFocusChange: (f) {
        setState(() => _focused = f);
        widget.onFocusChange?.call(f);
      },
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
             event.logicalKey == LogicalKeyboardKey.enter ||
             event.logicalKey == LogicalKeyboardKey.gameButtonSelect ||
             event.logicalKey == LogicalKeyboardKey.space)) {
          widget.onTap?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovered = true),
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: AppMotion.focusDuration,
            curve: AppMotion.focusCurve,
            padding: widget.padding,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.bg3
                  : (widget.backgroundColor ?? AppColors.bg1),
              borderRadius: radius,
              border: Border.all(
                color: _focused
                    ? AppColors.borderFocused
                    : (widget.borderColor ?? AppColors.border),
                width: _focused ? 1.5 : 1.0,
              ),
              boxShadow: _focused ? AppShadows.cardFocused : AppShadows.card,
            ),
            child: widget.child,
          ),
        ),
      ),
    );
  }
}
