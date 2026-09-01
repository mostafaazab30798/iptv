import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/data/repositories/auth_repository_impl.dart';

void main() {
  group('parseXtreamExpiry', () {
    test('parses Xtream Unix seconds as UTC', () {
      expect(
        parseXtreamExpiry('1893456000'),
        DateTime.utc(2030, 1, 1),
      );
    });

    test('accepts ISO timestamps', () {
      expect(
        parseXtreamExpiry('2030-01-01T03:00:00+03:00'),
        DateTime.utc(2030, 1, 1),
      );
    });

    test('treats missing and unlimited values as no expiry', () {
      expect(parseXtreamExpiry(null), isNull);
      expect(parseXtreamExpiry('null'), isNull);
      expect(parseXtreamExpiry('0'), isNull);
    });
  });
}
