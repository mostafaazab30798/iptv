import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/entities/epg_program.dart';
import 'package:iptv/domain/repositories/epg_repository.dart';
import 'package:iptv/domain/repositories/live_repository.dart';

class GuideState {
  const GuideState({
    this.channels = const [],
    this.programsByStreamId = const {},
    this.isLoading = false,
    this.error,
  });

  final List<Channel> channels;
  final Map<int, List<EpgProgram>> programsByStreamId;
  final bool isLoading;
  final String? error;

  GuideState copyWith({
    List<Channel>? channels,
    Map<int, List<EpgProgram>>? programsByStreamId,
    bool? isLoading,
    String? error,
  }) {
    return GuideState(
      channels: channels ?? this.channels,
      programsByStreamId: programsByStreamId ?? this.programsByStreamId,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class GuideController extends StateNotifier<GuideState> {
  GuideController(this._liveRepo, this._epgRepo) : super(const GuideState()) {
    loadData();
  }

  final LiveRepository? _liveRepo;
  final EpgRepository? _epgRepo;

  Future<void> loadData() async {
    final liveRepo = _liveRepo;
    final epgRepo = _epgRepo;
    if (liveRepo == null) return;

    state = state.copyWith(isLoading: true);

    try {
      final channelsRes = await liveRepo.getChannels();
      final channels = channelsRes.when(
        ok: (c) => c.take(20).toList(),
        err: (_) => <Channel>[],
      );

      final programsMap = <int, List<EpgProgram>>{};

      if (epgRepo != null && channels.isNotEmpty) {
        // Fetch EPG for the first 10 channels in parallel instead of one at a time.
        // Total time = max of 10 round-trips instead of the sum of 10 round-trips.
        final epgChannels = channels.take(10).toList();
        final futures = epgChannels.map(
          (ch) => epgRepo.getProgramsForChannel(ch.streamId.toString()),
        );
        final results = await Future.wait(futures);

        for (var i = 0; i < epgChannels.length; i++) {
          results[i].when(
            ok: (p) => programsMap[epgChannels[i].streamId] = p,
            err: (_) {},
          );
        }
      }

      state = state.copyWith(
        channels: channels,
        programsByStreamId: programsMap,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final guideControllerProvider =
    StateNotifierProvider<GuideController, GuideState>((ref) {
  // Shares LiveRepositoryImpl static cache — no second full catalog in Guide state
  // (Guide only keeps a small take(20) slice for the grid).
  ref.keepAlive();
  final liveRepo = ref.watch(liveRepositoryProvider);
  final epgRepo = ref.watch(epgRepositoryProvider);
  return GuideController(liveRepo, epgRepo);
});
