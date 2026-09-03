import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/player/application/player_controller.dart';
import 'package:iptv/player/domain/entities/player_source.dart';
import 'package:iptv/player/handoff/application/audio_handoff_server_controller.dart';
import 'package:iptv/player/handoff/application/companion_sync_engine.dart';
import 'package:iptv/player/handoff/domain/audio_handoff_models.dart';
import 'package:iptv/player/infrastructure/fake_player_engine.dart';

void main() {
  group('Audio Handoff Domain Models', () {
    test('HandoffSessionInfo encodes and decodes QR payload cleanly', () {
      final source = PlayerSource.live(
        url: 'http://example.com/live/stream.m3u8',
        title: 'Sports HD',
        channelId: 101,
        categoryId: 5,
        logoUrl: 'http://example.com/logo.png',
        currentProgramTitle: 'Championship Match',
      );

      final session = HandoffSessionInfo(
        hostIp: '192.168.1.55',
        port: 8998,
        sessionToken: 'test_token_abc123',
        pinCode: '7842',
        source: source,
        serverDeviceName: 'Living Room TV',
      );

      final qrString = session.toQrPayload();
      expect(qrString, startsWith('http://192.168.1.55:8998/'));
      expect(qrString, contains('tok=test_token_abc123'));
      expect(qrString, contains('pin=7842'));

      // 1. Decode from HTTP URL
      final decodedFromUrl = HandoffSessionInfo.fromQrPayload(qrString);
      expect(decodedFromUrl, isNotNull);
      expect(decodedFromUrl!.hostIp, '192.168.1.55');
      expect(decodedFromUrl.port, 8998);
      expect(decodedFromUrl.sessionToken, 'test_token_abc123');
      expect(decodedFromUrl.pinCode, '7842');

      // 2. Decode from raw JSON
      const jsonPayload =
          '{"v":1,"ip":"192.168.1.55","p":8998,"tok":"json_tok","pin":"1234","dev":"Living Room TV","src":{"url":"http://test.com/stream.m3u8","title":"Sports HD","prof":"live","st":"auto","hdrs":{},"chId":101,"catId":5,"prog":"Championship Match"}}';
      final decodedFromJson = HandoffSessionInfo.fromQrPayload(jsonPayload);
      expect(decodedFromJson, isNotNull);
      expect(decodedFromJson!.hostIp, '192.168.1.55');
      expect(decodedFromJson.port, 8998);
      expect(decodedFromJson.sessionToken, 'json_tok');
      expect(decodedFromJson.pinCode, '1234');
      expect(decodedFromJson.source.url, 'http://test.com/stream.m3u8');
      expect(decodedFromJson.source.title, 'Sports HD');
      expect(decodedFromJson.source.channelId, 101);
      expect(decodedFromJson.source.currentProgramTitle, 'Championship Match');
    });

    test('HandoffSyncPacket encodes and decodes JSON correctly', () {
      const packet = HandoffSyncPacket(
        serverTimestampMs: 1700000000,
        positionMs: 45000,
        durationMs: 3600000,
        isPlaying: true,
        isBuffering: false,
        streamUrl: 'http://test.m3u8',
        title: 'Channel 1',
        channelId: 42,
        isLive: true,
      );

      final json = packet.toJson();
      final fromJson = HandoffSyncPacket.fromJson(json);

      expect(fromJson.serverTimestampMs, 1700000000);
      expect(fromJson.positionMs, 45000);
      expect(fromJson.durationMs, 3600000);
      expect(fromJson.isPlaying, isTrue);
      expect(fromJson.isBuffering, isFalse);
      expect(fromJson.title, 'Channel 1');
      expect(fromJson.channelId, 42);
      expect(fromJson.isLive, isTrue);
    });

    test('HandoffCommand serializes action and payload correctly', () {
      const command = HandoffCommand(
        action: HandoffCommand.actionMuteTv,
        payload: {'reason': 'phone_listening'},
      );

      final json = command.toJson();
      final fromJson = HandoffCommand.fromJson(json);

      expect(fromJson.action, HandoffCommand.actionMuteTv);
      expect(fromJson.payload['reason'], 'phone_listening');
    });

    test('HandoffCommand mouse & keyboard factories serialize properly', () {
      final moveCmd = HandoffCommand.mouseMove(dx: 15.5, dy: -8.0);
      expect(moveCmd.action, HandoffCommand.actionMouseMove);
      expect(moveCmd.payload['dx'], 15.5);
      expect(moveCmd.payload['dy'], -8.0);

      final tapCmd = HandoffCommand.mouseTap(button: 'left');
      expect(tapCmd.action, HandoffCommand.actionMouseTap);
      expect(tapCmd.payload['button'], 'left');

      final clickCmd = HandoffCommand.mouseClick(button: 'right', down: true);
      expect(clickCmd.action, HandoffCommand.actionMouseClick);
      expect(clickCmd.payload['button'], 'right');
      expect(clickCmd.payload['down'], isTrue);

      final scrollCmd = HandoffCommand.mouseScroll(dx: 0.0, dy: -25.0);
      expect(scrollCmd.action, HandoffCommand.actionMouseScroll);
      expect(scrollCmd.payload['dy'], -25.0);

      final keyCmd = HandoffCommand.keyPress('enter');
      expect(keyCmd.action, HandoffCommand.actionKeyPress);
      expect(keyCmd.payload['key'], 'enter');

      final typeCmd = HandoffCommand.typeText('BBC News', replace: false);
      expect(typeCmd.action, HandoffCommand.actionTypeText);
      expect(typeCmd.payload['text'], 'BBC News');
      expect(typeCmd.payload['replace'], isFalse);

      final fromJson = HandoffCommand.fromJson(typeCmd.toJson());
      expect(fromJson.action, HandoffCommand.actionTypeText);
      expect(fromJson.payload['text'], 'BBC News');
    });
  });


  group('CompanionSyncEngine', () {
    test('Drift within 100ms tolerance does not trigger seek', () async {
      int seekCount = 0;
      final engine = CompanionSyncEngine(
        microSeekThresholdMs: 100,
        onSeek: (pos) async {
          seekCount++;
        },
        onAdjustRate: (rate) async {},
      );

      // TV at 10000ms, phone at 9950ms (50ms drift)
      const packet = HandoffSyncPacket(
        serverTimestampMs: 1000,
        positionMs: 10000,
        durationMs: 100000,
        isPlaying: true,
        isBuffering: false,
      );

      await engine.processSyncTick(
        packet: packet,
        localPhonePosition: const Duration(milliseconds: 9950),
        estimatedRttMs: 20, // 10ms one-way delay -> target = 10010ms, drift ~60ms
        isPhonePlaying: true,
      );

      expect(seekCount, 0);
      expect(engine.isInSync, isTrue);
    });

    test('Drift exceeding 100ms triggers micro-seek to target position', () async {
      Duration? soughtPosition;
      final engine = CompanionSyncEngine(
        microSeekThresholdMs: 100,
        onSeek: (pos) async {
          soughtPosition = pos;
        },
        onAdjustRate: (rate) async {},
      );

      // TV at 10000ms, phone lagging at 9600ms (~400ms drift)
      const packet = HandoffSyncPacket(
        serverTimestampMs: 1000,
        positionMs: 10000,
        durationMs: 100000,
        isPlaying: true,
        isBuffering: false,
      );

      await engine.processSyncTick(
        packet: packet,
        localPhonePosition: const Duration(milliseconds: 9600),
        estimatedRttMs: 20,
        isPhonePlaying: true,
      );

      expect(soughtPosition, isNotNull);
      // Target position should be around 10010ms (10000 + 10ms network delay)
      expect(soughtPosition!.inMilliseconds, 10010);
    });

    test('Bluetooth latency offset adjusts target playback position', () async {
      Duration? soughtPosition;
      final engine = CompanionSyncEngine(
        microSeekThresholdMs: 100,
        onSeek: (pos) async {
          soughtPosition = pos;
        },
        onAdjustRate: (rate) async {},
      );

      // Add +150ms Bluetooth headphone hardware delay compensation
      engine.setBluetoothOffset(150);
      expect(engine.bluetoothOffsetMs, 150);

      const packet = HandoffSyncPacket(
        serverTimestampMs: 1000,
        positionMs: 20000,
        durationMs: 100000,
        isPlaying: true,
        isBuffering: false,
      );

      await engine.processSyncTick(
        packet: packet,
        localPhonePosition: const Duration(milliseconds: 19000), // 1000ms lag
        estimatedRttMs: 20,
        isPhonePlaying: true,
      );

      expect(soughtPosition, isNotNull);
      // Target = 20000 (TV) + 10 (network RTT/2) + 150 (Bluetooth offset) = 20160ms
      expect(soughtPosition!.inMilliseconds, 20160);
    });

    test('Live streams never seek even with large timeline drift', () async {
      var seekCount = 0;
      final engine = CompanionSyncEngine(
        microSeekThresholdMs: 100,
        onSeek: (_) async {
          seekCount++;
        },
        onAdjustRate: (_) async {},
      );
      engine.setIsLive(true);

      const packet = HandoffSyncPacket(
        serverTimestampMs: 1000,
        positionMs: 120000,
        durationMs: 0,
        isPlaying: true,
        isBuffering: false,
        isLive: true,
      );

      await engine.processSyncTick(
        packet: packet,
        localPhonePosition: Duration.zero,
        estimatedRttMs: 40,
        isPhonePlaying: true,
      );

      expect(seekCount, 0);
      expect(engine.isInSync, isTrue);
    });

    test('Unbounded VOD (duration 0) does not seek', () async {
      var seekCount = 0;
      final engine = CompanionSyncEngine(
        microSeekThresholdMs: 100,
        onSeek: (_) async {
          seekCount++;
        },
        onAdjustRate: (_) async {},
      );

      const packet = HandoffSyncPacket(
        serverTimestampMs: 1000,
        positionMs: 8000,
        durationMs: 0,
        isPlaying: true,
        isBuffering: false,
      );

      await engine.processSyncTick(
        packet: packet,
        localPhonePosition: Duration.zero,
        estimatedRttMs: 20,
        isPhonePlaying: true,
      );

      expect(seekCount, 0);
    });
  });

  group('AudioHandoffServerController TV mute', () {
    test('muteTvAudio silences the bound player and unmute restores volume',
        () async {
      final fakeEngine = FakePlayerEngine();
      final player = PlayerController(engine: fakeEngine);
      addTearDown(player.dispose);

      await player.setVolume(0.6);
      expect(player.state.volume, 0.6);

      final controller = AudioHandoffServerController();
      addTearDown(controller.dispose);
      controller.bindPlayback(player);

      await controller.muteTvAudio(player);
      expect(controller.state.isTvMuted, isTrue);
      expect(player.state.volume, 0.0);
      expect(fakeEngine.volume, 0.0);

      await controller.unmuteTvAudio(player);
      expect(controller.state.isTvMuted, isFalse);
      expect(player.state.volume, closeTo(0.6, 0.01));
      expect(fakeEngine.volume, closeTo(0.6, 0.01));
    });

    test('load notifies onSourceChanged so the TV host can bind playback',
        () async {
      final fakeEngine = FakePlayerEngine();
      PlayerSource? boundSource;
      final player = PlayerController(
        engine: fakeEngine,
        onSourceChanged: (source) {
          boundSource = source;
        },
      );
      addTearDown(player.dispose);

      final source = PlayerSource.live(
        url: 'http://example.com/live.ts',
        title: 'News',
        channelId: 7,
      );
      await player.load(source);

      expect(boundSource, isNotNull);
      expect(boundSource!.url, 'http://example.com/live.ts');
      expect(boundSource!.title, 'News');
    });
  });
}
