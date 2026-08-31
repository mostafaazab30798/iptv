import 'package:iptv/domain/entities/category.dart';

class KidsContentPolicy {
  const KidsContentPolicy();

  static const Set<String> _kidsCategoryTerms = {
    'kid',
    'kids',
    'child',
    'children',
    'cartoon',
    'cartoons',
    'animation',
    'animated',
    'anime',
    'junior',
    'preschool',
    'family',
    'اطفال',
    'الاطفال',
    'طفل',
    'الطفل',
    'كرتون',
    'رسوم متحركه',
    'انمي',
    'عائلي',
  };

  static const Set<String> _courseTerms = {
    'course',
    'courses',
    'education',
    'educational',
    'learning',
    'tutorial',
    'school',
    'درس',
    'دروس',
    'دوره',
    'دورات',
    'تعليم',
    'تعليمي',
  };

  static const Set<String> _denyTerms = {
    'adult',
    'adults',
    '18',
    '18 plus',
    'xxx',
    'للكبار',
    'بالغين',
  };

  static const Set<String> _liveChannelAliases = {
    'cartoon network',
    'cartoonito',
    'boomerang',
    'nickelodeon',
    'nick jr',
    'nicktoons',
    'disney channel',
    'disney junior',
    'disney xd',
    'baby tv',
    'babytv',
    'cbeebies',
    'pbs kids',
    'bein kids',
    'bein junior',
    'spacetoon',
    'سبيستون',
    'mbc 3',
    'mbc3',
    'majid kids',
    'ماجد',
    'jeem',
    'جيم',
    'baraem',
    'براعم',
    'toyor al janah',
    'طيور الجنه',
    'karameesh',
    'كراميش',
    'taha',
    'طه',
  };

  bool allowsCategory(Category category) {
    final normalized = normalize(category.name);
    if (_containsAny(normalized, _denyTerms)) return false;
    if (_containsAny(normalized, _kidsCategoryTerms)) return true;
    return category.type == CategoryType.series &&
        _containsAny(normalized, _courseTerms);
  }

  bool allowsLiveChannelName(String name) {
    final normalized = normalize(name);
    if (_containsAny(normalized, _denyTerms)) return false;
    return _containsAny(normalized, _liveChannelAliases) ||
        _containsAny(normalized, const {'kids', 'children'});
  }

  static String normalize(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
        .replaceAll(RegExp('[أإآٱ]'), 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ة', 'ه')
        .replaceAll(RegExp(r'[^a-z0-9\u0600-\u06ff]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool _containsAny(String value, Set<String> terms) {
    final padded = ' $value ';
    for (final term in terms) {
      if (padded.contains(' $term ')) return true;
    }
    return false;
  }
}
