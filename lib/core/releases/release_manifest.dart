import 'dart:convert';

/// Signed update manifest from the control plane.
class ReleaseManifest {
  const ReleaseManifest({
    required this.schemaVersion,
    required this.platform,
    required this.architecture,
    required this.channel,
    required this.version,
    required this.buildNumber,
    required this.minimumSupportedVersion,
    required this.mandatory,
    required this.fileSize,
    required this.sha256,
    required this.downloadAuthorizationPath,
    required this.publishedAt,
    required this.releaseNotesEn,
    required this.releaseNotesAr,
    required this.keyId,
    required this.signature,
    this.downloadUrl,
  });

  final int schemaVersion;
  final String platform;
  final String architecture;
  final String channel;
  final String version;
  final int buildNumber;
  final String? minimumSupportedVersion;
  final bool mandatory;
  final int? fileSize;
  final String sha256;
  final String downloadAuthorizationPath;
  final String publishedAt;
  final String? releaseNotesEn;
  final String? releaseNotesAr;
  final String keyId;
  final String signature;
  final String? downloadUrl;

  String get directDownloadUrl {
    final direct = downloadUrl;
    if (direct != null && direct.isNotEmpty) {
      return direct;
    }
    final fileName =
        platform == 'windows' ? 'HOPE_IPTV_Setup.exe' : 'HOPE_IPTV.apk';
    return 'https://github.com/mostafaazab30798/iptv/releases/download/v$version-build.$buildNumber/$fileName';
  }

  factory ReleaseManifest.fromJson(Map<String, dynamic> json) {
    return ReleaseManifest(
      schemaVersion: (json['schemaVersion'] as num?)?.toInt() ?? 1,
      platform: json['platform'] as String? ?? 'unknown',
      architecture: json['architecture'] as String? ?? 'universal',
      channel: json['channel'] as String? ?? 'stable',
      version: json['version'] as String? ?? '0.0.0',
      buildNumber: (json['buildNumber'] as num?)?.toInt() ?? 0,
      minimumSupportedVersion: json['minimumSupportedVersion'] as String?,
      mandatory: json['mandatory'] == true,
      fileSize: (json['fileSize'] as num?)?.toInt(),
      sha256: json['sha256'] as String? ?? '',
      downloadAuthorizationPath:
          json['downloadAuthorizationPath'] as String? ??
          '/v1/downloads/authorize',
      publishedAt: json['publishedAt'] as String? ?? '',
      releaseNotesEn: json['releaseNotesEn'] as String?,
      releaseNotesAr: json['releaseNotesAr'] as String?,
      keyId: json['keyId'] as String? ?? '',
      signature: json['signature'] as String? ?? '',
      downloadUrl: json['downloadUrl'] as String? ??
          json['object_key'] as String? ??
          json['objectKey'] as String?,
    );
  }

  Map<String, dynamic> toUnsignedJson() => {
    'schemaVersion': schemaVersion,
    'platform': platform,
    'architecture': architecture,
    'channel': channel,
    'version': version,
    'buildNumber': buildNumber,
    'minimumSupportedVersion': minimumSupportedVersion,
    'mandatory': mandatory,
    'fileSize': fileSize,
    'sha256': sha256,
    'downloadAuthorizationPath': downloadAuthorizationPath,
    'publishedAt': publishedAt,
    'releaseNotesEn': releaseNotesEn,
    'releaseNotesAr': releaseNotesAr,
    'keyId': keyId,
  };

  String canonicalJson() => jsonEncode(_sortKeys(toUnsignedJson()));

  static dynamic _sortKeys(dynamic value) {
    if (value is List) return value.map(_sortKeys).toList();
    if (value is Map) {
      final keys = value.keys.map((k) => '$k').toList()..sort();
      return {for (final k in keys) k: _sortKeys(value[k])};
    }
    return value;
  }
}

class ReleaseCheckResult {
  const ReleaseCheckResult({
    required this.updateAvailable,
    this.releaseId,
    this.manifest,
    this.installedBuildNumber,
    this.unsupportedPlatform = false,
  });

  final bool updateAvailable;
  final String? releaseId;
  final ReleaseManifest? manifest;
  final int? installedBuildNumber;
  final bool unsupportedPlatform;
}

class DownloadAuthorization {
  const DownloadAuthorization({
    required this.downloadUrl,
    required this.expiresAt,
    required this.releaseId,
  });

  final String downloadUrl;
  final DateTime expiresAt;
  final String releaseId;

  factory DownloadAuthorization.fromJson(Map<String, dynamic> json) {
    return DownloadAuthorization(
      downloadUrl: json['downloadUrl'] as String? ?? '',
      expiresAt: DateTime.parse(
        json['expiresAt'] as String? ??
            DateTime.now().toUtc().toIso8601String(),
      ),
      releaseId: json['releaseId'] as String? ?? '',
    );
  }
}
