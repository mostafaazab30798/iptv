import 'package:iptv/shared/navigation/navigation_intents.dart';

/// Navigation intents namespace — maps all input sources to typed intents.
///
/// Individual screens handle these intents via Flutter's Actions system.
/// No screen ever hardcodes raw keyboard/remote key logic.
abstract final class NavigationIntent {
  static const moveFocusUp = MoveFocusUpIntent();
  static const moveFocusDown = MoveFocusDownIntent();
  static const moveFocusLeft = MoveFocusLeftIntent();
  static const moveFocusRight = MoveFocusRightIntent();
  static const select = IptvSelectIntent();
  static const back = IptvBackIntent();
  static const playPause = PlayPauseIntent();
  static const nextChannel = NextChannelIntent();
  static const previousChannel = PreviousChannelIntent();
  static const openGuide = OpenGuideIntent();
  static const openSearch = OpenSearchIntent();
  static const toggleFullscreen = ToggleFullscreenIntent();
}
