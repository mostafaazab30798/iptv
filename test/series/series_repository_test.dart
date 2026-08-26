import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/core/network/api_client.dart';
import 'package:iptv/core/network/api_config.dart';
import 'package:iptv/data/datasources/xtream_remote_datasource.dart';
import 'package:iptv/data/mappers/data_mapper.dart';
import 'package:iptv/data/repositories/series_repository_impl.dart';

class FakeXtreamRemoteDataSource extends XtreamRemoteDataSource {
  FakeXtreamRemoteDataSource(this.mockSeriesInfo)
      : super(ApiClient(const ApiConfig(baseUrl: 'http://example.com', username: 'u', password: 'p')));

  final Map<String, dynamic> mockSeriesInfo;

  @override
  Future<Map<String, dynamic>> getSeriesInfo(int seriesId) async {
    return mockSeriesInfo;
  }
}

void main() {
  group('DataMapper.seriesFromJson', () {
    test('Correctly prioritizes series_id over num index', () {
      final json = {
        'num': 1,
        'name': 'Game of Thrones',
        'series_id': 1452,
        'cover': 'http://example.com/got.jpg',
        'rating': '9.3',
        'category_id': '4',
      };

      final series = DataMapper.seriesFromJson(json);

      expect(series.seriesId, 1452);
      expect(series.id, 1452);
      expect(series.name, 'Game of Thrones');
      expect(series.cover, 'http://example.com/got.jpg');
      expect(series.categoryId, 4);
    });
  });

  group('SeriesRepositoryImpl.getSeasons', () {
    test('parses standard seasons list and episodes map', () async {
      final payload = {
        'seasons': [
          {
            'air_date': '2008-01-20',
            'episode_count': 7,
            'id': 1,
            'name': 'Season 1',
            'season_number': 1,
            'cover': 'http://example.com/s1.jpg',
          },
          {
            'air_date': '2009-03-08',
            'episode_count': 13,
            'id': 2,
            'name': 'Season 2',
            'season_number': 2,
            'cover': 'http://example.com/s2.jpg',
          }
        ],
        'episodes': {
          '1': [
            {
              'id': '101',
              'episode_num': 1,
              'title': 'Pilot',
              'container_extension': 'mkv',
              'info': {
                'name': 'Pilot Episode',
                'plot': 'A chemistry teacher...',
                'duration_secs': 3480,
                'movie_image': 'http://example.com/ep1.jpg',
              }
            },
            {
              'id': '102',
              'episode_num': 2,
              'title': 'Cat\'s in the Bag...',
              'container_extension': 'mp4',
              'info': {
                'name': 'Cat\'s in the Bag',
                'duration': '00:48:00',
              }
            }
          ],
          '2': [
            {
              'id': '201',
              'episode_num': 1,
              'title': 'Seven Thirty-Seven',
              'container_extension': 'mp4',
            }
          ]
        }
      };

      final repo = SeriesRepositoryImpl(
        remoteDataSource: FakeXtreamRemoteDataSource(payload),
      );

      final result = await repo.getSeasons(1452);

      expect(result.isOk, isTrue);
      final seasons = result.value;
      expect(seasons.length, 2);

      // Season 1
      expect(seasons[0].seasonNumber, 1);
      expect(seasons[0].name, 'Season 1');
      expect(seasons[0].cover, 'http://example.com/s1.jpg');
      expect(seasons[0].episodes.length, 2);

      final ep1 = seasons[0].episodes[0];
      expect(ep1.id, 101);
      expect(ep1.streamId, 101);
      expect(ep1.episodeNum, 1);
      expect(ep1.title, 'Pilot Episode');
      expect(ep1.containerExtension, 'mkv');
      expect(ep1.durationSecs, 3480);
      expect(ep1.plot, 'A chemistry teacher...');
      expect(ep1.cover, 'http://example.com/ep1.jpg');

      final ep2 = seasons[0].episodes[1];
      expect(ep2.id, 102);
      expect(ep2.title, 'Cat\'s in the Bag');
      expect(ep2.durationSecs, 2880); // 48 mins converted from "00:48:00"

      // Season 2
      expect(seasons[1].seasonNumber, 2);
      expect(seasons[1].episodes.length, 1);
      expect(seasons[1].episodes[0].id, 201);
      expect(seasons[1].episodes[0].title, 'Seven Thirty-Seven');
    });

    test('handles seasons returned as a Map instead of List', () async {
      final payload = {
        'seasons': {
          '1': {
            'season_number': 1,
            'name': 'First Season',
            'cover': 'http://example.com/s1.jpg',
          },
        },
        'episodes': {
          '1': [
            {
              'id': '501',
              'episode_num': 1,
              'name': 'The Awakening',
              'container_extension': 'mp4',
            }
          ]
        }
      };

      final repo = SeriesRepositoryImpl(
        remoteDataSource: FakeXtreamRemoteDataSource(payload),
      );

      final result = await repo.getSeasons(999);
      expect(result.isOk, isTrue);
      final seasons = result.value;
      expect(seasons.length, 1);
      expect(seasons[0].seasonNumber, 1);
      expect(seasons[0].name, 'First Season');
      expect(seasons[0].episodes.length, 1);
      expect(seasons[0].episodes[0].title, 'The Awakening');
    });

    test('derives seasons when seasons array is empty but episodes map is populated', () async {
      final payload = {
        'seasons': <dynamic>[],
        'episodes': {
          '1': [
            {
              'id': '801',
              'episode_num': 1,
              'title': 'Standalone Ep 1',
              'container_extension': 'mp4',
            }
          ],
          '2': [
            {
              'id': '802',
              'episode_num': 1,
              'title': 'Standalone Ep 2',
              'container_extension': 'mp4',
            }
          ]
        }
      };

      final repo = SeriesRepositoryImpl(
        remoteDataSource: FakeXtreamRemoteDataSource(payload),
      );

      final result = await repo.getSeasons(123);
      expect(result.isOk, isTrue);
      final seasons = result.value;
      expect(seasons.length, 2);
      expect(seasons[0].seasonNumber, 1);
      expect(seasons[0].name, 'Season 1');
      expect(seasons[0].episodes[0].title, 'Standalone Ep 1');
      expect(seasons[1].seasonNumber, 2);
      expect(seasons[1].episodes[0].title, 'Standalone Ep 2');
    });

    test('handles episodes as flat list with season numbers', () async {
      final payload = {
        'seasons': null,
        'episodes': [
          {
            'id': '901',
            'season': 1,
            'episode_num': 1,
            'title': 'Flat List Ep 1',
          },
          {
            'id': '902',
            'season': 1,
            'episode_num': 2,
            'title': 'Flat List Ep 2',
          }
        ]
      };

      final repo = SeriesRepositoryImpl(
        remoteDataSource: FakeXtreamRemoteDataSource(payload),
      );

      final result = await repo.getSeasons(456);
      expect(result.isOk, isTrue);
      final seasons = result.value;
      expect(seasons.length, 1);
      expect(seasons[0].seasonNumber, 1);
      expect(seasons[0].episodes.length, 2);
      expect(seasons[0].episodes[0].title, 'Flat List Ep 1');
      expect(seasons[0].episodes[1].title, 'Flat List Ep 2');
    });
  });
}
