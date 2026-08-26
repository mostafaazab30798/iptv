import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/movie.dart';
import 'package:iptv/domain/repositories/vod_repository.dart';

class MoviesState {
  const MoviesState({
    this.categories = const [],
    this.selectedCategoryId,
    this.movies = const [],
    this.filteredMovies = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  final List<Category> categories;
  final int? selectedCategoryId;
  final List<Movie> movies;
  final List<Movie> filteredMovies;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  MoviesState copyWith({
    List<Category>? categories,
    int? selectedCategoryId,
    bool clearCategory = false,
    List<Movie>? movies,
    List<Movie>? filteredMovies,
    String? searchQuery,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return MoviesState(
      categories: categories ?? this.categories,
      selectedCategoryId: clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      movies: movies ?? this.movies,
      filteredMovies: filteredMovies ?? this.filteredMovies,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class MoviesController extends StateNotifier<MoviesState> {
  MoviesController(this._vodRepo) : super(const MoviesState()) {
    loadData();
  }

  final VodRepository? _vodRepo;

  Future<void> loadData({bool forceRefresh = false}) async {
    final repo = _vodRepo;
    if (repo == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final catResult = await repo.getCategories(forceRefresh: forceRefresh);
      final categories = catResult.when(
        ok: (cats) => cats,
        err: (_) => <Category>[],
      );

      final movieResult = await repo.getMovies(
        categoryId: null,
        forceRefresh: forceRefresh,
      );

      final movies = movieResult.when(
        ok: (m) => m,
        err: (_) => <Movie>[],
      );

      state = state.copyWith(
        categories: categories,
        clearCategory: true,
        movies: movies,
        filteredMovies: movies,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> selectCategory(int? categoryId) async {
    final repo = _vodRepo;
    if (repo == null) return;

    state = state.copyWith(
      selectedCategoryId: categoryId,
      clearCategory: categoryId == null,
      searchQuery: '',
      isLoading: true,
      clearError: true,
    );

    try {
      final movieResult = await repo.getMovies(categoryId: categoryId);
      final movies = movieResult.when(
        ok: (m) => m,
        err: (_) => <Movie>[],
      );

      state = state.copyWith(
        movies: movies,
        filteredMovies: movies,
        searchQuery: '',
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void search(String query) {
    final q = query.trim();
    state = state.copyWith(
      searchQuery: q,
      filteredMovies: _applyFilter(state.movies, q),
    );
  }

  List<Movie> _applyFilter(List<Movie> list, String query) {
    if (query.isEmpty) return list;
    final q = query.toLowerCase();
    return list.where((m) => m.name.toLowerCase().contains(q)).toList();
  }
}

final moviesControllerProvider =
    StateNotifierProvider<MoviesController, MoviesState>((ref) {
  final repo = ref.watch(vodRepositoryProvider);
  return MoviesController(repo);
});
