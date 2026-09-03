import 'package:flutter/material.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_radius.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/shared/widgets/shimmer.dart';

// =============================================================================
// Home Screen Skeleton
// =============================================================================

/// Skeleton shimmer effect for the Home screen mimicking the hero banner and content rows.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isPortrait =
        MediaQuery.orientationOf(context) == Orientation.portrait;
    final bannerHeight = isPortrait ? 260.0 : (screenWidth > 1200 ? 360.0 : 300.0);

    return Shimmer(
      child: ListView(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
        children: [
          // 1. Hero Banner Skeleton
          Container(
            width: double.infinity,
            height: bannerHeight,
            margin: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              color: AppColors.bg2,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Tag / Badge
                const ShimmerBox(width: 80, height: 22, borderRadius: 6),
                const SizedBox(height: 12),
                // Title
                ShimmerBox(
                  width: screenWidth * 0.45 > 280 ? 280 : screenWidth * 0.45,
                  height: 28,
                  borderRadius: 6,
                ),
                const SizedBox(height: 10),
                // Subtitle / metadata
                const ShimmerBox(width: 180, height: 14, borderRadius: 4),
                const SizedBox(height: 20),
                // Action Buttons
                const Row(
                  children: [
                    ShimmerBox(width: 120, height: 40, borderRadius: 10),
                    SizedBox(width: 12),
                    ShimmerBox(width: 110, height: 40, borderRadius: 10),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // 2. Section 1 (Continue Watching / History)
          const _HorizontalRowSkeleton(
            titleWidth: 140,
            cardWidth: 160,
            cardHeight: 110,
            count: 5,
          ),
          const SizedBox(height: AppSpacing.lg),

          // 3. Section 2 (Featured Movies)
          const _HorizontalRowSkeleton(
            titleWidth: 130,
            cardWidth: 120,
            cardHeight: 180,
            count: 6,
          ),
          const SizedBox(height: AppSpacing.lg),

          // 4. Section 3 (Popular Series)
          const _HorizontalRowSkeleton(
            titleWidth: 120,
            cardWidth: 120,
            cardHeight: 180,
            count: 6,
          ),
        ],
      ),
    );
  }
}

class _HorizontalRowSkeleton extends StatelessWidget {
  const _HorizontalRowSkeleton({
    required this.titleWidth,
    required this.cardWidth,
    required this.cardHeight,
    this.count = 5,
  });

  final double titleWidth;
  final double cardWidth;
  final double cardHeight;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              const ShimmerBox(width: 18, height: 18, borderRadius: 4),
              const SizedBox(width: 8),
              ShimmerBox(width: titleWidth, height: 18, borderRadius: 4),
              const Spacer(),
              const ShimmerBox(width: 60, height: 14, borderRadius: 4),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // Horizontal Cards
          SizedBox(
            height: cardHeight,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: count,
              separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) => ShimmerBox(
                width: cardWidth,
                height: cardHeight,
                borderRadius: AppRadius.md,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Category Hub Skeleton
// =============================================================================

/// Skeleton shimmer effect for Category list views (Movies, Series, Live TV categories).
class CategoryListSkeleton extends StatelessWidget {
  const CategoryListSkeleton({super.key, this.itemCount = 10});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) => Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.bg1,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              // Category Icon
              ShimmerBox(width: 40, height: 40, borderRadius: 10),
              SizedBox(width: 14),
              // Category Title & Subtitle
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ShimmerBox(width: 140, height: 16, borderRadius: 4),
                  SizedBox(height: 6),
                  ShimmerBox(width: 60, height: 12, borderRadius: 4),
                ],
              ),
              Spacer(),
              // Arrow Indicator
              ShimmerBox(width: 16, height: 16, borderRadius: 4),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Poster Grid Skeleton
// =============================================================================

/// Skeleton shimmer effect for Movies, Series, and Video grids.
class PosterGridSkeleton extends StatelessWidget {
  const PosterGridSkeleton({super.key, this.itemCount = 18});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: GridView.builder(
        padding: const EdgeInsets.all(AppSpacing.md),
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 170,
          childAspectRatio: 2 / 3,
          crossAxisSpacing: AppSpacing.md,
          mainAxisSpacing: AppSpacing.md,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) => Container(
          decoration: BoxDecoration(
            color: AppColors.bg1,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.border),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster Body
              Expanded(
                child: ShimmerBox(
                  width: double.infinity,
                  height: double.infinity,
                  borderRadius: AppRadius.md,
                ),
              ),
              // Poster Bottom Info Line
              Padding(
                padding: EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ShimmerBox(width: double.infinity, height: 12, borderRadius: 3),
                    SizedBox(height: 6),
                    ShimmerBox(width: 60, height: 10, borderRadius: 3),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Channel List Skeleton
// =============================================================================

/// Skeleton shimmer effect for Live TV channels and search channel lists.
class ChannelListSkeleton extends StatelessWidget {
  const ChannelListSkeleton({super.key, this.itemCount = 12});

  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) => Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF10131B),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withAlpha(18)),
          ),
          child: const Row(
            children: [
              // 44x44 Squircle Logo Stage
              ShimmerBox(width: 44, height: 44, borderRadius: 12),
              SizedBox(width: 14),
              // Channel info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShimmerBox(width: 160, height: 15, borderRadius: 4),
                    SizedBox(height: 6),
                    ShimmerBox(width: 100, height: 11, borderRadius: 3),
                  ],
                ),
              ),
              // Action buttons placeholder
              ShimmerBox(width: 28, height: 28, shape: BoxShape.circle),
              SizedBox(width: 8),
              ShimmerBox(width: 28, height: 28, shape: BoxShape.circle),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// Series Detail Skeleton
// =============================================================================

/// Skeleton shimmer effect for Series seasons & episodes view.
class SeriesDetailSkeleton extends StatelessWidget {
  const SeriesDetailSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Season tabs bar
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                ShimmerBox(width: 90, height: 34, borderRadius: 17),
                SizedBox(width: 10),
                ShimmerBox(width: 90, height: 34, borderRadius: 17),
                SizedBox(width: 10),
                ShimmerBox(width: 90, height: 34, borderRadius: 17),
              ],
            ),
          ),
          const Divider(color: Colors.white12, height: 1),
          // Episodes list
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 6,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) => Container(
                height: 76,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.bg1,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    ShimmerBox(width: 96, height: double.infinity, borderRadius: 8),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ShimmerBox(width: 180, height: 14, borderRadius: 4),
                          SizedBox(height: 6),
                          ShimmerBox(width: 120, height: 11, borderRadius: 3),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// =============================================================================
// Search Skeleton
// =============================================================================

/// Skeleton shimmer effect for Search results.
class SearchSkeleton extends StatelessWidget {
  const SearchSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.md),
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const ShimmerBox(width: 140, height: 18, borderRadius: 4),
          const SizedBox(height: AppSpacing.sm),
          // Results Row
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 4,
              separatorBuilder: (context, index) => const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) => const ShimmerBox(
                width: 110,
                height: 160,
                borderRadius: AppRadius.md,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          const ShimmerBox(width: 120, height: 18, borderRadius: 4),
          const SizedBox(height: AppSpacing.sm),
          // Channels List
          for (int i = 0; i < 4; i++) ...[
            Container(
              height: 56,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.bg1,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                children: [
                  ShimmerBox(width: 38, height: 38, borderRadius: 8),
                  SizedBox(width: 12),
                  ShimmerBox(width: 160, height: 14, borderRadius: 4),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// =============================================================================
// Favorites & History Skeleton
// =============================================================================

/// Skeleton shimmer effect for Favorites screen.
class FavoritesSkeleton extends StatelessWidget {
  const FavoritesSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const Shimmer(
      child: Column(
        children: [
          // Filter tabs
          Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                ShimmerBox(width: 70, height: 34, borderRadius: 17),
                SizedBox(width: 8),
                ShimmerBox(width: 90, height: 34, borderRadius: 17),
                SizedBox(width: 8),
                ShimmerBox(width: 90, height: 34, borderRadius: 17),
                SizedBox(width: 8),
                ShimmerBox(width: 90, height: 34, borderRadius: 17),
              ],
            ),
          ),
          Expanded(
            child: PosterGridSkeleton(itemCount: 12),
          ),
        ],
      ),
    );
  }
}

/// Skeleton shimmer effect for History screen.
class HistorySkeleton extends StatelessWidget {
  const HistorySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: ListView.separated(
        padding: const EdgeInsets.all(AppSpacing.md),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 8,
        separatorBuilder: (context, index) => const SizedBox(height: 12),
        itemBuilder: (context, index) => Container(
          height: 90,
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.bg1,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: const Row(
            children: [
              ShimmerBox(width: 120, height: double.infinity, borderRadius: 10),
              SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ShimmerBox(width: 180, height: 16, borderRadius: 4),
                    SizedBox(height: 8),
                    ShimmerBox(width: 100, height: 12, borderRadius: 4),
                    SizedBox(height: 8),
                    ShimmerBox(width: double.infinity, height: 4, borderRadius: 2),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
