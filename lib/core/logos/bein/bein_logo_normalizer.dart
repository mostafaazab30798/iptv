/// Reusable token-aware normalizer for beIN SPORTS channels.
///
/// Converts diverse IPTV channel titles, Arabic aliases, and quality tags into
/// deterministic canonical keys (e.g., `bein_sports_1`, `bein_sports_news`).
abstract final class BeinLogoNormalizer {
  // Arabic numeral mapping
  static const Map<String, String> _arabicDigits = {
    '٠': '0',
    '١': '1',
    '٢': '2',
    '٣': '3',
    '٤': '4',
    '٥': '5',
    '٦': '6',
    '٧': '7',
    '٨': '8',
    '٩': '9',
  };

  // Safe presentation and packaging suffixes/prefixes that should be stripped
  static final RegExp _presentationTokensRegex = RegExp(
    r'\b(hd|fhd|uhd|sd|1080p|720p|50fps|60fps|hevc|h265|h264|raw|vip|ar|en|fr|mena|low|multi|qatar|live|tv|ch)\b',
    caseSensitive: false,
  );

  /// Normalizes a channel name string to a canonical beIN key, or `null` if not recognized.
  static String? normalize(String? rawName) {
    if (rawName == null || rawName.trim().isEmpty) return null;

    var s = rawName.trim();

    // Convert Arabic digits to Western digits
    _arabicDigits.forEach((ar, en) {
      s = s.replaceAll(ar, en);
    });

    // Lowercase
    s = s.toLowerCase();

    // Map Arabic terms to standard English tokens
    s = _normalizeArabicTokens(s);

    // Replace brackets, separators, and punctuation with spaces
    s = s.replaceAll(RegExp(r'[\[\]\(\)\{\}\-_:\|/\\,\.\+★*#]'), ' ');

    // Collapse multiple spaces
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

    // Tokenize
    final rawTokens = s.split(' ').where((t) => t.isNotEmpty).toList();

    // Filter out safe presentation tokens (preserving '4k' and channel numbers)
    final filteredTokens = <String>[];
    for (final token in rawTokens) {
      if (token == '4k') {
        filteredTokens.add(token);
      } else if (!_presentationTokensRegex.hasMatch(token)) {
        filteredTokens.add(token);
      }
    }

    final normalizedLine = filteredTokens.join(' ');

    // Verify this is indeed a beIN sports channel
    if (!_isBein(normalizedLine, filteredTokens)) {
      return null;
    }

    return _resolveCanonicalKey(filteredTokens);
  }

  static bool _isBein(String line, List<String> tokens) {
    final hasBrand = tokens.contains('bein') ||
        tokens.contains('beinsports') ||
        line.startsWith('bein ') ||
        line.contains(' bein ') ||
        line.endsWith(' bein');
    if (!hasBrand) return false;

    // beIN also operates kids and entertainment channels. Never assign those
    // the bundled beIN SPORTS logo merely because the brand name is present.
    const childTokens = {
      'kid',
      'kids',
      'junior',
      'child',
      'children',
      'cartoon',
      'اطفال',
      'أطفال',
      'الاطفال',
      'براعم',
    };
    if (tokens.any(childTokens.contains)) return false;

    final hasSportsMarker = tokens.contains('sport') ||
        tokens.contains('sports') ||
        tokens.contains('beinsports');
    if (hasSportsMarker) return true;

    const nonSportsTokens = {
      'movie',
      'movies',
      'series',
      'drama',
      'gourmet',
      'entertainment',
      'documentary',
      'سينما',
      'افلام',
      'مسلسلات',
    };
    if (tokens.any(nonSportsTokens.contains)) return false;

    // Preserve established short aliases such as "beIN 1" and specific
    // sports sub-brands, but reject an otherwise generic beIN channel.
    return tokens.any((token) => RegExp(r'^\d+$').hasMatch(token)) ||
        tokens.any(
          const {
            'news',
            'akhbar',
            'ikhbariya',
            'nba',
            '4k',
            'uhd4k',
            'premium',
            'prem',
            'max',
            'xtra',
            'extra',
          }.contains,
        );
  }

  static String? _resolveCanonicalKey(List<String> tokens) {
    // Check specific sub-brands
    final hasNews = tokens.contains('news') || tokens.contains('akhbar') || tokens.contains('ikhbariya');
    final hasNba = tokens.contains('nba');
    final has4k = tokens.contains('4k') || tokens.contains('uhd4k');
    final hasPremium = tokens.contains('premium') || tokens.contains('prem');
    final hasMax = tokens.contains('max');
    final hasXtra = tokens.contains('xtra') || tokens.contains('extra');
    final hasEnglish = tokens.contains('english') || tokens.contains('eng');
    final hasFrench = tokens.contains('french') || tokens.contains('fra');

    // Extract exact channel number token (e.g. '1', '2', '3')
    String? channelNumber;
    for (final t in tokens) {
      if (RegExp(r'^\d+$').hasMatch(t)) {
        channelNumber = t;
        break;
      }
    }

    // beIN Sports News
    if (hasNews) {
      return 'bein_sports_news';
    }

    // beIN Sports NBA
    if (hasNba) {
      return 'bein_sports_nba';
    }

    // beIN Sports 4K
    if (has4k && channelNumber == null) {
      return 'bein_sports_4k';
    }

    // Numbered variants with qualifiers
    if (channelNumber != null) {
      if (hasPremium) {
        return 'bein_sports_${channelNumber}_premium';
      }
      if (hasMax) {
        return 'bein_sports_${channelNumber}_max';
      }
      if (hasXtra) {
        return 'bein_sports_${channelNumber}_xtra';
      }
      if (hasEnglish) {
        return 'bein_sports_${channelNumber}_english';
      }
      if (hasFrench) {
        return 'bein_sports_${channelNumber}_french';
      }
      if (has4k) {
        return 'bein_sports_4k';
      }

      return 'bein_sports_$channelNumber';
    }

    // Generic / non-numbered variants
    if (hasMax) return 'bein_sports_1_max';
    if (hasPremium) return 'bein_sports_1_premium';
    if (hasXtra) return 'bein_sports_1_xtra';

    // Global main channel
    return 'bein_sports';
  }

  static String _normalizeArabicTokens(String s) {
    var out = s;

    // Normalizing Arabic beIN variants
    out = out.replaceAll(RegExp(r'بي\s*إن\s*سبورت(س)?'), 'bein sports');
    out = out.replaceAll(RegExp(r'بي\s*ان\s*سبورت(س)?'), 'bein sports');
    out = out.replaceAll(RegExp(r'بين\s*سبورت(س)?'), 'bein sports');
    out = out.replaceAll(RegExp(r'بي\s*إن'), 'bein');
    out = out.replaceAll(RegExp(r'بي\s*ان'), 'bein');
    out = out.replaceAll(RegExp(r'بين'), 'bein');

    // Qualifiers
    out = out.replaceAll(RegExp(r'الإخبارية|الاخبارية|أخبار|اخبار'), 'news');
    out = out.replaceAll(RegExp(r'بريميوم|بريميم'), 'premium');
    out = out.replaceAll(RegExp(r'ماكس|مكس'), 'max');
    out = out.replaceAll(RegExp(r'اكسترا|إكسترا'), 'xtra');
    out = out.replaceAll(RegExp(r'الإنجليزية|الانجليزية|انجليزي|إنجليزي'), 'english');
    out = out.replaceAll(RegExp(r'الفرنسية|فرنسي'), 'french');
    out = out.replaceAll(RegExp(r'فور\s*كي|فور\s*كيه|4\s*كي'), '4k');

    return out;
  }
}
