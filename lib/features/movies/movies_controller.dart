import 'dart:async';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/movie.dart';
import 'package:iptv/domain/repositories/vod_repository.dart';

class MoviesState {
  const MoviesState({
    this.categories = const [],
    this.selectedCategoryId,
    this.filteredMovies = const [],
    this.totalMovieCount = 0,
    this.categoryCounts = const {},
    this.categoryLeadingLogos = const {},
    this.categoryNames = const {},
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  final List<Category> categories;
  final int? selectedCategoryId;
  final List<Movie> filteredMovies;
  final int totalMovieCount;
  final Map<int, int> categoryCounts;
  final Map<int, String?> categoryLeadingLogos;
  final Map<int, String> categoryNames;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  /// Alias for hub count widgets that previously read `movies.length`.
  List<Movie> get movies => filteredMovies;

  MoviesState copyWith({
    List<Category>? categories,
    int? selectedCategoryId,
    bool clearCategory = false,
    List<Movie>? filteredMovies,
    int? totalMovieCount,
    Map<int, int>? categoryCounts,
    Map<int, String?>? categoryLeadingLogos,
    Map<int, String>? categoryNames,
    String? searchQuery,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return MoviesState(
      categories: categories ?? this.categories,
      selectedCategoryId: clearCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      filteredMovies: filteredMovies ?? this.filteredMovies,
      totalMovieCount: totalMovieCount ?? this.totalMovieCount,
      categoryCounts: categoryCounts ?? this.categoryCounts,
      categoryLeadingLogos: categoryLeadingLogos ?? this.categoryLeadingLogos,
      categoryNames: categoryNames ?? this.categoryNames,
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
  List<Movie> _catalog = const [];
  Timer? _searchDebounce;
  int _searchEpoch = 0;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> loadData({bool forceRefresh = false}) async {
    final repo = _vodRepo;
    if (repo == null || !mounted) return;

    if (!forceRefresh &&
        _catalog.isNotEmpty &&
        state.categories.isNotEmpty &&
        !state.isLoading) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final catResult = await repo.getCategories(forceRefresh: forceRefresh);
      if (!mounted) return;
      final categories = catResult.when(
        ok: (cats) => cats,
        err: (_) => <Category>[],
      );

      final movieResult = await repo.getMovies(
        categoryId: null,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;

      final movies = movieResult.when(ok: (m) => m, err: (_) => <Movie>[]);

      _catalog = movies;

      final counts = <int, int>{};
      final leadingLogos = <int, String?>{};
      for (final movie in movies) {
        final catId = movie.categoryId;
        if (catId != null) {
          counts[catId] = (counts[catId] ?? 0) + 1;
          if (!leadingLogos.containsKey(catId) &&
              movie.streamIcon != null &&
              movie.streamIcon!.isNotEmpty) {
            leadingLogos[catId] = movie.streamIcon;
          }
        }
      }

      final names = <int, String>{};
      for (final cat in categories) {
        names[cat.id] = cat.name;
      }

      final selectedId = state.selectedCategoryId;
      final List<Movie> visible;
      if (state.filteredMovies.isNotEmpty || selectedId != null) {
        visible = selectedId == null
            ? movies
            : movies.where((m) => m.categoryId == selectedId).toList();
      } else {
        visible = const [];
      }

      if (!mounted) return;
      state = state.copyWith(
        categories: categories,
        filteredMovies: visible,
        totalMovieCount: movies.length,
        categoryCounts: counts,
        categoryLeadingLogos: leadingLogos,
        categoryNames: names,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> selectCategory(int? categoryId) async {
    _searchDebounce?.cancel();
    if (categoryId == null) {
      showCategoriesHub();
      return;
    }

    state = state.copyWith(
      selectedCategoryId: categoryId,
      searchQuery: '',
      filteredMovies: _catalog
          .where((m) => m.categoryId == categoryId)
          .toList(),
      isLoading: false,
    );
  }

  void showAllMovies() {
    _searchDebounce?.cancel();
    state = state.copyWith(
      clearCategory: true,
      searchQuery: '',
      filteredMovies: _catalog,
    );
  }

  void showCategoriesHub() {
    _searchDebounce?.cancel();
    state = state.copyWith(
      clearCategory: true,
      searchQuery: '',
      filteredMovies: const [],
    );
  }

  void search(String query) {
    _searchDebounce?.cancel();
    if (!mounted) return;
    final trimmed = query.trim();
    state = state.copyWith(searchQuery: trimmed);
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      unawaited(_runSearch(trimmed));
    });
  }

  Future<void> _runSearch(String query) async {
    if (!mounted) return;
    final epoch = ++_searchEpoch;
    final base = state.selectedCategoryId == null
        ? _catalog
        : _catalog
              .where((m) => m.categoryId == state.selectedCategoryId)
              .toList();

    if (query.isEmpty) {
      if (!mounted || epoch != _searchEpoch) return;
      state = state.copyWith(filteredMovies: base);
      return;
    }

    final List<Movie> filtered;
    if (base.length > 1500) {
      final names = [for (final m in base) m.name];
      final indexes = await compute(_filterNameIndexes, (
        names,
        query.toLowerCase(),
      ));
      if (!mounted || epoch != _searchEpoch) return;
      filtered = [for (final i in indexes) base[i]];
    } else {
      final q = query.toLowerCase();
      filtered = base.where((m) => m.name.toLowerCase().contains(q)).toList();
    }

    if (!mounted || epoch != _searchEpoch) return;
    state = state.copyWith(filteredMovies: filtered);
  }
}

List<int> _filterNameIndexes((List<String> names, String query) args) {
  final names = args.$1;
  final q = args.$2;
  final out = <int>[];
  for (var i = 0; i < names.length; i++) {
    if (names[i].toLowerCase().contains(q)) out.add(i);
  }
  return out;
}

final moviesControllerProvider =
    StateNotifierProvider.autoDispose<MoviesController, MoviesState>((ref) {
      final repo = ref.watch(vodRepositoryProvider);
      return MoviesController(repo);
    });
