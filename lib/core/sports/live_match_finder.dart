import 'package:iptv/core/sports/big_match_detector.dart';
import 'package:iptv/core/sports/channel_mapper.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/entities/live_fixture.dart';
import 'package:iptv/domain/entities/live_match.dart';

/// Binds live scoreboard fixtures to beIN / Arabic sports channels.
abstract final class LiveMatchFinder {
  static const defaultLimit = 15;
  static const heroLimit = 15;

  static List<Channel> allowedChannels(Iterable<Channel> channels) {
    return channels
        .where((channel) =>
            BigMatchDetector.isAllowedMatchChannel(channel.name))
        .toList();
  }

  /// Highest-resolution copy of each logical sports station, for EPG probes.
  static List<Channel> epgProbeChannels(
    Iterable<Channel> channels, {
    int limit = 32,
  }) {
    final byKey = <String, Channel>{};
    for (final channel in channels) {
      if (!BigMatchDetector.isBeinOrArabicSportsNetwork(channel.name)) {
        continue;
      }
      if (BigMatchDetector.isOfficialClubChannel(channel.name)) continue;
      final key = BigMatchDetector.fingerprint(channel.name);
      if (key.isEmpty) continue;
      final current = byKey[key];
      if (current == null ||
          BigMatchDetector.channelQuality(channel.name) >
              BigMatchDetector.channelQuality(current.name)) {
        byKey[key] = channel;
      }
    }
    final list = byKey.values.toList()
      ..sort(
        (a, b) => BigMatchDetector.channelQuality(b.name)
            .compareTo(BigMatchDetector.channelQuality(a.name)),
      );
    if (list.length <= limit) return list;
    return list.sublist(0, limit);
  }

  static List<LiveMatch> bindFixtures({
    required List<LiveFixture> fixtures,
    required Iterable<Channel> channels,
    Map<int, String> epgTitles = const {},
    int limit = heroLimit,
  }) {
    if (fixtures.isEmpty) return const [];
    final allowed = allowedChannels(channels);
    if (allowed.isEmpty) return const [];

    final matches = <LiveMatch>[];
    for (final fixture in fixtures) {
      Channel? best;
      var bestFromEpg = false;
      var bestScore = -1;

      // 1. Direct match using scraped broadcast channel (e.g. from Yallakora)
      if (fixture.broadcastChannel != null &&
          fixture.broadcastChannel!.isNotEmpty) {
        best = ChannelMapper.findBestChannel(
          fixture.broadcastChannel!,
          allowed,
        );
      }

      // 2. Club name and EPG broadcast matching
      if (best == null) {
        for (final channel in allowed) {
          final epgTitle = epgTitles[channel.streamId] ?? '';
          final nameHit = fixture.matchesBroadcastText(channel.name);
          final epgHit =
              epgTitle.isNotEmpty && fixture.matchesBroadcastText(epgTitle);
          if (!nameHit && !epgHit) continue;
          final score = BigMatchDetector.channelQuality(channel.name) +
              (epgHit ? 2 : 0);
          if (score > bestScore) {
            best = channel;
            bestFromEpg = epgHit && !nameHit;
            bestScore = score;
          }
        }
      }

      best ??= fallbackWatchChannel(allowed);
      if (best == null) continue;
      final epgTitle = epgTitles[best.streamId] ?? '';
      matches.add(
        LiveMatch(
          channel: best,
          programTitle: epgTitle.isNotEmpty ? epgTitle : fixture.headline,
          teams: fixture.teams,
          fromEpg: bestFromEpg,
          fixture: fixture,
        ),
      );
    }
    return _takeBest(matches, limit);
  }

  /// When EPG never names the clubs, still open a main beIN / Arabic sports 1.
  static Channel? fallbackWatchChannel(Iterable<Channel> channels) {
    Channel? best;
    var bestScore = -1;
    for (final channel in channels) {
      if (!BigMatchDetector.isBeinOrArabicSportsNetwork(channel.name)) {
        continue;
      }
      if (BigMatchDetector.isOfficialClubChannel(channel.name)) continue;
      final n = BigMatchDetector.normalize(channel.name);
      var score = BigMatchDetector.channelQuality(channel.name);
      if (RegExp(r'(^| )1($| )').hasMatch(n)) score += 20;
      if (n.contains('bein')) score += 3;
      if (score > bestScore) {
        best = channel;
        bestScore = score;
      }
    }
    return best;
  }

  static int _quality(LiveMatch match) {
    var score = BigMatchDetector.channelQuality(match.channel.name);
    if (match.teams.length >= 2) score += 5;
    if (match.fixture?.isLive == true) score += 8;
    if (match.fromEpg) score += 1;
    return score;
  }

  static List<LiveMatch> _takeBest(Iterable<LiveMatch> matches, int limit) {
    final list = matches.toList()
      ..sort((a, b) => _quality(b).compareTo(_quality(a)));
    if (list.length <= limit) return list;
    return list.sublist(0, limit);
  }
}
