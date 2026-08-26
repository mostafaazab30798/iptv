import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:iptv/player/domain/entities/device_decode_profile.dart';
import 'package:iptv/player/utils/player_logger.dart';

/// Probes actual hardware decode capability via libmpv at first launch and caches the result.
///
/// Design rationale (§8.1):
/// - We do NOT call platform-native APIs (MediaCodecList / VideoToolbox / D3D11) because
///   they can lie — devices sometimes report a codec as "supported" but underperform on
///   the real decode path. The libmpv probe tests the actual path.
/// - The probe reads `hwdec-current` from a live mpv player instance shortly after init,
///   which tells us exactly which backend (d3d11va, mediacodec, vaapi, nvdec …) engaged.
///   A value of 'no' means hardware decode is genuinely unavailable.
/// - The result is stored in SharedPreferences keyed by an OS+device fingerprint.
///   It is invalidated automatically if the fingerprint changes (e.g. OS update).
/// - The profile is re-probed if a runtime mismatch is detected (§8.1 step 5).
class DeviceDecodeProber {
  DeviceDecodeProber({SharedPreferences? prefs}) : _prefs = prefs;

  static const _cacheKey = 'player_device_decode_profile_v1';

  // Minimum age before a valid cached profile is re-probed (30 days).
  static const _maxCacheAge = Duration(days: 30);

  SharedPreferences? _prefs;
  DeviceDecodeProfile? _cachedProfile;

  /// The last successfully loaded or probed profile.
  DeviceDecodeProfile? get cachedProfile => _cachedProfile;

  /// Loads a cached profile from SharedPreferences if valid. Returns null if stale or absent.
  Future<DeviceDecodeProfile?> loadCached() async {
    final prefs = await _ensurePrefs();
    if (prefs == null) return null;
    final raw = prefs.getString(_cacheKey);
    if (raw == null) return null;

    try {
      final parts = raw.split('|');
      if (parts.length < 10) return null;

      final probedAt = DateTime.tryParse(parts[0]);
      if (probedAt == null) return null;

      final fingerprint = parts[1];
      final currentFingerprint = await _deviceFingerprint();
      if (fingerprint != currentFingerprint) {
        PlayerLogger.note('[DeviceDecodeProber] Fingerprint changed — cache invalidated.');
        return null;
      }

      if (DateTime.now().difference(probedAt) > _maxCacheAge) {
        PlayerLogger.note('[DeviceDecodeProber] Cache expired (>30 days) — will re-probe.');
        return null;
      }

      _cachedProfile = DeviceDecodeProfile(
        probedAt: probedAt,
        deviceFingerprint: fingerprint,
        canHardwareDecodeAny: parts[2] == '1',
        canHardwareDecodeH264: parts[3] == '1',
        canHardwareDecodeH264High: parts[4] == '1',
        canHardwareDecodeHEVC: parts[5] == '1',
        canHardwareDecodeHEVC10bit: parts[6] == '1',
        activeBackend: parts[7].isEmpty ? null : parts[7],
        probedSuccessfully: parts[8] == '1',
      );
      PlayerLogger.note(
        '[DeviceDecodeProber] Loaded cached profile: backend=${_cachedProfile!.activeBackend}, '
        'h264=${_cachedProfile!.canHardwareDecodeH264}, hevc=${_cachedProfile!.canHardwareDecodeHEVC}',
      );
      return _cachedProfile;
    } catch (e) {
      PlayerLogger.note('[DeviceDecodeProber] Cache parse error: $e');
      return null;
    }
  }

  /// Probes hardware decode capability from the live [hwdecCurrentValue] read from mpv.
  ///
  /// Call this after the engine has been initialized and played for at least 1-2 seconds
  /// so that mpv has had time to negotiate the hardware decode backend.
  ///
  /// [hwdecCurrentValue] = the value of mpv property `hwdec-current` from the telemetry loop.
  Future<DeviceDecodeProfile> probeFromHwdecCurrent(String? hwdecCurrentValue) async {
    final fingerprint = await _deviceFingerprint();
    final backend = hwdecCurrentValue?.trim().toLowerCase();

    final isHwActive = backend != null &&
        backend.isNotEmpty &&
        backend != 'no' &&
        backend != 'auto-safe' &&
        backend != 'disabled';

    // Infer capability tiers from the backend name.
    // Full zero-copy backends (d3d11va, nvdec, mediacodec, vaapi, videotoolbox) generally
    // support H.264 and HEVC. 10-bit HEVC is less universal.
    final isCopyBackend = backend != null && backend.contains('-copy');
    final isFullBackend = isHwActive && !isCopyBackend;

    final profile = DeviceDecodeProfile(
      probedAt: DateTime.now(),
      deviceFingerprint: fingerprint,
      canHardwareDecodeAny: isHwActive,
      canHardwareDecodeH264: isHwActive,
      canHardwareDecodeH264High: isFullBackend, // copy-back backends may struggle at High@L5.1
      canHardwareDecodeHEVC: isFullBackend,
      canHardwareDecodeHEVC10bit: isFullBackend &&
          (backend.contains('d3d11va') ||
              backend.contains('nvdec') ||
              backend.contains('videotoolbox') ||
              backend.contains('vaapi')),
      activeBackend: isHwActive ? hwdecCurrentValue : null,
      probedSuccessfully: true,
    );

    _cachedProfile = profile;
    await _persist(profile);

    PlayerLogger.note(
      '[DeviceDecodeProber] Probe complete: backend=${profile.activeBackend ?? "none (SW)"}, '
      'h264High=${profile.canHardwareDecodeH264High}, hevc=${profile.canHardwareDecodeHEVC}, '
      'hevc10bit=${profile.canHardwareDecodeHEVC10bit}',
    );

    return profile;
  }

  /// Updates the cached profile if the runtime [hwdecCurrentValue] contradicts it.
  ///
  /// Called every few seconds from the telemetry loop when `hwdec-current` is available.
  /// This covers the §8.1 step-5 requirement: "treat the cache as a hint, not permanent truth."
  Future<void> reconcile(String? hwdecCurrentValue) async {
    final current = _cachedProfile;
    if (current == null || hwdecCurrentValue == null) return;

    final hwIsActive = hwdecCurrentValue.trim().toLowerCase() != 'no' &&
        hwdecCurrentValue.trim().toLowerCase() != 'disabled' &&
        hwdecCurrentValue.trim().isNotEmpty;

    // If cache says HW is available but runtime says 'no', re-probe.
    if (current.canHardwareDecodeAny && !hwIsActive) {
      PlayerLogger.note(
        '[DeviceDecodeProber] Runtime hwdec="$hwdecCurrentValue" contradicts cache '
        '(expected HW active). Re-probing.',
      );
      await probeFromHwdecCurrent(hwdecCurrentValue);
    }
  }

  Future<void> _persist(DeviceDecodeProfile profile) async {
    final prefs = await _ensurePrefs();
    if (prefs == null) return;
    final encoded = [
      profile.probedAt.toIso8601String(),
      profile.deviceFingerprint,
      profile.canHardwareDecodeAny ? '1' : '0',
      profile.canHardwareDecodeH264 ? '1' : '0',
      profile.canHardwareDecodeH264High ? '1' : '0',
      profile.canHardwareDecodeHEVC ? '1' : '0',
      profile.canHardwareDecodeHEVC10bit ? '1' : '0',
      profile.activeBackend ?? '',
      profile.probedSuccessfully ? '1' : '0',
      '', // reserved
    ].join('|');
    await prefs.setString(_cacheKey, encoded);
  }

  Future<SharedPreferences?> _ensurePrefs() async {
    if (_prefs != null) return _prefs;
    try {
      _prefs = await SharedPreferences.getInstance();
      return _prefs;
    } catch (_) {
      // SharedPreferences unavailable in test environments without mock setup.
      return null;
    }
  }

  /// Builds a device fingerprint from OS version, platform, and compile mode.
  /// Changes after an OS update, triggering a re-probe.
  static Future<String> _deviceFingerprint() async {
    if (kIsWeb) return 'web';
    try {
      final platform = Platform.operatingSystem;
      final version = Platform.operatingSystemVersion;
      return '$platform:$version:${kReleaseMode ? 'rel' : 'dbg'}';
    } catch (_) {
      return 'unknown';
    }
  }
}
