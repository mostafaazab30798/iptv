import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/domain/services/stream_url_builder.dart';

void main() {
  group('StreamUrlBuilder.catchUp', () {
    const builder = StreamUrlBuilder();

    test('builds an Xtream timeshift URL in UTC', () {
      final url = builder.catchUp(
        serverUrl: 'https://panel.example.com/',
        username: 'viewer',
        password: 'secret',
        streamId: 42,
        start: DateTime.parse('2026-09-26T20:30:00+02:00'),
        duration: const Duration(minutes: 47, seconds: 1),
      );

      expect(
        url,
        'https://panel.example.com/timeshift/viewer/secret/48/'
        '2026-09-26:18-30/42.ts',
      );
    });

    test('keeps the duration within provider-safe bounds', () {
      final start = DateTime.utc(2026, 9, 26);

      expect(
        builder.catchUp(
          serverUrl: 'https://panel.example.com',
          username: 'u',
          password: 'p',
          streamId: 1,
          start: start,
          duration: Duration.zero,
        ),
        contains('/1/2026-09-26:00-00/1.ts'),
      );
      expect(
        builder.catchUp(
          serverUrl: 'https://panel.example.com',
          username: 'u',
          password: 'p',
          streamId: 1,
          start: start,
          duration: const Duration(days: 2),
        ),
        contains('/1440/2026-09-26:00-00/1.ts'),
      );
    });
  });
}
