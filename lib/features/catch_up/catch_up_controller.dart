import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/entities/epg_program.dart';
import 'package:iptv/features/catch_up/data/catch_up_repository.dart';

final catchUpControllerProvider = StateNotifierProvider.autoDispose
    .family<CatchUpController, AsyncValue<List<EpgProgram>>, Channel>((
      ref,
      channel,
    ) {
      final dataSource = ref.watch(xtreamDataSourceProvider);
      final controller = CatchUpController(
        channel: channel,
        repository: dataSource == null ? null : CatchUpRepository(dataSource),
      );
      controller.load();
      return controller;
    });

class CatchUpController extends StateNotifier<AsyncValue<List<EpgProgram>>> {
  CatchUpController({required this.channel, required this.repository})
    : super(const AsyncValue.loading());

  final Channel channel;
  final CatchUpRepository? repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    final repo = repository;
    if (repo == null) {
      state = AsyncValue.error(
        StateError('No active IPTV session'),
        StackTrace.current,
      );
      return;
    }
    state = await AsyncValue.guard(() => repo.getArchivedPrograms(channel));
  }
}
