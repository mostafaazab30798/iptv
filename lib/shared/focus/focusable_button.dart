import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_motion.dart';
import 'package:iptv/app/theme/app_radius.dart';

/// A focusable button for TV / keyboard navigation.
class FocusableButton extends StatefulWidget {
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
  State<FocusableButton> createState() => _FocusableButtonState();
}

class _FocusableButtonState extends State<FocusableButton> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final isActive = _focused || widget.isSelected;

    return Focus(
      autofocus: widget.autofocus,
      focusNode: widget.focusNode,
      onFocusChange: (f) => setState(() => _focused = f),
      onKeyEvent: (_, event) {
        if (event is KeyDownEvent &&
            (event.logicalKey == LogicalKeyboardKey.select ||
             event.logicalKey == LogicalKeyboardKey.enter ||
             event.logicalKey == LogicalKeyboardKey.space)) {
          widget.onPressed?.call();
          return KeyEventResult.handled;
        }
        return KeyEventResult.ignored;
      },
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppMotion.focusDuration,
          curve: AppMotion.focusCurve,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isActive ? AppColors.accent : AppColors.bg2,
            borderRadius: BorderRadius.circular(AppRadius.button),
            border: Border.all(
              color: _focused ? AppColors.accent : AppColors.border,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                widget.icon is IconData
                    ? Icon(
                        widget.icon as IconData,
                        size: 16,
                        color: isActive ? AppColors.textOnAccent : AppColors.textPrimary,
                      )
                    : HugeIcon(
                        icon: widget.icon as List<List<dynamic>>,
                        size: 16,
                        color: isActive ? AppColors.textOnAccent : AppColors.textPrimary,
                      ),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: isActive ? AppColors.textOnAccent : AppColors.textPrimary,
                  fontSize: 14,
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
