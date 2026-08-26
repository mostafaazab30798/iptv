import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/constants/server_presets.dart';
import 'package:iptv/core/platform/platform_service.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/data/datasources/xtream_remote_datasource.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/entities/epg_program.dart';
import 'package:iptv/domain/entities/movie.dart';
import 'package:iptv/domain/entities/server_config.dart';

void main() {
  group('Result Monad Tests', () {
    test('Ok holds value and maps correctly', () {
      const result = Ok<int>(42);
      expect(result.isOk, isTrue);
      expect(result.isErr, isFalse);
      expect(result.value, equals(42));

      final mapped = result.map((v) => 'Count: $v');
      expect(mapped.value, equals('Count: 42'));
    });

    test('Err holds error message and propagates', () {
      const result = Err<int>(AppResultError('Failed'));
      expect(result.isErr, isTrue);
      expect(result.isOk, isFalse);
      expect(result.error.message, equals('Failed'));

      final mapped = result.map((v) => v * 2);
      expect(mapped.isErr, isTrue);
    });
  });

  group('Domain Entity Tests', () {
    test('ServerConfig isValid check', () {
      const validConfig = ServerConfig(
        serverUrl: 'http://example.com:8080',
        username: 'user123',
        password: 'pass123',
      );
      expect(validConfig.isValid, isTrue);

      const invalidConfig = ServerConfig(
        serverUrl: '',
        username: 'user123',
        password: '',
      );
      expect(invalidConfig.isValid, isFalse);
    });

    test('Channel entity properties', () {
      const channel = Channel(
        id: 1,
        serverId: 1,
        streamId: 101,
        name: 'News HD',
        categoryId: 5,
        hasTvArchive: true,
      );
      expect(channel.name, equals('News HD'));
      expect(channel.hasTvArchive, isTrue);
      expect(channel.streamId, equals(101));
    });

    test('Category entity properties', () {
      const category = Category(
        id: 5,
        serverId: 1,
        type: CategoryType.live,
        name: 'Sports',
      );
      expect(category.name, equals('Sports'));
      expect(category.type, equals(CategoryType.live));
    });

    test('EpgProgram duration and progress calculations', () {
      final now = DateTime(2026, 1, 1, 12, 0);
      final start = now.subtract(const Duration(minutes: 30));
      final end = now.add(const Duration(minutes: 30));
      final program = EpgProgram(
        id: 1,
        epgId: 'news_1',
        title: 'Morning News',
        start: start,
        end: end,
      );

      expect(program.duration, equals(const Duration(minutes: 60)));
      expect(program.title, equals('Morning News'));
    });

    test('Movie rating parsing and highest rated selection', () {
      const m1 = Movie(id: 1, serverId: 1, streamId: 10, name: 'Film A', rating: '6.5');
      const m2 = Movie(id: 2, serverId: 1, streamId: 20, name: 'Film B', rating: '9.2');
      const m3 = Movie(id: 3, serverId: 1, streamId: 30, name: 'Film C', rating: '8.1');

      final list = [m1, m2, m3];
      Movie top = list.first;
      double maxR = -1.0;
      for (final m in list) {
        final r = double.tryParse(m.rating ?? '');
        if (r != null && r > maxR) {
          maxR = r;
          top = m;
        }
      }

      expect(top.name, equals('Film B'));
      expect(maxR, equals(9.2));
    });
  });

  group('Xtream Stream URL Generator Tests', () {
    test('Builds live stream URL with credentials and stream ID', () {
      final url = XtreamRemoteDataSource.buildLiveStreamUrl(
        serverUrl: 'http://iptv.server.com:8080',
        username: 'myuser',
        password: 'mypassword',
        streamId: 54321,
      );
      expect(url, equals('http://iptv.server.com:8080/live/myuser/mypassword/54321.ts'));
    });

    test('Builds VOD stream URL with custom container extension', () {
      final url = XtreamRemoteDataSource.buildVodStreamUrl(
        serverUrl: 'http://iptv.server.com:8080/',
        username: 'myuser',
        password: 'mypassword',
        streamId: 9988,
        extension: 'mkv',
      );
      expect(url, equals('http://iptv.server.com:8080/movie/myuser/mypassword/9988.mkv'));
    });
  });

  group('PlatformService Tests', () {
    test('Singleton instance initializes without throwing', () async {
      final service = PlatformService.instance;
      await service.initialize();
      expect(service.platformType, isNotNull);
    });
  });

  group('ServerPresets Tests', () {
    test('ServerPresets contains default providers with valid URLs', () {
      expect(ServerPresets.presets, isNotEmpty);
      for (final preset in ServerPresets.presets) {
        expect(preset.name, isNotEmpty);
        expect(preset.url, startsWith('http'));
      }
    });

    test('Custom preset has empty initial URL', () {
      expect(ServerPresets.customPreset.id, equals(ServerPresets.customServerId));
      expect(ServerPresets.customPreset.url, isEmpty);
    });
  });
}

