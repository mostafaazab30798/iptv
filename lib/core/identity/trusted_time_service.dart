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

    final wallMs = wall.millisecondsSinceEpoch;
    final elapsed = wallMs - _monoAtTrustMs!;

    // If the device clock was rolled back prior to our reference timestamp,
    // advance the reference baseline and re-anchor so future ticks still advance.
    if (elapsed < 0) {
      _monoAtTrustMs = wallMs;
      await _storage.write(key: _keyMonoAtTrust, value: '$wallMs');
    }

    final safeElapsed = elapsed < 0 ? 0 : elapsed;
    final estimated = DateTime.fromMillisecondsSinceEpoch(
      _lastTrustedMs! + safeElapsed,
      isUtc: true,
    );
    if (safeElapsed > 0) {
      _lastTrustedMs = estimated.millisecondsSinceEpoch;
      _monoAtTrustMs = wallMs;
    }

    // Device clock moving backward must not extend entitlement.
    if (wall.isBefore(estimated)) {
      return estimated;
    }
    if (wallMs < _lastTrustedMs!) {
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
