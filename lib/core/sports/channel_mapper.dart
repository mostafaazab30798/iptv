import 'package:iptv/core/sports/big_match_detector.dart';
import 'package:iptv/domain/entities/channel.dart';

/// Normalizes scraped Arabic / English sports broadcast channel names
/// and maps them to the best available user IPTV stream.
abstract final class ChannelMapper {
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

  /// Normalizes Arabic characters and converts Arabic digits to Western digits.
  static String normalize(String input) {
    if (input.isEmpty) return '';
    var text = input.trim().toLowerCase();

    // Replace Arabic digits
    _arabicDigits.forEach((ar, en) {
      text = text.replaceAll(ar, en);
    });

    // Normalize Arabic letters
    text = text
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ئ', 'ي')
        .replaceAll('ة', 'ه');

    return BigMatchDetector.normalize(text);
  }

  /// Extracts the canonical network identifier and channel number/qualifier.
  static ({
    String network,
    String? number,
    bool isXtra,
    bool isPremium,
    bool isMax,
    bool isEnglish,
    bool isFrench,
    bool isSpanish,
    bool isTurkish,
    bool isAfc,
    bool isNews,
    bool isNba,
  })
  extractNetworkInfo(String channelName) {
    final n = normalize(channelName);

    var network = '';
    if (BigMatchDetector.isNonSportsStation(channelName)) {
      network = '';
    } else if (n.contains('bein') ||
        n.contains('be in') ||
        n.contains('بي ان') ||
        n.contains('بى ان') ||
        n.contains('بين سبورت')) {
      network = 'bein';
    } else if (n.contains('ontime') ||
        n.contains('on time') ||
        n.contains('on sport') ||
        n.contains('onsport') ||
        n.contains('اون تايم') ||
        n.contains('اون سبورت') ||
        n.contains('تايم سبورت')) {
      network = 'ontime';
    } else if (n.contains('ssc') || n.contains('اس اس سي')) {
      network = 'ssc';
    } else if (n.contains('abudhabi') ||
        n.contains('abu dhabi') ||
        n.contains('ad sport') ||
        n.contains('adsport') ||
        n.contains('ابو ظبي') ||
        n.contains('ابوظبي')) {
      network = 'adsports';
    } else if (n.contains('alkass') ||
        n.contains('al kass') ||
        n.contains('الكاس') ||
        n.contains('الكأس')) {
      network = 'alkass';
    } else if (n.contains('thmanyah') ||
        n.contains('thamanyah') ||
        n.contains('ثمانيه') ||
        n.contains('ثمانية')) {
      network = 'thmanyah';
    } else if (n.contains('dubai sport') || n.contains('دبي الرياضيه')) {
      network = 'dubaisports';
    } else if (n.contains('sharjah sport') || n.contains('الشارقه الرياضيه')) {
      network = 'sharjahsports';
    } else if (n.contains('ksa sport') ||
        n.contains('saudi sport') ||
        n.contains('السعوديه الرياضيه')) {
      network = 'ksasports';
    } else if (n.contains('kuwait sport') || n.contains('الكويت الرياضيه')) {
      network = 'kuwaitsports';
    } else if (n.contains('oman sport') || n.contains('عمان الرياضيه')) {
      network = 'omansports';
    } else if (n.contains('bahrain sport') || n.contains('البحرين الرياضيه')) {
      network = 'bahrainsports';
    } else if (n.contains('iraq sport') ||
        n.contains('iraqia sport') ||
        n.contains('العراقيه الرياضيه')) {
      network = 'iraqiasports';
    } else if (n.contains('jordan sport') || n.contains('الاردن الرياضيه')) {
      network = 'jordansports';
    } else if (n.contains('nile sport') || n.contains('النيل للرياضه')) {
      network = 'nilesports';
    }

    final isXtra =
        n.contains('xtra') || n.contains('extra') || n.contains('اكسترا');
    final isPremium =
        n.contains('premium') ||
        RegExp(r'(^| )prem( |$)').hasMatch(n) ||
        n.contains('بريميوم') ||
        n.contains('بريميم');
    final isMax =
        RegExp(r'(^| )max([0-9]*)( |$)').hasMatch(n) ||
        n.contains('ماكس') ||
        n.contains('مكس');
    final isEnglish = isEnglishVariant(n);
    final isFrench = isFrenchVariant(n);
    final isSpanish = isSpanishVariant(n);
    final isTurkish = isTurkishVariant(n);
    final isAfc =
        RegExp(r'(^| )afc( |$)').hasMatch(n) || n.contains('اسيا');
    final isNews =
        RegExp(r'(^| )(news|akhbar|ikhbariya)( |$)').hasMatch(n) ||
        n.contains('الاخباريه') ||
        n.contains('اخبار');
    final isNba = RegExp(r'(^| )nba( |$)').hasMatch(n);

    // Clean resolution and codec tags so attached suffixes/prefixes like "1hd",
    // "hd1", "4k", "1080p", or "h265" are accurately parsed without false numbers.
    var textForNumber = ' $n ';
    textForNumber = textForNumber.replaceAll(
      RegExp(r'[48]k', caseSensitive: false),
      ' ',
    );
    textForNumber = textForNumber.replaceAll(
      RegExp(
        r'\b(?:2160p?|1080p?|720p?|480p?|50fps|60fps|h264|h265|hevc|mp4)\b',
        caseSensitive: false,
      ),
      ' ',
    );
    textForNumber = textForNumber.replaceAll(
      RegExp(r'(?:uhd|fhd|hd|sd)', caseSensitive: false),
      ' ',
    );
    // Separate numbers attached directly to letters (e.g. "bein1", "ssc1", "max2", "ch1")
    textForNumber = textForNumber.replaceAllMapped(
      RegExp(r'([a-z\u0600-\u06FF])(\d+)'),
      (m) => '${m.group(1)} ${m.group(2)}',
    );
    textForNumber = textForNumber.replaceAllMapped(
      RegExp(r'(\d+)([a-z\u0600-\u06FF])'),
      (m) => '${m.group(1)} ${m.group(2)}',
    );

    // Extract channel number (1 to 16)
    String? number;
    final match = RegExp(
      r'(?:^|\s)(1[0-6]|[1-9])(?:\s|$)',
    ).firstMatch(textForNumber);
    if (match != null) {
      number = match.group(1);
    } else if (network == 'ontime' &&
        !isMax &&
        (n.contains('on sport') ||
            n.contains('onsport') ||
            n.contains('on time') ||
            n.contains('ontime') ||
            n.contains('اون سبورت') ||
            n.contains('اون تايم'))) {
      // Default ON Sport / ON Time Sports without number is typically channel 1
      number = '1';
    }

    return (
      network: network,
      number: number,
      isXtra: isXtra,
      isPremium: isPremium,
      isMax: isMax,
      isEnglish: isEnglish,
      isFrench: isFrench,
      isSpanish: isSpanish,
      isTurkish: isTurkish,
      isAfc: isAfc,
      isNews: isNews,
      isNba: isNba,
    );
  }

  /// Whether the station name explicitly identifies the English beIN package.
  /// Note: provider prefix tags like `EN |` are not treated as the English sub-brand
  /// unless `English` or `EN` appears as part of the station identity.
  static bool isEnglishVariant(String channelName) {
    final cleaned = _stripLeadingProviderPrefix(channelName);
    final normalized = normalize(cleaned);
    return RegExp(
      r'(^| )(en|eng|english|انجليزي|انجليزيه)( |$)',
    ).hasMatch(normalized);
  }

  /// Whether the station name explicitly identifies the French beIN package.
  static bool isFrenchVariant(String channelName) {
    final normalized = normalize(channelName);
    return RegExp(
      r'(^| )(fr|fra|france|french|francais|français|فرنسا|فرنسي|فرنسيه)( |$)',
    ).hasMatch(normalized);
  }

  /// Whether the station name explicitly identifies the Spanish beIN package.
  static bool isSpanishVariant(String channelName) {
    final normalized = normalize(channelName);
    return RegExp(
      r'(^| )(es|esp|espan|espana|spain|spanish|اسباني|اسبانيه)( |$)',
    ).hasMatch(normalized);
  }

  /// Whether the station name explicitly identifies the Turkish beIN package.
  static bool isTurkishVariant(String channelName) {
    final normalized = normalize(channelName);
    return RegExp(
      r'(^| )(tr|tur|turk|turkey|turkish|تركي|تركيه)( |$)',
    ).hasMatch(normalized);
  }

  static String _stripLeadingProviderPrefix(String raw) {
    var out = raw.trim();
    out = out.replaceAll(
      RegExp(r'^(?:ar|en|fr|tr|es|vip|raw)\s*\|\s*', caseSensitive: false),
      '',
    );
    out = out.replaceAll(
      RegExp(
        r'^\|\s*(?:ar|en|fr|tr|es|vip|raw)\s*\|\s*',
        caseSensitive: false,
      ),
      '',
    );
    out = out.replaceAll(
      RegExp(r'^\[(?:ar|en|fr|tr|es|vip|raw)\]\s*', caseSensitive: false),
      '',
    );
    return out;
  }

  /// Finds the highest-quality matching IPTV channel for a scraped broadcast channel name.
  static Channel? findBestChannel(
    String targetBroadcastName,
    Iterable<Channel> availableChannels,
  ) {
    final target = targetBroadcastName.trim();
    if (target.isEmpty ||
        target.toLowerCase() == 'not available' ||
        target == 'غير متوفر') {
      return null;
    }

    final targetInfo = extractNetworkInfo(target);
    if (targetInfo.network.isEmpty) {
      // Fallback: match by direct substring if target has recognizable keywords
      final normTarget = normalize(target);
      Channel? bestFallback;
      var bestFallbackScore = -1;

      for (final ch in availableChannels) {
        if (BigMatchDetector.isOfficialClubChannel(ch.name)) continue;
        if (BigMatchDetector.isNonSportsStation(ch.name)) continue;
        final normCh = normalize(ch.name);
        if (normCh.contains(normTarget) || normTarget.contains(normCh)) {
          final score = BigMatchDetector.channelQuality(ch.name);
          if (score > bestFallbackScore) {
            bestFallback = ch;
            bestFallbackScore = score;
          }
        }
      }
      return bestFallback;
    }

    final candidates = <Channel>[];
    for (final channel in availableChannels) {
      if (BigMatchDetector.isOfficialClubChannel(channel.name)) continue;
      if (BigMatchDetector.isNonSportsStation(channel.name)) continue;

      final info = extractNetworkInfo(channel.name);
      if (info.network != targetInfo.network) continue;

      // Check number match:
      // - If target specifies a number (e.g. "beIN Sports 1"), candidate must have that exact number.
      // - If target does not specify a number (e.g. "beIN Sports News" or "beIN Sports 4K"),
      //   candidate must match the sub-brand or not be a mismatched numbered channel.
      if (targetInfo.number != null) {
        if (info.number != targetInfo.number) continue;
      }

      // Check sub-brand distinctions (Xtra, Max, Premium, News, NBA, AFC)
      if (targetInfo.isXtra != info.isXtra) continue;
      if (targetInfo.isMax != info.isMax) continue;
      if (targetInfo.isPremium != info.isPremium) continue;
      if (targetInfo.isNews != info.isNews) continue;
      if (targetInfo.isNba != info.isNba) continue;
      if (targetInfo.isAfc != info.isAfc) continue;

      // Regional / language package distinctions:
      // A generic beIN listing means the main Arabic package. Regional or
      // foreign-language variants are eligible only when explicitly named.
      if (targetInfo.isFrench != info.isFrench) continue;
      if (targetInfo.isEnglish != info.isEnglish) continue;
      if (targetInfo.isSpanish != info.isSpanish) continue;
      if (targetInfo.isTurkish != info.isTurkish) continue;

      candidates.add(channel);
    }

    if (candidates.isEmpty && targetInfo.isPremium) {
      // Some providers relabeled "beIN Sports 1 Premium" back to "beIN Sports 1".
      // If no explicit Premium channel exists in the playlist, allow regular numbered beIN.
      for (final channel in availableChannels) {
        if (BigMatchDetector.isOfficialClubChannel(channel.name)) continue;
        if (BigMatchDetector.isNonSportsStation(channel.name)) continue;
        final info = extractNetworkInfo(channel.name);
        if (info.network != targetInfo.network) continue;
        if (targetInfo.number != null && info.number != targetInfo.number) {
          continue;
        }
        if (info.isXtra || info.isMax || info.isNews || info.isNba || info.isAfc) {
          continue;
        }
        if (targetInfo.isFrench != info.isFrench ||
            targetInfo.isEnglish != info.isEnglish ||
            targetInfo.isSpanish != info.isSpanish ||
            targetInfo.isTurkish != info.isTurkish) {
          continue;
        }
        candidates.add(channel);
      }
    }

    if (candidates.isEmpty) return null;

    // Pick candidate with highest stream quality (4K > FHD > HD > SD)
    candidates.sort((a, b) {
      final qA = BigMatchDetector.channelQuality(a.name);
      final qB = BigMatchDetector.channelQuality(b.name);
      return qB.compareTo(qA);
    });

    return candidates.first;
  }
}
