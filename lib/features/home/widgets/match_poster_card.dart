part of 'home_hero_banner.dart';

class MatchPosterCard extends StatelessWidget {
  const MatchPosterCard({
    super.key,
    required this.match,
    this.item,
    required this.width,
    required this.height,
  });

  final LiveMatch match;
  final HomeHeroItem? item;
  final double width;
  final double height;

  /// Computes how many distinct player goal rows are needed for a fixture.
  static int goalRowsForFixture(LiveFixture? fixture) =>
      MatchPosterLayout.goalRowsForFixture(fixture);

  /// Extra height to dynamically expand the card so ALL goals fit without truncation.
  static double extraHeightForGoals(int goalRows) =>
      MatchPosterLayout.extraHeightForGoals(goalRows);

  /// Responsive card footprint for landscape / TV heroes.
  static ({double width, double height}) sizeForWidth(
    double screenWidth, {
    int goalRows = 0,
  }) => MatchPosterLayout.sizeForWidth(screenWidth, goalRows: goalRows);

  @override
  Widget build(BuildContext context) {
    final fixture = match.fixture;
    final isLive = fixture?.isLive ?? false;
    final scheduledTime = fixture?.scheduledTime ?? fixture?.clock ?? '';
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final rawChannel =
        fixture?.broadcastChannel ?? item?.channel?.name ?? match.channel.name;
    final channel = SportsLocalization.localizeChannel(
      rawChannel,
      isArabic: isArabic,
    );
    final rawLeague = fixture?.league;
    final league = SportsLocalization.localizeLeague(
      rawLeague,
      isArabic: isArabic,
    );
    final homeName = SportsLocalization.localizeTeam(
      fixture?.homeName ?? 'Home',
      isArabic: isArabic,
    );
    final awayName = SportsLocalization.localizeTeam(
      fixture?.awayName ?? 'Away',
      isArabic: isArabic,
    );
    final isFinished = fixture?.isFinished ?? false;
    final timeLabel = isLive
        ? (fixture?.clock ?? (isArabic ? 'مباشر' : 'LIVE'))
        : (isFinished
              ? (fixture?.clock ?? (isArabic ? 'انتهت' : 'FT'))
              : (scheduledTime.isNotEmpty ? scheduledTime : ''));

    final isExpanded = width >= 520;
    final gutter = isExpanded ? 12.0 : 10.0;
    final outerRadius = isExpanded ? 28.0 : 24.0;
    final cellRadius = isExpanded ? 18.0 : 16.0;
    final topRowHeight = isExpanded ? 44.0 : 40.0;
    final footerHeight = isExpanded ? 42.0 : 38.0;
    final arenaPadV = isExpanded ? 8.0 : 6.0;
    final teamFont = isExpanded ? 12.5 : 11.5;
    final goalRows = goalRowsForFixture(fixture);
    final hasGoals = goalRows > 0;
    final scorersShelfHeight = hasGoals ? (goalRows * 22.0 + 8.0) : 0.0;
    // Keep emblems inside the arena: card chrome + rows leave a fixed budget.
    final arenaBudget =
        height -
        (gutter * 2) -
        topRowHeight -
        gutter -
        footerHeight -
        gutter -
        (arenaPadV * 2) -
        scorersShelfHeight;
    final logoSize = (arenaBudget - 6 - teamFont * 1.25)
        .clamp(28.0, isExpanded ? 48.0 : 40.0)
        .toDouble();

    return SizedBox(
      width: width,
      height: height,
      child: SilverGlassCapsule(
        borderRadius: outerRadius,
        padding: EdgeInsets.zero,
        enableBlur: false,
        sigma: 24,
        highlightHeight: isExpanded ? 36 : 28,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.40),
            blurRadius: 32,
            offset: const Offset(0, 14),
          ),
        ],
        child: SizedBox(
          width: width,
          height: height,
          child: Padding(
            padding: EdgeInsets.all(gutter),
            child: Column(
              children: [
                // Top bento row: league + status/time compartments
                SizedBox(
                  height: topRowHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        flex: isExpanded ? 5 : 4,
                        child: _MatchBentoCell(
                          radius: cellRadius,
                          padding: EdgeInsets.symmetric(
                            horizontal: isExpanded ? 14 : 12,
                          ),
                          child: Row(
                            children: [
                              SilverGlassCapsule(
                                borderRadius: 10,
                                enableBlur: false,
                                highlightHeight: 8,
                                padding: EdgeInsets.all(isExpanded ? 7 : 6),
                                child: Icon(
                                  Icons.emoji_events_rounded,
                                  size: isExpanded ? 16 : 14,
                                  color: const Color(0xFFF7F8FA),
                                  shadows: const [
                                    Shadow(
                                      color: Color(0x73000000),
                                      blurRadius: 4,
                                      offset: Offset(0, 0.5),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(width: isExpanded ? 10 : 8),
                              Expanded(
                                child: Text(
                                  (league != null && league.isNotEmpty)
                                      ? league
                                      : (isArabic ? 'مباراة' : 'Match'),
                                  style: TextStyle(
                                    color: AppColors.textPrimary.withValues(
                                      alpha: 0.9,
                                    ),
                                    fontSize: isExpanded ? 13 : 12,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: -0.1,
                                    height: 1.15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: gutter),
                      Expanded(
                        flex: 3,
                        child: SilverGlassCapsule(
                          borderRadius: AppRadius.full,
                          enableBlur: false,
                          highlightHeight: 10,
                          padding: EdgeInsets.symmetric(
                            horizontal: isExpanded ? 14 : 12,
                          ),
                          child: Center(
                            child: isLive
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const _MatchStatusChip(compact: true),
                                      if (fixture?.clock != null &&
                                          fixture!.clock!.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          fixture.clock!,
                                          style: TextStyle(
                                            color: const Color(0xFFF7F8FA),
                                            fontSize: isExpanded ? 14 : 13,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                            height: 1,
                                            shadows: const [
                                              Shadow(
                                                color: Color(0x73000000),
                                                blurRadius: 4,
                                                offset: Offset(0, 0.5),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Flexible(
                                        child: Text(
                                          timeLabel.isNotEmpty
                                              ? timeLabel
                                              : (isArabic ? 'اليوم' : 'TODAY'),
                                          style: TextStyle(
                                            color: const Color(0xFFF7F8FA),
                                            fontSize: isExpanded ? 14 : 13,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2,
                                            height: 1,
                                            shadows: const [
                                              Shadow(
                                                color: Color(0x73000000),
                                                blurRadius: 4,
                                                offset: Offset(0, 0.5),
                                              ),
                                            ],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      if (timeLabel.isNotEmpty) ...[
                                        const SizedBox(width: 8),
                                        Text(
                                          isFinished
                                              ? (isArabic ? 'انتهت' : 'FINAL')
                                              : (isArabic ? 'اليوم' : 'TODAY'),
                                          style: TextStyle(
                                            color: const Color(0xCCF7F8FA),
                                            fontSize: isExpanded ? 10 : 9,
                                            fontWeight: FontWeight.w700,
                                            letterSpacing: 0.8,
                                            height: 1,
                                            shadows: const [
                                              Shadow(
                                                color: Color(0x73000000),
                                                blurRadius: 4,
                                                offset: Offset(0, 0.5),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: gutter),
                // Main arena: teams + score + broadcast goals shelf
                Expanded(
                  child: _MatchBentoCell(
                    radius: cellRadius,
                    padding: EdgeInsets.symmetric(
                      horizontal: isExpanded ? 14 : 10,
                      vertical: arenaPadV,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Expanded(
                                child: _TeamEmblemColumn(
                                  name: homeName,
                                  logoUrl: fixture?.homeLogoUrl,
                                  logoSize: logoSize,
                                  fontSize: teamFont,
                                  elevated: true,
                                  maxNameLines: 1,
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: isExpanded ? 12 : 8,
                                ),
                                child: _VersusOrScoreBadge(
                                  fixture: fixture,
                                  large: isExpanded,
                                ),
                              ),
                              Expanded(
                                child: _TeamEmblemColumn(
                                  name: awayName,
                                  logoUrl: fixture?.awayLogoUrl,
                                  logoSize: logoSize,
                                  fontSize: teamFont,
                                  elevated: true,
                                  maxNameLines: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (hasGoals) ...[
                          Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            child: Container(
                              height: 1,
                              color: Colors.white.withValues(alpha: 0.08),
                            ),
                          ),
                          _MatchScorersShelf(
                            homeGoals: fixture!.homeGoals,
                            awayGoals: fixture.awayGoals,
                            isExpanded: isExpanded,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                SizedBox(height: gutter),
                // Footer bento: channel + CTA
                SizedBox(
                  height: footerHeight,
                  child: Row(
                    children: [
                      Expanded(
                        child: _MatchBentoCell(
                          radius: cellRadius,
                          padding: EdgeInsets.symmetric(
                            horizontal: isExpanded ? 14 : 12,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.tv_rounded,
                                size: isExpanded ? 16 : 14,
                                color: AppColors.textSecondary.withValues(
                                  alpha: 0.85,
                                ),
                              ),
                              SizedBox(width: isExpanded ? 8 : 6),
                              Expanded(
                                child: Text(
                                  channel.isNotEmpty
                                      ? channel
                                      : (isArabic ? 'القناة' : 'Channel'),
                                  style: TextStyle(
                                    color: AppColors.textPrimary.withValues(
                                      alpha: 0.78,
                                    ),
                                    fontSize: isExpanded ? 12.5 : 11.5,
                                    fontWeight: FontWeight.w500,
                                    height: 1.15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SizedBox(width: gutter),
                      SilverGlassCapsule(
                        borderRadius: AppRadius.full,
                        enableBlur: false,
                        highlightHeight: 10,
                        padding: EdgeInsets.symmetric(
                          horizontal: isExpanded ? 16 : 12,
                          vertical: 8,
                        ),
                        child: _MatchWatchCue(
                          isLive: isLive,
                          isArabic: isArabic,
                          compact: !isExpanded,
                          silver: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Soft glass compartment used inside the wide match bento card.
class _MatchBentoCell extends StatelessWidget {
  const _MatchBentoCell({
    required this.child,
    required this.radius,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: const Color(0x40FFFFFF), width: 0.75),
      ),
      child: Padding(
        padding: padding,
        child: Align(alignment: Alignment.center, child: child),
      ),
    );
  }
}

class _PortraitMatchSlide extends StatelessWidget {
  const _PortraitMatchSlide({required this.item});

  final HomeHeroItem item;

  @override
  Widget build(BuildContext context) {
    final match = item.match!;
    final fixture = match.fixture;
    final isLive = fixture?.isLive ?? false;
    final scheduledTime = fixture?.scheduledTime ?? fixture?.clock ?? '';
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    final rawChannel = fixture?.broadcastChannel ?? match.channel.name;
    final channel = SportsLocalization.localizeChannel(
      rawChannel,
      isArabic: isArabic,
    );
    final rawLeague = fixture?.league;
    final league = SportsLocalization.localizeLeague(
      rawLeague,
      isArabic: isArabic,
    );
    final homeName = SportsLocalization.localizeTeam(
      fixture?.homeName ?? 'Home',
      isArabic: isArabic,
    );
    final awayName = SportsLocalization.localizeTeam(
      fixture?.awayName ?? 'Away',
      isArabic: isArabic,
    );
    final isFinished = fixture?.isFinished ?? false;
    final timeLabel = isLive
        ? (fixture?.clock ?? (isArabic ? 'مباشر' : 'LIVE'))
        : (isFinished
              ? (fixture?.clock ?? (isArabic ? 'انتهت' : 'FT'))
              : (scheduledTime.isNotEmpty ? scheduledTime : '—'));

    return Stack(
      fit: StackFit.expand,
      children: [
        _MatchStadiumBackdrop(match: match),
        const Positioned.fill(child: _MatchHeroScrim()),
        Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.lg,
            // Match [ShellPortraitHeader] — Home strips MediaQuery top padding.
            ShellPortraitHeader.heightOf(context) + AppSpacing.xs,
            AppSpacing.lg,
            AppSpacing.x4l,
          ),
          child: Column(
            children: [
              if (isLive) const _MatchStatusChip(),
              const Spacer(flex: 2),
              _MatchKickoffDisplay(
                timeLabel: timeLabel,
                isLive: isLive,
                isArabic: isArabic,
              ),
              const Spacer(flex: 2),
              Row(
                children: [
                  Expanded(
                    child: _TeamEmblemColumn(
                      name: homeName,
                      logoUrl: fixture?.homeLogoUrl,
                      goals: fixture?.homeGoals ?? const [],
                      showGoalsUnder: true,
                      logoSize:
                          (fixture?.homeGoals.isNotEmpty == true ||
                              fixture?.awayGoals.isNotEmpty == true)
                          ? 54
                          : 64,
                      fontSize: 13,
                      elevated: true,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    child: _VersusOrScoreBadge(fixture: fixture, large: true),
                  ),
                  Expanded(
                    child: _TeamEmblemColumn(
                      name: awayName,
                      logoUrl: fixture?.awayLogoUrl,
                      goals: fixture?.awayGoals ?? const [],
                      showGoalsUnder: true,
                      logoSize:
                          (fixture?.homeGoals.isNotEmpty == true ||
                              fixture?.awayGoals.isNotEmpty == true)
                          ? 54
                          : 64,
                      fontSize: 13,
                      elevated: true,
                    ),
                  ),
                ],
              ),
              const Spacer(flex: 3),
              _MatchMetaLine(
                league: league,
                channel: channel,
                centered: true,
                prominent: true,
              ),
              const SizedBox(height: AppSpacing.sm),
              _MatchWatchCue(isLive: isLive, isArabic: isArabic),
            ],
          ),
        ),
      ],
    );
  }
}

class _MatchStatusChip extends StatelessWidget {
  const _MatchStatusChip({this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final isArabic = Localizations.localeOf(context).languageCode == 'ar';
    const color = AppColors.live;
    final label = isArabic ? 'مباشر' : 'LIVE';

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 10,
        vertical: compact ? 3 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: color.withValues(alpha: 0.55)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: compact ? 5 : 6,
            height: compact ? 5 : 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.55), blurRadius: 6),
              ],
            ),
          ),
          SizedBox(width: compact ? 5 : 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Kickoff / clock chronograph — compact horizontal pill on small screens,
/// roomier plate on wide heroes.
class _MatchKickoffDisplay extends StatelessWidget {
  const _MatchKickoffDisplay({
    required this.timeLabel,
    required this.isLive,
    required this.isArabic,
    this.large = false,
    this.alignStart = false,
  });

  final String timeLabel;
  final bool isLive;
  final bool isArabic;
  final bool large;
  final bool alignStart;

  @override
  Widget build(BuildContext context) {
    final accent = isLive ? AppColors.live : AppColors.accent;
    final dayLabel = isArabic ? 'اليوم' : 'TODAY';
    final isFinished =
        timeLabel.contains('FT') ||
        timeLabel.contains('انتهت') ||
        timeLabel.contains('Pen') ||
        timeLabel.contains('AET');
    final headerLabel = isLive
        ? (isArabic ? 'مباشر الآن' : 'LIVE NOW')
        : (isFinished ? (isArabic ? 'النتيجة النهائية' : 'FINAL') : dayLabel);

    if (!large) {
      return Align(
        alignment: alignStart
            ? AlignmentDirectional.centerStart
            : Alignment.center,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 280),
          child: SilverGlassCapsule(
            borderRadius: AppRadius.full,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: alignStart
                  ? CrossAxisAlignment.start
                  : CrossAxisAlignment.center,
              children: [
                Text(
                  headerLabel,
                  style: TextStyle(
                    color: isLive ? AppColors.live : const Color(0xE6F7F8FA),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                    height: 1,
                    shadows: const [
                      Shadow(
                        color: Color(0x73000000),
                        blurRadius: 4,
                        offset: Offset(0, 0.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeLabel,
                  style: TextStyle(
                    color: isLive ? AppColors.live : const Color(0xFFF7F8FA),
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    height: 1.05,
                    shadows: const [
                      Shadow(
                        color: Color(0x73000000),
                        blurRadius: 4,
                        offset: Offset(0, 0.5),
                      ),
                    ],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Align(
      alignment: alignStart
          ? AlignmentDirectional.centerStart
          : Alignment.center,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 18,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Stack(
            children: [
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(color: accent.withValues(alpha: 0.4)),
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xF0121620),
                        const Color(0xE608090B),
                        Color.lerp(const Color(0xE608090B), accent, 0.08) ??
                            const Color(0xE608090B),
                      ],
                    ),
                  ),
                ),
              ),
              const Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 22,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x28FFFFFF), Colors.transparent],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 18,
                  vertical: 12,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: alignStart
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    if (!isLive) ...[
                      Text(
                        headerLabel,
                        style: TextStyle(
                          color: isFinished
                              ? const Color(0xCCF7F8FA)
                              : AppColors.accent,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                          height: 1,
                        ),
                      ),
                      const SizedBox(height: 6),
                    ],
                    Text(
                      timeLabel,
                      style: TextStyle(
                        color: isLive ? AppColors.live : AppColors.textPrimary,
                        fontSize: 36,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1.0,
                        height: 1.0,
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
}

class _MatchMetaLine extends StatelessWidget {
  const _MatchMetaLine({
    required this.league,
    required this.channel,
    this.centered = false,
    this.prominent = false,
  });

  final String? league;
  final String channel;
  final bool centered;
  final bool prominent;

  @override
  Widget build(BuildContext context) {
    final parts = <String>[
      if (league != null && league!.isNotEmpty) league!,
      if (channel.isNotEmpty) channel,
    ];
    if (parts.isEmpty) return const SizedBox.shrink();

    final text = Text(
      parts.join('  ·  '),
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: TextStyle(
        color: AppColors.textPrimary.withValues(alpha: prominent ? 0.78 : 0.62),
        fontSize: prominent ? 12.5 : 11,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.15,
        height: 1.25,
        shadows: prominent
            ? const [
                Shadow(
                  color: Color(0x88000000),
                  blurRadius: 10,
                  offset: Offset(0, 1),
                ),
              ]
            : null,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );

    if (!prominent) return text;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(AppRadius.full),
        border: Border.all(color: AppColors.border),
      ),
      child: text,
    );
  }
}

class _MatchWatchCue extends StatelessWidget {
  const _MatchWatchCue({
    required this.isLive,
    required this.isArabic,
    this.compact = false,
    this.silver = false,
  });

  final bool isLive;
  final bool isArabic;
  final bool compact;
  final bool silver;

  @override
  Widget build(BuildContext context) {
    final label = isLive
        ? (isArabic ? 'شاهد الآن' : 'Watch now')
        : (isArabic ? 'انتقل للقناة' : 'Go to channel');
    const silverColor = Color(0xFFF7F8FA);
    const silverShadows = [
      Shadow(color: Color(0x73000000), blurRadius: 4, offset: Offset(0, 0.5)),
    ];
    final color = silver ? silverColor : AppColors.accent;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isLive ? Icons.play_arrow_rounded : Icons.tv_rounded,
          size: compact ? 15 : 16,
          color: color,
          shadows: silver ? silverShadows : null,
        ),
        SizedBox(width: compact ? 4 : 5),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: compact ? 12 : 13,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            height: 1,
            shadows: silver ? silverShadows : null,
          ),
        ),
      ],
    );
  }
}

/// Formats a football player's name like official broadcast graphics & shirt names.
/// If <= 16 chars (e.g. "Mohamed Salah", "Erling Haaland"), keeps full name.
/// If longer (e.g. "Trent Alexander-Arnold"), uses initial + surname ("T. Alexander-Arnold").
String _formatPlayerName(String rawName) {
  final trimmed = rawName.trim();
  if (trimmed.length <= 16) return trimmed;
  final parts = trimmed.split(RegExp(r'\s+'));
  if (parts.length >= 2) {
    final firstInitial = parts.first.isNotEmpty ? '${parts.first[0]}. ' : '';
    final lastName = parts.sublist(1).join(' ');
    final shortened = '$firstInitial$lastName';
    if (shortened.length <= 18) return shortened;
    return lastName;
  }
  return trimmed;
}

/// Broadcast-grade goals ticker shelf for landscape / big screens.
/// Positioned across the full width below the teams, providing ~220-280px of
/// breathing room per team so player names and minutes never get cut off.
class _MatchScorersShelf extends StatelessWidget {
  const _MatchScorersShelf({
    required this.homeGoals,
    required this.awayGoals,
    required this.isExpanded,
  });

  final List<MatchGoal> homeGoals;
  final List<MatchGoal> awayGoals;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Home scorers (left half)
          Expanded(
            child: _TeamGoalsShelfColumn(
              goals: homeGoals,
              alignEnd: false,
              isExpanded: isExpanded,
            ),
          ),
          // Subtle vertical divider matching the center score badge axis
          Container(
            width: 1,
            height: 16,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white.withValues(alpha: 0.10),
          ),
          // Away scorers (right half)
          Expanded(
            child: _TeamGoalsShelfColumn(
              goals: awayGoals,
              alignEnd: true,
              isExpanded: isExpanded,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamGoalsShelfColumn extends StatelessWidget {
  const _TeamGoalsShelfColumn({
    required this.goals,
    required this.alignEnd,
    required this.isExpanded,
  });

  final List<MatchGoal> goals;
  final bool alignEnd;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) {
      return const SizedBox.shrink();
    }

    final grouped = <String, List<String>>{};
    for (final g in goals) {
      var minuteLabel = g.minute;
      if (g.isOwnGoal) minuteLabel += ' (OG)';
      if (g.isPenalty) minuteLabel += ' (P)';
      grouped.putIfAbsent(g.player, () => []).add(minuteLabel);
    }

    final entries = grouped.entries.toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: alignEnd
          ? CrossAxisAlignment.end
          : CrossAxisAlignment.start,
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: alignEnd
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              children: alignEnd
                  ? [
                      // Away: [23', 68' (P)] PlayerName ⚽
                      _MinuteBadge(
                        minutes: entry.value.join(', '),
                        isExpanded: isExpanded,
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          _formatPlayerName(entry.key),
                          style: TextStyle(
                            color: AppColors.textPrimary.withValues(
                              alpha: 0.95,
                            ),
                            fontSize: isExpanded ? 11 : 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                            shadows: const [
                              Shadow(
                                color: Color(0x99000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.end,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Text('⚽', style: TextStyle(fontSize: 8.5)),
                    ]
                  : [
                      // Home: ⚽ PlayerName [23', 68' (P)]
                      const Text('⚽', style: TextStyle(fontSize: 8.5)),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          _formatPlayerName(entry.key),
                          style: TextStyle(
                            color: AppColors.textPrimary.withValues(
                              alpha: 0.95,
                            ),
                            fontSize: isExpanded ? 11 : 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.1,
                            shadows: const [
                              Shadow(
                                color: Color(0x99000000),
                                blurRadius: 4,
                                offset: Offset(0, 1),
                              ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.start,
                        ),
                      ),
                      const SizedBox(width: 5),
                      _MinuteBadge(
                        minutes: entry.value.join(', '),
                        isExpanded: isExpanded,
                      ),
                    ],
            ),
          ),
      ],
    );
  }
}

class _MinuteBadge extends StatelessWidget {
  const _MinuteBadge({required this.minutes, required this.isExpanded});

  final String minutes;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4.5, vertical: 1.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.12),
          width: 0.5,
        ),
      ),
      child: Text(
        minutes,
        style: TextStyle(
          color: const Color(0xFFFFD54F), // Amber gold
          fontSize: isExpanded ? 9.5 : 8.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.1,
          height: 1.1,
        ),
        maxLines: 1,
      ),
    );
  }
}

/// Renders goal scorers and minutes (e.g. ⚽ Felix Bacher 28', 53').
class _TeamGoalsList extends StatelessWidget {
  const _TeamGoalsList({
    required this.goals,
    this.compact = false,
    this.center = false,
    this.elevated = false,
  });

  final List<MatchGoal> goals;
  final bool compact;
  final bool center;
  final bool elevated;

  @override
  Widget build(BuildContext context) {
    if (goals.isEmpty) return const SizedBox.shrink();

    // Group goals by player to avoid duplicate lines for multiple goals
    final grouped = <String, List<String>>{};
    for (final g in goals) {
      final key = g.player;
      var minuteLabel = g.minute;
      if (g.isOwnGoal) minuteLabel += ' (OG)';
      if (g.isPenalty) minuteLabel += ' (P)';
      grouped.putIfAbsent(key, () => []).add(minuteLabel);
    }

    final entries = grouped.entries.toList();

    final crossAxis = center
        ? CrossAxisAlignment.center
        : CrossAxisAlignment.start;
    final rowMainAxis = center
        ? MainAxisAlignment.center
        : MainAxisAlignment.start;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: crossAxis,
      children: [
        for (final entry in entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 1.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: rowMainAxis,
              children: [
                const Text('⚽', style: TextStyle(fontSize: 8.5, height: 1)),
                const SizedBox(width: 3.5),
                Flexible(
                  child: Text(
                    '${_formatPlayerName(entry.key)} ${entry.value.join(', ')}',
                    style: TextStyle(
                      color: AppColors.textPrimary.withValues(alpha: 0.90),
                      fontSize: compact ? 9.5 : 10.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.1,
                      height: 1.15,
                      shadows: elevated
                          ? const [
                              Shadow(
                                color: Color(0x99000000),
                                blurRadius: 6,
                                offset: Offset(0, 1),
                              ),
                            ]
                          : null,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: center ? TextAlign.center : TextAlign.start,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _TeamEmblemColumn extends StatelessWidget {
  const _TeamEmblemColumn({
    required this.name,
    required this.logoUrl,
    this.goals = const [],
    this.showGoalsUnder = false,
    this.logoSize = 48,
    this.fontSize = 12,
    this.elevated = false,
    this.maxNameLines = 2,
  });

  final String name;
  final String? logoUrl;
  final List<MatchGoal> goals;
  final bool showGoalsUnder;
  final double logoSize;
  final double fontSize;
  final bool elevated;
  final int maxNameLines;

  @override
  Widget build(BuildContext context) {
    final gap = elevated ? 6.0 : 4.0;
    final column = Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: logoSize,
          height: logoSize,
          child: logoUrl != null && logoUrl!.isNotEmpty
              ? CachedImage(
                  imageUrl: logoUrl,
                  fit: BoxFit.contain,
                  fallbackIcon: AppIcons.live,
                )
              : Icon(
                  Icons.sports_soccer,
                  color: AppColors.textSecondary,
                  size: logoSize * 0.55,
                ),
        ),
        SizedBox(height: gap),
        Text(
          name,
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.15,
            height: 1.2,
            shadows: elevated
                ? const [
                    Shadow(
                      color: Color(0x99000000),
                      blurRadius: 8,
                      offset: Offset(0, 1),
                    ),
                  ]
                : null,
          ),
          textAlign: TextAlign.center,
          maxLines: maxNameLines,
          overflow: TextOverflow.ellipsis,
        ),
        if (showGoalsUnder && goals.isNotEmpty) ...[
          const SizedBox(height: 5),
          _TeamGoalsList(
            goals: goals,
            compact: true,
            elevated: elevated,
            center: true,
          ),
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (!constraints.maxHeight.isFinite) return column;
        return FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.center,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: constraints.maxWidth),
            child: column,
          ),
        );
      },
    );
  }
}

class _VersusOrScoreBadge extends StatelessWidget {
  const _VersusOrScoreBadge({required this.fixture, this.large = false});

  final LiveFixture? fixture;
  final bool large;

  @override
  Widget build(BuildContext context) {
    final hasScores = fixture?.homeScore != null && fixture?.awayScore != null;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.full),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.32),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.full),
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.full),
            // Apple silver glass: cool translucent fill + hairline rim.
            gradient: const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x73FFFFFF), Color(0x3DF2F4F7), Color(0x33A8B0BC)],
              stops: [0.0, 0.5, 1.0],
            ),
            border: Border.all(color: const Color(0x66FFFFFF), width: 0.75),
          ),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: large ? 12 : 9,
                child: const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0x66FFFFFF), Color(0x00FFFFFF)],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: large
                      ? (hasScores ? 14 : 16)
                      : (hasScores ? 12 : 14),
                  vertical: large ? 9 : 7,
                ),
                child: Text(
                  hasScores
                      ? '${fixture!.homeScore}–${fixture!.awayScore}'
                      : 'VS',
                  style: TextStyle(
                    color: const Color(0xFFF7F8FA),
                    fontSize: hasScores ? (large ? 22 : 15) : (large ? 12 : 11),
                    fontWeight: FontWeight.w700,
                    letterSpacing: hasScores ? -0.4 : 1.0,
                    height: 1,
                    shadows: const [
                      Shadow(
                        color: Color(0x73000000),
                        blurRadius: 4,
                        offset: Offset(0, 0.5),
                      ),
                    ],
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
