import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists the current commercial device id after registration.
class CurrentDeviceStore {
  CurrentDeviceStore({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              wOptions: WindowsOptions(),
              webOptions: WebOptions(dbName: 'hope_tv_device_vault'),
            );

  final FlutterSecureStorage _storage;
  static const _key = 'hope_tv_current_device_id';

  Future<void> save(String deviceId) => _storage.write(key: _key, value: deviceId);

  Future<String?> read() => _storage.read(key: _key);

  Future<void> clear() => _storage.delete(key: _key);
}
