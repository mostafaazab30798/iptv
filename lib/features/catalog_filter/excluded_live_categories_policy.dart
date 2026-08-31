import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/features/kids_mode/kids_content_policy.dart';

/// Hides non–Middle-East country packages from the live catalog
/// (normal mode and Kids Mode).
class ExcludedLiveCategoriesPolicy {
  const ExcludedLiveCategoriesPolicy();

  /// Country / region tokens from provider package names
  /// (e.g. "FRANCE Tv", "ESPAN BK Tv", "USA Tv |BACK UP|").
  static const Set<String> _excludedCountryTokens = {
    'france',
    'italy',
    'germany',
    'espan',
    'espana',
    'spain',
    'poland',
    'exyu',
    'england',
    'portugal',
    'portuguel',
    'turkey',
    'nederland',
    'netherlands',
    'amos',
    'canada',
    'usa',
    'brazil',
    'greece',
    'romania',
    'albania',
    'russian',
    'russia',
    'india',
    'okko',
    'iran',
    'kurdish',
    'christian',
  };

  /// Keep beIN regional feeds (beIN SPORTS FRANCE / TURKEY / ESPAN).
  static const Set<String> _keepBrandTokens = {'bein', 'be in'};

  bool isExcluded(Category category) {
    if (category.type != CategoryType.live) return false;
    final normalized = KidsContentPolicy.normalize(category.name);
    if (normalized.isEmpty) return false;
    if (_containsAny(normalized, _keepBrandTokens)) return false;
    return _containsAny(normalized, _excludedCountryTokens);
  }

  bool allowsCategory(Category category) => !isExcluded(category);

  static bool _containsAny(String value, Set<String> terms) {
    final padded = ' $value ';
    for (final term in terms) {
      if (padded.contains(' $term ')) return true;
    }
    return false;
  }
}
