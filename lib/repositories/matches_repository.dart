import 'package:iptv/data/datasources/yallakora_matches_datasource.dart';
import 'package:iptv/data/models/match_model.dart';
import 'package:iptv/domain/entities/live_fixture.dart';

/// High-level repository for accessing today's match fixtures.
class MatchesRepository {
  MatchesRepository({YallakoraMatchesDataSource? dataSource})
      : _dataSource = dataSource ?? YallakoraMatchesDataSource();

  final YallakoraMatchesDataSource _dataSource;

  /// Retrieves today's matches parsed from the static JSON API.
  Future<List<MatchModel>> getTodayMatches({bool forceRefresh = false}) {
    return _dataSource.fetchTodayMatches(forceRefresh: forceRefresh);
  }

  /// Retrieves matches adapted as [LiveFixture] entities.
  Future<List<LiveFixture>> getTodayLiveFixtures({bool forceRefresh = false}) {
    return _dataSource.fetchLiveBigMatches();
  }
}
