import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/shared/focus/remote_focus.dart';

/// A single D-pad / remote stop for chrome (nav items, icon buttons, hero
/// actions). Cards should keep using [FocusableCard] instead.
///
/// Unfocused instances stay animation-free so dense Home rows scroll smoothly.
class TvFocusable extends StatelessWidget {
  const TvFocusable({
    super.key,
    required this.child,
    this.onSelect,
    this.onFocusChange,
    this.onDirection,
    this.focusNode,
    this.autofocus = false,
    this.enabled = true,
    this.entry = false,
    this.scale = 1.08,
  });

  final Widget child;
  final VoidCallback? onSelect;
  final ValueChanged<bool>? onFocusChange;
  final DpadDirectionCallback? onDirection;
  final FocusNode? focusNode;
  final bool autofocus;
  final bool enabled;
  final bool entry;
  final double scale;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onSelect,
      child: DpadFocusable(
        autofocus: autofocus,
        enabled: enabled,
        entry: entry,
        focusNode: focusNode,
        onSelect: onSelect,
        onFocusChange: onFocusChange,
        onDirection: onDirection,
      builder: (context, state, child) {
        final visual = RemoteFocus.visualOf(context, state);
        final focused = visual.focused;
        final pressed = visual.pressed;

        if (!focused && !pressed) {
          return child;
        }

        return AnimatedScale(
          scale: pressed ? 0.94 : scale,
          duration: const Duration(milliseconds: 140),
          curve: Curves.easeOutCubic,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            curve: Curves.easeOutCubic,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: focused ? AppColors.accent : Colors.transparent,
                width: 2,
              ),
              boxShadow: focused
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.45),
                        blurRadius: 12,
                        spreadRadius: 0.5,
                      ),
                    ]
                  : null,
            ),
            child: child,
          ),
        );
      },
      child: child,
      ),
    );
  }
}
