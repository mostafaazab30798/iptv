import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/series.dart';
import 'package:iptv/domain/entities/season.dart';

abstract interface class SeriesRepository {
  Future<Result<List<Category>>> getCategories({bool forceRefresh = false});
  Future<Result<List<Series>>> getSeries({
    int? categoryId,
    bool forceRefresh = false,
  });
  Future<Result<List<Season>>> getSeasons(int seriesId);
}
