import 'dart:io' show File, Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Best-effort device memory helpers for low-RAM defaults.
abstract final class DeviceMemory {
  static int? _totalRamMb;

  /// Total physical RAM in MiB when detectable (Android/Linux `/proc/meminfo`).
  static int? get totalRamMb {
    _totalRamMb ??= _readTotalRamMb();
    return _totalRamMb;
  }

  /// True when device reports ≤3 GiB RAM, or when we cannot read RAM on Android phones
  /// (conservative default for low-spec handsets).
  static bool get isLowRamDevice {
    final mb = totalRamMb;
    if (mb != null) return mb <= 3072;
    if (kIsWeb) return false;
    try {
      return Platform.isAndroid;
    } catch (_) {
      return false;
    }
  }

  static int? _readTotalRamMb() {
    if (kIsWeb) return null;
    try {
      if (!Platform.isAndroid && !Platform.isLinux) return null;
      final lines = File('/proc/meminfo').readAsLinesSync();
      for (final line in lines) {
        if (!line.startsWith('MemTotal:')) continue;
        final parts = line.split(RegExp(r'\s+'));
        if (parts.length < 2) return null;
        final kb = int.tryParse(parts[1]);
        if (kb == null) return null;
        return kb ~/ 1024;
      }
    } catch (_) {}
    return null;
  }
}
