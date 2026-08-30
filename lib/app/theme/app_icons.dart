import 'package:flutter/widgets.dart';
import 'package:hugeicons/hugeicons.dart';

/// Centralized repository of Hugeicons tokens and helper widget used across the application.
abstract final class AppIcons {
  // --- Main Navigation ---
  static const List<List<dynamic>> home = HugeIcons.strokeRoundedHome01;
  static const List<List<dynamic>> homeAlt = HugeIcons.strokeRoundedHome02;

  static const List<List<dynamic>> live = HugeIcons.strokeRoundedTv01;
  static const List<List<dynamic>> liveAlt = HugeIcons.strokeRoundedTv02;

  static const List<List<dynamic>> movies = HugeIcons.strokeRoundedFilm01;
  static const List<List<dynamic>> moviesAlt = HugeIcons.strokeRoundedFilm02;

  static const List<List<dynamic>> series = HugeIcons.strokeRoundedVideo01;
  static const List<List<dynamic>> seriesAlt = HugeIcons.strokeRoundedVideotape;

  static const List<List<dynamic>> favorites = HugeIcons.strokeRoundedFavourite;
  static const List<List<dynamic>> history = HugeIcons.strokeRoundedTime01;
  static const List<List<dynamic>> historyAlt = HugeIcons.strokeRoundedTime02;

  static const List<List<dynamic>> settings = HugeIcons.strokeRoundedSettings02;
  static const List<List<dynamic>> settingsAlt =
      HugeIcons.strokeRoundedSettings01;

  static const List<List<dynamic>> search = HugeIcons.strokeRoundedSearch01;
  static const List<List<dynamic>> clear = HugeIcons.strokeRoundedCancel01;
  static const List<List<dynamic>> close = HugeIcons.strokeRoundedCancel01;
  static const List<List<dynamic>> refresh = HugeIcons.strokeRoundedRefresh;
  static const List<List<dynamic>> filter = HugeIcons.strokeRoundedFilter;
  static const List<List<dynamic>> sort = HugeIcons.strokeRoundedSorting01;
  static const List<List<dynamic>> moreVert =
      HugeIcons.strokeRoundedMoreVertical;
  static const List<List<dynamic>> moreHoriz =
      HugeIcons.strokeRoundedMoreHorizontal;
  static const List<List<dynamic>> check = HugeIcons.strokeRoundedTick01;
  static const List<List<dynamic>> checkSimple = HugeIcons.strokeRoundedTick02;

  // --- Arrows & Navigation ---
  static const List<List<dynamic>> arrowBack =
      HugeIcons.strokeRoundedArrowLeft01;
  static const List<List<dynamic>> arrowForward =
      HugeIcons.strokeRoundedArrowRight01;
  static const List<List<dynamic>> arrowDown =
      HugeIcons.strokeRoundedArrowDown01;
  static const List<List<dynamic>> arrowUp = HugeIcons.strokeRoundedArrowUp01;
  static const List<List<dynamic>> chevronRight =
      HugeIcons.strokeRoundedArrowRight01;
  static const List<List<dynamic>> chevronLeft =
      HugeIcons.strokeRoundedArrowLeft01;

  // --- Media & Player Controls ---
  static const List<List<dynamic>> play = HugeIcons.strokeRoundedPlay;
  static const List<List<dynamic>> pause = HugeIcons.strokeRoundedPause;
  static const List<List<dynamic>> stop = HugeIcons.strokeRoundedStop;
  static const List<List<dynamic>> replay = HugeIcons.strokeRoundedRotateLeft01;
  static const List<List<dynamic>> forward10 =
      HugeIcons.strokeRoundedGoForward10Sec;
  static const List<List<dynamic>> replay10 =
      HugeIcons.strokeRoundedGoBackward10Sec;
  static const List<List<dynamic>> fastForward =
      HugeIcons.strokeRoundedForward01;
  static const List<List<dynamic>> fastRewind =
      HugeIcons.strokeRoundedBackward01;
  static const List<List<dynamic>> next = HugeIcons.strokeRoundedNext;
  static const List<List<dynamic>> previous = HugeIcons.strokeRoundedPrevious;
  static const List<List<dynamic>> volumeHigh =
      HugeIcons.strokeRoundedVolumeHigh;
  static const List<List<dynamic>> volumeLow = HugeIcons.strokeRoundedVolumeLow;
  static const List<List<dynamic>> volumeMute =
      HugeIcons.strokeRoundedVolumeMute01;
  static const List<List<dynamic>> brightness = HugeIcons.strokeRoundedSun01;
  static const List<List<dynamic>> subtitles = HugeIcons.strokeRoundedSubtitle;
  static const List<List<dynamic>> audioTrack =
      HugeIcons.strokeRoundedMusicNote01;
  static const List<List<dynamic>> aspectRatio =
      HugeIcons.strokeRoundedAspectRatio;
  static const List<List<dynamic>> fullscreen =
      HugeIcons.strokeRoundedFullScreen;
  static const List<List<dynamic>> exitFullscreen =
      HugeIcons.strokeRoundedArrowShrink02;
  static const List<List<dynamic>> lock = HugeIcons.strokeRoundedLock;
  static const List<List<dynamic>> unlock =
      HugeIcons.strokeRoundedCircleUnlock01;
  static const List<List<dynamic>> speed =
      HugeIcons.strokeRoundedDashboardSpeed01;
  static const List<List<dynamic>> tune =
      HugeIcons.strokeRoundedSlidersHorizontal;
  static const List<List<dynamic>> waveform =
      HugeIcons.strokeRoundedAudioWave01;
  static const List<List<dynamic>> moon = HugeIcons.strokeRoundedMoon02;
  static const List<List<dynamic>> timer = HugeIcons.strokeRoundedTimer01;
  static const List<List<dynamic>> timerOff =
      HugeIcons.strokeRoundedAlarmClockOff;

  // --- Categories & Genres ---
  static const List<List<dynamic>> sports = HugeIcons.strokeRoundedFootball;
  static const List<List<dynamic>> news = HugeIcons.strokeRoundedNews;
  static const List<List<dynamic>> music = HugeIcons.strokeRoundedMusicNote02;
  static const List<List<dynamic>> globe = HugeIcons.strokeRoundedGlobe;
  static const List<List<dynamic>> trending = HugeIcons.strokeRoundedFire;
  static const List<List<dynamic>> comedy = HugeIcons.strokeRoundedSmile;
  static const List<List<dynamic>> premium = HugeIcons.strokeRoundedShield01;
  static const List<List<dynamic>> generalTv = HugeIcons.strokeRoundedTv02;
  static const List<List<dynamic>> gridView = HugeIcons.strokeRoundedGridTable;
  static const List<List<dynamic>> listView = HugeIcons.strokeRoundedListView;

  // --- Feedback & States ---
  static const List<List<dynamic>> error = HugeIcons.strokeRoundedAlertCircle;
  static const List<List<dynamic>> warning = HugeIcons.strokeRoundedAlert02;
  static const List<List<dynamic>> info =
      HugeIcons.strokeRoundedInformationCircle;
  static const List<List<dynamic>> empty = HugeIcons.strokeRoundedInbox;
  static const List<List<dynamic>> imageFallback =
      HugeIcons.strokeRoundedImage01;
  static const List<List<dynamic>> memory = HugeIcons.strokeRoundedCpu;
  static const List<List<dynamic>> analytics =
      HugeIcons.strokeRoundedAnalytics01;

  // --- Settings & Actions ---
  static const List<List<dynamic>> server = HugeIcons.strokeRoundedCloudServer;
  static const List<List<dynamic>> dns = HugeIcons.strokeRoundedServerStack01;
  static const List<List<dynamic>> bolt = HugeIcons.strokeRoundedFlash;
  static const List<List<dynamic>> swap = HugeIcons.strokeRoundedExchange01;
  static const List<List<dynamic>> hub = HugeIcons.strokeRoundedRouter01;
  static const List<List<dynamic>> link = HugeIcons.strokeRoundedLink01;
  static const List<List<dynamic>> playlist = HugeIcons.strokeRoundedPlayList;
  static const List<List<dynamic>> epg = HugeIcons.strokeRoundedCalendar03;
  static const List<List<dynamic>> star = HugeIcons.strokeRoundedStar;
  static const List<List<dynamic>> delete = HugeIcons.strokeRoundedDelete02;
  static const List<List<dynamic>> edit = HugeIcons.strokeRoundedEdit02;
  static const List<List<dynamic>> user = HugeIcons.strokeRoundedUser;
  static const List<List<dynamic>> logout = HugeIcons.strokeRoundedLogout01;
  static const List<List<dynamic>> language = HugeIcons.strokeRoundedTranslate;
  static const List<List<dynamic>> palette = HugeIcons.strokeRoundedColors;
  static const List<List<dynamic>> viewList = HugeIcons.strokeRoundedListView;
  static const List<List<dynamic>> visibility = HugeIcons.strokeRoundedView;
  static const List<List<dynamic>> visibilityOff =
      HugeIcons.strokeRoundedViewOff;
  static const List<List<dynamic>> checkCircle =
      HugeIcons.strokeRoundedCheckmarkCircle01;
  static const List<List<dynamic>> circle = HugeIcons.strokeRoundedCircle;
  static const List<List<dynamic>> searchOff = HugeIcons.strokeRoundedSearch01;
  static const List<List<dynamic>> paste = HugeIcons.strokeRoundedClipboard;
  static const List<List<dynamic>> chevronDown =
      HugeIcons.strokeRoundedArrowDown01;
  static const List<List<dynamic>> guide = HugeIcons.strokeRoundedCalendar03;
  static const List<List<dynamic>> deleteSweep =
      HugeIcons.strokeRoundedDelete01;
  static const List<List<dynamic>> time = HugeIcons.strokeRoundedClock01;

  // --- Authentication ---
  static const List<List<dynamic>> mail = HugeIcons.strokeRoundedMail01;
  static const List<List<dynamic>> securityCheck =
      HugeIcons.strokeRoundedSecurityCheck;
}

/// Convenience widget wrapper for rendering HugeIcons
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.color,
    this.size = 22.0,
    this.semanticLabel,
  });

  final dynamic icon;
  final Color? color;
  final double size;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? const Color(0xFFFFFFFF);
    return Semantics(
      label: semanticLabel,
      child: icon is IconData
          ? Icon(icon as IconData, color: effectiveColor, size: size)
          : HugeIcon(
              icon: icon as List<List<dynamic>>,
              color: effectiveColor,
              size: size,
            ),
    );
  }
}
