import 'package:shared_preferences/shared_preferences.dart';

/// Local update UX preferences (skip optional build, check cache timestamp).
class UpdatePreferences {
  UpdatePreferences({SharedPreferences? preferences})
    : _preferencesFuture = preferences != null
          ? Future.value(preferences)
          : SharedPreferences.getInstance();

  final Future<SharedPreferences> _preferencesFuture;

  static const _skippedBuildKey = 'update_skipped_build_number';
  static const _lastCheckMsKey = 'update_last_check_ms';
  static const _cachedMandatoryManifestKey = 'update_cached_mandatory_manifest';

  Future<int?> skippedBuildNumber() async {
    final prefs = await _preferencesFuture;
    final value = prefs.getInt(_skippedBuildKey);
    return value;
  }

  Future<void> setSkippedBuildNumber(int buildNumber) async {
    final prefs = await _preferencesFuture;
    await prefs.setInt(_skippedBuildKey, buildNumber);
  }

  Future<DateTime?> lastCheckAt() async {
    final prefs = await _preferencesFuture;
    final ms = prefs.getInt(_lastCheckMsKey);
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
  }

  Future<void> setLastCheckAt(DateTime when) async {
    final prefs = await _preferencesFuture;
    await prefs.setInt(_lastCheckMsKey, when.millisecondsSinceEpoch);
  }

  Future<String?> cachedMandatoryManifestJson() async {
    final prefs = await _preferencesFuture;
    return prefs.getString(_cachedMandatoryManifestKey);
  }

  Future<void> setCachedMandatoryManifestJson(String? json) async {
    final prefs = await _preferencesFuture;
    if (json == null || json.isEmpty) {
      await prefs.remove(_cachedMandatoryManifestKey);
      return;
    }
    await prefs.setString(_cachedMandatoryManifestKey, json);
  }
}
