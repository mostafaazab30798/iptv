import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/domain/entities/live_fixture.dart';
import 'package:iptv/features/home/widgets/match_poster_layout.dart';

void main() {
  group('MatchPosterLayout', () {
    test('goalRowsForFixture uses distinct scorers per side', () {
      const fixture = LiveFixture(
        homeName: 'A',
        awayName: 'B',
        teams: [],
        homeGoals: [
          MatchGoal(player: 'Alice', minute: "10'"),
          MatchGoal(player: 'Alice', minute: "20'"),
          MatchGoal(player: 'Bob', minute: "30'"),
        ],
        awayGoals: [
          MatchGoal(player: 'Carol', minute: "15'"),
        ],
      );
      expect(MatchPosterLayout.goalRowsForFixture(fixture), 2);
      expect(MatchPosterLayout.goalRowsForFixture(null), 0);
    });

    test('extraHeightForGoals scales with rows', () {
      expect(MatchPosterLayout.extraHeightForGoals(0), 0);
      expect(MatchPosterLayout.extraHeightForGoals(2), 12 + 44);
    });

    test('sizeForWidth breakpoints', () {
      expect(MatchPosterLayout.sizeForWidth(800).width, 420);
      expect(MatchPosterLayout.sizeForWidth(1000).width, 480);
      expect(MatchPosterLayout.sizeForWidth(1300).width, 560);
      expect(MatchPosterLayout.sizeForWidth(1700).width, 640);
      final withGoals = MatchPosterLayout.sizeForWidth(1000, goalRows: 1);
      expect(withGoals.height, 208 + MatchPosterLayout.extraHeightForGoals(1));
    });
  });
}
