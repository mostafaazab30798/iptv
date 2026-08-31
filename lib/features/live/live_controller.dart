import 'dart:async';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/repositories/live_repository.dart';

class LiveState {
  const LiveState({
    this.categories = const [],
    this.selectedCategoryId,
    this.filteredChannels = const [],
    this.totalChannelCount = 0,
    this.categoryCounts = const {},
    this.categoryLeadingChannels = const {},
    this.categoryNames = const {},
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  final List<Category> categories;
  final int? selectedCategoryId;

  /// Visible list for the current category / All / search page.
  final List<Channel> filteredChannels;

  /// Full catalog size for the All-channels card (catalog stays in controller/repo).
  final int totalChannelCount;
  final Map<int, int> categoryCounts;
  final Map<int, Channel> categoryLeadingChannels;
  final Map<int, String> categoryNames;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  LiveState copyWith({
    List<Category>? categories,
    int? selectedCategoryId,
    bool clearCategory = false,
    List<Channel>? filteredChannels,
    int? totalChannelCount,
    Map<int, int>? categoryCounts,
    Map<int, Channel>? categoryLeadingChannels,
    Map<int, String>? categoryNames,
    String? searchQuery,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return LiveState(
      categories: categories ?? this.categories,
      selectedCategoryId: clearCategory
          ? null
          : (selectedCategoryId ?? this.selectedCategoryId),
      filteredChannels: filteredChannels ?? this.filteredChannels,
      totalChannelCount: totalChannelCount ?? this.totalChannelCount,
      categoryCounts: categoryCounts ?? this.categoryCounts,
      categoryLeadingChannels:
          categoryLeadingChannels ?? this.categoryLeadingChannels,
      categoryNames: categoryNames ?? this.categoryNames,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class LiveController extends StateNotifier<LiveState> {
  LiveController(this._liveRepo) : super(const LiveState()) {
    loadData();
  }

  final LiveRepository? _liveRepo;

  /// Full catalog held once; UI state only mirrors the active visible page.
  List<Channel> _catalog = const [];
  Timer? _searchDebounce;
  int _searchEpoch = 0;

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  Future<void> loadData({bool forceRefresh = false}) async {
    final repo = _liveRepo;
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

      final chanResult = await repo.getChannels(
        categoryId: null,
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;

      final channels = chanResult.when(
        ok: (chans) => chans,
        err: (_) => <Channel>[],
      );

      _catalog = channels;

      final counts = <int, int>{};
      final leading = <int, Channel>{};
      for (final channel in channels) {
        final catId = channel.categoryId;
        if (catId != null) {
          counts[catId] = (counts[catId] ?? 0) + 1;
          leading.putIfAbsent(catId, () => channel);
        }
      }

      final names = <int, String>{};
      for (final cat in categories) {
        names[cat.id] = cat.name;
      }

      final selectedId = state.selectedCategoryId;
      final List<Channel> visible;
      if (state.filteredChannels.isNotEmpty || selectedId != null) {
        // Preserve in-category view across soft refresh.
        visible = selectedId == null
            ? channels
            : channels.where((c) => c.categoryId == selectedId).toList();
      } else {
        visible = const [];
      }

      if (!mounted) return;
      state = state.copyWith(
        categories: categories,
        filteredChannels: visible,
        totalChannelCount: channels.length,
        categoryCounts: counts,
        categoryLeadingChannels: leading,
        categoryNames: names,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Open a single category page (scoped list only).
  void selectCategory(int categoryId) {
    _searchDebounce?.cancel();
    final filtered = _catalog.where((c) => c.categoryId == categoryId).toList();
    state = state.copyWith(
      selectedCategoryId: categoryId,
      searchQuery: '',
      filteredChannels: filtered,
    );
  }

  /// "All channels" — one visible page over the shared catalog reference.
  void showAllChannels() {
    _searchDebounce?.cancel();
    state = state.copyWith(
      clearCategory: true,
      searchQuery: '',
      filteredChannels: _catalog,
    );
  }

  /// Categories hub — drop the visible channel list from UI state.
  void showCategoriesHub() {
    _searchDebounce?.cancel();
    state = state.copyWith(
      clearCategory: true,
      searchQuery: '',
      filteredChannels: const [],
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
              .where((c) => c.categoryId == state.selectedCategoryId)
              .toList();

    if (query.isEmpty) {
      if (!mounted || epoch != _searchEpoch) return;
      state = state.copyWith(filteredChannels: base);
      return;
    }

    final List<Channel> filtered;
    if (base.length > 1500) {
      final names = [for (final c in base) c.name];
      final indexes = await compute(_filterNameIndexes, (
        names,
        query.toLowerCase(),
      ));
      if (!mounted || epoch != _searchEpoch) return;
      filtered = [for (final i in indexes) base[i]];
    } else {
      final q = query.toLowerCase();
      filtered = base.where((c) => c.name.toLowerCase().contains(q)).toList();
    }

    if (!mounted || epoch != _searchEpoch) return;
    state = state.copyWith(filteredChannels: filtered);
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

final liveControllerProvider =
    StateNotifierProvider.autoDispose<LiveController, LiveState>((ref) {
      final repo = ref.watch(liveRepositoryProvider);
      return LiveController(repo);
    });
