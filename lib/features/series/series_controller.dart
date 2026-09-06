import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/series.dart';
import 'package:iptv/domain/repositories/series_repository.dart';
import 'package:iptv/features/catalog/catalog_controller.dart';

typedef SeriesState = CatalogState<Series, String?>;

extension SeriesStateX on SeriesState {
  List<Series> get filteredSeries => filteredItems;
  List<Series> get seriesList => filteredItems;
  int get totalSeriesCount => totalCount;
  Map<int, String?> get categoryLeadingCovers => categoryLeading;
}

class SeriesController extends CatalogController<Series, String?> {
  SeriesController(this._seriesRepo);

  final SeriesRepository? _seriesRepo;

  @override
  bool get hasRepository => _seriesRepo != null;

  @override
  Future<Result<List<Category>>> fetchCategories({
    required bool forceRefresh,
  }) {
    return _seriesRepo!.getCategories(forceRefresh: forceRefresh);
  }

  @override
  Future<Result<List<Series>>> fetchItems({
    int? categoryId,
    required bool forceRefresh,
  }) {
    return _seriesRepo!.getSeries(
      categoryId: categoryId,
      forceRefresh: forceRefresh,
    );
  }

  @override
  int? categoryIdOf(Series item) => item.categoryId;

  @override
  String nameOf(Series item) => item.name;

  @override
  Object itemKey(Series item) => item.seriesId;

  @override
  String? leadingOf(Series item) {
    final cover = item.cover;
    if (cover == null || cover.isEmpty) return null;
    return cover;
  }

  Future<void> selectCategory(int? categoryId) =>
      selectCategoryAsync(categoryId);

  void showAllSeries() => showAllItems();
}

final seriesControllerProvider =
    StateNotifierProvider.autoDispose<SeriesController, SeriesState>((ref) {
      final repo = ref.watch(seriesRepositoryProvider);
      return SeriesController(repo);
    });
