import 'package:iptv/core/logos/bein/bein_logo_normalizer.dart';

/// Represents a verified local beIN SPORTS logo entry.
class BeinLogoItem {
  const BeinLogoItem({
    required this.key,
    required this.assetPath,
    required this.title,
    this.aliases = const [],
    this.tvgIds = const [],
    this.streamIds = const [],
  });

  final String key;
  final String assetPath;
  final String title;
  final List<String> aliases;
  final List<String> tvgIds;
  final List<int> streamIds;
}

/// In-memory catalog of bundled beIN SPORTS logos.
abstract final class BeinLogoCatalog {
  static const String _assetBase = 'assets/logos/bein';

  static final Map<String, BeinLogoItem> _catalog = {
    'bein_sports': const BeinLogoItem(
      key: 'bein_sports',
      assetPath: '$_assetBase/bein_sports.webp',
      title: 'beIN SPORTS Global',
      aliases: ['bein sports', 'bein sport', 'beinsports'],
    ),
    'bein_sports_1': const BeinLogoItem(
      key: 'bein_sports_1',
      assetPath: '$_assetBase/bein_sports_1.webp',
      title: 'beIN SPORTS 1',
      aliases: ['bein sports 1', 'bein sport 1', 'beinsports 1', 'bein 1'],
    ),
    'bein_sports_2': const BeinLogoItem(
      key: 'bein_sports_2',
      assetPath: '$_assetBase/bein_sports_2.webp',
      title: 'beIN SPORTS 2',
      aliases: ['bein sports 2', 'bein sport 2', 'beinsports 2', 'bein 2'],
    ),
    'bein_sports_3': const BeinLogoItem(
      key: 'bein_sports_3',
      assetPath: '$_assetBase/bein_sports_3.webp',
      title: 'beIN SPORTS 3',
      aliases: ['bein sports 3', 'bein sport 3', 'beinsports 3', 'bein 3'],
    ),
    'bein_sports_4': const BeinLogoItem(
      key: 'bein_sports_4',
      assetPath: '$_assetBase/bein_sports_4.webp',
      title: 'beIN SPORTS 4',
      aliases: ['bein sports 4', 'bein sport 4', 'beinsports 4', 'bein 4'],
    ),
    'bein_sports_5': const BeinLogoItem(
      key: 'bein_sports_5',
      assetPath: '$_assetBase/bein_sports_5.webp',
      title: 'beIN SPORTS 5',
      aliases: ['bein sports 5', 'bein sport 5', 'beinsports 5', 'bein 5'],
    ),
    'bein_sports_6': const BeinLogoItem(
      key: 'bein_sports_6',
      assetPath: '$_assetBase/bein_sports_6.webp',
      title: 'beIN SPORTS 6',
      aliases: ['bein sports 6', 'bein sport 6', 'beinsports 6', 'bein 6'],
    ),
    'bein_sports_7': const BeinLogoItem(
      key: 'bein_sports_7',
      assetPath: '$_assetBase/bein_sports_7.webp',
      title: 'beIN SPORTS 7',
      aliases: ['bein sports 7', 'bein sport 7', 'beinsports 7', 'bein 7'],
    ),
    'bein_sports_8': const BeinLogoItem(
      key: 'bein_sports_8',
      assetPath: '$_assetBase/bein_sports_8.webp',
      title: 'beIN SPORTS 8',
      aliases: ['bein sports 8', 'bein sport 8', 'beinsports 8', 'bein 8'],
    ),
    'bein_sports_9': const BeinLogoItem(
      key: 'bein_sports_9',
      assetPath: '$_assetBase/bein_sports_9.webp',
      title: 'beIN SPORTS 9',
      aliases: ['bein sports 9', 'bein sport 9', 'beinsports 9', 'bein 9'],
    ),
    'bein_sports_4k': const BeinLogoItem(
      key: 'bein_sports_4k',
      assetPath: '$_assetBase/bein_sports_4k.webp',
      title: 'beIN SPORTS 4K',
      aliases: ['bein sports 4k', 'bein 4k', 'beinsports 4k'],
    ),
    'bein_sports_news': const BeinLogoItem(
      key: 'bein_sports_news',
      assetPath: '$_assetBase/bein_sports_news.webp',
      title: 'beIN SPORTS News',
      aliases: ['bein sports news', 'bein news', 'beinsports news', 'bein sports ikhbariya'],
    ),
    'bein_sports_1_premium': const BeinLogoItem(
      key: 'bein_sports_1_premium',
      assetPath: '$_assetBase/bein_sports_1_premium.webp',
      title: 'beIN SPORTS 1 Premium',
      aliases: ['bein sports 1 premium', 'bein 1 premium', 'bein sports premium 1'],
    ),
    'bein_sports_2_premium': const BeinLogoItem(
      key: 'bein_sports_2_premium',
      assetPath: '$_assetBase/bein_sports_2_premium.webp',
      title: 'beIN SPORTS 2 Premium',
      aliases: ['bein sports 2 premium', 'bein 2 premium', 'bein sports premium 2'],
    ),
    'bein_sports_3_premium': const BeinLogoItem(
      key: 'bein_sports_3_premium',
      assetPath: '$_assetBase/bein_sports_3_premium.webp',
      title: 'beIN SPORTS 3 Premium',
      aliases: ['bein sports 3 premium', 'bein 3 premium', 'bein sports premium 3'],
    ),
    'bein_sports_1_max': const BeinLogoItem(
      key: 'bein_sports_1_max',
      assetPath: '$_assetBase/bein_sports_1_max.webp',
      title: 'beIN SPORTS 1 Max',
      aliases: ['bein sports 1 max', 'bein 1 max', 'bein sports max 1'],
    ),
    'bein_sports_2_max': const BeinLogoItem(
      key: 'bein_sports_2_max',
      assetPath: '$_assetBase/bein_sports_2_max.webp',
      title: 'beIN SPORTS 2 Max',
      aliases: ['bein sports 2 max', 'bein 2 max', 'bein sports max 2'],
    ),
    'bein_sports_3_max': const BeinLogoItem(
      key: 'bein_sports_3_max',
      assetPath: '$_assetBase/bein_sports_3_max.webp',
      title: 'beIN SPORTS 3 Max',
      aliases: ['bein sports 3 max', 'bein 3 max', 'bein sports max 3'],
    ),
    'bein_sports_4_max': const BeinLogoItem(
      key: 'bein_sports_4_max',
      assetPath: '$_assetBase/bein_sports_4_max.webp',
      title: 'beIN SPORTS 4 Max',
      aliases: ['bein sports 4 max', 'bein 4 max', 'bein sports max 4'],
    ),
    'bein_sports_5_max': const BeinLogoItem(
      key: 'bein_sports_5_max',
      assetPath: '$_assetBase/bein_sports_5_max.webp',
      title: 'beIN SPORTS 5 Max',
      aliases: ['bein sports 5 max', 'bein 5 max', 'bein sports max 5'],
    ),
    'bein_sports_6_max': const BeinLogoItem(
      key: 'bein_sports_6_max',
      assetPath: '$_assetBase/bein_sports_6_max.webp',
      title: 'beIN SPORTS 6 Max',
      aliases: ['bein sports 6 max', 'bein 6 max', 'bein sports max 6'],
    ),
    'bein_sports_1_xtra': const BeinLogoItem(
      key: 'bein_sports_1_xtra',
      assetPath: '$_assetBase/bein_sports_1_xtra.webp',
      title: 'beIN SPORTS 1 Xtra',
      aliases: ['bein sports 1 xtra', 'bein 1 xtra', 'bein sports xtra 1'],
    ),
    'bein_sports_2_xtra': const BeinLogoItem(
      key: 'bein_sports_2_xtra',
      assetPath: '$_assetBase/bein_sports_2_xtra.webp',
      title: 'beIN SPORTS 2 Xtra',
      aliases: ['bein sports 2 xtra', 'bein 2 xtra', 'bein sports xtra 2'],
    ),
    'bein_sports_1_english': const BeinLogoItem(
      key: 'bein_sports_1_english',
      assetPath: '$_assetBase/bein_sports_1_english.webp',
      title: 'beIN SPORTS 1 English',
      aliases: ['bein sports 1 english', 'bein 1 english', 'bein sports english 1'],
    ),
    'bein_sports_2_english': const BeinLogoItem(
      key: 'bein_sports_2_english',
      assetPath: '$_assetBase/bein_sports_2_english.webp',
      title: 'beIN SPORTS 2 English',
      aliases: ['bein sports 2 english', 'bein 2 english', 'bein sports english 2'],
    ),
    'bein_sports_3_english': const BeinLogoItem(
      key: 'bein_sports_3_english',
      assetPath: '$_assetBase/bein_sports_3_english.webp',
      title: 'beIN SPORTS 3 English',
      aliases: ['bein sports 3 english', 'bein 3 english', 'bein sports english 3'],
    ),
    'bein_sports_1_french': const BeinLogoItem(
      key: 'bein_sports_1_french',
      assetPath: '$_assetBase/bein_sports_1_french.webp',
      title: 'beIN SPORTS 1 French',
      aliases: ['bein sports 1 french', 'bein 1 french', 'bein sports french 1'],
    ),
    'bein_sports_2_french': const BeinLogoItem(
      key: 'bein_sports_2_french',
      assetPath: '$_assetBase/bein_sports_2_french.webp',
      title: 'beIN SPORTS 2 French',
      aliases: ['bein sports 2 french', 'bein 2 french', 'bein sports french 2'],
    ),
    'bein_sports_3_french': const BeinLogoItem(
      key: 'bein_sports_3_french',
      assetPath: '$_assetBase/bein_sports_3_french.webp',
      title: 'beIN SPORTS 3 French',
      aliases: ['bein sports 3 french', 'bein 3 french', 'bein sports french 3'],
    ),
    'bein_sports_nba': const BeinLogoItem(
      key: 'bein_sports_nba',
      assetPath: '$_assetBase/bein_sports_nba.webp',
      title: 'beIN SPORTS NBA',
      aliases: ['bein sports nba', 'bein nba', 'beinsports nba'],
    ),
  };

  /// Lookup an entry by normalized key.
  static BeinLogoItem? getByKey(String? key) {
    if (key == null) return null;
    return _catalog[key];
  }

  /// Resolve a channel name against the catalog.
  static BeinLogoItem? resolveByName(String? name) {
    final key = BeinLogoNormalizer.normalize(name);
    if (key == null) return null;
    return _catalog[key];
  }

  /// All catalog entries.
  static List<BeinLogoItem> get allEntries => _catalog.values.toList();
}
