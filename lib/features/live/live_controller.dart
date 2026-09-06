import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iptv/app/providers.dart';
import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/repositories/live_repository.dart';
import 'package:iptv/features/catalog/catalog_controller.dart';

typedef LiveState = CatalogState<Channel, Channel>;

extension LiveStateX on LiveState {
  List<Channel> get filteredChannels => filteredItems;
  int get totalChannelCount => totalCount;
  Map<int, Channel> get categoryLeadingChannels => categoryLeading;
}

class LiveController extends CatalogController<Channel, Channel> {
  LiveController(this._liveRepo);

  final LiveRepository? _liveRepo;

  @override
  bool get hasRepository => _liveRepo != null;

  @override
  Future<Result<List<Category>>> fetchCategories({
    required bool forceRefresh,
  }) {
    return _liveRepo!.getCategories(forceRefresh: forceRefresh);
  }

  @override
  Future<Result<List<Channel>>> fetchItems({
    int? categoryId,
    required bool forceRefresh,
  }) {
    return _liveRepo!.getChannels(
      categoryId: categoryId,
      forceRefresh: forceRefresh,
    );
  }

  @override
  int? categoryIdOf(Channel item) => item.categoryId;

  @override
  String nameOf(Channel item) => item.name;

  @override
  Object itemKey(Channel item) => item.streamId;

  @override
  Channel? leadingOf(Channel item) => item;

  void selectCategory(int categoryId) => selectCategorySync(categoryId);

  void showAllChannels() => showAllItems();
}

final liveControllerProvider =
    StateNotifierProvider.autoDispose<LiveController, LiveState>((ref) {
      final repo = ref.watch(liveRepositoryProvider);
      return LiveController(repo);
    });
