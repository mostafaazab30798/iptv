import 'package:flutter/material.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/shared/widgets/shimmer.dart';

/// Reusable shimmer-based loading indicator.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({
    super.key,
    this.message,
    this.size = 32,
  });

  final String? message;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Shimmer(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size * 1.5,
              height: size * 1.5,
              decoration: BoxDecoration(
                color: AppColors.bg2,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Center(
                child: Container(
                  width: size * 0.7,
                  height: size * 0.7,
                  decoration: const BoxDecoration(
                    color: AppColors.accent,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
            if (message != null) ...[
              const SizedBox(height: 16),
              const ShimmerBox(
                width: 120,
                height: 14,
                borderRadius: 4,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
