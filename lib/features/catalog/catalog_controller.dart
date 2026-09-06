import 'dart:async';

import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/category.dart';

/// Shared catalog screen state for Live / Movies / Series.
class CatalogState<TItem, TLeading> {
  const CatalogState({
    this.categories = const [],
    this.selectedCategoryId,
    this.filteredItems = const [],
    this.totalCount = 0,
    this.categoryCounts = const {},
    this.categoryLeading = const {},
    this.categoryNames = const {},
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  final List<Category> categories;
  final int? selectedCategoryId;
  final List<TItem> filteredItems;
  final int totalCount;
  final Map<int, int> categoryCounts;
  final Map<int, TLeading> categoryLeading;
  final Map<int, String> categoryNames;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  CatalogState<TItem, TLeading> copyWith({
    List<Category>? categories,
    int? selectedCategoryId,
    bool clearCategory = false,
    List<TItem>? filteredItems,
    int? totalCount,
    Map<int, int>? categoryCounts,
    Map<int, TLeading>? categoryLeading,
    Map<int, String>? categoryNames,
    String? searchQuery,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return CatalogState<TItem, TLeading>(
      categories: categories ?? this.categories,
      selectedCategoryId: clearCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      filteredItems: filteredItems ?? this.filteredItems,
      totalCount: totalCount ?? this.totalCount,
      categoryCounts: categoryCounts ?? this.categoryCounts,
      categoryLeading: categoryLeading ?? this.categoryLeading,
      categoryNames: categoryNames ?? this.categoryNames,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Generic catalog load / filter / search controller.
///
/// Feature controllers keep stable public provider names; this base owns the
/// shared debounce, hub/category/all navigation, and load pipeline.
abstract class CatalogController<TItem, TLeading>
    extends StateNotifier<CatalogState<TItem, TLeading>> {
  CatalogController() : super(CatalogState<TItem, TLeading>()) {
    loadData();
  }

  List<TItem> _catalog = const [];
  List<TItem> get catalog => _catalog;

  Timer? _searchDebounce;
  int _searchEpoch = 0;

  bool get hasRepository;

  /// When true, [Result.Err] is stored on [CatalogState.error].
  bool get surfaceResultErrors => true;

  /// Movies merges on-demand category rows into the in-memory catalog; Series does not.
  bool get mergeOnDemandIntoCatalog => false;

  Future<Result<List<Category>>> fetchCategories({
    required bool forceRefresh,
  });

  Future<Result<List<TItem>>> fetchItems({
    int? categoryId,
    required bool forceRefresh,
  });

  int? categoryIdOf(TItem item);

  String nameOf(TItem item);

  /// Stable identity for de-dupe when merging on-demand pages.
  Object itemKey(TItem item);

  /// Optional leading media (logo/cover/channel). Return null to skip.
  TLeading? leadingOf(TItem item);

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> loadData({bool forceRefresh = false}) async {
    if (!hasRepository || !mounted) return;

    if (!forceRefresh &&
        _catalog.isNotEmpty &&
        state.categories.isNotEmpty &&
        !state.isLoading) {
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final catResult = await fetchCategories(forceRefresh: forceRefresh);
      if (!mounted) return;

      final categories = _unwrapList(catResult, empty: <Category>[]);
      if (categories == null) return;

      final names = <int, String>{};
      for (final cat in categories) {
        names[cat.id] = cat.name;
      }

      // Immediately render categories so the screen is never stuck blank.
      state = state.copyWith(
        categories: categories,
        categoryNames: names,
        isLoading: false,
      );

      final itemsResult = await fetchItems(
        categoryId: null,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;

      final items = _unwrapList(itemsResult, empty: <TItem>[]);
      if (items == null) return;

      _catalog = items;

      final counts = <int, int>{};
      final leading = <int, TLeading>{};
      for (final item in items) {
        final catId = categoryIdOf(item);
        if (catId == null) continue;
        counts[catId] = (counts[catId] ?? 0) + 1;
        if (!leading.containsKey(catId)) {
          final lead = leadingOf(item);
          if (lead != null) leading[catId] = lead;
        }
      }

      final selectedId = state.selectedCategoryId;
      final List<TItem> visible;
      if (state.filteredItems.isNotEmpty || selectedId != null) {
        visible = selectedId == null
            ? items
            : items.where((i) => categoryIdOf(i) == selectedId).toList();
      } else {
        visible = const [];
      }

      if (!mounted) return;
      state = state.copyWith(
        filteredItems: visible,
        totalCount: items.length,
        categoryCounts: counts,
        categoryLeading: leading,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Live-style sync category open; lazy-fetches when the catalog is still cold.
  void selectCategorySync(int categoryId) {
    _searchDebounce?.cancel();
    if (_catalog.isEmpty) {
      state = state.copyWith(
        selectedCategoryId: categoryId,
        searchQuery: '',
        filteredItems: const [],
      );
      unawaited(_loadCategoryOnDemand(categoryId));
      return;
    }
    final filtered =
        _catalog.where((i) => categoryIdOf(i) == categoryId).toList();
    state = state.copyWith(
      selectedCategoryId: categoryId,
      searchQuery: '',
      filteredItems: filtered,
    );
  }

  /// Movies/Series-style: null clears to hub; may lazy-fetch empty categories.
  Future<void> selectCategoryAsync(int? categoryId) async {
    _searchDebounce?.cancel();
    if (categoryId == null) {
      showCategoriesHub();
      return;
    }

    final cached =
        _catalog.where((i) => categoryIdOf(i) == categoryId).toList();
    if (cached.isNotEmpty || !hasRepository) {
      state = state.copyWith(
        selectedCategoryId: categoryId,
        searchQuery: '',
        filteredItems: cached,
        isLoading: false,
      );
      return;
    }

    state = state.copyWith(
      selectedCategoryId: categoryId,
      searchQuery: '',
      filteredItems: const [],
      isLoading: true,
    );

    try {
      final res = await fetchItems(categoryId: categoryId, forceRefresh: false);
      if (!mounted || state.selectedCategoryId != categoryId) return;
      final items = _unwrapList(res, empty: <TItem>[]);
      if (items == null) {
        state = state.copyWith(isLoading: false);
        return;
      }

      if (mergeOnDemandIntoCatalog) {
        final existingKeys = {for (final i in _catalog) itemKey(i)};
        final fresh =
            items.where((i) => !existingKeys.contains(itemKey(i))).toList();
        if (fresh.isNotEmpty) {
          _catalog = [..._catalog, ...fresh];
        }
      }

      state = state.copyWith(filteredItems: items, isLoading: false);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void showAllItems() {
    _searchDebounce?.cancel();
    state = state.copyWith(
      clearCategory: true,
      searchQuery: '',
      filteredItems: _catalog,
    );
  }

  void showCategoriesHub() {
    _searchDebounce?.cancel();
    state = state.copyWith(
      clearCategory: true,
      searchQuery: '',
      filteredItems: const [],
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

  Future<void> _loadCategoryOnDemand(int categoryId) async {
    if (!hasRepository) return;
    try {
      final res = await fetchItems(categoryId: categoryId, forceRefresh: false);
      if (!mounted || state.selectedCategoryId != categoryId) return;
      final items = _unwrapList(res, empty: <TItem>[]);
      if (items == null) return;
      state = state.copyWith(filteredItems: items);
    } catch (e) {
      if (!mounted) return;
      if (surfaceResultErrors) {
        state = state.copyWith(error: e.toString());
      }
    }
  }

  Future<void> _runSearch(String query) async {
    if (!mounted) return;
    final epoch = ++_searchEpoch;
    final base = state.selectedCategoryId == null
        ? _catalog
        : _catalog
            .where((i) => categoryIdOf(i) == state.selectedCategoryId)
            .toList();

    if (query.isEmpty) {
      if (!mounted || epoch != _searchEpoch) return;
      state = state.copyWith(filteredItems: base);
      return;
    }

    final List<TItem> filtered;
    if (base.length > 1500) {
      final names = [for (final i in base) nameOf(i)];
      final indexes = await compute(catalogFilterNameIndexes, (
        names,
        query.toLowerCase(),
      ));
      if (!mounted || epoch != _searchEpoch) return;
      filtered = [for (final i in indexes) base[i]];
    } else {
      final q = query.toLowerCase();
      filtered =
          base.where((i) => nameOf(i).toLowerCase().contains(q)).toList();
    }

    if (!mounted || epoch != _searchEpoch) return;
    state = state.copyWith(filteredItems: filtered);
  }

  /// Returns null when an error was written to state and callers should stop.
  List<E>? _unwrapList<E>(Result<List<E>> result, {required List<E> empty}) {
    return result.when(
      ok: (data) => data,
      err: (error) {
        if (surfaceResultErrors) {
          state = state.copyWith(isLoading: false, error: error.message);
          return null;
        }
        return empty;
      },
    );
  }
}

/// Isolate entry for large catalog name filters.
List<int> catalogFilterNameIndexes((List<String> names, String query) args) {
  final names = args.$1;
  final q = args.$2;
  final out = <int>[];
  for (var i = 0; i < names.length; i++) {
    if (names[i].toLowerCase().contains(q)) out.add(i);
  }
  return out;
}
