import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/sports/channel_mapper.dart';
import 'package:iptv/domain/entities/channel.dart';

Channel _ch(int id, String name) {
  return Channel(id: id, serverId: 1, streamId: id, name: name, categoryId: 1);
}

void main() {
  group('ChannelMapper', () {
    test('extractNetworkInfo handles Arabic and English variations', () {
      final bein1 = ChannelMapper.extractNetworkInfo('بى ان سبورت 1HD');
      expect(bein1.network, 'bein');
      expect(bein1.number, '1');

      final onSport = ChannelMapper.extractNetworkInfo('ON Sport');
      expect(onSport.network, 'ontime');
      expect(onSport.number, '1');

      final ssc5 = ChannelMapper.extractNetworkInfo('اس اس سي 5');
      expect(ssc5.network, 'ssc');
      expect(ssc5.number, '5');
    });

    test(
      'findBestChannel selects highest quality match for scraped channel',
      () {
        final channels = [
          _ch(1, 'beIN Sports 1 SD'),
          _ch(2, 'beIN Sports 1 HD'),
          _ch(3, 'beIN Sports 1 FHD'),
          _ch(4, 'beIN Sports 1 4K'),
          _ch(5, 'beIN Sports 2 HD'),
          _ch(6, 'ON Time Sports 1 HD'),
        ];

        final best = ChannelMapper.findBestChannel('بى ان سبورت 1HD', channels);
        expect(best, isNotNull);
        expect(best!.streamId, 4); // 4K has highest quality
        expect(best.name, contains('beIN Sports 1 4K'));
      },
    );

    test('findBestChannel matches ON Sport to ON Time Sports 1', () {
      final channels = [
        _ch(10, 'ON Time Sports 2 HD'),
        _ch(11, 'ON Time Sports 1 FHD'),
        _ch(12, 'ON Time Sports 1 HD'),
      ];

      final best = ChannelMapper.findBestChannel('ON Sport', channels);
      expect(best, isNotNull);
      expect(best!.streamId, 11); // FHD over HD
    });

    test('regular beIN does not resolve to a French regional channel', () {
      final channels = [
        _ch(20, 'beIN Sports FR 1 4K'),
        _ch(21, 'beIN Sports 1 HD'),
      ];

      final regular = ChannelMapper.findBestChannel('beIN Sports 1', channels);
      final french = ChannelMapper.findBestChannel(
        'beIN Sports France 1',
        channels,
      );

      expect(regular?.streamId, 21);
      expect(french?.streamId, 20);
    });

    test('beIN Sports 1 never resolves to beIN Series 1, Movies 1, or Drama 1', () {
      final channels = [
        _ch(30, 'beIN Series 1 4K'),
        _ch(31, 'beIN Movies 1 4K'),
        _ch(32, 'beIN Drama 1 FHD'),
        _ch(33, 'beIN Box Office 1 FHD'),
        _ch(34, 'beIN Gourmet 1 FHD'),
        _ch(35, 'beIN Sports 1 HD'),
      ];

      final best = ChannelMapper.findBestChannel('بى ان سبورت 1HD', channels);
      expect(best, isNotNull);
      expect(best!.streamId, 35);
      expect(best.name, 'beIN Sports 1 HD');
    });

    test('beIN Sports 1 does not mismatch with Max 1, Xtra 1, English 1, or AFC 1', () {
      final channels = [
        _ch(40, 'beIN Sports 1 Max 4K'),
        _ch(41, 'beIN Sports 1 Xtra 4K'),
        _ch(42, 'beIN Sports 1 English 4K'),
        _ch(43, 'beIN Sports 1 AFC 4K'),
        _ch(44, 'beIN Sports 1 HD'),
      ];

      expect(
        ChannelMapper.findBestChannel('beIN Sports 1', channels)?.streamId,
        44,
      );
      expect(
        ChannelMapper.findBestChannel('beIN Sports 1 Max', channels)?.streamId,
        40,
      );
      expect(
        ChannelMapper.findBestChannel('beIN Sports 1 Xtra', channels)?.streamId,
        41,
      );
      expect(
        ChannelMapper.findBestChannel('beIN Sports 1 English', channels)?.streamId,
        42,
      );
      expect(
        ChannelMapper.findBestChannel('beIN Sports 1 AFC', channels)?.streamId,
        43,
      );
    });

    test('handles attached digits and codec tags like BEIN1, MAX1, 1080p, H265', () {
      final channels = [
        _ch(50, 'AR | BEIN1 1080p H265'),
        _ch(51, 'AR | BEIN SPORTS MAX1 FHD'),
        _ch(52, 'AR | SSC1 HD'),
      ];

      expect(
        ChannelMapper.findBestChannel('بى ان سبورت 1HD', channels)?.streamId,
        50,
      );
      expect(
        ChannelMapper.findBestChannel('بي ان سبورت ماكس 1', channels)?.streamId,
        51,
      );
      expect(
        ChannelMapper.findBestChannel('SSC 1', channels)?.streamId,
        52,
      );
    });

    test('findBestChannel returns null for Not Available', () {
      final channels = [_ch(1, 'beIN Sports 1 HD')];
      expect(ChannelMapper.findBestChannel('Not Available', channels), isNull);
      expect(ChannelMapper.findBestChannel('', channels), isNull);
    });
  });
}
