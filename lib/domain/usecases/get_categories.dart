import 'package:iptv/core/utils/result.dart';
import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/repositories/live_repository.dart';

class GetCategoriesUseCase {
  const GetCategoriesUseCase(this._repository);

  final LiveRepository _repository;

  Future<Result<List<Category>>> call({bool forceRefresh = false}) {
    return _repository.getCategories(forceRefresh: forceRefresh);
  }
}
