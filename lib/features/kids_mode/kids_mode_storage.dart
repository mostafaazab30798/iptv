import 'package:iptv/core/storage/secure_storage.dart';

class StoredKidsModeConfig {
  const StoredKidsModeConfig({
    required this.enabled,
    required this.pinSalt,
    required this.pinVerifier,
  });

  final bool enabled;
  final String? pinSalt;
  final String? pinVerifier;

  bool get hasPin =>
      pinSalt != null &&
      pinSalt!.isNotEmpty &&
      pinVerifier != null &&
      pinVerifier!.isNotEmpty;
}

abstract interface class KidsModeStorage {
  Future<StoredKidsModeConfig> load();

  Future<void> savePin({required String salt, required String verifier});

  Future<void> setEnabled(bool enabled);
}

class SecureKidsModeStorage implements KidsModeStorage {
  const SecureKidsModeStorage(this._secureStorage);

  final SecureStorage _secureStorage;

  @override
  Future<StoredKidsModeConfig> load() async {
    final data = await _secureStorage.loadKidsModeConfig();
    return StoredKidsModeConfig(
      enabled: data.enabled,
      pinSalt: data.pinSalt,
      pinVerifier: data.pinVerifier,
    );
  }

  @override
  Future<void> savePin({required String salt, required String verifier}) =>
      _secureStorage.saveKidsModePin(salt: salt, verifier: verifier);

  @override
  Future<void> setEnabled(bool enabled) =>
      _secureStorage.setKidsModeEnabled(enabled);
}
