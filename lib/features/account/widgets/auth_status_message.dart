import 'package:flutter/material.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_motion.dart';
import 'package:iptv/app/theme/app_spacing.dart';

/// Tone of an inline [AuthStatusMessage].
///
/// Each tone pairs a color with a distinct icon so state is never conveyed
/// by color alone.
enum AuthStatusTone { info, error, success }

/// An inline, screen-reader-announced status line used for validation
/// errors, network failures, extended-wait hints, and resend confirmations.
///
/// Rendered as a live region so assistive technology announces the change
/// as soon as [message] updates, without needing a transient SnackBar.
class AuthStatusMessage extends StatelessWidget {
  const AuthStatusMessage({
    super.key,
    required this.message,
    this.tone = AuthStatusTone.info,
  });

  final String? message;
  final AuthStatusTone tone;

  IconData _icon() {
    switch (tone) {
      case AuthStatusTone.error:
        return Icons.error_outline_rounded;
      case AuthStatusTone.success:
        return Icons.check_circle_outline_rounded;
      case AuthStatusTone.info:
        return Icons.info_outline_rounded;
    }
  }

  Color _color() {
    switch (tone) {
      case AuthStatusTone.error:
        return AppColors.error;
      case AuthStatusTone.success:
        return AppColors.success;
      case AuthStatusTone.info:
        return AppColors.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final policy = MotionPolicy.of(context);
    final hasMessage = message != null && message!.isNotEmpty;
    return AnimatedSize(
      duration: policy.fast,
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: !hasMessage
          ? const SizedBox(width: double.infinity)
          : Padding(
              padding: const EdgeInsets.only(top: AppSpacing.md),
              child: Semantics(
                liveRegion: true,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_icon(), size: 16, color: _color()),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        message!,
                        style: TextStyle(
                          color: _color(),
                          fontSize: 13,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
