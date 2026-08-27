import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/player/application/player_controller.dart';
import 'package:iptv/player/domain/entities/player_source.dart';
import 'package:iptv/player/domain/enums/player_status.dart';
import 'package:iptv/player/infrastructure/fake_player_engine.dart';

/// Lightweight smoke harness for featherweight Live leave/zap/catalog behavior
/// that CI can run without a device. Pair with optional adb RSS checks on device.
void main() {
  test('leave-Live style stop clears source (decoder release contract)', () async {
    final engine = FakePlayerEngine();
    final controller = PlayerController(engine: engine);

    await controller.load(
      PlayerSource.live(
        url: 'http://test.live/ch1.m3u8',
        title: 'Ch 1',
        channelId: 1,
      ),
    );
    expect(controller.state.isPlaying, isTrue);
    expect(engine.currentSource, isNotNull);

    // Mirrors Live browse leave when fullscreen route is not active.
    await controller.stopWhenLeavingLiveRoute();

    expect(controller.state.status, PlayerStatus.stopped);
    expect(controller.state.source, isNull);
    expect(engine.currentStatus, PlayerStatus.stopped);
    expect(engine.currentSource, isNull);

    controller.dispose();
  });

  test('zap neighbor window stays bounded (playlist cache smoke)', () async {
    final engine = FakePlayerEngine();
    final controller = PlayerController(engine: engine);

    final playlist = List.generate(
      200,
      (i) => PlayerSource.live(
        url: 'http://test.live/ch$i.m3u8',
        title: 'Ch $i',
        channelId: i + 1,
      ),
    );

    final sw = Stopwatch()..start();
    controller.setChannelPlaylist(playlist, initialIndex: 0);
    await controller.load(playlist.first);
    for (var i = 0; i < 10; i++) {
      await controller.nextChannel();
    }
    sw.stop();

    expect(controller.state.source?.channelId, 11);
    expect(sw.elapsedMilliseconds, lessThan(2000));
    // ignore: avoid_print
    print('zap_smoke 10_zaps_ms=${sw.elapsedMilliseconds}');

    await controller.stop();
    controller.dispose();
  });
}
