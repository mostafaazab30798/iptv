import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/repositories/live_repository.dart';
import 'package:iptv/features/catalog_filter/excluded_live_categories_policy.dart';

const _blockedContentError = AppResultError(
  'Content is blocked by catalog filter',
);

/// Live repository wrapper that removes excluded country categories and their
/// channels — applied in normal mode (and under Kids Mode filtering).
class ExcludedCategoriesLiveRepository implements LiveRepository {
  ExcludedCategoriesLiveRepository(this._delegate, this._policy);

  final LiveRepository _delegate;
  final ExcludedLiveCategoriesPolicy _policy;

  Future<Result<Set<int>>> _excludedCategoryIds({
    bool forceRefresh = false,
  }) async {
    return (await _delegate.getCategories(forceRefresh: forceRefresh)).map(
      (categories) => categories
          .where(_policy.isExcluded)
          .map((category) => category.id)
          .toSet(),
    );
  }

  @override
  Future<Result<List<Category>>> getCategories({
    bool forceRefresh = false,
  }) async {
    return (await _delegate.getCategories(
      forceRefresh: forceRefresh,
    )).map((categories) => categories.where(_policy.allowsCategory).toList());
  }

  @override
  Future<Result<List<Channel>>> getChannels({
    int? categoryId,
    bool forceRefresh = false,
  }) async {
    final excludedResult = await _excludedCategoryIds(
      forceRefresh: forceRefresh,
    );
    if (excludedResult case Err<Set<int>>(:final appError)) {
      return Err(appError);
    }
    final excluded = excludedResult.value;
    if (categoryId != null && excluded.contains(categoryId)) {
      return const Ok(<Channel>[]);
    }
    return (await _delegate.getChannels(
      categoryId: categoryId,
      forceRefresh: forceRefresh,
    )).map(
      (channels) => channels
          .where(
            (channel) =>
                channel.categoryId == null ||
                !excluded.contains(channel.categoryId),
          )
          .toList(),
    );
  }

  @override
  Future<Result<Channel>> getChannelById(int streamId) async {
    final result = await _delegate.getChannelById(streamId);
    if (result case Err<Channel>()) return result;
    final channel = result.value;
    final categoryId = channel.categoryId;
    if (categoryId == null) return result;

    final excludedResult = await _excludedCategoryIds();
    if (excludedResult case Err<Set<int>>(:final appError)) {
      return Err(appError);
    }
    return excludedResult.value.contains(categoryId)
        ? const Err(_blockedContentError)
        : result;
  }
}
