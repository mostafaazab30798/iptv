import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/movie.dart';

abstract interface class VodRepository {
  Future<Result<List<Category>>> getCategories({bool forceRefresh = false});
  Future<Result<List<Movie>>> getMovies({
    int? categoryId,
    bool forceRefresh = false,
  });
  Future<Result<Movie>> getMovieById(int streamId);
}
