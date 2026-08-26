import 'package:equatable/equatable.dart';

/// Immutable record of the device's actual hardware decode capability tiers,
/// determined by a one-time libmpv-based probe on first launch.
///
/// Each field reflects whether the device's hardware video decoder can actually
/// accelerate that codec/profile tier — as observed via `hwdec-current` after
/// attempting a real decode, not from a potentially-lying OS capability query.
class DeviceDecodeProfile extends Equatable {
  const DeviceDecodeProfile({
    required this.probedAt,
    required this.deviceFingerprint,
    this.canHardwareDecodeAny = false,
    this.canHardwareDecodeH264 = false,
    this.canHardwareDecodeH264High = false,
    this.canHardwareDecodeHEVC = false,
    this.canHardwareDecodeHEVC10bit = false,
    this.activeBackend,
    this.probedSuccessfully = false,
  });

  /// Timestamp of the last probe.
  final DateTime probedAt;

  /// Device + OS version fingerprint used to invalidate cached probes after an update.
  final String deviceFingerprint;

  /// Whether any hardware decode backend is available at all.
  final bool canHardwareDecodeAny;

  /// H.264 Baseline / Main / High (up to ~L4.1, 1080p30).
  final bool canHardwareDecodeH264;

  /// H.264 High@L5.1+ (1080p60 / 4K).
  final bool canHardwareDecodeH264High;

  /// HEVC / H.265 Main 8-bit.
  final bool canHardwareDecodeHEVC;

  /// HEVC Main10 / HDR (10-bit, 4K HDR).
  final bool canHardwareDecodeHEVC10bit;

  /// The name of the engaged hardware backend (e.g. 'd3d11va', 'mediacodec', 'vaapi').
  final String? activeBackend;

  /// Whether the probe completed without error. False means the profile is a
  /// conservative fallback (assume software only).
  final bool probedSuccessfully;

  /// Unknown/fallback profile — assumes software decode only.
  static DeviceDecodeProfile unknown(String fingerprint) => DeviceDecodeProfile(
        probedAt: DateTime.now(),
        deviceFingerprint: fingerprint,
        probedSuccessfully: false,
      );

  /// Evaluates whether a stream described by [videoCodec] (e.g. 'h264', 'hevc') and
  /// [is10bit] can be hardware-decoded on this device.
  bool canHardwareDecode({required String videoCodec, bool is10bit = false}) {
    if (!canHardwareDecodeAny) return false;
    final codec = videoCodec.toLowerCase();
    if (codec.contains('hevc') || codec.contains('h265')) {
      return is10bit ? canHardwareDecodeHEVC10bit : canHardwareDecodeHEVC;
    }
    if (codec.contains('h264') || codec.contains('avc')) {
      return canHardwareDecodeH264;
    }
    // Unknown codec — assume hardware can handle it if any backend is active.
    return canHardwareDecodeAny;
  }

  DeviceDecodeProfile copyWith({
    DateTime? probedAt,
    String? deviceFingerprint,
    bool? canHardwareDecodeAny,
    bool? canHardwareDecodeH264,
    bool? canHardwareDecodeH264High,
    bool? canHardwareDecodeHEVC,
    bool? canHardwareDecodeHEVC10bit,
    String? activeBackend,
    bool? probedSuccessfully,
  }) {
    return DeviceDecodeProfile(
      probedAt: probedAt ?? this.probedAt,
      deviceFingerprint: deviceFingerprint ?? this.deviceFingerprint,
      canHardwareDecodeAny: canHardwareDecodeAny ?? this.canHardwareDecodeAny,
      canHardwareDecodeH264: canHardwareDecodeH264 ?? this.canHardwareDecodeH264,
      canHardwareDecodeH264High: canHardwareDecodeH264High ?? this.canHardwareDecodeH264High,
      canHardwareDecodeHEVC: canHardwareDecodeHEVC ?? this.canHardwareDecodeHEVC,
      canHardwareDecodeHEVC10bit: canHardwareDecodeHEVC10bit ?? this.canHardwareDecodeHEVC10bit,
      activeBackend: activeBackend ?? this.activeBackend,
      probedSuccessfully: probedSuccessfully ?? this.probedSuccessfully,
    );
  }

  @override
  List<Object?> get props => [
        probedAt,
        deviceFingerprint,
        canHardwareDecodeAny,
        canHardwareDecodeH264,
        canHardwareDecodeH264High,
        canHardwareDecodeHEVC,
        canHardwareDecodeHEVC10bit,
        activeBackend,
        probedSuccessfully,
      ];
}
