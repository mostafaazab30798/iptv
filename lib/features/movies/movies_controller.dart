import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/movie.dart';
import 'package:iptv/domain/repositories/vod_repository.dart';
import 'package:iptv/features/catalog/catalog_controller.dart';

typedef MoviesState = CatalogState<Movie, String?>;

extension MoviesStateX on MoviesState {
  List<Movie> get filteredMovies => filteredItems;
  List<Movie> get movies => filteredItems;
  int get totalMovieCount => totalCount;
  Map<int, String?> get categoryLeadingLogos => categoryLeading;
}

class MoviesController extends CatalogController<Movie, String?> {
  MoviesController(this._vodRepo);

  final VodRepository? _vodRepo;

  @override
  bool get hasRepository => _vodRepo != null;

  @override
  bool get mergeOnDemandIntoCatalog => true;

  @override
  Future<Result<List<Category>>> fetchCategories({
    required bool forceRefresh,
  }) {
    return _vodRepo!.getCategories(forceRefresh: forceRefresh);
  }

  @override
  Future<Result<List<Movie>>> fetchItems({
    int? categoryId,
    required bool forceRefresh,
  }) {
    return _vodRepo!.getMovies(
      categoryId: categoryId,
      forceRefresh: forceRefresh,
    );
  }

  @override
  int? categoryIdOf(Movie item) => item.categoryId;

  @override
  String nameOf(Movie item) => item.name;

  @override
  Object itemKey(Movie item) => item.streamId;

  @override
  String? leadingOf(Movie item) {
    final icon = item.streamIcon;
    if (icon == null || icon.isEmpty) return null;
    return icon;
  }

  Future<void> selectCategory(int? categoryId) =>
      selectCategoryAsync(categoryId);

  void showAllMovies() => showAllItems();
}

final moviesControllerProvider =
    StateNotifierProvider.autoDispose<MoviesController, MoviesState>((ref) {
      final repo = ref.watch(vodRepositoryProvider);
      return MoviesController(repo);
    });
