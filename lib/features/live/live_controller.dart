import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/repositories/live_repository.dart';

class LiveState {
  const LiveState({
    this.categories = const [],
    this.selectedCategoryId,
    this.channels = const [],
    this.filteredChannels = const [],
    this.searchQuery = '',
    this.isLoading = false,
    this.error,
  });

  final List<Category> categories;
  final int? selectedCategoryId;
  final List<Channel> channels;
  final List<Channel> filteredChannels;
  final String searchQuery;
  final bool isLoading;
  final String? error;

  LiveState copyWith({
    List<Category>? categories,
    int? selectedCategoryId,
    bool clearCategory = false,
    List<Channel>? channels,
    List<Channel>? filteredChannels,
    String? searchQuery,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return LiveState(
      categories: categories ?? this.categories,
      selectedCategoryId: clearCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      channels: channels ?? this.channels,
      filteredChannels: filteredChannels ?? this.filteredChannels,
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

  Future<void> loadData({bool forceRefresh = false}) async {
    final repo = _liveRepo;
    if (repo == null) return;

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final catResult = await repo.getCategories(forceRefresh: forceRefresh);
      final categories = catResult.when(
        ok: (cats) => cats,
        err: (e) => <Category>[],
      );

      final chanResult = await repo.getChannels(
        categoryId: null,
        forceRefresh: forceRefresh,
      );

      final channels = chanResult.when(
        ok: (chans) => chans,
        err: (e) => <Channel>[],
      );

      state = state.copyWith(
        categories: categories,
        clearCategory: true,
        channels: channels,
        filteredChannels: channels,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> selectCategory(int? categoryId) async {
    // Filter the already-loaded channel list client-side — no network round-trip needed.
    final allChannels = state.channels;
    final filtered = categoryId == null
        ? allChannels
        : allChannels.where((c) => c.categoryId == categoryId).toList();

    state = state.copyWith(
      selectedCategoryId: categoryId,
      clearCategory: categoryId == null,
      searchQuery: '',
      filteredChannels: filtered,
    );
  }

  void search(String query) {
    final q = query.trim();
    // Scope the base list to the active category before applying the text filter,
    // so that clearing the search bar still respects the category selection.
    final baseList = state.selectedCategoryId == null
        ? state.channels
        : state.channels.where((c) => c.categoryId == state.selectedCategoryId).toList();
    state = state.copyWith(
      searchQuery: q,
      filteredChannels: _applyFilter(baseList, q),
    );
  }

  List<Channel> _applyFilter(List<Channel> list, String query) {
    if (query.isEmpty) return list;
    final q = query.toLowerCase();
    return list.where((c) => c.name.toLowerCase().contains(q)).toList();
  }
}

final liveControllerProvider =
    StateNotifierProvider<LiveController, LiveState>((ref) {
  final repo = ref.watch(liveRepositoryProvider);
  return LiveController(repo);
});
