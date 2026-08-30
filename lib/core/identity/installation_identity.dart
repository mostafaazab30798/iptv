import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:iptv/core/logging/app_logger.dart';
import 'package:iptv/core/platform/platform_service.dart';
import 'package:uuid/uuid.dart';

/// Random installation identity for this app install (not a person fingerprint).
class InstallationIdentity {
  InstallationIdentity({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              wOptions: WindowsOptions(),
              webOptions: WebOptions(dbName: 'hope_tv_identity_vault'),
            );

  final FlutterSecureStorage _storage;
  static const _keyInstallationId = 'hope_tv_installation_id';
  static const _uuid = Uuid();

  String? _cachedId;
  String? _cachedHash;

  Future<String> getInstallationId() async {
    if (_cachedId != null) return _cachedId!;

    try {
      final existing = await _storage.read(key: _keyInstallationId);
      if (existing != null && existing.isNotEmpty) {
        _cachedId = existing;
        return existing;
      }
    } catch (e) {
      AppLogger.error('Failed reading installation id: $e', feature: 'identity');
    }

    final created = _uuid.v4();
    try {
      await _storage.write(key: _keyInstallationId, value: created);
    } catch (e) {
      AppLogger.error('Failed persisting installation id: $e', feature: 'identity');
    }
    _cachedId = created;
    return created;
  }

  Future<String> getInstallationIdHash() async {
    if (_cachedHash != null) return _cachedHash!;
    final id = await getInstallationId();
    _cachedHash = sha256.convert(utf8.encode(id)).toString();
    return _cachedHash!;
  }

  String platformCode() {
    final p = PlatformService.instance;
    if (p.isAndroid || p.isAndroidTv) return 'android';
    if (p.isWindows) return 'windows';
    if (p.isWeb) return 'web';
    return 'unknown';
  }
}
