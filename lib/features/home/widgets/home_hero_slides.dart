part of 'home_hero_banner.dart';

class _HeroCardSlide extends StatelessWidget {
  const _HeroCardSlide({
    required this.item,
    required this.bannerHeight,
    required this.showWideLayout,
  });

  final HomeHeroItem item;
  final double bannerHeight;
  final bool showWideLayout;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final hasArt = item.backdropUrl != null && item.backdropUrl!.isNotEmpty;
    // Decode on a single axis so portrait panel posters keep full resolution
    // instead of being crushed into a short landscape mem-cache box.
    final blurCacheWidth = (screenWidth * dpr).round().clamp(720, 1920);
    final posterCacheHeight = (bannerHeight * dpr * 0.92).round().clamp(
      640,
      1600,
    );

    if (showWideLayout) {
      return _WideHeroSlide(
        item: item,
        bannerHeight: bannerHeight,
        hasArt: hasArt,
        blurCacheWidth: blurCacheWidth,
        posterCacheHeight: posterCacheHeight,
      );
    }

    if (item.type == HeroItemType.live && item.match != null) {
      return _PortraitMatchSlide(item: item);
    }

    final topPadding = MediaQuery.paddingOf(context).top;
    final blurAreaHeight = (topPadding > 0 ? topPadding : 20.0) + 75.0;

    return Stack(
      fit: StackFit.expand,
      children: [
        // Continuous full-bleed cover (top-anchored poster crop).
        if (hasArt)
          CachedImage(
            imageUrl: item.backdropUrl,
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            fallbackIcon: item.type == HeroItemType.live
                ? AppIcons.live
                : AppIcons.movies,
            memCacheWidth: 1080,
            memCacheHeight: 720,
          )
        else
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B2333), Color(0xFF0B0E14)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

        // Buttery gradient blur at top of image under title & app shell
        if (hasArt)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: blurAreaHeight,
            child: ClipRect(
              child: ShaderMask(
                shaderCallback: (bounds) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.0, 0.40, 0.75, 1.0],
                    colors: [
                      Colors.black,
                      Colors.black87,
                      Colors.black26,
                      Colors.transparent,
                    ],
                  ).createShader(bounds);
                },
                blendMode: BlendMode.dstIn,
                child: ImageFiltered(
                  imageFilter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Transform.scale(
                    scale: 1.10,
                    child: CachedImage(
                      imageUrl: item.backdropUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      memCacheWidth: 400,
                    ),
                  ),
                ),
              ),
            ),
          ),

        // Soft contrast veil over the top region
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: blurAreaHeight + 15.0,
          child: const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.50, 0.85, 1.0],
                colors: [
                  Color(0x6008090B),
                  Color(0x3008090B),
                  Color(0x1008090B),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),

        // Bottom fade gradient (original)
        const Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.3, 0.62, 0.88, 1.0],
                colors: [
                  Colors.transparent,
                  Color(0x7508090B),
                  Color(0xF008090B),
                  AppColors.bg0,
                ],
              ),
            ),
          ),
        ),

        Positioned(
          left: screenWidth > 600 ? 48.0 : 20.0,
          right: screenWidth > 600 ? 48.0 : 20.0,
          bottom: 34,
          child: _HeroCopy(item: item, wide: false),
        ),
      ],
    );
  }
}

class _WideHeroSlide extends StatelessWidget {
  const _WideHeroSlide({
    required this.item,
    required this.bannerHeight,
    required this.hasArt,
    required this.blurCacheWidth,
    required this.posterCacheHeight,
  });

  final HomeHeroItem item;
  final double bannerHeight;
  final bool hasArt;
  final int blurCacheWidth;
  final int posterCacheHeight;

  @override
  Widget build(BuildContext context) {
    final posterHeight = (bannerHeight * 0.78).clamp(200.0, 400.0);
    final posterWidth = posterHeight * (2 / 3);

    if (item.type == HeroItemType.live && item.match != null) {
      final screenWidth = MediaQuery.sizeOf(context).width;
      final fixture = item.match!.fixture;
      final goalRows = MatchPosterCard.goalRowsForFixture(fixture);
      final matchSize = MatchPosterCard.sizeForWidth(
        screenWidth,
        goalRows: goalRows,
      );

      return Stack(
        fit: StackFit.expand,
        children: [
          _MatchStadiumBackdrop(match: item.match!),
          const Positioned.fill(child: _MatchHeroScrim()),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x3l,
              AppSpacing.xl,
              AppSpacing.x4l,
              AppSpacing.xxl,
            ),
            child: Align(
              alignment: Alignment.bottomLeft,
              child: MatchPosterCard(
                match: item.match!,
                item: item,
                width: matchSize.width,
                height: matchSize.height,
              ),
            ),
          ),
        ],
      );
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        if (hasArt)
          // Avoid ImageFiltered blur during scroll — it forces expensive
          // per-frame rasterization of a full-bleed bitmap. A darkened cover
          // + scrim reads similarly and scrolls smoothly.
          Stack(
            fit: StackFit.expand,
            children: [
              CachedImage(
                imageUrl: item.backdropUrl,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                fallbackIcon: item.type == HeroItemType.live
                    ? AppIcons.live
                    : AppIcons.movies,
                memCacheWidth: blurCacheWidth.clamp(480, 960),
              ),
              const ColoredBox(color: Color(0x3D08090B)),
            ],
          )
        else
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF1B2333), Color(0xFF0B0E14)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        const Positioned.fill(child: _HeroScrim()),
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 28, 48, 36),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (hasArt)
                SizedBox(
                  width: posterWidth,
                  height: posterHeight,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.45),
                          blurRadius: 28,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: CachedImage(
                      imageUrl: item.posterUrl ?? item.backdropUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                      borderRadius: BorderRadius.circular(12),
                      fallbackIcon: item.type == HeroItemType.live
                          ? AppIcons.live
                          : AppIcons.movies,
                      memCacheHeight: posterCacheHeight,
                    ),
                  ),
                ),
              if (hasArt) const SizedBox(width: 28),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: posterHeight * 0.06),
                  child: _HeroCopy(item: item, wide: true),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroScrim extends StatelessWidget {
  const _HeroScrim();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.16, 0.42, 0.72, 1.0],
          colors: [
            Color(0x5908090B),
            Color(0x2408090B),
            Colors.transparent,
            Color(0xD008090B),
            AppColors.bg0,
          ],
        ),
      ),
    );
  }
}

class _HeroCopy extends StatelessWidget {
  const _HeroCopy({required this.item, required this.wide});

  final HomeHeroItem item;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    if (item.type == HeroItemType.live && item.match != null) {
      return _MatchHeroCopy(match: item.match!, item: item, wide: wide);
    }

    final meta = _formatMetadata(item);
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final localizedChannel = item.channel != null
        ? SportsLocalization.localizeChannel(
            item.channel!.name,
            isArabic: isArabic,
          )
        : '';

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: wide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        if (item.type == HeroItemType.live) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF00FF87).withAlpha(36),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF00FF87).withAlpha(140)),
            ),
            child: Text(
              context.l10n.homeLiveMatch,
              style: const TextStyle(
                color: Color(0xFF00FF87),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
        Text(
          item.title,
          textAlign: wide ? TextAlign.start : TextAlign.center,
          style: TextStyle(
            color: const Color(0xFFF3C74C),
            fontSize: wide ? 32 : 24,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            height: 1.15,
            shadows: const [
              Shadow(color: Colors.black, blurRadius: 14, offset: Offset(0, 3)),
            ],
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (meta.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            meta,
            textAlign: wide ? TextAlign.start : TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(210),
              fontSize: wide ? 15 : 13,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.2,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        if (item.description != null && item.description!.isNotEmpty) ...[
          const SizedBox(height: 10),
          Text(
            item.type == HeroItemType.live && item.channel != null
                ? context.l10n.homeWatchOnChannel(localizedChannel)
                : item.description!,
            textAlign: wide ? TextAlign.start : TextAlign.center,
            style: TextStyle(
              color: Colors.white.withAlpha(155),
              fontSize: wide ? 14 : 12.5,
              height: 1.35,
              letterSpacing: -0.1,
            ),
            maxLines: wide ? 3 : 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  String _formatMetadata(HomeHeroItem item) {
    final parts = <String>[];
    if (item.type == HeroItemType.live) {
      if (item.badge != null && item.badge!.isNotEmpty) {
        parts.add(item.badge!);
      }
      if (item.subtitle.isNotEmpty) parts.add(item.subtitle);
      return parts.join(' • ');
    }
    if (item.genre != null && item.genre!.isNotEmpty) {
      parts.add(item.genre!);
    }
    if (item.subtitle.isNotEmpty) {
      parts.add(item.subtitle);
    } else if (item.badge != null && item.badge!.isNotEmpty) {
      parts.add(item.badge!);
    }
    return parts.join(' • ');
  }
}

class _MatchHeroCopy extends StatelessWidget {
  const _MatchHeroCopy({
    required this.match,
    required this.item,
    required this.wide,
  });

  final LiveMatch match;
  final HomeHeroItem item;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final fixture = match.fixture;
    final isLive = fixture?.isLive ?? false;
    final scheduledTime = fixture?.scheduledTime ?? fixture?.clock ?? '';
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final rawChannel =
        fixture?.broadcastChannel ?? item.channel?.name ?? match.channel.name;
    final channel = SportsLocalization.localizeChannel(
      rawChannel,
      isArabic: isArabic,
    );
    final rawLeague = fixture?.league;
    final league = SportsLocalization.localizeLeague(
      rawLeague,
      isArabic: isArabic,
    );
    final isFinished = fixture?.isFinished ?? false;
    final timeLabel = isLive
        ? (fixture?.clock ?? (isArabic ? 'مباشر' : 'LIVE'))
        : (isFinished
              ? (fixture?.clock ?? (isArabic ? 'انتهت' : 'FT'))
              : (scheduledTime.isNotEmpty ? scheduledTime : '—'));

    final metaParts = <String>[
      if (league != null && league.isNotEmpty) league,
      if (channel.isNotEmpty) channel,
      if (item.badge != null && item.badge!.isNotEmpty) item.badge!,
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: wide
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        if (isLive) ...[
          const _MatchStatusChip(),
          SizedBox(height: wide ? AppSpacing.sm : AppSpacing.xs),
        ],
        _MatchKickoffDisplay(
          timeLabel: timeLabel,
          isLive: isLive,
          isArabic: isArabic,
          large: wide,
          alignStart: wide,
        ),
        if (metaParts.isNotEmpty) ...[
          SizedBox(height: wide ? AppSpacing.sm : AppSpacing.xs),
          Text(
            metaParts.join('  ·  '),
            textAlign: wide ? TextAlign.start : TextAlign.center,
            style: TextStyle(
              color: AppColors.textPrimary.withValues(alpha: 0.78),
              fontSize: wide ? 14 : 12,
              fontWeight: FontWeight.w500,
              letterSpacing: 0.1,
              height: 1.3,
              shadows: const [
                Shadow(
                  color: Color(0xCC000000),
                  blurRadius: 10,
                  offset: Offset(0, 1),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        SizedBox(height: wide ? AppSpacing.md : AppSpacing.sm),
        _MatchWatchCue(isLive: isLive, isArabic: isArabic),
      ],
    );
  }
}

class _MatchStadiumBackdrop extends StatelessWidget {
  const _MatchStadiumBackdrop({required this.match});

  final LiveMatch match;

  @override
  Widget build(BuildContext context) {
    final isLive = match.fixture?.isLive ?? false;
    final wallpaperAsset = MatchWallpaperResolver.resolveWallpaper(match);

    return Stack(
      fit: StackFit.expand,
      children: [
        _buildDefaultGradients(isLive),
        if (wallpaperAsset != null) ...[
          Positioned.fill(
            child: Image.asset(
              wallpaperAsset,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.15),
              errorBuilder: (context, error, stackTrace) {
                return const SizedBox.shrink();
              },
            ),
          ),
          // Soft edge vignette — keeps wallpaper visible in the center.
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment(0, -0.1),
                  radius: 1.15,
                  colors: [
                    Color(0x0808090B),
                    Color(0x4808090B),
                    Color(0x9808090B),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
            ),
          ),
        ],
        // Glossy sheen layer (no blur — cheap during carousel scroll).
        const Positioned.fill(child: _MatchGlossOverlay()),
      ],
    );
  }

  Widget _buildDefaultGradients(bool isLive) {
    final glow = isLive ? AppColors.live : AppColors.accent;
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF101622), AppColors.bg0],
            ),
          ),
        ),
        Positioned(
          left: -60,
          top: -20,
          width: 280,
          height: 280,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [glow.withValues(alpha: 0.14), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned(
          right: -40,
          bottom: -30,
          width: 260,
          height: 260,
          child: DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.accent.withValues(alpha: 0.08),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Lighter scrim so branded wallpapers stay visible while copy stays legible.
class _MatchHeroScrim extends StatelessWidget {
  const _MatchHeroScrim();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.22, 0.52, 0.78, 1.0],
          colors: [
            Color(0x4D08090B),
            Color(0x1808090B),
            Colors.transparent,
            Color(0xA008090B),
            AppColors.bg0,
          ],
        ),
      ),
    );
  }
}

/// Cinema gloss: rim light + diagonal specular streak over the wallpaper.
class _MatchGlossOverlay extends StatelessWidget {
  const _MatchGlossOverlay();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: RepaintBoundary(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Soft top rim highlight (stadium floodlight feel).
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.18, 0.42],
                  colors: [
                    Color(0x38FFFFFF),
                    Color(0x12FFFFFF),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Diagonal specular sheen.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-0.95, -1.0),
                  end: Alignment(0.85, 0.7),
                  stops: [0.0, 0.28, 0.42, 0.56, 1.0],
                  colors: [
                    Colors.transparent,
                    Color(0x22FFFFFF),
                    Color(0x38FFFFFF),
                    Color(0x14FFFFFF),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Cool accent glint (brand cyan, very subtle).
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment(-1.0, -0.4),
                  end: Alignment(0.6, 0.9),
                  stops: [0.0, 0.35, 0.55, 1.0],
                  colors: [
                    Colors.transparent,
                    Color(0x1200C2FF),
                    Color(0x0800C2FF),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            // Bottom glass reflection fade into app bg.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.center,
                  stops: [0.0, 0.35, 1.0],
                  colors: [
                    Color(0x2800C2FF),
                    Color(0x0800C2FF),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
