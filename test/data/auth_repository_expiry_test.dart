import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/data/repositories/auth_repository_impl.dart';
import 'package:iptv/domain/entities/server_config.dart';

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

  group('ServerConfig expiry', () {
    const credentials = (
      serverUrl: 'https://provider.example',
      username: 'viewer',
      password: 'secret',
    );

    test('expired credentials are not a valid catalog session', () {
      final config = ServerConfig(
        serverUrl: credentials.serverUrl,
        username: credentials.username,
        password: credentials.password,
        expiresAt: DateTime.utc(2000),
      );

      expect(config.hasCredentials, isTrue);
      expect(config.isExpiredAt(DateTime.utc(2030)), isTrue);
      expect(config.isValid, isFalse);
    });

    test('future and unlimited credentials remain valid', () {
      final future = ServerConfig(
        serverUrl: credentials.serverUrl,
        username: credentials.username,
        password: credentials.password,
        expiresAt: DateTime.utc(2999),
      );
      final unlimited = ServerConfig(
        serverUrl: credentials.serverUrl,
        username: credentials.username,
        password: credentials.password,
      );

      expect(future.isExpiredAt(DateTime.utc(2030)), isFalse);
      expect(future.isValid, isTrue);
      expect(unlimited.isExpiredAt(DateTime.utc(2030)), isFalse);
      expect(unlimited.isValid, isTrue);
    });
  });
}
