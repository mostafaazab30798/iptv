import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/sports/big_match_detector.dart';
import 'package:iptv/core/sports/live_match_finder.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/entities/live_fixture.dart';

Channel _ch(int id, String name) {
  return Channel(
    id: id,
    serverId: 1,
    streamId: id,
    name: name,
    categoryId: 1,
  );
}

void main() {
  final liverpool = BigMatchDetector.teamsIn('Liverpool').first;

  final fixture = LiveFixture(
    homeName: 'Ipswich Town',
    awayName: 'Liverpool',
    teams: [liverpool],
    state: 'in',
    clock: "67'",
    league: 'English Premier League',
  );

  test('binds a live fixture to the Arabic sports channel showing it', () {
    final matches = LiveMatchFinder.bindFixtures(
      fixtures: [fixture],
      channels: [
        _ch(1, 'Barcelona TV HD'),
        _ch(2, 'Liverpool TV'),
        _ch(3, 'Sky Sports 1'),
        _ch(4, 'AD Sports 1 HD'),
        _ch(5, 'AD Sports 1 4K'),
        _ch(6, 'beIN Sports 1 HD'),
      ],
      epgTitles: {
        4: 'Ipswich Town vs Liverpool',
        5: 'Ipswich Town vs Liverpool',
        6: 'Studio',
      },
    );

    expect(matches, hasLength(1));
    expect(matches.first.channel.streamId, 5);
    expect(matches.first.channel.name, contains('AD Sports'));
    expect(matches.first.resolutionLabel, '4K');
  });

  test('does not treat club TV as a match even when the team name matches', () {
    final matches = LiveMatchFinder.bindFixtures(
      fixtures: [fixture],
      channels: [
        _ch(1, 'Liverpool TV 4K'),
        _ch(2, 'FC Barcelona TV'),
      ],
      epgTitles: {1: 'Ipswich Town vs Liverpool'},
    );
    expect(matches, isEmpty);
  });

  test('prefers a 4K beIN event stream over HD', () {
    final barcaReal = LiveFixture(
      homeName: 'Barcelona',
      awayName: 'Real Madrid',
      teams: BigMatchDetector.teamsIn('Barcelona Real Madrid'),
      state: 'in',
    );
    final matches = LiveMatchFinder.bindFixtures(
      fixtures: [barcaReal],
      channels: [
        _ch(10, '|AR| Barcelona vs Real Madrid HD'),
        _ch(11, '|AR| Barcelona vs Real Madrid 4K'),
        _ch(12, 'beIN Sports 1 HD'),
      ],
    );
    expect(matches.single.channel.streamId, 11);
  });

  test('still binds a live cup match when EPG never names the teams', () {
    final matches = LiveMatchFinder.bindFixtures(
      fixtures: [fixture],
      channels: [
        _ch(1, 'Barcelona TV HD'),
        _ch(2, 'Sky Sports 1'),
        _ch(3, 'AD Sports 1 HD'),
        _ch(4, 'beIN Sports 1 4K'),
        _ch(5, 'beIN Sports 2 HD'),
      ],
    );

    expect(matches, hasLength(1));
    expect(matches.single.channel.streamId, 4);
    expect(matches.single.fixture?.awayName, 'Liverpool');
  });
}
