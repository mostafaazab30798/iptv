import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:iptv/core/platform/platform_io.dart'
    if (dart.library.html) 'package:iptv/core/platform/platform_web.dart'
    as plat;

/// Platform type enumeration.
enum PlatformType {
  android,
  androidTv,
  windows,
  web,
  unknown,
}

/// Centralized platform detection and capability surface.
///
/// Use this instead of scattering [Platform.isX] or [kIsWeb] checks
/// throughout the codebase.
class PlatformService {
  PlatformService._();

  static PlatformService? _instance;

  static PlatformService get instance {
    _instance ??= PlatformService._();
    return _instance!;
  }

  PlatformType _platformType = PlatformType.unknown;
  bool _isTv = false;

  /// Must be called once during bootstrap before [platformType] is accessed.
  Future<void> initialize() async {
    _platformType = _detectPlatform();
    _isTv = await _detectTv();
    if (_isTv && _platformType == PlatformType.android) {
      _platformType = PlatformType.androidTv;
    }
  }

  PlatformType get platformType => _platformType;

  // ---------------------------------------------------------------------------
  // Platform booleans
  // ---------------------------------------------------------------------------

  bool get isAndroid => _platformType == PlatformType.android || _isTv;
  bool get isAndroidTv => _platformType == PlatformType.androidTv;
  bool get isWindows => _platformType == PlatformType.windows;
  bool get isWeb => _platformType == PlatformType.web;
  bool get isTv => _isTv;

  // ---------------------------------------------------------------------------
  // Capability booleans
  // ---------------------------------------------------------------------------

  bool get supportsKeyboard => isWindows || isWeb || isAndroidTv;
  bool get supportsRemote => isAndroidTv;
  bool get supportsHardwareBack => isAndroid;
  bool get supportsFullscreen => isAndroidTv || isWindows || isWeb;
  bool get supportsPip => isAndroid || isWindows;
  bool get supportsNativePlayer => isAndroid || isWindows;
  bool get supportsMouse => isWindows || isWeb;

  // ---------------------------------------------------------------------------
  // Internal helpers
  // ---------------------------------------------------------------------------

  PlatformType _detectPlatform() {
    if (kIsWeb) return PlatformType.web;
    if (plat.isWindows()) return PlatformType.windows;
    if (plat.isAndroid()) return PlatformType.android;
    return PlatformType.unknown;
  }

  Future<bool> _detectTv() async {
    // TV detection via platform channel is deferred to a future phase.
    // Override via a setting or ADB property flag in development.
    return false;
  }
}
