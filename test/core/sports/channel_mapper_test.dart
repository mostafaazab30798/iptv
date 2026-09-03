import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/sports/channel_mapper.dart';
import 'package:iptv/domain/entities/channel.dart';

Channel _ch(int id, String name) {
  return Channel(
    id: id,
    serverId: 1,
    streamId: id,
    name: name,
    categoryId: 1,
  );
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

    test('findBestChannel selects highest quality match for scraped channel', () {
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
    });

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

    test('findBestChannel returns null for Not Available', () {
      final channels = [_ch(1, 'beIN Sports 1 HD')];
      expect(ChannelMapper.findBestChannel('Not Available', channels), isNull);
      expect(ChannelMapper.findBestChannel('', channels), isNull);
    });
  });
}
