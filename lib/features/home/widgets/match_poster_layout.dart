/// Pure layout helpers for home match hero poster sizing.
library;

import 'package:iptv/domain/entities/live_fixture.dart';

abstract final class MatchPosterLayout {
  /// Computes how many distinct player goal rows are needed for a fixture.
  static int goalRowsForFixture(LiveFixture? fixture) {
    if (fixture == null) return 0;
    final homeCount = fixture.homeGoals.map((g) => g.player).toSet().length;
    final awayCount = fixture.awayGoals.map((g) => g.player).toSet().length;
    final maxRows = homeCount > awayCount ? homeCount : awayCount;
    return maxRows;
  }

  /// Extra height to dynamically expand the card so ALL goals fit without truncation.
  static double extraHeightForGoals(int goalRows) {
    if (goalRows <= 0) return 0.0;
    // 12px for divider + margins, plus 22px per goal row
    return 12.0 + (goalRows * 22.0);
  }

  /// Responsive card footprint for landscape / TV heroes.
  static ({double width, double height}) sizeForWidth(
    double screenWidth, {
    int goalRows = 0,
  }) {
    final extraH = extraHeightForGoals(goalRows);
    if (screenWidth >= 1600) {
      return (width: 640.0, height: 248.0 + extraH);
    }
    if (screenWidth >= 1200) {
      return (width: 560.0, height: 228.0 + extraH);
    }
    if (screenWidth >= 900) {
      return (width: 480.0, height: 208.0 + extraH);
    }
    return (width: 420.0, height: 196.0 + extraH);
  }
}
