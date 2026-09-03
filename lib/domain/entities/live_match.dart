import 'package:equatable/equatable.dart';
import 'package:iptv/core/sports/big_match_detector.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/entities/live_fixture.dart';

/// A live sports event bound to a beIN / Arabic sports channel.
class LiveMatch extends Equatable {
  const LiveMatch({
    required this.channel,
    required this.programTitle,
    required this.teams,
    this.fromEpg = false,
    this.fixture,
  });

  final Channel channel;
  final String programTitle;
  final List<BigTeam> teams;
  final bool fromEpg;
  final LiveFixture? fixture;

  String get headline {
    final fromFixture = fixture?.headline.trim() ?? '';
    if (fromFixture.isNotEmpty) return fromFixture;
    final title = programTitle.trim();
    if (fromEpg && title.isNotEmpty) return title;
    if (title.isNotEmpty) return title;
    return channel.name;
  }

  /// Match title without stream-quality suffixes (`4K`, `HEVC`, …).
  String get displayTitle {
    var title = headline;
    title = title.replaceAll(RegExp(r'[|\[\]{}]'), ' ');
    title = title.replaceAll(
      RegExp(
        r'\b(?:4k|uhd|fhd|hd|sd|hevc|h\.?265|h\.?264|50fps|60fps|1080p|720p|2160p|multi audio)\b',
        caseSensitive: false,
      ),
      '',
    );
    title = title.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    title = title.replaceAll(RegExp(r'^[-–—:|]+|[-–—:|]+$'), '').trim();
    return title.isEmpty ? headline : title;
  }

  String get resolutionLabel {
    final name = channel.name.toLowerCase();
    if (name.contains('4k') ||
        name.contains('uhd') ||
        name.contains('2160')) {
      return '4K';
    }
    if (name.contains('fhd') || name.contains('1080')) return 'FHD';
    if (name.contains('hd')) return 'HD';
    return 'LIVE';
  }

  String get teamsLabel {
    final fixture = this.fixture;
    if (fixture != null) return fixture.headline;
    if (teams.length >= 2) {
      return '${teams[0].displayName} vs ${teams[1].displayName}';
    }
    if (teams.length == 1) return teams.first.displayName;
    return displayTitle;
  }

  String? get channelLabel {
    final name = channel.name.trim();
    if (name.isEmpty || name == headline || name == displayTitle) return null;
    return name;
  }

  @override
  List<Object?> get props => [channel.streamId, programTitle, fromEpg];
}
