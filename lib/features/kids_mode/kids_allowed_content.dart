import 'package:iptv/domain/entities/favorite.dart';
import 'package:iptv/domain/entities/watch_history.dart';
import 'package:iptv/player/domain/entities/player_source.dart';
import 'package:iptv/player/domain/enums/playback_profile.dart';

class KidsAllowedContent {
  const KidsAllowedContent({
    required this.restricted,
    this.channelIds = const {},
    this.movieIds = const {},
    this.seriesIds = const {},
  });

  const KidsAllowedContent.unrestricted()
    : restricted = false,
      channelIds = const {},
      movieIds = const {},
      seriesIds = const {};

  const KidsAllowedContent.denyAll()
    : restricted = true,
      channelIds = const {},
      movieIds = const {},
      seriesIds = const {};

  final bool restricted;
  final Set<int> channelIds;
  final Set<int> movieIds;
  final Set<int> seriesIds;

  bool allowsFavorite(Favorite favorite) {
    if (!restricted) return true;
    return switch (favorite.type) {
      FavoriteType.channel => channelIds.contains(favorite.itemId),
      FavoriteType.movie => movieIds.contains(favorite.itemId),
      FavoriteType.series => seriesIds.contains(favorite.itemId),
    };
  }

  bool allowsHistory(WatchHistoryEntry entry) {
    if (!restricted) return true;
    return switch (entry.type) {
      WatchHistoryType.channel => channelIds.contains(entry.itemId),
      WatchHistoryType.movie => movieIds.contains(entry.itemId),
      // Existing history rows do not carry their parent series ID, so hiding
      // them is the only safe fallback. New playback is still available from
      // an allowed series screen.
      WatchHistoryType.episode => false,
    };
  }

  bool allowsSource(PlayerSource source) {
    if (!restricted) return true;
    final id = source.channelId;
    if (id == null) return false;
    if (source is EpisodeSource || source.metadata['type'] == 'episode') {
      final seriesId = source.metadata['seriesId'];
      return seriesId is int && seriesIds.contains(seriesId);
    }
    if (source.profile == PlaybackProfile.vod) {
      return movieIds.contains(id);
    }
    return channelIds.contains(id);
  }
}
