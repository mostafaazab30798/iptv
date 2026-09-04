import 'package:iptv/core/sports/big_match_detector.dart';
import 'package:iptv/core/sports/channel_mapper.dart';

/// Provides bidirectional Arabic <-> English localization for football team names,
/// sports broadcasting channels, and tournament leagues.
abstract final class SportsLocalization {
  static final RegExp _arabicScript = RegExp(r'[\u0600-\u06FF]');

  /// Returns true if the string contains Arabic characters.
  static bool hasArabic(String text) => _arabicScript.hasMatch(text);

  /// Normalizes Arabic text for dictionary lookup by standardizing letters,
  /// removing tatweel/kashida, and stripping zero-width/formatting characters.
  static String normalizeArabic(String input) {
    if (input.isEmpty) return '';
    var s = input.trim();
    // Remove tatweel / kashida
    s = s.replaceAll('ـ', '');
    // Remove zero-width & directional formatting characters
    s = s.replaceAll(RegExp(r'[\u200B-\u200F\uFEFF\u202A-\u202E]'), '');
    // Normalize alef
    s = s.replaceAll(RegExp(r'[أإآ]'), 'ا');
    // Normalize yaa and taa marbuta
    s = s.replaceAll(RegExp(r'[ىئ]'), 'ي');
    s = s.replaceAll('ة', 'ه');
    // Collapse whitespace
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    return s.toLowerCase();
  }

  /// Localizes a team name based on whether the interface is in Arabic.
  static String localizeTeam(String name, {required bool isArabic}) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return trimmed;

    if (isArabic) {
      if (hasArabic(trimmed)) {
        return trimmed.replaceAll('ـ', '').trim();
      }
      final lower = trimmed.toLowerCase();
      final arName = _enToArTeams[lower];
      if (arName != null) return arName;
      return trimmed;
    }

    // English interface requested
    if (!hasArabic(trimmed)) {
      return trimmed;
    }

    final norm = normalizeArabic(trimmed);
    final direct = _arToEnTeams[norm];
    if (direct != null) return direct;

    // Check BigMatchDetector recognized big clubs
    final bigTeams = BigMatchDetector.teamsIn(trimmed);
    if (bigTeams.isNotEmpty) {
      return bigTeams.first.displayName;
    }

    // Substring fallback for compound team names
    for (final entry in _arToEnTeams.entries) {
      if (entry.key.length >= 4 && norm.contains(entry.key)) {
        return entry.value;
      }
    }

    return trimmed;
  }

  /// Localizes a sports channel name (e.g. from Yallakora or IPTV stream).
  static String localizeChannel(String channelName, {required bool isArabic}) {
    final trimmed = channelName.trim();
    if (trimmed.isEmpty) return trimmed;

    if (isArabic) {
      if (hasArabic(trimmed)) {
        return trimmed.replaceAll('ـ', '').trim();
      }
      final lower = trimmed.toLowerCase();
      final ar = _enToArChannels[lower];
      if (ar != null) return ar;
      return trimmed;
    }

    // English interface requested
    if (hasArabic(trimmed)) {
      final norm = normalizeArabic(trimmed);
      final direct = _arToEnChannels[norm];
      if (direct != null) return direct;

      final info = ChannelMapper.extractNetworkInfo(trimmed);
      final lower = trimmed.toLowerCase();
      if (info.network == 'bein') {
        var out = 'beIN Sports';
        if (info.number != null) out += ' ${info.number}';
        if (info.isPremium) out += ' Premium';
        if (info.isXtra) out += ' Xtra';
        if (lower.contains('4k')) {
          out += ' 4K';
        } else if (lower.contains('fhd')) {
          out += ' FHD';
        } else if (lower.contains('hd')) {
          out += ' HD';
        }
        return out;
      } else if (info.network == 'ontime') {
        var out = 'ON Time Sports';
        if (lower.contains('max')) {
          out = 'ON Sport MAX';
        } else if (info.number != null) {
          out += ' ${info.number}';
        } else {
          out = 'ON Sport';
        }
        if (lower.contains('hd')) out += ' HD';
        return out;
      } else if (info.network == 'ssc') {
        var out = 'SSC';
        if (info.number != null) out += ' ${info.number}';
        if (lower.contains('extra')) out += ' Extra';
        if (lower.contains('hd')) out += ' HD';
        return out;
      } else if (info.network == 'adsports') {
        var out = 'AD Sports';
        if (info.number != null) out += ' ${info.number}';
        if (lower.contains('hd')) out += ' HD';
        return out;
      } else if (info.network == 'alkass') {
        var out = 'Alkass';
        if (info.number != null) out += ' ${info.number}';
        if (lower.contains('hd')) out += ' HD';
        return out;
      }

      if (norm.contains('ثمانيه 1') || norm.contains('ثمانية 1')) return 'Thmanyah 1';
      if (norm.contains('ثمانيه 2') || norm.contains('ثمانية 2')) return 'Thmanyah 2';
      if (norm.contains('ثمانيه 3') || norm.contains('ثمانية 3')) return 'Thmanyah 3';
      if (norm.contains('دبي الرياضيه')) return 'Dubai Sports';
      if (norm.contains('الشارقه الرياضيه')) return 'Sharjah Sports';
      if (norm.contains('السعوديه الرياضيه')) return 'KSA Sports';
      if (norm.contains('الكويت الرياضيه')) return 'Kuwait Sports';
      if (norm.contains('عمان الرياضيه')) return 'Oman Sports';
      if (norm.contains('العراقيه الرياضيه')) return 'Iraqia Sports';
      if (norm.contains('الاردن الرياضيه')) return 'Jordan Sports';
      if (norm.contains('النيل للرياضه')) return 'Nile Sports';
      if (norm.contains('غير متوفر')) return 'Not Available';
    }

    return _cleanEnglishChannelName(trimmed);
  }

  /// Localizes a football league / competition name.
  static String? localizeLeague(String? league, {required bool isArabic}) {
    if (league == null || league.trim().isEmpty) return null;
    final trimmed = league.trim();

    if (isArabic) {
      if (hasArabic(trimmed)) return trimmed;
      final lower = trimmed.toLowerCase();
      final ar = _enToArLeagues[lower];
      if (ar != null) return ar;
      return trimmed;
    }

    if (!hasArabic(trimmed)) return trimmed;

    final norm = normalizeArabic(trimmed);
    final direct = _arToEnLeagues[norm];
    if (direct != null) return direct;

    for (final entry in _arToEnLeagues.entries) {
      if (norm.contains(entry.key) || entry.key.contains(norm)) {
        return entry.value;
      }
    }

    return trimmed;
  }

  static String _cleanEnglishChannelName(String name) {
    var out = name.trim();
    out = out.replaceAll(RegExp(r'^(?:ar|en|fr|vip|raw)\s*\|\s*', caseSensitive: false), '');
    out = out.replaceAll(RegExp(r'^\|\s*(?:ar|en|fr|vip|raw)\s*\|\s*', caseSensitive: false), '');
    out = out.replaceAll(RegExp(r'^\[(?:ar|en|fr|vip|raw)\]\s*', caseSensitive: false), '');
    out = out.replaceAll(RegExp(r'^(?:ar|en|fr|vip|raw)\s*:\s*', caseSensitive: false), '');
    return out.isEmpty ? name : out;
  }

  // ---------------------------------------------------------------------------
  // Dictionaries
  // ---------------------------------------------------------------------------

  static final Map<String, String> _rawArToEnTeams = {
    // Spanish La Liga
    'ريال مدريد': 'Real Madrid',
    'برشلونه': 'Barcelona',
    'برشلونة': 'Barcelona',
    'اتلتيكو مدريد': 'Atletico Madrid',
    'أتلتيكو مدريد': 'Atletico Madrid',
    'ريال بيتيس': 'Real Betis',
    'اشبيليه': 'Sevilla',
    'إشبيلية': 'Sevilla',
    'فالنسيا': 'Valencia',
    'فياريال': 'Villarreal',
    'ريال سوسيداد': 'Real Sociedad',
    'اتلتيك بلباو': 'Athletic Bilbao',
    'أتلتيك بلباو': 'Athletic Bilbao',
    'سيلتا فيجو': 'Celta Vigo',
    'خيتافي': 'Getafe',
    'جيرونا': 'Girona',
    'اوساسونا': 'Osasuna',
    'أوساسونا': 'Osasuna',
    'رايو فاليكانو': 'Rayo Vallecano',
    'ريال مايوركا': 'Mallorca',
    'مايوركا': 'Mallorca',
    'اسبانيول': 'Espanyol',
    'إسبانيول': 'Espanyol',
    'ديبورتيفو الافيس': 'Alaves',
    'الافيس': 'Alaves',
    'ألافيس': 'Alaves',
    'لاس بالماس': 'Las Palmas',
    'ليجانيس': 'Leganes',
    'بلد الوليد': 'Real Valladolid',
    'ريال بلد الوليد': 'Real Valladolid',

    // English Premier League
    'ليفربول': 'Liverpool',
    'مانشستر سيتي': 'Manchester City',
    'ارسنال': 'Arsenal',
    'أرسنال': 'Arsenal',
    'تشيلسي': 'Chelsea',
    'مانشستر يونايتد': 'Manchester United',
    'توتنهام': 'Tottenham Hotspur',
    'توتنهام هوتسبير': 'Tottenham Hotspur',
    'نيوكاسل': 'Newcastle United',
    'نيوكاسل يونايتد': 'Newcastle United',
    'استون فيلا': 'Aston Villa',
    'أستون فيلا': 'Aston Villa',
    'برايتون': 'Brighton',
    'وست هام': 'West Ham',
    'وست هام يونايتد': 'West Ham',
    'ايفيرتون': 'Everton',
    'ايفرتون': 'Everton',
    'إيفرتون': 'Everton',
    'وولفرهامبتون': 'Wolves',
    'بورنموث': 'Bournemouth',
    'فولهام': 'Fulham',
    'برينتفورد': 'Brentford',
    'كريستال بالاس': 'Crystal Palace',
    'نوتنجهام فورست': 'Nottingham Forest',
    'ليستر سيتي': 'Leicester City',
    'ايبسويتش تاون': 'Ipswich Town',
    'إيبسويتش تاون': 'Ipswich Town',
    'ساوثهامبتون': 'Southampton',
    'ليدز يونايتد': 'Leeds United',
    'بيرنلي': 'Burnley',

    // Italian Serie A
    'انتر ميلان': 'Inter Milan',
    'إنتر ميلان': 'Inter Milan',
    'انتر': 'Inter Milan',
    'إنتر': 'Inter Milan',
    'ميلان': 'AC Milan',
    'ايه سي ميلان': 'AC Milan',
    'يوفنتوس': 'Juventus',
    'نابولي': 'Napoli',
    'اتالانتا': 'Atalanta',
    'أتالانتا': 'Atalanta',
    'روما': 'AS Roma',
    'لاتسيو': 'Lazio',
    'فيورنتينا': 'Fiorentina',
    'بولونيا': 'Bologna',
    'تورينو': 'Torino',
    'جنوى': 'Genoa',
    'كومو': 'Como',
    'مونزا': 'Monza',
    'بارما': 'Parma',
    'كالياري': 'Cagliari',
    'امبولي': 'Empoli',
    'إمبولي': 'Empoli',
    'هيلاس فيرونا': 'Hellas Verona',
    'فيرونا': 'Hellas Verona',
    'ليتشي': 'Lecce',
    'فينيزيا': 'Venezia',
    'اودينيزي': 'Udinese',
    'أودينيزي': 'Udinese',

    // German Bundesliga
    'بايرن ميونخ': 'Bayern Munich',
    'بوروسيا دورتموند': 'Borussia Dortmund',
    'باير ليفركوزن': 'Bayer Leverkusen',
    'لايبزيج': 'RB Leipzig',
    'اينتراخت فرانكفورت': 'Eintracht Frankfurt',
    'آينتراخت فرانكفورت': 'Eintracht Frankfurt',
    'فرانكفورت': 'Eintracht Frankfurt',
    'شتوتجارت': 'Stuttgart',
    'فولفسبورج': 'Wolfsburg',
    'بوروسيا مونشنجلادباخ': 'Mönchengladbach',
    'مونشنجلادباخ': 'Mönchengladbach',
    'فرايبورج': 'Freiburg',
    'يونيون برلين': 'Union Berlin',
    'هوفنهايم': 'Hoffenheim',
    'فيردر بريمن': 'Werder Bremen',
    'ماينز': 'Mainz 05',
    'اوجسبورج': 'Augsburg',
    'أوجسبورج': 'Augsburg',
    'هايدنهايم': 'Heidenheim',
    'سانت باولي': 'St. Pauli',
    'هولشتاين كيل': 'Holstein Kiel',
    'كولن': 'FC Köln',
    'بوخوم': 'VfL Bochum',

    // French Ligue 1
    'باريس سان جيرمان': 'Paris Saint-Germain',
    'موناكو': 'Monaco',
    'مارسيليا': 'Marseille',
    'اولمبيك مارسيليا': 'Marseille',
    'أولمبيك مارسيليا': 'Marseille',
    'ليل': 'Lille',
    'ليون': 'Lyon',
    'اولمبيك ليون': 'Lyon',
    'أولمبيك ليون': 'Lyon',
    'لانس': 'Lens',
    'نيس': 'Nice',
    'رين': 'Rennes',
    'ستاد رين': 'Rennes',
    'بريست': 'Brest',
    'ستاد بريست': 'Brest',
    'ريمس': 'Reims',
    'ستراسبورج': 'Strasbourg',
    'تولوز': 'Toulouse',
    'مونبلييه': 'Montpellier',
    'نانت': 'Nantes',
    'اوكسير': 'Auxerre',
    'أوكسير': 'Auxerre',
    'لوهافر': 'Le Havre',
    'انجيه': 'Angers',
    'أنجيه': 'Angers',
    'سانت ايتيان': 'Saint-Etienne',
    'سانت إيتيان': 'Saint-Etienne',

    // Portuguese & Turkish & Other European
    'بورتو': 'Porto',
    'بنفيكا': 'Benfica',
    'سبورتينج لشبونه': 'Sporting CP',
    'سبورتينغ لشبونة': 'Sporting CP',
    'سبورتنج لشبونه': 'Sporting CP',
    'سبورتينج': 'Sporting CP',
    'براغا': 'SC Braga',
    'سبورتينج براغا': 'SC Braga',
    'موريرنسي': 'Moreirense',
    'فيتوريا غيماريش': 'Vitoria Guimaraes',
    'جالاتا سراي': 'Galatasaray',
    'فنربخشة': 'Fenerbahce',
    'فنربخشه': 'Fenerbahce',
    'بشكتاش': 'Besiktas' ,
    'طرابزون سبور': 'Trabzonspor',
    'اسطنبول باشاكشهير': 'Istanbul Basaksehir',
    'إسطنبول باشاكشهير': 'Istanbul Basaksehir',
    'باشاك شهير': 'Istanbul Basaksehir',
    'اياكس': 'Ajax',
    'أياكس': 'Ajax',
    'فينورد': 'Feyenoord',
    'ايندهوفن': 'PSV Eindhoven',
    'بي اس في ايندهوفن': 'PSV Eindhoven',
    'سيلتيك': 'Celtic',
    'رينجرز': 'Rangers',

    // Egyptian League & Division 2
    'الاهلي': 'Al Ahly',
    'الأهلي': 'Al Ahly',
    'الزمالك': 'Zamalek',
    'بيراميدز': 'Pyramids FC',
    'الاسماعيلي': 'Ismaily',
    'الإسماعيلي': 'Ismaily',
    'المصري': 'Al Masry',
    'المصري البورسعيدي': 'Al Masry',
    'الاتحاد السكندري': 'Al Ittihad',
    'سيراميكا كليوباترا': 'Ceramica Cleopatra',
    'سيراميكا': 'Ceramica Cleopatra',
    'مودرن سبورت': 'Modern Sport',
    'مودرن فيوتشر': 'Modern Future',
    'فيوتشر': 'Future FC',
    'سموحه': 'Smouha',
    'سموحة': 'Smouha',
    'زد': 'ZED FC',
    'انبي': 'ENPPI',
    'إنبي': 'ENPPI',
    'طلائع الجيش': 'Talaea El Gaish',
    'البنك الاهلي': 'National Bank',
    'البنك الأهلي': 'National Bank',
    'الجونه': 'El Gouna',
    'الجونة': 'El Gouna',
    'بلديه المحله': 'Baladiyat El Mahalla',
    'بلدية المحلة': 'Baladiyat El Mahalla',
    'المقاولون العرب': 'Arab Contractors',
    'المقاولون': 'Arab Contractors',
    'الداخليه': 'El Dakhleya',
    'الداخلية': 'El Dakhleya',
    'فاركو': 'Pharco',
    'غزل المحله': 'Ghazl El Mahalla',
    'غزل المحلة': 'Ghazl El Mahalla',
    'حرس الحدود': 'Haras El Hodoud',
    'بتروجيت': 'Petrojet',
    'الترسانه': 'Tersana',
    'الترسانة': 'Tersana',
    'طنطا': 'Tanta',
    'بروكسي': 'Proxy SC',
    'مسار': 'Massar',
    'دلتا يونايتد': 'Delta United',
    'نادى دلتا يونايتد': 'Delta United',
    'نادي لوسيل': 'Lusail SC',
    'ايه اس بورت': 'AS Port',
    'إيه أس بورت': 'AS Port',

    // Saudi Pro League
    'الهلال': 'Al Hilal',
    'النصر': 'Al Nassr',
    'الاتحاد': 'Al Ittihad',
    'اهلي جده': 'Al Ahli',
    'أهلي جدة': 'Al Ahli',
    'الاهلي السعودي': 'Al Ahli',
    'الشباب': 'Al Shabab',
    'الاتفاق': 'Al Ettifaq',
    'الاتفـاق': 'Al Ettifaq',
    'التعاون': 'Al Taawoun',
    'الفتح': 'Al Fateh',
    'الفيحاء': 'Al Fayha',
    'ضمك': 'Damac',
    'الوحده': 'Al Wehda',
    'الوحدة': 'Al Wehda',
    'الخليج': 'Al Khaleej',
    'الرائد': 'Al Raed',
    'الاخدود': 'Al Okhdood',
    'الأخدود': 'Al Okhdood',
    'الرياض': 'Al Riyadh',
    'العروبه': 'Al Orobah',
    'العروبة': 'Al Orobah',
    'القادسيه': 'Al Qadsiah',
    'القادسية': 'Al Qadsiah',
    'الخلود': 'Al Kholood',
    'ابها': 'Abha',
    'أبها': 'Abha',
    'الطائي': 'Al Tai',
    'الحزم': 'Al Hazem',

    // UAE & Qatar & Gulf
    'العين': 'Al Ain',
    'الوصل': 'Al Wasl',
    'شباب الاهلي': 'Shabab Al Ahli',
    'شباب الأهلي': 'Shabab Al Ahli',
    'الشارقه': 'Sharjah FC',
    'الشارقة': 'Sharjah FC',
    'الجزيره': 'Al Jazira',
    'الجزيرة': 'Al Jazira',
    'الوحده الاماراتي': 'Al Wahda',
    'الوحدة الإماراتي': 'Al Wahda',
    'النصر الاماراتي': 'Al Nasr',
    'عجمان': 'Ajman',
    'بني ياس': 'Baniyas',
    'خورفكان': 'Khor Fakkan',
    'اتحاد كلباء': 'Ittihad Kalba',
    'البطائح': 'Al Bataeh',
    'دبا الحصن': 'Diba Al Hisn',
    'السد': 'Al Sadd',
    'الريان': 'Al Rayyan',
    'الدحيل': 'Al Duhail',
    'العربي': 'Al Arabi',
    'الغرافه': 'Al Gharafa',
    'الغرافة': 'Al Gharafa',
    'الوكرة': 'Al Wakrah',
    'الو Hub': 'Al Wakrah',
    'قطر': 'Qatar SC',
    'ام صلال': 'Umm Salal',
    'أم صلال': 'Umm Salal',
    'الاهلي القطري': 'Al Ahli',
    'الشمال': 'Al Shamal',
    'الخور': 'Al Khor',
    'الشحانيه': 'Al Shahaniya',
    'الشحانية': 'Al Shahaniya',
    'معيذر': 'Muaither',

    // Other Arab & African Champions
    'الترجي': 'Esperance',
    'الترجي التونسي': 'Esperance',
    'الوداد': 'Wydad AC',
    'الوداد الرياضي': 'Wydad AC',
    'الرجاء': 'Raja Casablanca',
    'الرجاء الرياضي': 'Raja Casablanca',
    'الجيش الملكي': 'AS FAR',
    'نهضه بركان': 'RS Berkane',
    'نهضة بركان': 'RS Berkane',
    'النجم الساحلي': 'Etoile du Sahel',
    'النادي الافريقي': 'Club Africain',
    'الصفاقسي': 'CS Sfaxien',
    'شباب بلوزداد': 'CR Belouizdad',
    'اتحاد العاصمه': 'USM Alger',
    'مولوديه الجزائر': 'MC Alger',
    'صن داونز': 'Mamelodi Sundowns',
    'ماميلودي صنداونز': 'Mamelodi Sundowns',
    'مازيمبي': 'TP Mazembe',
    'تي بي مازيمبي': 'TP Mazembe',
    'سيمبا': 'Simba SC',
    'يانج افريكانز': 'Young Africans',
  };

  static final Map<String, String> _rawArToEnLeagues = {
    'الدوري الاسباني': 'La Liga',
    'الدوري الإسباني': 'La Liga',
    'الدوري الانجليزي': 'Premier League',
    'الدوري الإنجليزي': 'Premier League',
    'دوري ابطال اوروبا': 'UEFA Champions League',
    'دوري أبطال أوروبا': 'UEFA Champions League',
    'الدوري الايطالي': 'Serie A',
    'الدوري الإيطالي': 'Serie A',
    'الدوري الالماني': 'Bundesliga',
    'الدوري الألماني': 'Bundesliga',
    'الدوري الفرنسي': 'Ligue 1',
    'دوري ابطال افريقيا': 'CAF Champions League',
    'دوري أبطال أفريقيا': 'CAF Champions League',
    'دوري ابطال اسيا': 'AFC Champions League',
    'دوري أبطال آسيا': 'AFC Champions League',
    'الدوري التركي': 'Süper Lig',
    'الدوري البرتغالي': 'Primeira Liga',
    'الدوري السعودي': 'Saudi Pro League',
    'الدوري الاماراتي': 'UAE Pro League',
    'الدوري الإماراتي': 'UAE Pro League',
    'دوري نجوم قطر': 'Qatar Stars League',
    'دوري القسم الثاني-أ': 'Egyptian Second Division',
    'الدوري المصري': 'Egyptian Premier League',
    'كاس ملك اسبانيا': 'Copa del Rey',
    'كأس ملك إسبانيا': 'Copa del Rey',
    'كاس الاتحاد الانجليزي': 'FA Cup',
    'كأس الاتحاد الإنجليزي': 'FA Cup',
    'كاس كاراباو': 'Carabao Cup',
    'كأس كاراباو': 'Carabao Cup',
    'كاس ايطاليا': 'Coppa Italia',
    'كأس إيطاليا': 'Coppa Italia',
    'كاس المانيا': 'DFB-Pokal',
    'كأس ألمانيا': 'DFB-Pokal',
    'كاس فرنسا': 'Coupe de France',
    'كأس فرنسا': 'Coupe de France',
    'كاس مصر': 'Egypt Cup',
    'كأس مصر': 'Egypt Cup',
    'كاس السوبر الاسباني': 'Supercopa de España',
    'كأس السوبر الإسباني': 'Supercopa de España',
    'كاس السوبر الافريقي': 'CAF Super Cup',
    'كأس السوبر الإفريقي': 'CAF Super Cup',
    'الدوري الاوروبي': 'UEFA Europa League',
    'الدوري الأوروبي': 'UEFA Europa League',
    'دوري المؤتمر الاوروبي': 'UEFA Conference League',
    'دوري المؤتمر الأوروبي': 'UEFA Conference League',
    'كاس العالم': 'FIFA World Cup',
    'كأس العالم': 'FIFA World Cup',
    'كاس العالم للانديه': 'FIFA Club World Cup',
    'كأس العالم للأندية': 'FIFA Club World Cup',
    'كاس امم افريقيا': 'Africa Cup of Nations',
    'كأس أمم أفريقيا': 'Africa Cup of Nations',
  };

  static final Map<String, String> _rawArToEnChannels = {
    'بي ان سبورت': 'beIN Sports',
    'بى ان سبورت': 'beIN Sports',
    'ابو ظبي الرياضيه': 'AD Sports',
    'ابوظبي الرياضيه': 'AD Sports',
    'أبوظبي الرياضية': 'AD Sports',
    'اون تايم سبورت': 'ON Time Sports',
    'اون سبورت': 'ON Sport',
    'الكاس': 'Alkass',
    'ثمانيه 1': 'Thmanyah 1',
    'ثمانية 1': 'Thmanyah 1',
    'ثمانيه 2': 'Thmanyah 2',
    'ثمانية 2': 'Thmanyah 2',
    'ثمانيه 3': 'Thmanyah 3',
    'ثمانية 3': 'Thmanyah 3',
  };

  static final Map<String, String> _arToEnTeams =
      _buildNormalizedMap(_rawArToEnTeams);

  static final Map<String, String> _arToEnLeagues =
      _buildNormalizedMap(_rawArToEnLeagues);

  static final Map<String, String> _arToEnChannels =
      _buildNormalizedMap(_rawArToEnChannels);

  static final Map<String, String> _enToArTeams = {
    for (final e in _rawArToEnTeams.entries) e.value.toLowerCase(): e.key,
  };

  static final Map<String, String> _enToArLeagues = {
    for (final e in _rawArToEnLeagues.entries) e.value.toLowerCase(): e.key,
  };

  static final Map<String, String> _enToArChannels = {
    for (final e in _rawArToEnChannels.entries) e.value.toLowerCase(): e.key,
  };

  static Map<String, String> _buildNormalizedMap(Map<String, String> source) {
    final result = <String, String>{};
    for (final entry in source.entries) {
      result[normalizeArabic(entry.key)] = entry.value;
    }
    return result;
  }
}
