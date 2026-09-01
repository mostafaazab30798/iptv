import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/foundation.dart' show listEquals;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/entities/watch_history.dart';
import 'package:iptv/domain/repositories/history_repository.dart';
import 'package:iptv/player/application/player_capability_service.dart';
import 'package:iptv/player/application/player_state.dart';
import 'package:iptv/player/application/smart_playback_engine.dart';
import 'package:iptv/player/domain/entities/player_source.dart';
import 'package:iptv/player/domain/entities/player_track.dart';
import 'package:iptv/player/domain/enums/playback_buffer_mode.dart';
import 'package:iptv/player/domain/enums/playback_profile.dart';
import 'package:iptv/player/domain/enums/player_error_type.dart';
import 'package:iptv/player/domain/enums/player_status.dart';
import 'package:iptv/player/domain/interfaces/player_engine.dart';
import 'package:iptv/player/infrastructure/media_kit_player_engine.dart';
import 'package:iptv/player/utils/player_logger.dart';

/// Riverpod StateNotifier managing active player state and user playback actions.
class PlayerController extends StateNotifier<PlayerState> {
  PlayerController({
    PlayerEngine? engine,
    HistoryRepository? historyRepository,
    PlaybackBufferMode? initialBufferMode,
    Future<bool> Function(PlayerSource source)? canLoadSource,
  })  : _engine = engine ??
            MediaKitPlayerEngine(
              initialBufferMode:
                  initialBufferMode ?? PlaybackBufferMode.deviceDefault,
            ),
        _historyRepository = historyRepository,
        _canLoadSource = canLoadSource,
        super(
          PlayerState.initial.copyWith(
            bufferMode: initialBufferMode ??
                (engine == null
                    ? PlaybackBufferMode.deviceDefault
                    : PlaybackBufferMode.balanced),
          ),
        ) {
    _smartEngine = SmartPlaybackEngine(
      engine: _engine,
      initialBufferMode: state.bufferMode,
    );
    _initSubscriptions();
  }

  final PlayerEngine _engine;
  final HistoryRepository? _historyRepository;
  final Future<bool> Function(PlayerSource source)? _canLoadSource;
  late final SmartPlaybackEngine _smartEngine;
  final List<StreamSubscription<dynamic>> _subscriptions = [];

  /// Materialized playlist (tests / non-live callers). Empty when using lazy live IDs.
  List<PlayerSource> _channelPlaylist = const [];

  /// Lazy live playlist: channel IDs + URL resolver; only neighbors are materialized.
  List<int> _liveChannelIds = const [];
  Map<int, Channel> _liveChannelById = const {};
  String Function(Channel channel)? _liveUrlFor;
  static const _neighborWindowRadius = 25;
  final Map<int, PlayerSource> _neighborSourceCache = {};

  int _currentChannelIndex = -1;
  bool _deviceProfileInitialized = false;
  Timer? _progressSaveTimer;
  bool _seekScrubActive = false;
  bool _resumeAfterSeekScrub = false;
  Future<void>? _seekScrubPauseOperation;

  /// Incremented on every [load]/[stop] so late async work from a previous
  /// channel enter/leave cannot clobber the active playback session.
  int _playbackEpoch = 0;

  PlayerEngine get engine => _engine;
  SmartPlaybackEngine get smartEngine => _smartEngine;
  List<PlayerSource> get channelPlaylist => _channelPlaylist;

  bool get _hasLazyLivePlaylist =>
      _liveChannelIds.isNotEmpty && _liveUrlFor != null;

  /// True when Live TV registered a lazy playlist so the mini-preview can keep
  /// the current live stream after leaving the fullscreen player route.
  bool get hasLivePreviewHandoff => _hasLazyLivePlaylist;

  int get _playlistLength =>
      _hasLazyLivePlaylist ? _liveChannelIds.length : _channelPlaylist.length;

  void _startPeriodicProgressSaver() {
    _progressSaveTimer?.cancel();
    // Flush progress every 5 seconds during active playback
    _progressSaveTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted && state.isPlaying && state.source != null) {
        savePlaybackProgress();
      }
    });
  }

  void _stopPeriodicProgressSaver() {
    _progressSaveTimer?.cancel();
    _progressSaveTimer = null;
  }

  void _initSubscriptions() {
    _subscriptions.add(
      _engine.statusStream.listen((status) {
        if (!mounted) return;
        state = state.copyWith(
          status: status,
          clearError: status == PlayerStatus.playing || status == PlayerStatus.loading,
          isRetrying: status == PlayerStatus.playing ? false : state.isRetrying,
          retryAttempt: status == PlayerStatus.playing ? 0 : state.retryAttempt,
        );

        if (status == PlayerStatus.playing) {
          _startPeriodicProgressSaver();
        } else {
          _stopPeriodicProgressSaver();
        }

        if (status == PlayerStatus.completed) {
          _handlePlaybackCompleted();
        }
      }),
    );


    _subscriptions.add(
      _engine.positionStream.listen((pos) {
        if (!mounted) return;
        state = state.copyWith(position: pos);
      }),
    );

    _subscriptions.add(
      _engine.durationStream.listen((dur) {
        if (!mounted) return;
        state = state.copyWith(duration: dur);
      }),
    );

    _subscriptions.add(
      _engine.bufferStream.listen((buf) {
        if (!mounted) return;
        state = state.copyWith(bufferedPosition: buf);
      }),
    );

    _subscriptions.add(
      _engine.errorStream.listen((err) {
        if (!mounted) return;

        final errorEpoch = _playbackEpoch;

        // Trigger bounded auto-retry (up to 5 attempts)
        final scheduled = _smartEngine.handleError(
          err,
          onExecuteRetry: () async {
            if (!mounted || errorEpoch != _playbackEpoch) return;
            await retry();
          },
          onRetryScheduled: (delay, attempt) {
            if (!mounted || errorEpoch != _playbackEpoch) return;
            state = state.copyWith(
              status: PlayerStatus.error,
              error: err,
              isRetrying: true,
              retryAttempt: attempt,
              maxRetries: 5,
              errorMessage: '${err.defaultMessage} (Attempt $attempt/5)...',
            );
          },
        );

        if (!scheduled && mounted && errorEpoch == _playbackEpoch) {
          state = state.copyWith(
            status: PlayerStatus.error,
            error: err,
            isRetrying: false,
            errorMessage: err.defaultMessage,
          );
        }
      }),
    );

    _subscriptions.add(
      _engine.audioTracksStream.listen((tracks) {
        if (!mounted) return;
        state = state.copyWith(availableAudioTracks: tracks);
      }),
    );

    _subscriptions.add(
      _engine.subtitleTracksStream.listen((tracks) {
        if (!mounted) return;
        state = state.copyWith(availableSubtitleTracks: tracks);
      }),
    );

    _subscriptions.add(
      _engine.metricsStream.listen((metrics) {
        if (!mounted) return;
        state = state.copyWith(
          metrics: metrics,
          bufferMode: metrics.bufferMode,
        );
      }),
    );
  }

  /// Sets the active channel list context (e.g. current category or favorites).
  void setChannelPlaylist(List<PlayerSource> playlist, {int initialIndex = 0}) {
    _clearLazyLivePlaylist();
    _channelPlaylist = List.unmodifiable(playlist);
    if (initialIndex >= 0 && initialIndex < playlist.length) {
      _currentChannelIndex = initialIndex;
    }
  }

  /// Lazy live playlist: keeps channel IDs + resolver instead of allocating a
  /// full [PlayerSource] list (with credentials) on every tap. Next/prev still
  /// traverse the entire filtered set; only a neighbor window is materialized.
  void setLazyLivePlaylist({
    required List<Channel> channels,
    required int initialIndex,
    required String Function(Channel channel) urlFor,
  }) {
    _channelPlaylist = const [];
    _liveChannelIds = List.unmodifiable(channels.map((c) => c.streamId));
    _liveChannelById = {
      for (final c in channels) c.streamId: c,
    };
    _liveUrlFor = urlFor;
    _neighborSourceCache.clear();
    if (initialIndex >= 0 && initialIndex < _liveChannelIds.length) {
      _currentChannelIndex = initialIndex;
    } else {
      _currentChannelIndex = _liveChannelIds.isEmpty ? -1 : 0;
    }
    _warmNeighborWindow(_currentChannelIndex);
  }

  void _clearLazyLivePlaylist() {
    _liveChannelIds = const [];
    _liveChannelById = const {};
    _liveUrlFor = null;
    _neighborSourceCache.clear();
  }

  PlayerSource? _resolveLiveSourceAt(int index) {
    if (!_hasLazyLivePlaylist) return null;
    if (index < 0 || index >= _liveChannelIds.length) return null;
    final cached = _neighborSourceCache[index];
    if (cached != null) return cached;
    final id = _liveChannelIds[index];
    final channel = _liveChannelById[id];
    final urlFor = _liveUrlFor;
    if (channel == null || urlFor == null) return null;
    final source = PlayerSource.live(
      url: urlFor(channel),
      title: channel.name,
      channelId: channel.streamId,
      logoUrl: channel.streamIcon,
    );
    _neighborSourceCache[index] = source;
    return source;
  }

  void _warmNeighborWindow(int center) {
    if (!_hasLazyLivePlaylist || center < 0) return;
    final len = _liveChannelIds.length;
    if (len == 0) return;
    final start = (center - _neighborWindowRadius).clamp(0, len - 1);
    final end = (center + _neighborWindowRadius).clamp(0, len - 1);
    final keep = <int>{};
    for (var i = start; i <= end; i++) {
      keep.add(i);
      _resolveLiveSourceAt(i);
    }
    _neighborSourceCache.removeWhere((key, _) => !keep.contains(key));
  }

  PlayerSource? _sourceAt(int index) {
    if (_hasLazyLivePlaylist) return _resolveLiveSourceAt(index);
    if (index < 0 || index >= _channelPlaylist.length) return null;
    return _channelPlaylist[index];
  }

  WatchHistoryType _determineHistoryType(PlayerSource source) {
    if (source is EpisodeSource || source.metadata['type'] == 'episode') {
      return WatchHistoryType.episode;
    }
    if (source.profile == PlaybackProfile.vod) {
      return WatchHistoryType.movie;
    }
    return WatchHistoryType.channel;
  }

  /// Flushes current playback progress to local storage immediately.
  Future<void> savePlaybackProgress() async {
    final source = state.source;
    if (source == null || source.channelId == null || _historyRepository == null) return;

    final type = _determineHistoryType(source);
    final posSecs = state.position.inSeconds;
    final durSecs = state.duration.inSeconds;

    if (posSecs > 0 || durSecs > 0) {
      await _historyRepository.updatePosition(
        type: type,
        itemId: source.channelId!,
        positionSecs: posSecs,
        durationSecs: durSecs > 0 ? durSecs : null,
      );
    }
  }

  Future<void> _handlePlaybackCompleted() async {
    final source = state.source;
    if (source == null || source.channelId == null || _historyRepository == null) return;

    final type = _determineHistoryType(source);
    final durSecs = state.duration.inSeconds > 0 ? state.duration.inSeconds : state.position.inSeconds;

    // Mark as finished by setting position to total duration
    await _historyRepository.updatePosition(
      type: type,
      itemId: source.channelId!,
      positionSecs: durSecs,
      durationSecs: durSecs,
    );
  }

  /// Loads and plays a [PlayerSource], automatically checking saved progress if applicable.
  Future<void> load(PlayerSource source) async {
    final epoch = ++_playbackEpoch;
    _smartEngine.cancelRetry();

    final canLoad = _canLoadSource;
    if (canLoad != null && !await canLoad(source)) {
      if (!mounted || epoch != _playbackEpoch) return;
      await _smartEngine.stop();
      if (!mounted || epoch != _playbackEpoch) return;
      state = state.copyWith(
        status: PlayerStatus.error,
        clearSource: true,
        error: PlayerErrorType.invalidSource,
        errorMessage: 'Content blocked by Kids Mode.',
        isRetrying: false,
        retryAttempt: 0,
      );
      return;
    }
    if (!mounted || epoch != _playbackEpoch) return;

    // Drop Live TV mini-preview handoff when loading something outside that
    // playlist (favourites, movies, series, search, etc.).
    if (_hasLazyLivePlaylist) {
      final id = source.channelId;
      final inLivePlaylist = id != null && _liveChannelIds.contains(id);
      if (!inLivePlaylist) {
        _clearLazyLivePlaylist();
      }
    }

    // Save progress of any previously playing media before switching
    if (state.source != null && state.position.inSeconds > 0) {
      await savePlaybackProgress();
      if (!mounted || epoch != _playbackEpoch) return;
    }

    var effectiveSource = source;

    // For VOD/Episodes: Check for saved progress if startAt was not explicitly specified
    if (effectiveSource.profile == PlaybackProfile.vod &&
        effectiveSource.channelId != null &&
        effectiveSource.startAt == null &&
        _historyRepository != null) {
      final type = _determineHistoryType(effectiveSource);
      final historyRes = await _historyRepository.getEntry(
        type: type,
        itemId: effectiveSource.channelId!,
      );
      if (!mounted || epoch != _playbackEpoch) return;

      final entry = historyRes.when(
        ok: (e) => e,
        err: (_) => null,
      );

      if (entry != null && entry.positionSecs >= 5 && !entry.isFinished) {
        effectiveSource = effectiveSource.copyWith(
          startAt: Duration(seconds: entry.positionSecs),
        );
      }
    }

    final capabilities = PlayerCapabilityService.getCapabilities(streamType: effectiveSource.streamType);
    state = state.copyWith(
      source: effectiveSource,
      status: PlayerStatus.loading,
      capabilities: capabilities,
      clearError: true,
      isRetrying: false,
      retryAttempt: 0,
    );

    // Record watch history entry in DB
    if (effectiveSource.channelId != null && _historyRepository != null) {
      final type = _determineHistoryType(effectiveSource);
      final entry = WatchHistoryEntry(
        id: 0,
        type: type,
        itemId: effectiveSource.channelId!,
        name: effectiveSource.title,
        imageUrl: effectiveSource.logoUrl,
        positionSecs: effectiveSource.startAt?.inSeconds ?? 0,
        durationSecs: null,
        watchedAt: DateTime.now(),
      );
      // Non-blocking write to avoid delaying playback initialization
      unawaited(_historyRepository.recordWatch(entry));
    }

    await _smartEngine.open(effectiveSource);
    if (!mounted || epoch != _playbackEpoch) return;

    // Initialise device decode profile on first channel load (async, non-blocking).
    if (!_deviceProfileInitialized) {
      _deviceProfileInitialized = true;
      unawaited(_smartEngine.initDeviceProfile());
    }

    if (mounted && epoch == _playbackEpoch && _engine.currentStatus != state.status) {
      state = state.copyWith(status: _engine.currentStatus);
    }
  }

  /// Switches to next channel in current playlist.
  Future<void> nextChannel() async {
    final len = _playlistLength;
    if (len == 0) return;
    _currentChannelIndex = (_currentChannelIndex + 1) % len;
    final nextSource = _sourceAt(_currentChannelIndex);
    if (nextSource == null) return;
    PlayerLogger.channelSwitch(
      state.source?.channelId,
      nextSource.channelId,
      nextSource.title,
    );
    _warmNeighborWindow(_currentChannelIndex);
    await load(nextSource);
  }

  /// Switches to previous channel in current playlist.
  Future<void> previousChannel() async {
    final len = _playlistLength;
    if (len == 0) return;
    _currentChannelIndex = (_currentChannelIndex - 1 + len) % len;
    final prevSource = _sourceAt(_currentChannelIndex);
    if (prevSource == null) return;
    PlayerLogger.channelSwitch(
      state.source?.channelId,
      prevSource.channelId,
      prevSource.title,
    );
    _warmNeighborWindow(_currentChannelIndex);
    await load(prevSource);
  }

  /// Stops live decode when leaving the Live browse route.
  /// No-op while the fullscreen player route owns the engine (mini-preview handoff).
  Future<void> stopWhenLeavingLiveRoute() async {
    if (!mounted) return;
    if (state.isPlayerRouteActive) return;
    if (state.source == null && state.status == PlayerStatus.stopped) return;
    await stop();
  }

  Future<void> play() async {
    await _smartEngine.play();
    if (mounted) {
      state = state.copyWith(status: PlayerStatus.playing);
    }
  }

  Future<void> pause() async {
    await savePlaybackProgress();
    await _smartEngine.pause();
    if (mounted) {
      state = state.copyWith(status: PlayerStatus.paused);
    }
  }

  Future<void> stop() async {
    _playbackEpoch++;
    _seekScrubActive = false;
    _resumeAfterSeekScrub = false;
    _seekScrubPauseOperation = null;
    _clearLazyLivePlaylist();
    await savePlaybackProgress();
    await _smartEngine.stop();
    if (!mounted) return;
    state = state.copyWith(
      status: PlayerStatus.stopped,
      clearSource: true,
      position: Duration.zero,
      duration: Duration.zero,
      bufferedPosition: Duration.zero,
      clearError: true,
      availableAudioTracks: const [],
      availableSubtitleTracks: const [],
      isRetrying: false,
      retryAttempt: 0,
    );
  }

  /// Cancels a pending auto-reconnect without tearing down the current source.
  /// Used when leaving fullscreen Live TV while keeping the mini-preview stream.
  void cancelAutoReconnect() {
    if (!mounted) return;
    _smartEngine.cancelRetry();
    if (state.isRetrying || state.retryAttempt > 0) {
      state = state.copyWith(
        isRetrying: false,
        retryAttempt: 0,
        clearError: true,
      );
    }
  }

  Future<void> seek(Duration position) async {
    await _smartEngine.seek(position);
    await savePlaybackProgress();
  }

  /// Starts a scrub session and freezes playback until the thumb is released.
  void beginSeekScrub() {
    if (!mounted || state.isLive || _seekScrubActive) return;
    _seekScrubActive = true;
    _resumeAfterSeekScrub = state.isPlaying;
    _seekScrubPauseOperation = _resumeAfterSeekScrub
        ? _smartEngine.pause().then((_) {
            if (mounted && _seekScrubActive) {
              state = state.copyWith(status: PlayerStatus.paused);
            }
          })
        : Future<void>.value();
  }

  /// Commits the final scrub position, then restores the pre-scrub play state.
  Future<void> finishSeekScrub(Duration position) async {
    if (!_seekScrubActive) {
      await seek(position);
      return;
    }

    final shouldResume = _resumeAfterSeekScrub;
    final pauseOperation = _seekScrubPauseOperation;
    _seekScrubActive = false;
    _resumeAfterSeekScrub = false;
    _seekScrubPauseOperation = null;

    await pauseOperation;
    if (!mounted) return;
    await _smartEngine.seek(position);
    await savePlaybackProgress();
    if (shouldResume && mounted) {
      await _smartEngine.play();
      if (mounted) state = state.copyWith(status: PlayerStatus.playing);
    }
  }

  /// Seeks without persisting watch history, waits for the decoder to render
  /// the requested position, then returns that real frame for the scrub HUD.
  Future<Uint8List?> createSeekPreview(Duration position) async {
    if (!mounted || state.isLive || state.duration <= Duration.zero) return null;

    if (!_seekScrubActive) beginSeekScrub();
    await _seekScrubPauseOperation;
    if (!mounted || !_seekScrubActive) return null;

    final frameBeforeSeek = await _smartEngine.captureFrame();
    if (!mounted || !_seekScrubActive) return null;
    await _smartEngine.seekForPreview(position);
    if (!mounted || !_seekScrubActive) return null;
    // Some backends briefly resume after a seek even if they were paused.
    await _smartEngine.pause();

    // A libmpv seek command is acknowledged before the target frame finishes
    // decoding. Wait until its playback clock reaches the requested region.
    for (var attempt = 0;
        attempt < 12 && mounted && _seekScrubActive;
        attempt++) {
      final delta =
          (state.position.inMilliseconds - position.inMilliseconds).abs();
      if (delta <= 1200) break;
      await Future<void>.delayed(const Duration(milliseconds: 50));
    }

    // The playback clock can advance one tick before the video texture. Poll
    // until the screenshot really changes, instead of repeatedly returning the
    // pre-seek frame. Static scenes safely fall back after the bounded timeout.
    Uint8List? latestFrame;
    for (var attempt = 0;
        attempt < 5 && mounted && _seekScrubActive;
        attempt++) {
      await Future<void>.delayed(const Duration(milliseconds: 80));
      latestFrame = await _smartEngine.captureFrame();
      if (latestFrame != null &&
          latestFrame.isNotEmpty &&
          (frameBeforeSeek == null ||
              !listEquals(latestFrame, frameBeforeSeek))) {
        return latestFrame;
      }
    }
    return mounted && _seekScrubActive ? latestFrame : null;
  }

  /// Relative seek (e.g. -10 seconds or +10 seconds).
  Future<void> seekRelative(Duration offset) async {
    await _smartEngine.seekRelative(offset);
    await savePlaybackProgress();
  }

  /// Sets video playback speed multiplier (0.5x, 0.75x, 1.0x, 1.25x, 1.5x, 2.0x).
  Future<void> setPlaybackRate(double rate) async {
    final clamped = rate.clamp(0.25, 3.0);
    await _smartEngine.setPlaybackRate(clamped);
    state = state.copyWith(playbackRate: clamped);
  }

  Future<void> setVolume(double volume) async {
    final clamped = volume.clamp(0.0, 1.0);
    if (state.isMuted && clamped > 0.0) {
      await _smartEngine.setMuted(false);
    }
    await _smartEngine.setVolume(clamped);
    state = state.copyWith(volume: clamped, isMuted: clamped == 0.0);
  }

  Future<void> mute(bool muted) async {
    await _smartEngine.setMuted(muted);
    state = state.copyWith(isMuted: muted);
  }

  Future<void> toggleMute() async {
    if (state.isMuted) {
      final restoreVol = state.volume > 0.0 ? state.volume : 1.0;
      await _smartEngine.setMuted(false);
      await _smartEngine.setVolume(restoreVol);
      state = state.copyWith(volume: restoreVol, isMuted: false);
    } else {
      await _smartEngine.setMuted(true);
      state = state.copyWith(isMuted: true);
    }
  }

  void setAspectRatio(int index) {
    state = state.copyWith(aspectRatioIndex: index.clamp(0, 3));
  }

  void cycleAspectRatio() {
    final nextIndex = (state.aspectRatioIndex + 1) % 4; // Fit -> Fill -> 16:9 -> 4:3
    state = state.copyWith(aspectRatioIndex: nextIndex);
  }

  void setLocked(bool locked) {
    state = state.copyWith(isLocked: locked);
  }

  void toggleLock() {
    setLocked(!state.isLocked);
  }

  Future<void> setAudioTrack(PlayerAudioTrack track) async {
    await _smartEngine.setAudioTrack(track);
    state = state.copyWith(currentAudioTrack: track);
  }

  Future<void> setSubtitleTrack(PlayerSubtitleTrack track) async {
    await _smartEngine.setSubtitleTrack(track);
    state = state.copyWith(currentSubtitleTrack: track);
  }

  Future<void> setBufferMode(PlaybackBufferMode mode) async {
    await _smartEngine.setBufferMode(mode);
    state = state.copyWith(bufferMode: mode);
  }

  void setFullscreen(bool fullscreen) {
    if (!mounted) return;
    state = state.copyWith(isFullscreen: fullscreen);
  }

  void setPlayerRouteActive(bool active) {
    if (!mounted) return;
    state = state.copyWith(isPlayerRouteActive: active);
  }

  void toggleFullscreen() {
    setFullscreen(!state.isFullscreen);
  }

  Future<void> retry() async {
    if (state.source != null) {
      await load(state.source!);
    }
  }

  @override
  void dispose() {
    _progressSaveTimer?.cancel();
    _progressSaveTimer = null;
    if (!mounted) return;
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _smartEngine.dispose();
    super.dispose();
  }
}

/// Global provider for the PlayerController.
final playerControllerProvider =
    StateNotifierProvider<PlayerController, PlayerState>((ref) {
  final historyRepo = ref.watch(historyRepositoryProvider);
  return PlayerController(
    historyRepository: historyRepo,
    canLoadSource: (source) async {
      final mode = ref.read(kidsModeProvider);
      if (!mode.isInitialized) return false;
      if (!mode.isEnabled) return true;
      final allowed = await ref.read(kidsAllowedContentProvider.future);
      return allowed.allowsSource(source);
    },
  );
});
