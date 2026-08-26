import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/repositories/live_repository.dart';

class GetChannelsUseCase {
  const GetChannelsUseCase(this._repository);

  final LiveRepository _repository;

  Future<Result<List<Channel>>> call({
    int? categoryId,
    bool forceRefresh = false,
  }) {
    return _repository.getChannels(
      categoryId: categoryId,
      forceRefresh: forceRefresh,
    );
  }
}
