import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:iptv/app/theme/app_colors.dart';
import 'package:iptv/app/theme/app_icons.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/shared/focus/focusable_card.dart';
import 'package:iptv/shared/widgets/smart_channel_logo.dart';

/// State-of-the-Art Category Card inspired by modern Dribbble & Apple TV design:
/// - Diagonal semi-transparent watermark logo/icon embedded across the background
/// - Freely framed foreground logo/icon without rigid enclosing boxes
/// - Subtle category-accented ambient gradient wash
/// - High-contrast typography with glowing selected states
/// - Minimalist frosted count chip
/// - Interactive spring hover chevron animation
class CategoryCard extends StatefulWidget {
  const CategoryCard({
    super.key,
    required this.title,
    this.itemCount,
    this.itemCountLabel,
    this.icon,
    this.onTap,
    this.isSelected = false,
    this.accentColor,
    this.isAllCard = false,
    this.leadingChannel,
    this.logoUrl,
  });

  final String title;
  final int? itemCount;
  final String? itemCountLabel;
  final dynamic icon;
  final VoidCallback? onTap;
  final bool isSelected;
  final Color? accentColor;
  final bool isAllCard;
  final Channel? leadingChannel;
  final String? logoUrl;

  @override
  State<CategoryCard> createState() => _CategoryCardState();
}

class _CategoryCardState extends State<CategoryCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = widget.accentColor ?? _getAccentForName(widget.title, widget.isAllCard);
    final effectiveIcon = widget.icon ?? _getIconForName(widget.title, widget.isAllCard);
    final hasLeadingChannelOrLogo = widget.leadingChannel != null || (widget.logoUrl != null && widget.logoUrl!.isNotEmpty);
    final isSelected = widget.isSelected;
    final isActive = isSelected || _isHovered;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: FocusableCard(
        onTap: widget.onTap,
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                isSelected
                    ? effectiveColor.withAlpha(45)
                    : _isHovered
                        ? effectiveColor.withAlpha(22)
                        : const Color(0xFF131722),
                isSelected
                    ? const Color(0xFF0F121C)
                    : const Color(0xFF090B10),
              ],
            ),
            border: Border.all(
              color: isSelected
                  ? effectiveColor
                  : _isHovered
                      ? effectiveColor.withAlpha(140)
                      : Colors.white.withAlpha(18),
              width: isSelected ? 1.4 : 0.9,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: effectiveColor.withAlpha(isSelected ? 90 : 45),
                      blurRadius: isSelected ? 18 : 12,
                      offset: const Offset(0, 3),
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withAlpha(80),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              // 1. Diagonal Large Semi-Transparent Watermark Logo / Icon on the Left Side
              Positioned(
                left: -14,
                top: -14,
                child: Transform.rotate(
                  angle: 0.22, // Diagonal tilt angle
                  child: Opacity(
                    opacity: isSelected ? 0.22 : (_isHovered ? 0.17 : 0.09),
                    child: hasLeadingChannelOrLogo
                        ? SizedBox(
                            width: 95,
                            height: 95,
                            child: SmartChannelLogo(
                              channel: widget.leadingChannel,
                              logoUrl: widget.logoUrl,
                              fit: BoxFit.contain,
                              fallbackIcon: effectiveIcon,
                              showInitials: false,
                              backgroundColor: Colors.transparent,
                            ),
                          )
                        : (effectiveIcon is IconData
                            ? Icon(
                                effectiveIcon,
                                size: 92,
                                color: effectiveColor,
                              )
                            : HugeIcon(
                                icon: effectiveIcon as List<List<dynamic>>,
                                size: 92,
                                color: effectiveColor,
                              )),
                  ),
                ),
              ),

              // 2. Foreground Interactive Content Row
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    // Freely Framed Foreground Icon / Logo (No rigid box)
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: Center(
                        child: hasLeadingChannelOrLogo
                            ? SmartChannelLogo(
                                channel: widget.leadingChannel,
                                logoUrl: widget.logoUrl,
                                width: 34,
                                height: 34,
                                fit: BoxFit.contain,
                                fallbackIcon: effectiveIcon,
                                showInitials: false,
                                backgroundColor: Colors.transparent,
                              )
                            : (effectiveIcon is IconData
                                ? Icon(
                                    effectiveIcon,
                                    size: 26,
                                    color: isSelected ? Colors.white : effectiveColor,
                                  )
                                : HugeIcon(
                                    icon: effectiveIcon as List<List<dynamic>>,
                                    size: 26,
                                    color: isSelected ? Colors.white : effectiveColor,
                                  )),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Category Title & Minimalist Item Count
                    Expanded(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : _isHovered
                                      ? Colors.white
                                      : AppColors.textPrimary,
                              fontSize: 14.5,
                              fontWeight: isActive ? FontWeight.w800 : FontWeight.w600,
                              letterSpacing: 0.2,
                              height: 1.2,
                              shadows: isSelected
                                  ? [
                                      Shadow(
                                        color: effectiveColor.withAlpha(160),
                                        blurRadius: 8,
                                      ),
                                    ]
                                  : null,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (widget.itemCount != null) ...[
                            const SizedBox(height: 4),
                            // Minimalist Count Chip
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6.5, vertical: 2),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? effectiveColor.withAlpha(30)
                                    : Colors.white.withAlpha(8),
                                borderRadius: BorderRadius.circular(5),
                                border: Border.all(
                                  color: isSelected
                                      ? effectiveColor.withAlpha(80)
                                      : Colors.white.withAlpha(14),
                                  width: 0.7,
                                ),
                              ),
                              child: Text(
                                '${widget.itemCount} ${widget.itemCountLabel ?? 'items'}',
                                style: TextStyle(
                                  color: isSelected
                                      ? effectiveColor
                                      : AppColors.textSecondary,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.1,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Interactive Chevron Indicator with Hover Slide (RTL-aware)
                    AnimatedSlide(
                      offset: _isHovered ? Offset(Directionality.of(context) == TextDirection.rtl ? -0.18 : 0.18, 0) : Offset.zero,
                      duration: const Duration(milliseconds: 180),
                      curve: Curves.easeOutBack,
                      child: HugeIcon(
                        icon: Directionality.of(context) == TextDirection.rtl
                            ? AppIcons.chevronLeft
                            : AppIcons.chevronRight,
                        size: 14,
                        color: isSelected
                            ? effectiveColor
                            : _isHovered
                                ? Colors.white
                                : AppColors.textDisabled,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static dynamic _getIconForName(String name, bool isAll) {
    if (isAll) return AppIcons.gridView;
    final lower = name.toLowerCase();

    if (lower.contains('sport') || lower.contains('bein') || lower.contains('football') || lower.contains('fifa') || lower.contains('nba') || lower.contains('رياض') || lower.contains('كورة') || lower.contains('بين')) {
      return AppIcons.sports;
    }
    if (lower.contains('news') || lower.contains('cnn') || lower.contains('bbc') || lower.contains('al jazeera') || lower.contains('أخبار') || lower.contains('إخبار') || lower.contains('الجزيرة') || lower.contains('العربية')) {
      return AppIcons.news;
    }
    if (lower.contains('movie') || lower.contains('cinema') || lower.contains('film') || lower.contains('hollywood') || lower.contains('netflix') || lower.contains('أفلام') || lower.contains('فيلم') || lower.contains('سينما')) {
      return AppIcons.movies;
    }
    if (lower.contains('series') || lower.contains('tv show') || lower.contains('drama') || lower.contains('episode') || lower.contains('مسلسل') || lower.contains('دراما')) {
      return AppIcons.series;
    }
    if (lower.contains('kid') || lower.contains('cartoon') || lower.contains('anim') || lower.contains('disney') || lower.contains('أطفال') || lower.contains('كرتون') || lower.contains('أنمي')) {
      return HugeIcons.strokeRoundedGameController01;
    }
    if (lower.contains('music') || lower.contains('song') || lower.contains('radio') || lower.contains('mtv') || lower.contains('موسيقى') || lower.contains('أغاني') || lower.contains('طرب')) {
      return AppIcons.music;
    }
    if (lower.contains('doc') || lower.contains('geo') || lower.contains('discovery') || lower.contains('nature') || lower.contains('وثائقي')) {
      return AppIcons.globe;
    }
    if (lower.contains('action') || lower.contains('adventure') || lower.contains('war') || lower.contains('حركة') || lower.contains('أكشن') || lower.contains('قتال')) {
      return AppIcons.trending;
    }
    if (lower.contains('comedy') || lower.contains('humor') || lower.contains('fun') || lower.contains('كوميد') || lower.contains('ضحك')) {
      return AppIcons.comedy;
    }
    if (lower.contains('horror') || lower.contains('thriller') || lower.contains('scary') || lower.contains('رعب')) {
      return AppIcons.premium;
    }
    if (lower.contains('sci-fi') || lower.contains('space') || lower.contains('fantasy') || lower.contains('خيال')) {
      return HugeIcons.strokeRoundedMagicWand01;
    }
    if (lower.contains('romance') || lower.contains('love') || lower.contains('رومانس')) {
      return AppIcons.favorites;
    }
    if (lower.contains('arabic') || lower.contains('nilesat') || lower.contains('arab') || lower.contains('عرب') || lower.contains('نايل سات')) {
      return AppIcons.language;
    }
    if (lower.contains('4k') || lower.contains('uhd') || lower.contains('fhd') || lower.contains('hd')) {
      return HugeIcons.strokeRoundedSparkles;
    }
    return AppIcons.generalTv;
  }

  static Color _getAccentForName(String name, bool isAll) {
    if (isAll) return AppColors.accent;
    final lower = name.toLowerCase();

    if (lower.contains('sport') || lower.contains('bein')) {
      return const Color(0xFF00E676); // Emerald Green
    }
    if (lower.contains('news')) {
      return const Color(0xFFFF5252); // Vivid Red
    }
    if (lower.contains('movie') || lower.contains('cinema')) {
      return const Color(0xFFFF9100); // Amber Orange
    }
    if (lower.contains('series') || lower.contains('drama')) {
      return const Color(0xFF7C4DFF); // Deep Purple
    }
    if (lower.contains('kid') || lower.contains('cartoon')) {
      return const Color(0xFFFF4081); // Neon Pink
    }
    if (lower.contains('music')) {
      return const Color(0xFF00E5FF); // Electric Cyan
    }
    if (lower.contains('doc') || lower.contains('geo')) {
      return const Color(0xFF00B0FF); // Sky Blue
    }
    if (lower.contains('action') || lower.contains('4k')) {
      return const Color(0xFFFFAB00); // Radiant Gold
    }

    // Default curated colors based on string hash
    const colors = [
      AppColors.accent,
      Color(0xFF8C52FF),
      Color(0xFF38EF7D),
      Color(0xFFFF758C),
      Color(0xFF4FACFE),
      Color(0xFFF78CA0),
      Color(0xFF667EEA),
      Color(0xFF43E97B),
    ];
    final hash = name.codeUnits.fold(0, (prev, elem) => prev + elem);
    return colors[hash % colors.length];
  }
}
