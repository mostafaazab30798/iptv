import 'package:flutter_test/flutter_test.dart';
import 'package:iptv/data/mappers/data_mapper.dart';
import 'package:iptv/domain/entities/movie.dart';

void main() {
  group('Movie domain entity', () {
    test('copyWith updates fields correctly', () {
      const movie = Movie(
        id: 1,
        serverId: 1,
        streamId: 100,
        name: 'Inception',
      );

      final updated = movie.copyWith(
        plot: 'A thief who steals corporate secrets...',
        cast: 'Leonardo DiCaprio, Joseph Gordon-Levitt',
        director: 'Christopher Nolan',
        genre: 'Sci-Fi, Action',
        rating: '8.8',
        releaseYear: 2010,
        durationSecs: 8880,
        videoResolution: '4K',
        country: 'USA',
        backdropPaths: ['https://example.com/backdrop1.jpg'],
      );

      expect(updated.name, 'Inception');
      expect(updated.plot, contains('corporate secrets'));
      expect(updated.cast, contains('Leonardo DiCaprio'));
      expect(updated.director, 'Christopher Nolan');
      expect(updated.videoResolution, '4K');
      expect(updated.backdropPaths?.length, 1);
      expect(updated.duration?.inMinutes, 148);
    });
  });

  group('DataMapper movie parsing', () {
    test('movieFromJson parses basic and extended fields', () {
      final json = {
        'num': 1,
        'name': 'Interstellar',
        'stream_id': 200,
        'stream_icon': 'https://example.com/icon.jpg',
        'rating': '8.7',
        'plot': 'A team of explorers travel through a wormhole in space.',
        'cast': 'Matthew McConaughey, Anne Hathaway',
        'director': 'Christopher Nolan',
        'genre': 'Adventure, Drama, Sci-Fi',
        'year': '2014',
        'duration_secs': 10140,
        'container_extension': 'mkv',
      };

      final movie = DataMapper.movieFromJson(json);

      expect(movie.streamId, 200);
      expect(movie.name, 'Interstellar');
      expect(movie.streamIcon, 'https://example.com/icon.jpg');
      expect(movie.rating, '8.7');
      expect(movie.plot, contains('wormhole'));
      expect(movie.cast, contains('Matthew McConaughey'));
      expect(movie.director, 'Christopher Nolan');
      expect(movie.genre, 'Adventure, Drama, Sci-Fi');
      expect(movie.releaseYear, 2014);
      expect(movie.durationSecs, 10140);
      expect(movie.containerExtension, 'mkv');
    });

    test('movieFromVodInfo extracts rich info including resolution and backdrops', () {
      const baseMovie = Movie(
        id: 300,
        serverId: 1,
        streamId: 300,
        name: 'Oppenheimer',
      );

      final vodInfoJson = {
        'info': {
          'name': 'Oppenheimer',
          'plot': 'The story of American scientist J. Robert Oppenheimer.',
          'actors': 'Cillian Murphy, Emily Blunt, Matt Damon',
          'director': 'Christopher Nolan',
          'genre': 'Biography, Drama, History',
          'rating': '8.9',
          'releasedate': '2023-07-21',
          'duration': '03:00:09',
          'country': 'United States',
          'age': 'R',
          'backdrop_path': [
            'https://example.com/oppenheimer_bg1.jpg',
            'https://example.com/oppenheimer_bg2.jpg',
          ],
          'video': {
            'width': 3840,
            'height': 2160,
          },
        },
        'movie_data': {
          'stream_id': 300,
          'name': 'Oppenheimer',
          'container_extension': 'mp4',
        },
      };

      final enriched = DataMapper.movieFromVodInfo(vodInfoJson, baseMovie);

      expect(enriched.streamId, 300);
      expect(enriched.name, 'Oppenheimer');
      expect(enriched.plot, contains('J. Robert Oppenheimer'));
      expect(enriched.cast, contains('Cillian Murphy'));
      expect(enriched.director, 'Christopher Nolan');
      expect(enriched.genre, 'Biography, Drama, History');
      expect(enriched.releaseDate, '2023-07-21');
      expect(enriched.releaseYear, 2023);
      expect(enriched.durationSecs, 10809);
      expect(enriched.country, 'United States');
      expect(enriched.mpaaRating, 'R');
      expect(enriched.backdropPaths?.length, 2);
      expect(enriched.videoResolution, '4K');
      expect(enriched.containerExtension, 'mp4');
    });

    test('parseRating handles diverse formats and filters out 0 ratings', () {
      // Direct numeric and string ratings
      expect(DataMapper.parseRating('8.7'), '8.7');
      expect(DataMapper.parseRating(8.7), '8.7');
      expect(DataMapper.parseRating(8), '8.0');
      expect(DataMapper.parseRating('8.0'), '8.0');
      expect(DataMapper.parseRating('8,5'), '8.5');
      expect(DataMapper.parseRating('8.5/10'), '8.5');
      expect(DataMapper.parseRating('4/5'), '8.0');
      expect(DataMapper.parseRating(7.800000190734863), '7.8');

      // 0, empty, and invalid strings return null
      expect(DataMapper.parseRating('0'), isNull);
      expect(DataMapper.parseRating('0.0'), isNull);
      expect(DataMapper.parseRating(0), isNull);
      expect(DataMapper.parseRating(0.0), isNull);
      expect(DataMapper.parseRating(''), isNull);
      expect(DataMapper.parseRating(null), isNull);
      expect(DataMapper.parseRating('null'), isNull);
      expect(DataMapper.parseRating('N/A'), isNull);

      // Fallback to 5-based rating if direct rating is missing or 0
      expect(DataMapper.parseRating('0', 4.3), '8.6');
      expect(DataMapper.parseRating(null, '4.5'), '9.0');
      expect(DataMapper.parseRating('0', 0), isNull);
      expect(DataMapper.parseRating(null, null), isNull);
    });

    test('movieFromJson and seriesFromJson map zero rating to null', () {
      final zeroMovieJson = {
        'num': 1,
        'name': 'Unrated Movie',
        'stream_id': 500,
        'rating': '0',
        'rating_5based': 0,
      };
      final movie = DataMapper.movieFromJson(zeroMovieJson);
      expect(movie.rating, isNull);

      final zeroSeriesJson = {
        'series_id': 600,
        'name': 'Unrated Series',
        'rating': '0.0',
        'rating_5based': '0',
      };
      final series = DataMapper.seriesFromJson(zeroSeriesJson);
      expect(series.rating, isNull);

      final ratedSeriesJson = {
        'series_id': 601,
        'name': 'Great Series',
        'rating': '9.2',
      };
      final ratedSeries = DataMapper.seriesFromJson(ratedSeriesJson);
      expect(ratedSeries.rating, '9.2');
    });
  });
}
