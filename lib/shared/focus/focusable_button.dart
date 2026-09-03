import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_motion.dart';
import 'package:iptv/app/theme/app_radius.dart';
import 'package:iptv/shared/focus/remote_focus.dart';

/// A focusable button for TV / keyboard navigation.
class FocusableButton extends StatelessWidget {
  const FocusableButton({
    super.key,
    required this.label,
    this.icon,
    required this.onPressed,
    this.autofocus = false,
    this.focusNode,
    this.isSelected = false,
  });

  final String label;
  final dynamic icon;
  final VoidCallback? onPressed;
  final bool autofocus;
  final FocusNode? focusNode;
  final bool isSelected;

  @override
  Widget build(BuildContext context) {
    return DpadFocusable(
      autofocus: autofocus,
      focusNode: focusNode,
      onSelect: onPressed,
      builder: (context, state, child) {
        final visual = RemoteFocus.visualOf(context, state);
        final isActive = visual.focused || isSelected;
        final contentColor =
            isActive ? AppColors.textOnAccent : AppColors.textPrimary;

        return AnimatedScale(
          scale: visual.pressed
              ? 0.96
              : (visual.focused ? 1.06 : 1.0),
          duration: AppMotion.focusDuration,
          curve: AppMotion.focusCurve,
          child: AnimatedContainer(
            duration: AppMotion.focusDuration,
            curve: AppMotion.focusCurve,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isActive ? AppColors.accent : AppColors.bg2,
              borderRadius: BorderRadius.circular(AppRadius.button),
              border: Border.all(
                color: visual.focused ? Colors.white : AppColors.border,
                width: visual.focused ? 2 : 1,
              ),
              boxShadow: visual.focused
                  ? [
                      BoxShadow(
                        color: AppColors.accent.withValues(alpha: 0.45),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[
                  icon is IconData
                      ? Icon(
                          icon as IconData,
                          size: 16,
                          color: contentColor,
                        )
                      : HugeIcon(
                          icon: icon as List<List<dynamic>>,
                          size: 16,
                          color: contentColor,
                        ),
                  const SizedBox(width: 8),
                ],
                Text(
                  label,
                  style: TextStyle(
                    color: contentColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
      child: const SizedBox.shrink(),
    );
  }
}
