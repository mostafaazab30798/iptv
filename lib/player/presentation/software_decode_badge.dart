import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/player/domain/enums/software_decode_fallback_tier.dart';

/// Persistent amber chip displayed in the player overlay when hardware decoding is
/// unavailable and libmpv has fallen back to software decode.
///
/// Design rationale (§8.2):
/// A persistent badge (not a toast) is used because viewers watching a full match need
/// to understand *why* occasional non-key frames appear softer — without needing the
/// explanation to re-appear every few minutes as motion varies.
///
/// Tapping the badge calls [onTap], which should open the Diagnostics HUD.
class SoftwareDecodeBadge extends StatelessWidget {
  const SoftwareDecodeBadge({
    super.key,
    required this.tier,
    this.onTap,
  });

  final SoftwareDecodeFallbackTier tier;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    if (!tier.isSoftwareFallback) return const SizedBox.shrink();

    final isTier2 = tier == SoftwareDecodeFallbackTier.frameSkip;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: (isTier2 ? Colors.red : Colors.orange).withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 0.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: isTier2 ? AppIcons.warning : AppIcons.memory,
              color: Colors.white,
              size: 12,
            ),
            const SizedBox(width: 5),
            Text(
              isTier2
                  ? 'Software Decode — Quality Reduced'
                  : 'Software Decode — Hardware Limit',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
