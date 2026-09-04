import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/data/datasources/yallakora_matches_datasource.dart';

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
  group('YallakoraMatchesDataSource', () {
    test('uses matches.hope-tv.site as defaultEndpointUrl', () {
      expect(
        YallakoraMatchesDataSource.defaultEndpointUrl,
        'https://matches.hope-tv.site/matches.json',
      );
    });

    test('successfully fetches and parses matches from matches.hope-tv.site', () async {
      final requestedUrls = <String>[];
      final dio = Dio();
      dio.httpClientAdapter = _FakeHttpClientAdapter((options) async {
        requestedUrls.add(options.uri.toString());
        final sampleJson = jsonEncode([
          {
            'league': 'الدوري الإنجليزي',
            'team_home': 'ليفربول',
            'team_away': 'مانشستر سيتي',
            'logo_home': 'https://example.com/liv.png',
            'logo_away': 'https://example.com/city.png',
            'score_home': '2',
            'score_away': '1',
            'time': '18:30',
            'status': 'جارية',
            'channel': 'beIN Sports 1 HD',
          }
        ]);

        return ResponseBody.fromString(
          sampleJson,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final dataSource = YallakoraMatchesDataSource(dio: dio);
      final matches = await dataSource.fetchTodayMatches(forceRefresh: true);

      expect(matches, hasLength(1));
      expect(matches.first.teamHome, 'ليفربول');
      expect(matches.first.teamAway, 'مانشستر سيتي');
      expect(requestedUrls.first, 'https://matches.hope-tv.site/matches.json');

      final fixtures = await dataSource.fetchLiveBigMatches();
      expect(fixtures, hasLength(1));
      expect(fixtures.first.homeName, 'ليفربول');
    });

    test('falls back to raw GitHub when candidate returns placeholder Hello world', () async {
      final requestedUrls = <String>[];
      final dio = Dio();
      dio.httpClientAdapter = _FakeHttpClientAdapter((options) async {
        final url = options.uri.toString();
        requestedUrls.add(url);

        if (url.contains('matches.hope-tv.site')) {
          // Emulate initial "Hello world" response
          return ResponseBody.fromString(
            'Hello world',
            200,
            headers: {
              Headers.contentTypeHeader: ['text/plain;charset=UTF-8'],
            },
          );
        }

        // GitHub raw fallback succeeds
        final sampleJson = jsonEncode([
          {
            'league': 'دوري أبطال أفريقيا',
            'team_home': 'الأهلي',
            'team_away': 'الترجي',
            'logo_home': 'https://example.com/ahly.png',
            'logo_away': 'https://example.com/taraji.png',
            'score_home': '1',
            'score_away': '0',
            'time': '21:00',
            'status': 'جارية',
            'channel': 'beIN Sports 4 HD',
          }
        ]);

        return ResponseBody.fromString(
          sampleJson,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final dataSource = YallakoraMatchesDataSource(dio: dio);
      final matches = await dataSource.fetchTodayMatches(forceRefresh: true);

      expect(matches, hasLength(1));
      expect(matches.first.teamHome, 'الأهلي');
      expect(matches.first.teamAway, 'الترجي');
      expect(
        requestedUrls,
        contains('https://raw.githubusercontent.com/mostafaazab30798/iptv/main/matches.json'),
      );
    });

    test('fetchLiveBigMatches filters to ONLY Barcelona, Real Madrid, and PL Big Six', () async {
      final dio = Dio();
      dio.httpClientAdapter = _FakeHttpClientAdapter((options) async {
        final sampleJson = jsonEncode([
          {
            'league': 'الدوري المصري',
            'team_home': 'إيه أس بورت',
            'team_away': 'الزمالك',
            'time': '20:00',
            'status': 'لم تبدأ',
            'channel': 'ON Sport',
          },
          {
            'league': 'الدوري الإنجليزي',
            'team_home': 'إيبسويتش تاون',
            'team_away': 'ليفربول',
            'time': '22:00',
            'status': 'لم تبدأ',
            'channel': 'beIN Sports 2 HD',
          },
          {
            'league': 'الدوري الإسباني',
            'team_home': 'ريال بيتيس',
            'team_away': 'ريال مدريد',
            'time': '22:00',
            'status': 'لم تبدأ',
            'channel': 'beIN Sports 3 HD',
          },
          {
            'league': 'دوري أبطال أوروبا',
            'team_home': 'باريس سان جيرمان',
            'team_away': 'برشلونة',
            'time': '21:00',
            'status': 'جارية',
            'channel': 'beIN Sports 1 HD',
          },
          {
            'league': 'الدوري الإيطالي',
            'team_home': 'جنوى',
            'team_away': 'كومو',
            'time': '19:30',
            'status': 'لم تبدأ',
            'channel': 'AD Sports',
          },
        ]);

        return ResponseBody.fromString(
          sampleJson,
          200,
          headers: {
            Headers.contentTypeHeader: [Headers.jsonContentType],
          },
        );
      });

      final dataSource = YallakoraMatchesDataSource(dio: dio);
      // Raw list returns all 5
      final allMatches = await dataSource.fetchTodayMatches(forceRefresh: true);
      expect(allMatches, hasLength(5));

      // fetchLiveBigMatches filters down to only Liverpool, Real Madrid, Barcelona (3 matches)
      final bigMatches = await dataSource.fetchLiveBigMatches();
      expect(bigMatches, hasLength(3));
      final names = bigMatches.map((m) => '${m.homeName} vs ${m.awayName}').toList();
      expect(names, contains('إيبسويتش تاون vs ليفربول'));
      expect(names, contains('ريال بيتيس vs ريال مدريد'));
      expect(names, contains('باريس سان جيرمان vs برشلونة'));

      // Live match (PSG vs Barcelona) sorted first!
      expect(bigMatches.first.homeName, 'باريس سان جيرمان');
      expect(bigMatches.first.awayName, 'برشلونة');
      expect(bigMatches.first.isLive, isTrue);
    });
  });
}
