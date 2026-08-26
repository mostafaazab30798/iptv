import 'package:equatable/equatable.dart';
import 'package:iptv/player/domain/enums/playback_profile.dart';
import 'package:iptv/player/domain/enums/stream_type.dart';

/// Immutable representation of media content to be played.
class PlayerSource extends Equatable {
  const PlayerSource({
    required this.url,
    required this.title,
    this.streamType = StreamType.auto,
    this.profile = PlaybackProfile.live,
    this.headers = const {},
    this.channelId,
    this.categoryId,
    this.logoUrl,
    this.epgProgramId,
    this.currentProgramTitle,
    this.nextProgramTitle,
    this.programProgress,
    this.startAt,
    this.metadata = const {},
  });

  final String url;
  final String title;
  final StreamType streamType;
  final PlaybackProfile profile;
  final Map<String, String> headers;
  final int? channelId;
  final int? categoryId;
  final String? logoUrl;
  final String? epgProgramId;
  final String? currentProgramTitle;
  final String? nextProgramTitle;
  final double? programProgress;
  final Duration? startAt;
  final Map<String, dynamic> metadata;

  /// Helper factory for live channels.
  factory PlayerSource.live({
    required String url,
    required String title,
    int? channelId,
    int? categoryId,
    String? logoUrl,
    String? currentProgramTitle,
    String? nextProgramTitle,
    double? programProgress,
    Map<String, String> headers = const {},
    StreamType streamType = StreamType.auto,
    Map<String, dynamic> metadata = const {},
  }) {
    return PlayerSource(
      url: url,
      title: title,
      profile: PlaybackProfile.live,
      streamType: streamType,
      channelId: channelId,
      categoryId: categoryId,
      logoUrl: logoUrl,
      currentProgramTitle: currentProgramTitle,
      nextProgramTitle: nextProgramTitle,
      programProgress: programProgress,
      headers: headers,
      metadata: metadata,
    );
  }

  /// Helper factory for VOD content.
  factory PlayerSource.vod({
    required String url,
    required String title,
    int? movieId,
    int? categoryId,
    String? posterUrl,
    Duration? startAt,
    Map<String, String> headers = const {},
    StreamType streamType = StreamType.auto,
    Map<String, dynamic> metadata = const {},
  }) {
    return PlayerSource(
      url: url,
      title: title,
      profile: PlaybackProfile.vod,
      streamType: streamType,
      channelId: movieId,
      categoryId: categoryId,
      logoUrl: posterUrl,
      startAt: startAt,
      headers: headers,
      metadata: metadata,
    );
  }

  PlayerSource copyWith({
    String? url,
    String? title,
    StreamType? streamType,
    PlaybackProfile? profile,
    Map<String, String>? headers,
    int? channelId,
    int? categoryId,
    String? logoUrl,
    String? epgProgramId,
    String? currentProgramTitle,
    String? nextProgramTitle,
    double? programProgress,
    Duration? startAt,
    Map<String, dynamic>? metadata,
  }) {
    return PlayerSource(
      url: url ?? this.url,
      title: title ?? this.title,
      streamType: streamType ?? this.streamType,
      profile: profile ?? this.profile,
      headers: headers ?? this.headers,
      channelId: channelId ?? this.channelId,
      categoryId: categoryId ?? this.categoryId,
      logoUrl: logoUrl ?? this.logoUrl,
      epgProgramId: epgProgramId ?? this.epgProgramId,
      currentProgramTitle: currentProgramTitle ?? this.currentProgramTitle,
      nextProgramTitle: nextProgramTitle ?? this.nextProgramTitle,
      programProgress: programProgress ?? this.programProgress,
      startAt: startAt ?? this.startAt,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  List<Object?> get props => [
        url,
        title,
        streamType,
        profile,
        headers,
        channelId,
        categoryId,
        logoUrl,
        epgProgramId,
        currentProgramTitle,
        nextProgramTitle,
        programProgress,
        startAt,
        metadata,
      ];
}

/// Backward compatibility class for live channels.
class LiveSource extends PlayerSource {
  const LiveSource({
    required super.url,
    required int channelId,
    required String channelName,
    super.logoUrl,
    super.headers,
    super.streamType,
    super.currentProgramTitle,
    super.nextProgramTitle,
    super.programProgress,
    super.metadata,
  }) : super(
          title: channelName,
          channelId: channelId,
          profile: PlaybackProfile.live,
        );
}

/// Backward compatibility class for VOD movies.
class VodSource extends PlayerSource {
  const VodSource({
    required super.url,
    required int movieId,
    required super.title,
    String? posterUrl,
    super.startAt,
    super.headers,
    super.streamType,
    super.metadata,
  }) : super(
          channelId: movieId,
          logoUrl: posterUrl,
          profile: PlaybackProfile.vod,
        );
}

/// Backward compatibility class for series episodes.
class EpisodeSource extends PlayerSource {
  const EpisodeSource({
    required super.url,
    required int episodeId,
    required super.title,
    String? seriesName,
    String? posterUrl,
    super.startAt,
    super.headers,
    super.streamType,
    super.metadata,
  }) : super(
          channelId: episodeId,
          logoUrl: posterUrl,
          profile: PlaybackProfile.vod,
          currentProgramTitle: seriesName,
        );
}

