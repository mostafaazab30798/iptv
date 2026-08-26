import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/series.dart';
import 'package:iptv/domain/repositories/series_repository.dart';

class SeriesState {
  const SeriesState({
    this.categories = const [],
    this.selectedCategoryId,
    this.seriesList = const [],
    this.filteredSeries = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  final List<Category> categories;
  final int? selectedCategoryId;
  final List<Series> seriesList;
  final List<Series> filteredSeries;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  SeriesState copyWith({
    List<Category>? categories,
    int? selectedCategoryId,
    bool clearCategory = false,
    List<Series>? seriesList,
    List<Series>? filteredSeries,
    String? searchQuery,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return SeriesState(
      categories: categories ?? this.categories,
      selectedCategoryId: clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      seriesList: seriesList ?? this.seriesList,
      filteredSeries: filteredSeries ?? this.filteredSeries,
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

  Future<void> loadData({bool forceRefresh = false}) async {
    final repo = _seriesRepo;
    if (repo == null) return;

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

      state = state.copyWith(
        categories: categories,
        clearCategory: true,
        seriesList: list,
        filteredSeries: list,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> selectCategory(int? categoryId) async {
    final repo = _seriesRepo;
    if (repo == null) return;

    state = state.copyWith(
      selectedCategoryId: categoryId,
      clearCategory: categoryId == null,
      searchQuery: '',
      isLoading: true,
      clearError: true,
    );

    try {
      final seriesResult = await repo.getSeries(categoryId: categoryId);
      final list = seriesResult.when(
        ok: (s) => s,
        err: (_) => <Series>[],
      );

      state = state.copyWith(
        seriesList: list,
        filteredSeries: list,
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
      filteredSeries: _applyFilter(state.seriesList, q),
    );
  }

  List<Series> _applyFilter(List<Series> list, String query) {
    if (query.isEmpty) return list;
    final q = query.toLowerCase();
    return list.where((s) => s.name.toLowerCase().contains(q)).toList();
  }
}

final seriesControllerProvider =
    StateNotifierProvider<SeriesController, SeriesState>((ref) {
  final repo = ref.watch(seriesRepositoryProvider);
  return SeriesController(repo);
});
