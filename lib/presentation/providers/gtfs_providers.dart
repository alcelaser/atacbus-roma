import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/gtfs_repository_impl.dart';
import '../../domain/entities/stop.dart';
import '../../domain/entities/departure.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/repositories/gtfs_repository.dart';
import '../../domain/usecases/search_stops.dart';
import '../../domain/usecases/get_stop_departures.dart';
import '../../domain/usecases/toggle_favorite.dart';
import 'sync_provider.dart';

final gtfsRepositoryProvider = Provider<GtfsRepository>((ref) {
  final db = ref.watch(databaseProvider);
  return GtfsRepositoryImpl(db);
});

final searchStopsProvider = Provider<SearchStops>((ref) {
  return SearchStops(ref.watch(gtfsRepositoryProvider));
});

final getStopDeparturesProvider = Provider<GetStopDepartures>((ref) {
  return GetStopDepartures(ref.watch(gtfsRepositoryProvider));
});

final toggleFavoriteProvider = Provider<ToggleFavorite>((ref) {
  return ToggleFavorite(ref.watch(gtfsRepositoryProvider));
});

// Search query state
final searchQueryProvider = StateProvider<String>((ref) => '');

// Search results
final searchResultsProvider = FutureProvider<List<Stop>>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.trim().isEmpty) return [];
  final searchStops = ref.watch(searchStopsProvider);
  return searchStops(query);
});

// Departures for a stop
final stopDeparturesProvider =
    FutureProvider.family<List<Departure>, String>((ref, stopId) async {
  final getDepartures = ref.watch(getStopDeparturesProvider);
  return getDepartures(stopId);
});

// Stop details
final stopDetailProvider =
    FutureProvider.family<Stop?, String>((ref, stopId) async {
  final repo = ref.watch(gtfsRepositoryProvider);
  return repo.getStopById(stopId);
});

// Routes for a stop
final routesForStopProvider =
    FutureProvider.family<List<RouteEntity>, String>((ref, stopId) async {
  final repo = ref.watch(gtfsRepositoryProvider);
  return repo.getRoutesForStop(stopId);
});

// Is favorite
final isFavoriteProvider =
    FutureProvider.family<bool, String>((ref, stopId) async {
  final repo = ref.watch(gtfsRepositoryProvider);
  return repo.isFavorite(stopId);
});

// Favorite stop IDs (stream)
final favoriteStopIdsProvider = StreamProvider<List<String>>((ref) {
  final repo = ref.watch(gtfsRepositoryProvider);
  return repo.watchFavoriteStopIds();
});

// All routes
final allRoutesProvider = FutureProvider<List<RouteEntity>>((ref) async {
  final repo = ref.watch(gtfsRepositoryProvider);
  return repo.getAllRoutes();
});

// Routes by type
final routesByTypeProvider =
    FutureProvider.family<List<RouteEntity>, int>((ref, type) async {
  final repo = ref.watch(gtfsRepositoryProvider);
  return repo.getRoutesByType(type);
});
