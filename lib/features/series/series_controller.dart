import 'dart:async';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/series.dart';
import 'package:iptv/domain/repositories/series_repository.dart';

class SeriesState {
  const SeriesState({
    this.categories = const [],
    this.selectedCategoryId,
    this.filteredSeries = const [],
    this.totalSeriesCount = 0,
    this.categoryCounts = const {},
    this.categoryLeadingCovers = const {},
    this.categoryNames = const {},
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  final List<Category> categories;
  final int? selectedCategoryId;
  final List<Series> filteredSeries;
  final int totalSeriesCount;
  final Map<int, int> categoryCounts;
  final Map<int, String?> categoryLeadingCovers;
  final Map<int, String> categoryNames;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  List<Series> get seriesList => filteredSeries;

  SeriesState copyWith({
    List<Category>? categories,
    int? selectedCategoryId,
    bool clearCategory = false,
    List<Series>? filteredSeries,
    int? totalSeriesCount,
    Map<int, int>? categoryCounts,
    Map<int, String?>? categoryLeadingCovers,
    Map<int, String>? categoryNames,
    String? searchQuery,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SeriesState(
      categories: categories ?? this.categories,
      selectedCategoryId:
          clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      filteredSeries: filteredSeries ?? this.filteredSeries,
      totalSeriesCount: totalSeriesCount ?? this.totalSeriesCount,
      categoryCounts: categoryCounts ?? this.categoryCounts,
      categoryLeadingCovers:
          categoryLeadingCovers ?? this.categoryLeadingCovers,
      categoryNames: categoryNames ?? this.categoryNames,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class SeriesController extends StateNotifier<SeriesState> {
  SeriesController(this._seriesRepo) : super(const SeriesState()) {
    loadData();
  }

  final SeriesRepository? _seriesRepo;
  List<Series> _catalog = const [];
  Timer? _searchDebounce;
  int _searchEpoch = 0;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> loadData({bool forceRefresh = false}) async {
    final repo = _seriesRepo;
    if (repo == null) return;

    if (!forceRefresh &&
        _catalog.isNotEmpty &&
        state.categories.isNotEmpty &&
        !state.isLoading) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final catResult = await repo.getCategories(forceRefresh: forceRefresh);
      final categories = catResult.when(
        ok: (cats) => cats,
        err: (_) => <Category>[],
      );

      final seriesResult = await repo.getSeries(
        categoryId: null,
        forceRefresh: forceRefresh,
      );

      final list = seriesResult.when(
        ok: (s) => s,
        err: (_) => <Series>[],
      );

      _catalog = list;

      final counts = <int, int>{};
      final leadingCovers = <int, String?>{};
      for (final series in list) {
        final catId = series.categoryId;
        if (catId != null) {
          counts[catId] = (counts[catId] ?? 0) + 1;
          if (!leadingCovers.containsKey(catId) &&
              series.cover != null &&
              series.cover!.isNotEmpty) {
            leadingCovers[catId] = series.cover;
          }
        }
      }

      final names = <int, String>{};
      for (final cat in categories) {
        names[cat.id] = cat.name;
      }

      final selectedId = state.selectedCategoryId;
      final List<Series> visible;
      if (state.filteredSeries.isNotEmpty || selectedId != null) {
        visible = selectedId == null
            ? list
            : list.where((s) => s.categoryId == selectedId).toList();
      } else {
        visible = const [];
      }

      state = state.copyWith(
        categories: categories,
        filteredSeries: visible,
        totalSeriesCount: list.length,
        categoryCounts: counts,
        categoryLeadingCovers: leadingCovers,
        categoryNames: names,
        isLoading: false,
      );
    } catch (e) {
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
      filteredSeries: _catalog.where((s) => s.categoryId == categoryId).toList(),
      isLoading: false,
    );
  }

  void showAllSeries() {
    _searchDebounce?.cancel();
    state = state.copyWith(
      clearCategory: true,
      searchQuery: '',
      filteredSeries: _catalog,
    );
  }

  void showCategoriesHub() {
    _searchDebounce?.cancel();
    state = state.copyWith(
      clearCategory: true,
      searchQuery: '',
      filteredSeries: const [],
    );
  }

  void search(String query) {
    _searchDebounce?.cancel();
    final trimmed = query.trim();
    state = state.copyWith(searchQuery: trimmed);
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      unawaited(_runSearch(trimmed));
    });
  }

  Future<void> _runSearch(String query) async {
    final epoch = ++_searchEpoch;
    final base = state.selectedCategoryId == null
        ? _catalog
        : _catalog
            .where((s) => s.categoryId == state.selectedCategoryId)
            .toList();

    if (query.isEmpty) {
      if (epoch != _searchEpoch) return;
      state = state.copyWith(filteredSeries: base);
      return;
    }

    final List<Series> filtered;
    if (base.length > 1500) {
      final names = [for (final s in base) s.name];
      final indexes =
          await compute(_filterNameIndexes, (names, query.toLowerCase()));
      if (epoch != _searchEpoch) return;
      filtered = [for (final i in indexes) base[i]];
    } else {
      final q = query.toLowerCase();
      filtered = base.where((s) => s.name.toLowerCase().contains(q)).toList();
    }

    if (epoch != _searchEpoch) return;
    state = state.copyWith(filteredSeries: filtered);
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

final seriesControllerProvider =
    StateNotifierProvider<SeriesController, SeriesState>((ref) {
  ref.keepAlive();
  final repo = ref.watch(seriesRepositoryProvider);
  return SeriesController(repo);
});
