import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/logos/logo_resolver.dart';
import 'package:iptv/domain/entities/channel.dart';

void main() {
  group('LogoResolver', () {
    test('Resolves known beIN channels to bundled local assets', () {
      const channel = Channel(
        id: 1,
        serverId: 1,
        streamId: 101,
        name: 'beIN Sports 1 HD',
        streamIcon: 'http://blocked-iptv-server.com/logos/bein1.png',
      );

      final result = LogoResolver.resolve(channel);

      expect(result.source, LogoSource.localCatalog);
      expect(result.isLocal, isTrue);
      expect(result.assetPath, 'assets/logos/bein/bein_sports_1.webp');
      expect(result.initials, 'BEIN');
    });

    test('Resolves Arabic beIN channel titles to bundled local assets', () {
      const channel = Channel(
        id: 2,
        serverId: 1,
        streamId: 102,
        name: 'بي إن سبورت 2',
        streamIcon: 'http://blocked-iptv-server.com/logos/bein2.png',
      );

      final result = LogoResolver.resolve(channel);

      expect(result.source, LogoSource.localCatalog);
      expect(result.isLocal, isTrue);
      expect(result.assetPath, 'assets/logos/bein/bein_sports_2.webp');
    });

    test('Falls back to provider URL for non-beIN channels with logo', () {
      const channel = Channel(
        id: 3,
        serverId: 1,
        streamId: 201,
        name: 'Sky Sports Football',
        streamIcon: 'https://cdn.example.com/sky_football.png',
      );

      final result = LogoResolver.resolve(channel);

      expect(result.source, LogoSource.provider);
      expect(result.isRemote, isTrue);
      expect(result.remoteUrl, 'https://cdn.example.com/sky_football.png');
      expect(result.initials, 'SSF');
    });

    test('does not assign sports assets to beIN kids channels', () {
      const channel = Channel(
        id: 30,
        serverId: 1,
        streamId: 230,
        name: 'beIN Junior HD',
        streamIcon: 'https://cdn.example.com/bein-junior.png',
      );

      final result = LogoResolver.resolve(channel);

      expect(result.source, LogoSource.provider);
      expect(result.assetPath, isNull);
      expect(result.remoteUrl, 'https://cdn.example.com/bein-junior.png');
    });

    test('Falls back to generic/initials when no local asset and no remote URL', () {
      const channel = Channel(
        id: 4,
        serverId: 1,
        streamId: 301,
        name: 'Discovery Science',
        streamIcon: null,
      );

      final result = LogoResolver.resolve(channel);

      expect(result.source, LogoSource.fallback);
      expect(result.isFallback, isTrue);
      expect(result.initials, 'DS');
    });

    test('Resolve by name directly', () {
      final r1 = LogoResolver.resolveByName('beIN Sports News');
      expect(r1.isLocal, isTrue);
      expect(r1.assetPath, 'assets/logos/bein/bein_sports_news.webp');

      final r2 = LogoResolver.resolveByName('Custom TV', remoteUrl: 'http://custom.com/logo.png');
      expect(r2.isRemote, isTrue);
      expect(r2.remoteUrl, 'http://custom.com/logo.png');

      final r3 = LogoResolver.resolveByName('Unknown Channel');
      expect(r3.isFallback, isTrue);
      expect(r3.initials, 'UC');
    });
  });
}
