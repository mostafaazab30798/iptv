import 'package:iptv/core/logos/bein/bein_logo_catalog.dart';
import 'package:iptv/core/logos/bein/bein_logo_normalizer.dart';
import 'package:iptv/domain/entities/channel.dart';

/// Origin source of a resolved channel logo.
enum LogoSource {
  /// Logo is bundled locally within the app's verified asset catalog.
  localCatalog,

  /// Logo is provided by the IPTV provider via remote URL.
  provider,

  /// No specific logo available; render fallback placeholder/initials.
  fallback,
}

/// Result of resolving a channel's logo.
class LogoResult {
  const LogoResult({
    required this.source,
    required this.displayName,
    this.assetPath,
    this.remoteUrl,
    this.initials,
  });

  /// The source type of the logo.
  final LogoSource source;

  /// Channel display name.
  final String displayName;

  /// Local Flutter asset path if [source] == [LogoSource.localCatalog].
  final String? assetPath;

  /// Remote URL if [source] == [LogoSource.provider].
  final String? remoteUrl;

  /// Generated 2-4 letter initials for fallback presentation.
  final String? initials;

  /// Whether the logo is bundled locally.
  bool get isLocal => source == LogoSource.localCatalog && assetPath != null;

  /// Whether the logo is a remote network URL.
  bool get isRemote => source == LogoSource.provider && remoteUrl != null;

  /// Whether no logo is available.
  bool get isFallback => source == LogoSource.fallback;

  @override
  String toString() =>
      'LogoResult(source: $source, asset: $assetPath, remote: $remoteUrl, name: $displayName)';
}

/// Isolated logo resolution service.
///
/// Resolves channel logos with strict deterministic precedence:
/// 1. Verified local asset catalog (e.g. beIN Sports)
/// 2. Provider logo URL
/// 3. Initial-based / generic fallback
abstract final class LogoResolver {
  /// Resolve logo for a [Channel] entity.
  static LogoResult resolve(Channel channel) {
    return resolveByName(
      channel.name,
      remoteUrl: channel.streamIcon,
      tvgId: channel.epgChannelId,
      streamId: channel.streamId,
    );
  }

  /// Resolve logo by raw channel name, optional remote URL, and identifiers.
  static LogoResult resolveByName(
    String? name, {
    String? remoteUrl,
    String? tvgId,
    int? streamId,
  }) {
    final cleanName = name?.trim() ?? '';
    final initials = _generateInitials(cleanName);

    // 1. Check local verified catalog
    final localItem = BeinLogoCatalog.resolveByName(cleanName);
    if (localItem != null) {
      return LogoResult(
        source: LogoSource.localCatalog,
        displayName: cleanName,
        assetPath: localItem.assetPath,
        initials: initials,
      );
    }

    // 2. Check provider remote URL
    if (remoteUrl != null && remoteUrl.trim().isNotEmpty) {
      final cleanUrl = remoteUrl.trim();
      return LogoResult(
        source: LogoSource.provider,
        displayName: cleanName,
        remoteUrl: cleanUrl,
        initials: initials,
      );
    }

    // 3. Fallback
    return LogoResult(
      source: LogoSource.fallback,
      displayName: cleanName,
      initials: initials,
    );
  }

  /// Generates clean 1 to 4 letter initials from channel title.
  static String _generateInitials(String name) {
    if (name.isEmpty) return 'TV';

    // Normalize for initial extraction
    final normalized = BeinLogoNormalizer.normalize(name);
    if (normalized != null && normalized.startsWith('bein')) {
      return 'BEIN';
    }

    final words = name
        .replaceAll(RegExp(r'[\[\]\(\)\{\}\-_:\|/\\,\.\+★*#]'), ' ')
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();

    if (words.isEmpty) return 'TV';
    if (words.length == 1) {
      return words.first.substring(0, words.first.length.clamp(1, 4)).toUpperCase();
    }

    final buffer = StringBuffer();
    for (var i = 0; i < words.length && buffer.length < 3; i++) {
      final w = words[i];
      if (w.isNotEmpty) {
        buffer.write(w[0].toUpperCase());
      }
    }

    return buffer.toString();
  }
}
