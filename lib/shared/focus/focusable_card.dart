import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_motion.dart';
import 'package:iptv/app/theme/app_radius.dart';
import 'package:iptv/app/theme/app_shadows.dart';
import 'package:iptv/shared/focus/remote_focus.dart';

/// A card that shows a visible focus ring and accent glow on TV/keyboard focus.
///
/// Idle cards use a plain [Container] (no implicit animations). Hover visuals
/// are intentionally omitted — mouse-wheel scrolling over rows would otherwise
/// fire enter/exit [setState] on every card that passes under the cursor.
class FocusableCard extends StatelessWidget {
  const FocusableCard({
    super.key,
    required this.child,
    this.onTap,
    this.onFocusChange,
    this.onDirection,
    this.autofocus = false,
    this.entry = false,
    this.borderRadius,
    this.backgroundColor,
    this.borderColor,
    this.padding,
    this.focusNode,
  });

  final Widget child;
  final VoidCallback? onTap;
  final ValueChanged<bool>? onFocusChange;
  final DpadDirectionCallback? onDirection;
  final bool autofocus;
  final bool entry;
  final BorderRadius? borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final EdgeInsets? padding;
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final radius =
        borderRadius ?? BorderRadius.circular(AppRadius.card);

    return DpadFocusable(
      autofocus: autofocus,
      entry: entry,
      focusNode: focusNode,
      onSelect: onTap,
      onFocusChange: onFocusChange,
      onDirection: onDirection,
      builder: (context, state, child) {
        final visual = RemoteFocus.visualOf(context, state);
        final focused = visual.focused;
        final pressed = visual.pressed;

        final decoration = BoxDecoration(
          color: focused
              ? AppColors.bg3
              : (backgroundColor ?? AppColors.bg1),
          borderRadius: radius,
          border: Border.all(
            color: focused
                ? AppColors.accent
                : (borderColor ?? AppColors.border),
            width: focused ? 2.0 : 1.0,
          ),
          boxShadow: focused ? AppShadows.cardFocused : null,
        );

        if (!focused && !pressed) {
          return Container(
            padding: padding,
            decoration: decoration,
            child: child,
          );
        }

        return AnimatedScale(
          scale: pressed ? 0.97 : 1.06,
          duration: AppMotion.focusDuration,
          curve: AppMotion.focusCurve,
          child: AnimatedContainer(
            duration: AppMotion.focusDuration,
            curve: AppMotion.focusCurve,
            padding: padding,
            decoration: decoration,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
