import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/app/theme/app_radius.dart';
import 'package:iptv/app/theme/app_spacing.dart';
import 'package:iptv/features/home/home_controller.dart';
import 'package:iptv/shared/extensions/context_extensions.dart';
import 'package:iptv/shared/focus/focusable_button.dart';
import 'package:iptv/shared/widgets/cached_image.dart';

/// Ultra-modern full-bleed Hero Banner for OTT / Home screen.
///
/// Features:
/// - Full-width high-resolution backdrop movie/stream artwork.
/// - RTL-aware directional cinematic edge-fade scrims so typography is crystal-clear in all languages.
/// - Vibrant micro-badges (4K UHD, IMDb Star Rating, Category tag).
/// - Large bold typography + plot description.
/// - High-contrast CTA Play button + Secondary Action button.
/// - Desktop/TV 3D thumbnail preview poster on right.
class HomeHeroBanner extends StatelessWidget {
  const HomeHeroBanner({
    super.key,
    required this.item,
    required this.onPlay,
    this.onSecondaryAction,
    this.secondaryActionLabel,
  });

  final HomeHeroItem item;
  final VoidCallback onPlay;
  final VoidCallback? onSecondaryAction;
  final String? secondaryActionLabel;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final isRtl = Directionality.of(context) == TextDirection.rtl;
    final showPoster = screenWidth > 860 && !isPortrait;

    // Dynamic responsive height matching industry standards (Apple TV/Netflix)
    final bannerHeight = isPortrait ? 300.0 : (screenWidth > 1200 ? 400.0 : 340.0);

    return Container(
      width: double.infinity,
      height: bannerHeight,
      margin: const EdgeInsets.only(bottom: AppSpacing.lg),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full-bleed backdrop movie artwork
          if (item.backdropUrl != null && item.backdropUrl!.isNotEmpty)
            Positioned.fill(
              child: CachedImage(
                imageUrl: item.backdropUrl,
                fit: BoxFit.cover,
                fallbackIcon: AppIcons.movies,
              ),
            )
          else
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF141A29), Color(0xFF090A0F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),

          // 2. High-end Layered Directional Cinematic Transparency Overlays
          // Start-to-End scrim: 90% opacity on text side -> translucent in middle -> transparent on other side
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: isRtl ? Alignment.centerRight : Alignment.centerLeft,
                  end: isRtl ? Alignment.centerLeft : Alignment.centerRight,
                  stops: const [0.0, 0.45, 0.75, 1.0],
                  colors: const [
                    Color(0xF0080B11),
                    Color(0xB3080B11),
                    Color(0x40080B11),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // Top-to-Bottom scrim: prevents bright sky/top background from clashing with top edges
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  stops: [0.0, 0.35, 1.0],
                  colors: [
                    Color(0xFF07090E),
                    Color(0x9907090E),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // 3. Main Interactive Hero Stage
          Padding(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth > 600 ? 32.0 : 20.0,
              vertical: 24.0,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left Content: Badges + Title + Description + CTA
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Micro Badges Row
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          // Live Indicator / 4K UHD Badge
                          if (item.type == HeroItemType.live)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.redAccent.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 5),
                                  Text(
                                    context.l10n.labelLive.toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 0.8,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [AppColors.accent, Color(0xFF00B0FF)],
                                ),
                                borderRadius: BorderRadius.circular(6),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.accent.withValues(alpha: 0.4),
                                    blurRadius: 8,
                                  ),
                                ],
                              ),
                              child: const Text(
                                '4K ULTRA HD',
                                style: TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),

                          // Rating Pill with Star
                          if (item.rating != null && item.rating!.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFFB300).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: const Color(0xFFFFB300).withValues(alpha: 0.3)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const HugeIcon(icon: AppIcons.star, size: 13, color: Color(0xFFFFB300)),
                                  const SizedBox(width: 3),
                                  Text(
                                    item.rating!,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Cinematic Title
                      Text(
                        item.title,
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: isPortrait ? 22 : 36,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.6,
                          height: 1.15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 10),

                      // Movie Plot / Description
                      if (item.description != null)
                        Text(
                          item.description!,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 14,
                            height: 1.4,
                          ),
                          maxLines: isPortrait ? 2 : 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                      const SizedBox(height: 20),

                      // Interactive Action Buttons
                      Row(
                        children: [
                          FocusableButton(
                            label: item.type == HeroItemType.live
                                ? '${context.l10n.actionWatch} ${context.l10n.labelLive}'
                                : context.l10n.actionWatch,
                            icon: AppIcons.play,
                            onPressed: onPlay,
                            autofocus: true,
                          ),
                          if (onSecondaryAction != null) ...[
                            const SizedBox(width: 12),
                            FocusableButton(
                              label: secondaryActionLabel ??
                                  (item.type == HeroItemType.live
                                      ? context.l10n.homeTvGuide
                                      : context.l10n.homeAllMovies),
                              icon: item.type == HeroItemType.live
                                  ? AppIcons.gridView
                                  : AppIcons.info,
                              onPressed: onSecondaryAction,
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Right 3D Poster Thumbnail Preview (for wide desktop & TV layouts)
                if (showPoster && item.posterUrl != null && item.posterUrl!.isNotEmpty) ...[
                  const SizedBox(width: 48),
                  Container(
                    width: 180,
                    height: 260,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.5),
                          blurRadius: 30,
                          offset: const Offset(0, 15),
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CachedImage(
                      imageUrl: item.posterUrl,
                      fit: BoxFit.cover,
                      fallbackIcon: AppIcons.movies,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
