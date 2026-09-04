import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/data/datasources/fotmob_realtime_datasource.dart';

class _FakeHttpClientAdapter implements HttpClientAdapter {
  _FakeHttpClientAdapter(this.handler);

  final Future<ResponseBody> Function(RequestOptions options) handler;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) {
    return handler(options);
  }

  @override
  void close({bool force = false}) {}
}

void main() {
  group('FotmobMatchItem', () {
    test('parses ongoing live match with elapsed minutes', () {
      final json = {
        'id': 12345,
        'home': {'name': 'Ipswich', 'longName': 'Ipswich Town', 'score': 0},
        'away': {'name': 'Liverpool', 'longName': 'Liverpool', 'score': 2},
        'status': {
          'started': true,
          'ongoing': true,
          'finished': false,
          'scoreStr': '0 - 2',
          'liveTime': {
            'short': '79\u200e’\u200e',
            'long': '78:30',
          },
        },
      };

      final item = FotmobMatchItem.fromJson(json);
      expect(item.id, 12345);
      expect(item.homeScore, 0);
      expect(item.awayScore, 2);
      expect(item.isLive, isTrue);
      expect(item.state, 'in');
      expect(item.resolveClock(), '79’');
    });

    test('parses half-time (HT) match', () {
      final json = {
        'id': 54321,
        'home': {'name': 'Real Betis', 'longName': 'Real Betis', 'score': 0},
        'away': {'name': 'Real Madrid', 'longName': 'Real Madrid', 'score': 0},
        'status': {
          'started': true,
          'ongoing': true,
          'finished': false,
          'scoreStr': '0 - 0',
          'liveTime': {
            'short': 'HT',
            'shortKey': 'halftime_short',
            'long': 'Half-Time',
          },
        },
      };

      final item = FotmobMatchItem.fromJson(json);
      expect(item.isLive, isTrue);
      expect(item.state, 'in');
      expect(item.resolveClock(), 'HT');
    });

    test('parses finished (FT) match', () {
      final json = {
        'id': 9999,
        'home': {'name': 'Ports', 'longName': 'AS Port', 'score': 1},
        'away': {'name': 'Zamalek', 'longName': 'Zamalek SC', 'score': 2},
        'status': {
          'started': true,
          'finished': true,
          'ongoing': false,
          'scoreStr': '1 - 2',
          'reason': {
            'short': 'FT',
            'shortKey': 'fulltime_short',
            'long': 'Full-Time',
          },
        },
      };

      final item = FotmobMatchItem.fromJson(json);
      expect(item.homeScore, 1);
      expect(item.awayScore, 2);
      expect(item.isLive, isFalse);
      expect(item.finished, isTrue);
      expect(item.state, 'post');
      expect(item.resolveClock(), 'FT');
    });

    test('parses extra time (AET) match', () {
      final json = {
        'id': 8888,
        'home': {'name': 'Team A', 'longName': 'Team A FC', 'score': 2},
        'away': {'name': 'Team B', 'longName': 'Team B FC', 'score': 1},
        'status': {
          'started': true,
          'finished': true,
          'ongoing': false,
          'scoreStr': '2 - 1',
          'reason': {
            'short': 'AET',
            'shortKey': 'afterextratime_short',
            'long': 'After extra time',
          },
        },
      };

      final item = FotmobMatchItem.fromJson(json);
      expect(item.finished, isTrue);
      expect(item.state, 'post');
      expect(item.resolveClock(), 'AET');
    });

    test('parses penalty shootout (Pen) match with shootout scores', () {
      final json = {
        'id': 7777,
        'home': {'name': 'Sassuolo', 'score': 1, 'penScore': 4},
        'away': {'name': 'Frosinone', 'score': 1, 'penScore': 3},
        'status': {
          'started': true,
          'finished': true,
          'ongoing': false,
          'scoreStr': '1 - 1',
          'reason': {
            'short': 'Pen',
            'shortKey': 'penalties_short',
            'long': 'After penalties',
          },
        },
      };

      final item = FotmobMatchItem.fromJson(json);
      expect(item.homeScore, 1);
      expect(item.awayScore, 1);
      expect(item.homePenScore, 4);
      expect(item.awayPenScore, 3);
      expect(item.finished, isTrue);
      expect(item.state, 'post');
      expect(item.resolveClock(), 'Pen (4-3)');
    });

    test('parses upcoming match', () {
      final json = {
        'id': 6666,
        'home': {'name': 'Barcelona', 'longName': 'FC Barcelona'},
        'away': {'name': 'Valencia', 'longName': 'Valencia CF'},
        'time': '22:00',
        'status': {
          'started': false,
          'ongoing': false,
          'finished': false,
        },
      };

      final item = FotmobMatchItem.fromJson(json);
      expect(item.homeScore, isNull);
      expect(item.awayScore, isNull);
      expect(item.state, 'pre');
      expect(item.resolveClock(fallbackTime: '22:00'), '22:00');
    });
  });

  group('FotmobRealtimeDataSource', () {
    setUp(FotmobRealtimeDataSource.clearCache);

    test('fetches and parses leagues and matches correctly', () async {
      final requestedUrls = <String>[];
      final dio = Dio();
      dio.httpClientAdapter = _FakeHttpClientAdapter((options) async {
        requestedUrls.add(options.uri.toString());
        final sampleJson = jsonEncode({
          'leagues': [
            {
              'id': 47,
              'name': 'Premier League',
              'matches': [
                {
                  'id': 101,
                  'home': {'name': 'Ipswich', 'longName': 'Ipswich Town', 'score': 0},
                  'away': {'name': 'Liverpool', 'longName': 'Liverpool', 'score': 2},
                  'status': {
                    'started': true,
                    'ongoing': true,
                    'finished': false,
                    'scoreStr': '0 - 2',
                    'liveTime': {'short': '82’'},
                  },
                }
              ]
            }
          ]
        });

        return ResponseBody.fromString(
          sampleJson,
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      });

      final ds = FotmobRealtimeDataSource(dio: dio);
      final matches = await ds.fetchMatches(forceRefresh: true);

      expect(matches, hasLength(1));
      expect(matches.first.id, 101);
      expect(matches.first.homeName, 'Ipswich');
      expect(matches.first.awayName, 'Liverpool');
      expect(matches.first.homeScore, 0);
      expect(matches.first.awayScore, 2);
      expect(matches.first.resolveClock(), '82’');
      expect(requestedUrls.first, contains('date='));
    });

    test('findMatchFor accurately matches Arabic names against FotMob matches', () {
      final ds = FotmobRealtimeDataSource();
      final fotmobMatches = [
        const FotmobMatchItem(
          id: 1,
          homeName: 'Ipswich',
          homeLongName: 'Ipswich Town',
          awayName: 'Liverpool',
          awayLongName: 'Liverpool',
          homeScore: 0,
          awayScore: 2,
          ongoing: true,
          liveTimeShort: '82’',
        ),
        const FotmobMatchItem(
          id: 2,
          homeName: 'Ports',
          homeLongName: 'AS Port',
          awayName: 'Zamalek',
          awayLongName: 'Zamalek SC',
          homeScore: 1,
          awayScore: 2,
          finished: true,
          reasonShort: 'FT',
        ),
        const FotmobMatchItem(
          id: 3,
          homeName: 'Real Betis',
          homeLongName: 'Real Betis',
          awayName: 'Real Madrid',
          awayLongName: 'Real Madrid',
          homeScore: 0,
          awayScore: 0,
          ongoing: true,
          liveTimeShort: '73’',
        ),
      ];

      // Match 1: إيبسويتش تاون vs ليفربول
      final match1 = ds.findMatchFor(
        fotmobMatches: fotmobMatches,
        homeName: 'إيبسويتش تاون',
        awayName: 'ليفربول',
      );
      expect(match1, isNotNull);
      expect(match1!.id, 1);
      expect(match1.homeScore, 0);
      expect(match1.awayScore, 2);

      // Match 2: إيه أس بورت vs الزمالك
      final match2 = ds.findMatchFor(
        fotmobMatches: fotmobMatches,
        homeName: 'إيه أس بورت',
        awayName: 'الزمالك',
      );
      expect(match2, isNotNull);
      expect(match2!.id, 2);
      expect(match2.homeScore, 1);
      expect(match2.awayScore, 2);

      // Match 3: ريال بيتيس vs ريال مدريد
      final match3 = ds.findMatchFor(
        fotmobMatches: fotmobMatches,
        homeName: 'ريال بيتيس',
        awayName: 'ريال مدريد',
      );
      expect(match3, isNotNull);
      expect(match3!.id, 3);
      expect(match3.homeScore, 0);
      expect(match3.awayScore, 0);
    });

    test('returns empty list gracefully if FotMob endpoint errors', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeHttpClientAdapter((options) async {
        return ResponseBody.fromString('Bad Gateway', 502);
      });

      final ds = FotmobRealtimeDataSource(dio: dio);
      final matches = await ds.fetchMatches(forceRefresh: true);
      expect(matches, isEmpty);
    });

    test('parseTeamGoals parses player name, minute, own goals, and penalties correctly', () {
      final rawGoals = {
        'Bacher': [
          {
            'nameStr': 'Felix Bacher',
            'timeStr': 28,
            'isPenaltyShootoutEvent': false,
            'ownGoal': false,
          },
        ],
        'Salah': [
          {
            'nameStr': 'Mohamed Salah',
            'time': 65,
            'suffix': 'P',
            'isPenaltyShootoutEvent': false,
          },
          {
            'nameStr': 'Mohamed Salah',
            'time': 12,
            'isPenaltyShootoutEvent': false,
          }
        ],
        'Disasi': [
          {
            'nameStr': 'Axel Disasi',
            'timeStr': 88,
            'ownGoal': true,
            'isPenaltyShootoutEvent': false,
          }
        ],
        'ShootoutPlayer': [
          {
            'nameStr': 'Penalty Scorer',
            'timeStr': 120,
            'isPenaltyShootoutEvent': true,
          }
        ]
      };

      final parsed = FotmobRealtimeDataSource.parseTeamGoals(rawGoals);
      // ShootoutPlayer must be excluded
      expect(parsed.length, 4);
      // Must be sorted by minute: 12', 28', 65', 88'
      expect(parsed[0].player, 'Mohamed Salah');
      expect(parsed[0].minute, "12'");
      expect(parsed[0].isPenalty, isFalse);
      expect(parsed[0].isOwnGoal, isFalse);

      expect(parsed[1].player, 'Felix Bacher');
      expect(parsed[1].minute, "28'");

      expect(parsed[2].player, 'Mohamed Salah');
      expect(parsed[2].minute, "65'");
      expect(parsed[2].isPenalty, isTrue);

      expect(parsed[3].player, 'Axel Disasi');
      expect(parsed[3].minute, "88'");
      expect(parsed[3].isOwnGoal, isTrue);
    });

    test('fetchMatchGoals retrieves and caches match goals for matchId', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeHttpClientAdapter((options) async {
        final sampleDetails = jsonEncode({
          'header': {
            'events': {
              'homeTeamGoals': {
                'Haaland': [
                  {'nameStr': 'Erling Haaland', 'timeStr': 23, 'isPenaltyShootoutEvent': false}
                ]
              },
              'awayTeamGoals': {
                'Son': [
                  {'nameStr': 'Heung-min Son', 'timeStr': 49, 'isPenaltyShootoutEvent': false}
                ]
              }
            }
          }
        });
        return ResponseBody.fromString(sampleDetails, 200);
      });

      final ds = FotmobRealtimeDataSource(dio: dio);
      final goals = await ds.fetchMatchGoals(12345, forceRefresh: true);

      expect(goals.homeGoals.length, 1);
      expect(goals.homeGoals.first.player, 'Erling Haaland');
      expect(goals.homeGoals.first.minute, "23'");

      expect(goals.awayGoals.length, 1);
      expect(goals.awayGoals.first.player, 'Heung-min Son');
      expect(goals.awayGoals.first.minute, "49'");
    });

    test('fetchMatches merges yesterday evening matches when called in early morning', () async {
      final requestedUrls = <String>[];
      final dio = Dio();
      dio.httpClientAdapter = _FakeHttpClientAdapter((options) async {
        final url = options.uri.toString();
        requestedUrls.add(url);
        if (url.contains('date=20260904')) {
          return ResponseBody.fromString(
            jsonEncode({
              'leagues': [
                {
                  'matches': [
                    {
                      'id': 101,
                      'home': {'name': 'Ipswich', 'score': 0},
                      'away': {'name': 'Liverpool', 'score': 2},
                      'status': {'finished': true, 'reason': {'short': 'FT'}},
                    }
                  ]
                }
              ]
            }),
            200,
            headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
          );
        }
        return ResponseBody.fromString(
          jsonEncode({
            'leagues': [
              {
                'matches': [
                  {
                    'id': 202,
                    'home': {'name': 'Valencia', 'score': 0},
                    'away': {'name': 'Celta', 'score': 0},
                    'status': {'started': false},
                  }
                ]
              }
            ]
          }),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      });

      final ds = FotmobRealtimeDataSource(dio: dio);
      final matches = await ds.fetchMatches(forceRefresh: true);
      // Both yesterday's and today's matches must be merged
      expect(matches.any((m) => m.id == 101), isTrue);
      expect(matches.any((m) => m.id == 202), isTrue);
    });

    test('fetchMatches with targetTeams includes teams query param and filters non-target matches', () async {
      final requestedUris = <Uri>[];
      final dio = Dio();
      dio.httpClientAdapter = _FakeHttpClientAdapter((options) async {
        requestedUris.add(options.uri);
        return ResponseBody.fromString(
          jsonEncode({
            'leagues': [
              {
                'matches': [
                  {
                    'id': 1,
                    'home': {'name': 'Liverpool', 'score': 3},
                    'away': {'name': 'Arsenal', 'score': 1},
                    'status': {'finished': true},
                  },
                  {
                    'id': 2,
                    'home': {'name': 'Random FC', 'score': 0},
                    'away': {'name': 'Other Club', 'score': 0},
                    'status': {'finished': true},
                  }
                ]
              }
            ]
          }),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
      });

      final ds = FotmobRealtimeDataSource(dio: dio);
      final matches = await ds.fetchMatches(
        forceRefresh: true,
        targetTeams: {'ليفربول'}, // Arabic team name
      );

      // Verify the request sent to proxy included the localized teams query parameter
      expect(requestedUris.any((uri) => uri.queryParameters.containsKey('teams')), isTrue);
      // Verify only Liverpool match is retained, Random FC is filtered out
      expect(matches.length, 1);
      expect(matches.first.id, 1);
      expect(matches.first.homeName, 'Liverpool');
    });
  });
}

