import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_radius.dart';
import 'package:iptv/core/logos/logo_resolver.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/shared/widgets/cached_image.dart';

/// Intelligent channel logo widget.
///
/// Features:
/// 1. Instant local asset loading for verified bundled channels (e.g., beIN SPORTS).
/// 2. Graceful remote fallback using [CachedImage] with anti-block headers.
/// 3. Initial-based & generic icon fallback when no logo is available or remote fails.
/// 4. Never displays a broken-image state.
/// 5. Dynamically fills parent container when [width] and [height] are null.
class SmartChannelLogo extends StatelessWidget {
  const SmartChannelLogo({
    super.key,
    this.channel,
    this.channelName,
    this.logoUrl,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
    this.borderRadius,
    this.fallbackIcon = AppIcons.live,
    this.showInitials = true,
    this.semanticLabel,
    this.backgroundColor,
  });

  /// Channel domain entity (preferred).
  final Channel? channel;

  /// Optional channel name if [channel] is not directly passed.
  final String? channelName;

  /// Optional remote logo URL if [channel] is not directly passed.
  final String? logoUrl;

  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final dynamic fallbackIcon;
  final bool showInitials;
  final String? semanticLabel;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final effectiveRadius = borderRadius ?? BorderRadius.circular(AppRadius.sm);
    final effectiveName = channel?.name ?? channelName ?? '';
    final effectiveUrl = channel?.streamIcon ?? logoUrl;

    final result = channel != null
        ? LogoResolver.resolve(channel!)
        : LogoResolver.resolveByName(effectiveName, remoteUrl: effectiveUrl);

    // 1. Bundled Local Asset (Instant, Zero Network)
    if (result.isLocal && result.assetPath != null) {
      return Semantics(
        label: semanticLabel ?? effectiveName,
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.transparent,
            borderRadius: effectiveRadius,
          ),
          clipBehavior: Clip.antiAlias,
          child: Image.asset(
            result.assetPath!,
            width: width,
            height: height,
            fit: fit,
            errorBuilder: (context, error, stackTrace) =>
                _buildFallback(effectiveRadius, result.initials),
          ),
        ),
      );
    }

    // 2. Remote Provider URL (Cached with Fallback)
    if (result.isRemote && result.remoteUrl != null) {
      return Semantics(
        label: semanticLabel ?? effectiveName,
        child: CachedImage(
          imageUrl: result.remoteUrl,
          width: width,
          height: height,
          fit: fit,
          borderRadius: effectiveRadius,
          fallbackIcon: fallbackIcon,
          memCacheWidth: (width ?? 64).ceil(),
          memCacheHeight: (height ?? 64).ceil(),
        ),
      );
    }

    // 3. Fallback Initials / Icon
    return _buildFallback(effectiveRadius, result.initials);
  }

  Widget _buildFallback(BorderRadius radius, String? initials) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.bg2,
        borderRadius: radius,
        border: Border.all(color: AppColors.border),
      ),
      child: Center(
        child: (showInitials && initials != null && initials.isNotEmpty)
            ? Text(
                initials,
                style: TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: (height != null) ? (height! * 0.32).clamp(9.0, 16.0) : 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              )
            : (fallbackIcon is IconData
                ? Icon(
                    fallbackIcon as IconData,
                    color: AppColors.textDisabled,
                    size: (height != null) ? (height! * 0.5).clamp(16.0, 28.0) : 20,
                  )
                : HugeIcon(
                    icon: fallbackIcon as List<List<dynamic>>,
                    color: AppColors.textDisabled,
                    size: (height != null) ? (height! * 0.5).clamp(16.0, 28.0) : 20,
                  )),
      ),
    );
  }
}
