import 'package:iptv/core/sports/big_match_detector.dart';
import 'package:iptv/domain/entities/live_fixture.dart';
import 'package:iptv/domain/entities/live_match.dart';

/// Resolves the branded wallpaper image asset for a match hero card.
///
/// Rules (in order of priority):
/// 1. Barcelona match -> `assets/images/fcb.jpg`
/// 2. Real Madrid match -> `assets/images/rm.jpg`
/// 3. Al Ahly match -> `assets/images/ahly.jpg`
/// 4. Zamalek match -> `assets/images/zamalek.jpg`
///    (If Ahly vs Zamalek -> Home team's wallpaper)
/// 5. Any Premier League match -> `assets/images/pl.jpg`
/// 6. Any UCL match for our filtered teams -> (`ucl1.jpg`, `ucl2.jpg`, `ucl3.jpg`)
abstract final class MatchWallpaperResolver {
  static const String barcelonaWallpaper = 'assets/images/fcb.jpg';
  static const String realMadridWallpaper = 'assets/images/rm.jpg';
  static const String ahlyWallpaper = 'assets/images/ahly.jpg';
  static const String zamalekWallpaper = 'assets/images/zamalek.jpg';
  static const String premierLeagueWallpaper = 'assets/images/pl.jpg';
  static const List<String> uclWallpapers = [
    'assets/images/ucl1.jpg',
    'assets/images/ucl2.jpg',
    'assets/images/ucl3.jpg',
  ];

  static final RegExp _plRegex = RegExp(
    r'(دوري.*[إا]نجليز|بريمير|premier\s*league|\bepl\b)',
    caseSensitive: false,
  );

  static final RegExp _uclRegex = RegExp(
    r'([أا]بطال\s*[أا]وروبا|تشامبيونز|شامبيونز|uefa\s*champions\s*league|champions\s*league|\bucl\b)',
    caseSensitive: false,
  );

  static final RegExp _nonUclChampionsRegex = RegExp(
    r'([أا]فريق|caf|آسيا|[اأ]سيا|afc)',
    caseSensitive: false,
  );

  /// Resolves the wallpaper asset path for a [LiveMatch]. Returns null if no rule matches.
  static String? resolveWallpaper(LiveMatch match) {
    final fixture = match.fixture;
    final homeText = fixture?.homeName ?? '';
    final awayText = fixture?.awayName ?? '';
    final combinedText =
        '$homeText $awayText ${match.headline} ${match.programTitle} ${match.channel.name}';

    final hasBarca = _hasTeam(
      teamId: 'barcelona',
      teams: match.teams,
      fixtureTeams: fixture?.teams,
      text: combinedText,
    );

    final hasRm = _hasTeam(
      teamId: 'real_madrid',
      teams: match.teams,
      fixtureTeams: fixture?.teams,
      text: combinedText,
    );

    final hasAhly = _hasTeam(
      teamId: 'ahly',
      teams: match.teams,
      fixtureTeams: fixture?.teams,
      text: combinedText,
    );

    final hasZamalek = _hasTeam(
      teamId: 'zamalek',
      teams: match.teams,
      fixtureTeams: fixture?.teams,
      text: combinedText,
    );

    // 1 & 2. European Club-specific wallpapers
    // If the match is Barcelona vs Real Madrid, use Barcelona's image
    if (hasBarca) {
      return barcelonaWallpaper;
    }
    if (hasRm) {
      return realMadridWallpaper;
    }

    // 3 & 4. Egyptian Derby & Club-specific wallpapers
    if (hasAhly && hasZamalek) {
      final homeNorm = BigMatchDetector.normalize(fixture?.homeName ?? '');
      if (homeNorm.contains('زمالك') || homeNorm.contains('zamalek')) {
        return zamalekWallpaper;
      }
      return ahlyWallpaper;
    }
    if (hasAhly) {
      return ahlyWallpaper;
    }
    if (hasZamalek) {
      return zamalekWallpaper;
    }

    // 5. Premier League match
    if (_isPremierLeague(match)) {
      return premierLeagueWallpaper;
    }

    // 6. UCL match for our filtered teams
    if (_isUcl(match)) {
      final seed = '${fixture?.headline ?? match.headline}_${match.channel.streamId}';
      return _pickUclWallpaper(seed);
    }

    return null;
  }

  /// Resolves the wallpaper asset path for a [LiveFixture] directly.
  static String? resolveWallpaperForFixture(LiveFixture fixture) {
    final combinedText = '${fixture.homeName} ${fixture.awayName}';

    final hasBarca = _hasTeam(
      teamId: 'barcelona',
      teams: const [],
      fixtureTeams: fixture.teams,
      text: combinedText,
    );

    final hasRm = _hasTeam(
      teamId: 'real_madrid',
      teams: const [],
      fixtureTeams: fixture.teams,
      text: combinedText,
    );

    final hasAhly = _hasTeam(
      teamId: 'ahly',
      teams: const [],
      fixtureTeams: fixture.teams,
      text: combinedText,
    );

    final hasZamalek = _hasTeam(
      teamId: 'zamalek',
      teams: const [],
      fixtureTeams: fixture.teams,
      text: combinedText,
    );

    if (hasBarca) return barcelonaWallpaper;
    if (hasRm) return realMadridWallpaper;
    if (hasAhly && hasZamalek) {
      final homeNorm = BigMatchDetector.normalize(fixture.homeName);
      if (homeNorm.contains('زمالك') || homeNorm.contains('zamalek')) {
        return zamalekWallpaper;
      }
      return ahlyWallpaper;
    }
    if (hasAhly) return ahlyWallpaper;
    if (hasZamalek) return zamalekWallpaper;

    final league = fixture.league ?? '';
    final normalizedLeague = BigMatchDetector.normalize(league);

    if (_plRegex.hasMatch(league) || _plRegex.hasMatch(normalizedLeague)) {
      return premierLeagueWallpaper;
    }

    if (_isUclLeague(league, normalizedLeague)) {
      return _pickUclWallpaper(fixture.headline);
    }

    return null;
  }

  static bool _hasTeam({
    required String teamId,
    required List<BigTeam> teams,
    required List<BigTeam>? fixtureTeams,
    required String text,
  }) {
    if (teams.any((t) => t.id == teamId)) return true;
    if (fixtureTeams != null && fixtureTeams.any((t) => t.id == teamId)) {
      return true;
    }
    final inText = BigMatchDetector.teamsIn(text);
    if (inText.any((t) => t.id == teamId)) return true;

    final norm = BigMatchDetector.normalize(text);
    if (teamId == 'zamalek') {
      return norm.contains('زمالك') || norm.contains('zamalek');
    }
    if (teamId == 'ahly') {
      if (norm.contains('اهلي جده') || norm.contains('اهلى جده')) {
        return false;
      }
      return norm.contains('الاهلي') ||
          norm.contains('الاهلى') ||
          norm.contains('ahly');
    }
    return false;
  }

  static bool _isPremierLeague(LiveMatch match) {
    final league = match.fixture?.league ?? '';
    final normalizedLeague = BigMatchDetector.normalize(league);
    if (_plRegex.hasMatch(league) || _plRegex.hasMatch(normalizedLeague)) {
      return true;
    }

    final channel = match.channel.name;
    final program = match.programTitle;
    return _plRegex.hasMatch(program) || _plRegex.hasMatch(channel);
  }

  static bool _isUcl(LiveMatch match) {
    final league = match.fixture?.league ?? '';
    final normalizedLeague = BigMatchDetector.normalize(league);
    if (_isUclLeague(league, normalizedLeague)) {
      return true;
    }

    final channel = match.channel.name;
    final program = match.programTitle;
    final text = '$program $channel';

    if (_nonUclChampionsRegex.hasMatch(text)) return false;
    return _uclRegex.hasMatch(text);
  }

  static bool _isUclLeague(String league, String normalizedLeague) {
    if (league.isEmpty) return false;
    // Exclude CAF / AFC Champions League
    if (_nonUclChampionsRegex.hasMatch(league) ||
        _nonUclChampionsRegex.hasMatch(normalizedLeague)) {
      return false;
    }
    return _uclRegex.hasMatch(league) || _uclRegex.hasMatch(normalizedLeague);
  }

  static String _pickUclWallpaper(String seed) {
    final index = seed.hashCode.abs() % uclWallpapers.length;
    return uclWallpapers[index];
  }
}
