/// Detects when a big football club appears in a channel name or EPG title.
///
/// IPTV panels often expose live matches as event channels
/// (`Barcelona vs Real Madrid 4K`) and sometimes only in EPG text
/// (`beIN Sports 1` → "Barcelona vs Girona").
abstract final class BigMatchDetector {
  static final List<BigTeam> teams = List<BigTeam>.unmodifiable(_teams);

  /// Clubs mentioned in [text], in the order they appear in [_teams].
  static List<BigTeam> teamsIn(String text) {
    final normalized = normalize(text);
    if (normalized.isEmpty) return const [];

    final hits = <BigTeam>[];
    for (final team in _teams) {
      if (team.matchesNormalized(normalized)) hits.add(team);
    }
    return hits;
  }

  static String normalize(String raw) {
    var out = raw.toLowerCase().trim();
    if (out.isEmpty) return out;

    const accents = {
      'á': 'a',
      'à': 'a',
      'ä': 'a',
      'â': 'a',
      'ã': 'a',
      'å': 'a',
      'é': 'e',
      'è': 'e',
      'ë': 'e',
      'ê': 'e',
      'í': 'i',
      'ì': 'i',
      'ï': 'i',
      'î': 'i',
      'ó': 'o',
      'ò': 'o',
      'ö': 'o',
      'ô': 'o',
      'õ': 'o',
      'ú': 'u',
      'ù': 'u',
      'ü': 'u',
      'û': 'u',
      'ñ': 'n',
      'ç': 'c',
      'ß': 'ss',
    };
    final buffer = StringBuffer();
    for (final rune in out.runes) {
      final ch = String.fromCharCode(rune);
      buffer.write(accents[ch] ?? ch);
    }
    out = buffer.toString();

    out = out.replaceAll(RegExp(r'[|\[\](){}_/\\,+~.]'), ' ');
    out = out.replaceAll(RegExp(r'[-–—:]'), ' ');
    out = out.replaceAll(RegExp(r'\s+'), ' ').trim();
    return out;
  }

  /// Strips quality / language tags so duplicate event streams collapse.
  static String fingerprint(String text) {
    var out = ' ${normalize(text)} ';
    const noise = [
      '4k',
      'uhd',
      'fhd',
      'hd',
      'sd',
      'hevc',
      'h265',
      'h264',
      '50fps',
      '60fps',
      '1080p',
      '720p',
      '2160p',
      'multi',
      'audio',
      'ar',
      'en',
      'fr',
      'es',
      'pt',
      'arabic',
      'english',
      'french',
    ];
    for (final token in noise) {
      out = out.replaceAll(' $token ', ' ');
    }
    return out.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  static final _arabicScript = RegExp(r'[\u0600-\u06FF]');

  /// Club 24/7 stations such as "Barcelona TV" / "Bayern TV".
  static bool isOfficialClubChannel(String channelName) {
    final teams = teamsIn(channelName);
    if (teams.isEmpty) return false;
    if (looksLikeMatchEvent(channelName)) return false;
    if (isBeinOrArabicSportsNetwork(channelName)) return false;
    final n = normalize(channelName);
    return RegExp(r'\b(tv|channel|official|club)\b').hasMatch(n);
  }

  static bool looksLikeMatchEvent(String channelName) {
    final n = ' ${normalize(channelName)} ';
    return n.contains(' vs ') ||
        n.contains(' v ') ||
        n.contains(' x ') ||
        channelName.contains('ضد');
  }

  static bool hasArabicBroadcastMarker(String channelName) {
    if (_arabicScript.hasMatch(channelName)) return true;
    final lower = channelName.toLowerCase();
    if (lower.contains('arabic') ||
        lower.contains('عربي') ||
        lower.contains('عربية')) {
      return true;
    }
    return RegExp(r'(\||\[|\s)ar(\||\]|\s)', caseSensitive: false)
        .hasMatch(' $channelName ');
  }

  /// beIN Sports or Arabic-region sports networks — not a specific channel number.
  static bool isBeinOrArabicSportsNetwork(String channelName) {
    final n = normalize(channelName);
    if (n.isEmpty) return false;

    if (n.contains('bein') ||
        n.contains('be in sport') ||
        n.contains('beinsport') ||
        channelName.contains('بي ان') ||
        channelName.contains('بي إن') ||
        channelName.contains('بين سبورت')) {
      return true;
    }

    const arabicRegionSports = [
      'ad sport',
      'adsport',
      'abu dhabi sport',
      'abudhabi sport',
      'dubai sport',
      'sharjah sport',
      'alkass',
      'al kass',
      'ssc',
      'ksa sport',
      'saudi sport',
      'on time',
      'ontime',
      'nile sport',
      'qatar sport',
      'oman sport',
      'kuwait sport',
      'bahrain sport',
      'iraq sport',
      'jordan sport',
    ];
    for (final token in arabicRegionSports) {
      if (n.contains(token)) return true;
    }

    if (_arabicScript.hasMatch(channelName) &&
        (n.contains('sport') ||
            channelName.contains('رياض') ||
            channelName.contains('كورة') ||
            channelName.contains('كرة'))) {
      return true;
    }

    return false;
  }

  /// Channels we are allowed to open for a live big match.
  static bool isAllowedMatchChannel(String channelName) {
    if (isOfficialClubChannel(channelName)) return false;
    if (isBeinOrArabicSportsNetwork(channelName)) return true;
    return hasArabicBroadcastMarker(channelName) &&
        looksLikeMatchEvent(channelName);
  }

  static int channelQuality(String channelName) {
    final n = channelName.toLowerCase();
    if (n.contains('4k') || n.contains('uhd') || n.contains('2160')) return 30;
    if (n.contains('fhd') || n.contains('1080')) return 20;
    if (n.contains('hd')) return 10;
    return 0;
  }
}

class BigTeam {
  const BigTeam({
    required this.id,
    required this.displayName,
    required this.aliases,
  });

  final String id;
  final String displayName;

  /// Already-normalized aliases. Multi-word aliases use substring match;
  /// single tokens require a word boundary so `city` does not match everything.
  final List<String> aliases;

  bool matchesNormalized(String normalizedHaystack) {
    final hay = ' $normalizedHaystack ';
    for (final alias in aliases) {
      if (alias.contains(' ')) {
        if (normalizedHaystack.contains(alias)) return true;
      } else if (hay.contains(' $alias ')) {
        return true;
      }
    }
    return false;
  }
}

const _teams = <BigTeam>[
  BigTeam(
    id: 'barcelona',
    displayName: 'Barcelona',
    aliases: [
      'barcelona',
      'barca',
      'fc barcelona',
      'fcb',
      'برشلونة',
      'بارسا',
      'بارسلونا',
    ],
  ),
  BigTeam(
    id: 'real_madrid',
    displayName: 'Real Madrid',
    aliases: [
      'real madrid',
      'real madrid cf',
      'rma',
      'rmcf',
      'ريال مدريد',
      'الريال',
    ],
  ),
  BigTeam(
    id: 'man_city',
    displayName: 'Manchester City',
    aliases: [
      'manchester city',
      'man city',
      'mancity',
      'mcfc',
      'مانشستر سيتي',
    ],
  ),
  BigTeam(
    id: 'man_united',
    displayName: 'Manchester United',
    aliases: [
      'manchester united',
      'man united',
      'man utd',
      'manu',
      'mufc',
      'مانشستر يونايتد',
    ],
  ),
  BigTeam(
    id: 'liverpool',
    displayName: 'Liverpool',
    aliases: ['liverpool', 'lfc', 'ليفربول'],
  ),
  BigTeam(
    id: 'chelsea',
    displayName: 'Chelsea',
    aliases: ['chelsea', 'تشيلسي'],
  ),
  BigTeam(
    id: 'arsenal',
    displayName: 'Arsenal',
    aliases: ['arsenal', 'ارسنال', 'أرسنال'],
  ),
  BigTeam(
    id: 'tottenham',
    displayName: 'Tottenham',
    aliases: [
      'tottenham hotspur',
      'tottenham',
      'spurs',
      'thfc',
      'توتنهام',
    ],
  ),
];
