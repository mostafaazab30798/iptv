import 'package:iptv/domain/entities/category.dart';
import 'package:iptv/domain/entities/channel.dart';
import 'package:iptv/domain/entities/epg_program.dart';
import 'package:iptv/domain/entities/movie.dart';
import 'package:iptv/domain/entities/season.dart';
import 'package:iptv/domain/entities/series.dart';

/// In-memory catalog cache owned by Riverpod and keyed by IPTV session.
///
/// Replacing static fields on repository impls so a server/account switch
/// cannot leak another session's catalog into the UI.
class CatalogMemoryCache {
  List<Category>? liveCategories;
  DateTime? liveCategoriesFetchedAt;
  List<Channel>? liveChannels;
  DateTime? liveChannelsFetchedAt;
  final Map<int, List<Channel>> liveCategoryChannels = {};
  final Map<int, Channel> liveChannelMap = {};
  final Map<int, List<Channel>> liveChannelsByCategoryIndex = {};
  final Map<int, List<EpgProgram>> liveEpg = {};
  final Map<int, DateTime> liveEpgFetchedAt = {};

  List<Category>? vodCategories;
  DateTime? vodCategoriesFetchedAt;
  List<Movie>? vodMovies;
  DateTime? vodMoviesFetchedAt;
  final Map<int, List<Movie>> vodCategoryMovies = {};
  final Map<int, Movie> vodMovieMap = {};

  List<Category>? seriesCategories;
  DateTime? seriesCategoriesFetchedAt;
  List<Series>? seriesList;
  DateTime? seriesFetchedAt;
  final Map<int, List<Series>> seriesCategoryItems = {};
  final Map<int, List<Season>> seriesSeasons = {};

  void clear() {
    liveCategories = null;
    liveCategoriesFetchedAt = null;
    liveChannels = null;
    liveChannelsFetchedAt = null;
    liveCategoryChannels.clear();
    liveChannelMap.clear();
    liveChannelsByCategoryIndex.clear();
    liveEpg.clear();
    liveEpgFetchedAt.clear();

    vodCategories = null;
    vodCategoriesFetchedAt = null;
    vodMovies = null;
    vodMoviesFetchedAt = null;
    vodCategoryMovies.clear();
    vodMovieMap.clear();

    seriesCategories = null;
    seriesCategoriesFetchedAt = null;
    seriesList = null;
    seriesFetchedAt = null;
    seriesCategoryItems.clear();
    seriesSeasons.clear();
  }
}
