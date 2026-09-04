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
  static ({String network, String? number, bool isXtra, bool isPremium})
      extractNetworkInfo(String channelName) {
    final n = normalize(channelName);

    var network = '';
    if (n.contains('bein') || n.contains('بي ان') || n.contains('بى ان')) {
      network = 'bein';
    } else if (n.contains('ontime') ||
        n.contains('on time') ||
        n.contains('on sport') ||
        n.contains('اون تايم') ||
        n.contains('اون سبورت') ||
        n.contains('تايم سبورت')) {
      network = 'ontime';
    } else if (n.contains('ssc') || n.contains('اس اس سي')) {
      network = 'ssc';
    } else if (n.contains('abudhabi') ||
        n.contains('abu dhabi') ||
        n.contains('ad sport') ||
        n.contains('ابو ظبي') ||
        n.contains('ابوظبي')) {
      network = 'adsports';
    } else if (n.contains('alkass') ||
        n.contains('al kass') ||
        n.contains('الكاس') ||
        n.contains('الكأس')) {
      network = 'alkass';
    }

    final isXtra = n.contains('xtra') || n.contains('extra') || n.contains('اكسترا');
    final isPremium = n.contains('premium') || n.contains('بريميوم') || n.contains('بريميم');

    // Clean resolution tags so attached suffixes/prefixes like "1hd", "hd1", or "4k" are accurately parsed
    var textForNumber = ' $n ';
    textForNumber = textForNumber.replaceAll(RegExp(r'[48]k', caseSensitive: false), ' ');
    textForNumber = textForNumber.replaceAll(
        RegExp(r'(?:hd|fhd|uhd|sd)', caseSensitive: false), ' ');

    // Extract channel number (1 to 16)
    String? number;
    final match = RegExp(r'(?:^|\s)(1[0-6]|[1-9])(?:\s|$)').firstMatch(textForNumber);
    if (match != null) {
      number = match.group(1);
    } else if (network == 'ontime' && (n.contains('on sport') || n.contains('اون سبورت'))) {
      // Default ON Sport without number is typically ON Time Sports 1
      number = '1';
    }

    return (
      network: network,
      number: number,
      isXtra: isXtra,
      isPremium: isPremium,
    );
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

      final info = extractNetworkInfo(channel.name);
      if (info.network != targetInfo.network) continue;

      // Check number match
      if (targetInfo.number != null && info.number != targetInfo.number) {
        continue;
      }

      // Check extra/xtra distinction
      if (targetInfo.isXtra != info.isXtra) {
        continue;
      }

      // Check premium distinction if target specified it
      if (targetInfo.isPremium && !info.isPremium) {
        continue;
      }

      candidates.add(channel);
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
