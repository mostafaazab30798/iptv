import 'package:shared_preferences/shared_preferences.dart';

/// Durable installation-lifetime markers stored in [SharedPreferences].
///
/// These survive app restarts within a single installation. Uninstalling and
/// reinstalling resets them — but the trial reset is prevented server-side
/// by account-identity checks, not by this marker.
class InstallationMarker {
  InstallationMarker({SharedPreferences? prefs}) : _prefs = prefs;

  SharedPreferences? _prefs;

  static const _keyFirstOpenSent = 'hope_tv_first_open_sent_v1';
  static const _keyLastVersion = 'hope_tv_last_version_v1';

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  // ---------------------------------------------------------------------------
  // First-open dedup
  // ---------------------------------------------------------------------------

  /// Returns true if this is the first observed open for this installation.
  /// Writes the marker so subsequent calls return false.
  Future<bool> claimFirstOpen() async {
    await _ensurePrefs();
    final already = _prefs!.getBool(_keyFirstOpenSent) ?? false;
    if (already) return false;
    await _prefs!.setBool(_keyFirstOpenSent, true);
    return true;
  }

  // ---------------------------------------------------------------------------
  // Version-change detection
  // ---------------------------------------------------------------------------

  /// Returns the previous version stored, or null if none.
  /// Writes [currentVersion] so subsequent calls return the current version.
  /// Returns null if there was no change (previous == current).
  Future<String?> claimVersionChange(String currentVersion) async {
    await _ensurePrefs();
    final previous = _prefs!.getString(_keyLastVersion);
    await _prefs!.setString(_keyLastVersion, currentVersion);
    if (previous == null || previous == currentVersion) return null;
    return previous; // caller emits app_updated with previousVersion = this
  }

  // ---------------------------------------------------------------------------
  // Test helpers
  // ---------------------------------------------------------------------------

  /// Resets all markers — for use in tests only.
  Future<void> resetForTesting() async {
    await _ensurePrefs();
    await _prefs!.remove(_keyFirstOpenSent);
    await _prefs!.remove(_keyLastVersion);
  }
}
