import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_radius.dart';

/// Reusable cached image widget with disk + memory caching, placeholder, and error fallback.
///
/// Pass [memCacheWidth] / [memCacheHeight] (logical pixels) to cap the decoded bitmap size in
/// the Flutter image cache. Callers that know the rendered size (e.g. poster grids) should
/// always provide these to avoid decoding 300–1000px source images into multi-MB bitmaps when
/// the widget is only ~170px wide on screen. Flutter multiplies by the device pixel ratio
/// internally, so pass logical pixels (same as [width]/[height]).
class CachedImage extends StatelessWidget {
  const CachedImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.fallbackIcon = AppIcons.imageFallback,
    this.memCacheWidth,
    this.memCacheHeight,
  });

  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final dynamic fallbackIcon;

  /// Optional memory-cache width cap in logical pixels.
  /// Defaults to [width] when not provided (if [width] is set).
  final int? memCacheWidth;

  /// Optional memory-cache height cap in logical pixels.
  /// Defaults to [height] when not provided (if [height] is set).
  final int? memCacheHeight;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(AppRadius.sm);

    if (imageUrl == null || imageUrl!.isEmpty) {
      return _buildPlaceholder(radius);
    }

    // Derive memory cache dimensions from explicit params or fall back to widget size.
    // CachedNetworkImage multiplies by devicePixelRatio internally.
    final effectiveCacheWidth = memCacheWidth ?? width?.ceil();
    final effectiveCacheHeight = memCacheHeight ?? height?.ceil();

    return ClipRRect(
      borderRadius: radius,
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: effectiveCacheWidth,
        memCacheHeight: effectiveCacheHeight,
        httpHeaders: const {
          'User-Agent':
              'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
          'Accept': 'image/avif,image/webp,image/apng,image/svg+xml,image/*,*/*;q=0.8',
        },
        placeholder: (context, url) => _buildLoading(radius),
        errorWidget: (context, url, error) => _buildPlaceholder(radius),
      ),
    );
  }

  Widget _buildPlaceholder(BorderRadius radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: radius,
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: fallbackIcon is IconData
            ? Icon(fallbackIcon as IconData, color: AppColors.textDisabled, size: 24)
            : HugeIcon(icon: fallbackIcon as List<List<dynamic>>, color: AppColors.textDisabled, size: 24),
      ),
    );
  }

  Widget _buildLoading(BorderRadius radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.bg2,
        borderRadius: radius,
      ),
      child: const Center(
        child: SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.accent,
          ),
        ),
      ),
    );
  }
}
