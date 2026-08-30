import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Tracks last trusted server time so device clock rollback cannot extend access.
class TrustedTimeService {
  TrustedTimeService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              wOptions: WindowsOptions(),
              webOptions: WebOptions(dbName: 'hope_tv_time_vault'),
            );

  final FlutterSecureStorage _storage;
  static const _keyLastTrusted = 'hope_tv_last_trusted_server_time_ms';
  static const _keyMonoAtTrust = 'hope_tv_mono_at_trust_ms';

  int? _lastTrustedMs;
  int? _monoAtTrustMs;

  Future<void> observeServerTime(DateTime serverTimeUtc) async {
    final serverMs = serverTimeUtc.toUtc().millisecondsSinceEpoch;
    final mono = DateTime.now().millisecondsSinceEpoch;
    _lastTrustedMs = serverMs;
    _monoAtTrustMs = mono;
    await _storage.write(key: _keyLastTrusted, value: '$serverMs');
    await _storage.write(key: _keyMonoAtTrust, value: '$mono');
  }

  Future<void> _ensureLoaded() async {
    if (_lastTrustedMs != null) return;
    final trusted = await _storage.read(key: _keyLastTrusted);
    final mono = await _storage.read(key: _keyMonoAtTrust);
    _lastTrustedMs = int.tryParse(trusted ?? '');
    _monoAtTrustMs = int.tryParse(mono ?? '');
  }

  /// Best-effort trusted "now". Never earlier than last trusted server time.
  Future<DateTime> nowUtc() async {
    await _ensureLoaded();
    final wall = DateTime.now().toUtc();
    if (_lastTrustedMs == null || _monoAtTrustMs == null) {
      return wall;
    }

    final elapsed = DateTime.now().millisecondsSinceEpoch - _monoAtTrustMs!;
    final estimated = DateTime.fromMillisecondsSinceEpoch(
      _lastTrustedMs! + (elapsed < 0 ? 0 : elapsed),
      isUtc: true,
    );

    // Device clock moving backward must not extend entitlement.
    if (wall.isBefore(estimated)) {
      return estimated;
    }
    // Prefer the later of wall and estimated only when wall does not go backward
    // relative to last trusted server observation.
    if (wall.millisecondsSinceEpoch < _lastTrustedMs!) {
      return estimated;
    }
    return wall.isAfter(estimated) ? wall : estimated;
  }

  Future<void> clear() async {
    _lastTrustedMs = null;
    _monoAtTrustMs = null;
    await _storage.delete(key: _keyLastTrusted);
    await _storage.delete(key: _keyMonoAtTrust);
  }
}
