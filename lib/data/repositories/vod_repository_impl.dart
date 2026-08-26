import 'package:iptv/core/utils/result.dart';
import 'package:iptv/data/datasources/xtream_remote_datasource.dart';
import 'package:iptv/data/mappers/data_mapper.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/movie.dart';
import 'package:iptv/domain/repositories/vod_repository.dart';

class VodRepositoryImpl implements VodRepository {
  const VodRepositoryImpl({required this.remoteDataSource});

  final XtreamRemoteDataSource remoteDataSource;

  @override
  Future<Result<List<Category>>> getCategories({bool forceRefresh = false}) async {
    try {
      final raw = await remoteDataSource.getVodCategories();
      final categories = raw.map((j) => DataMapper.categoryFromJson(j, CategoryType.vod)).toList();
      return Ok(categories);
    } catch (e) {
      return Err(AppResultError('Failed to load VOD categories', cause: e));
    }
  }

  @override
  Future<Result<List<Movie>>> getMovies({
    int? categoryId,
    bool forceRefresh = false,
  }) async {
    try {
      final raw = await remoteDataSource.getVodStreams(categoryId: categoryId);
      final movies = raw.map(DataMapper.movieFromJson).toList();
      return Ok(movies);
    } catch (e) {
      return Err(AppResultError('Failed to load movies', cause: e));
    }
  }

  @override
  Future<Result<Movie>> getMovieById(int streamId) async {
    try {
      final raw = await remoteDataSource.getVodStreams();
      final item = raw.firstWhere(
        (j) => int.tryParse(j['stream_id']?.toString() ?? '') == streamId,
        orElse: () => throw Exception('Movie not found'),
      );
      return Ok(DataMapper.movieFromJson(item));
    } catch (e) {
      return Err(AppResultError('Movie not found', cause: e));
    }
  }
}
