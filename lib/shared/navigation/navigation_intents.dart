import 'package:flutter/widgets.dart';

/// Typed intent classes for the IPTV navigation system.
///
/// Named with 'Iptv' prefix to avoid clash with Flutter's built-in [SelectIntent].
class MoveFocusUpIntent extends Intent { const MoveFocusUpIntent(); }
class MoveFocusDownIntent extends Intent { const MoveFocusDownIntent(); }
class MoveFocusLeftIntent extends Intent { const MoveFocusLeftIntent(); }
class MoveFocusRightIntent extends Intent { const MoveFocusRightIntent(); }
class IptvSelectIntent extends Intent { const IptvSelectIntent(); }
class IptvBackIntent extends Intent { const IptvBackIntent(); }
class PlayPauseIntent extends Intent { const PlayPauseIntent(); }
class NextChannelIntent extends Intent { const NextChannelIntent(); }
class PreviousChannelIntent extends Intent { const PreviousChannelIntent(); }
class OpenSearchIntent extends Intent { const OpenSearchIntent(); }
class ToggleFullscreenIntent extends Intent { const ToggleFullscreenIntent(); }
