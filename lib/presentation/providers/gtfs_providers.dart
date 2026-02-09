import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/distance_utils.dart';
import '../../data/datasources/remote/gtfs_realtime_api.dart';
import '../../data/repositories/gtfs_repository_impl.dart';
import '../../data/repositories/realtime_repository_impl.dart';
import '../../domain/entities/stop.dart';
import '../../domain/entities/departure.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/entities/service_alert.dart';
import '../../domain/entities/trip_plan.dart';
import '../../domain/entities/favorite_route.dart';
import '../../domain/entities/stop_time_detail.dart';
import '../../domain/repositories/realtime_repository.dart';
import '../../domain/usecases/search_stops.dart';
import '../../domain/usecases/get_stop_departures.dart';
import '../../domain/usecases/toggle_favorite.dart';
import '../../domain/usecases/plan_trip.dart';
import 'sync_provider.dart';

final gtfsRepositoryProvider = Provider<GtfsRepositoryImpl>((ref) {
  final db = ref.watch(databaseProvider);
  return GtfsRepositoryImpl(db);
});

// Real-time providers
final gtfsRealtimeApiProvider = Provider<GtfsRealtimeApi>((ref) {
  return GtfsRealtimeApi();
});

final realtimeRepositoryProvider = Provider<RealtimeRepository>((ref) {
  return RealtimeRepositoryImpl(ref.watch(gtfsRealtimeApiProvider));
});

// Connectivity
final connectivityProvider = StreamProvider<ConnectivityResult>((ref) {
  return Connectivity().onConnectivityChanged;
});

final isOnlineProvider = Provider<bool>((ref) {
  final connectivity = ref.watch(connectivityProvider);
  return connectivity.when(
    data: (result) => result != ConnectivityResult.none,
    loading: () => true,
    error: (_, __) => true,
  );
});

// Vehicle positions
final vehiclePositionsProvider = FutureProvider<List<Vehicle>>((ref) async {
  final repo = ref.watch(realtimeRepositoryProvider);
  return repo.getVehiclePositions();
});

// Service alerts
final serviceAlertsProvider = FutureProvider<List<ServiceAlert>>((ref) async {
  final repo = ref.watch(realtimeRepositoryProvider);
  return repo.getServiceAlerts();
});

final searchStopsProvider = Provider<SearchStops>((ref) {
  return SearchStops(ref.watch(gtfsRepositoryProvider));
});

final getStopDeparturesProvider = Provider<GetStopDepartures>((ref) {
  final isOnline = ref.watch(isOnlineProvider);
  return GetStopDepartures(
    ref.watch(gtfsRepositoryProvider),
    isOnline ? ref.watch(realtimeRepositoryProvider) : null,
  );
});

final toggleFavoriteProvider = Provider<ToggleFavorite>((ref) {
  return ToggleFavorite(ref.watch(gtfsRepositoryProvider));
});

// Search query state
final searchQueryProvider = StateProvider<String>((ref) => '');

// Route search query state (for route browser)
final routeSearchQueryProvider = StateProvider<String>((ref) => '');

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

// ─── Nearby stops ─────────────────────────────────────────────

/// A stop with pre-computed distance from the user.
class NearbyStop {
  final Stop stop;
  final double distanceMeters;
  const NearbyStop({required this.stop, required this.distanceMeters});
}

/// User location provider (reused from map_screen approach).
final nearbyLocationProvider = FutureProvider<Position?>((ref) async {
  bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
  if (!serviceEnabled) return null;

  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return null;
  }
  if (permission == LocationPermission.deniedForever) return null;

  return Geolocator.getCurrentPosition(
    desiredAccuracy: LocationAccuracy.medium,
  );
});

/// Stops within 1 km of the user, sorted by distance.
final nearbyStopsProvider = FutureProvider<List<NearbyStop>>((ref) async {
  final position = await ref.watch(nearbyLocationProvider.future);
  if (position == null) return [];

  final repo = ref.watch(gtfsRepositoryProvider);
  final allStops = await repo.getAllStops();

  final nearby = <NearbyStop>[];
  for (final stop in allStops) {
    final distance = DistanceUtils.haversineDistance(
      position.latitude,
      position.longitude,
      stop.stopLat,
      stop.stopLon,
    );
    if (distance <= AppConstants.nearbyRadiusMeters) {
      nearby.add(NearbyStop(stop: stop, distanceMeters: distance));
    }
  }
  nearby.sort((a, b) => a.distanceMeters.compareTo(b.distanceMeters));
  return nearby.take(10).toList();
});

// ─── Route directions ─────────────────────────────────────────

/// Available direction IDs for a route.
final routeDirectionsProvider =
    FutureProvider.family<List<int>, String>((ref, routeId) async {
  final repo = ref.watch(gtfsRepositoryProvider);
  return repo.getDirectionsForRoute(routeId);
});

/// Headsign for a given route + direction.
final directionHeadsignProvider =
    FutureProvider.family<String?, ({String routeId, int directionId})>(
        (ref, params) async {
  final repo = ref.watch(gtfsRepositoryProvider);
  return repo.getHeadsignForDirection(params.routeId, params.directionId);
});

// ─── Trip planning ───────────────────────────────────────────────

/// Represents a trip origin — either GPS-based or a selected stop.
class TripOrigin {
  final double lat;
  final double lon;
  final String name;
  final Stop? selectedStop; // null when GPS-based

  TripOrigin.gps({
    required this.lat,
    required this.lon,
    required this.name,
  }) : selectedStop = null;

  TripOrigin.stop(Stop stop)
      : lat = stop.stopLat,
        lon = stop.stopLon,
        name = stop.stopName,
        selectedStop = stop;
}

/// Selected origin for trip planning (GPS or stop).
final tripOriginProvider = StateProvider<TripOrigin?>((ref) => null);

/// Selected destination stop for trip planning.
final tripDestinationProvider = StateProvider<Stop?>((ref) => null);

/// Search query for origin stop input.
final originSearchQueryProvider = StateProvider<String>((ref) => '');

/// Search query for destination stop input.
final destinationSearchQueryProvider = StateProvider<String>((ref) => '');

/// Search results for origin stop autocomplete.
final originSearchResultsProvider = FutureProvider<List<Stop>>((ref) async {
  final query = ref.watch(originSearchQueryProvider);
  if (query.trim().isEmpty) return [];
  final searchStops = ref.watch(searchStopsProvider);
  return searchStops(query);
});

/// Search results for destination stop autocomplete.
final destinationSearchResultsProvider =
    FutureProvider<List<Stop>>((ref) async {
  final query = ref.watch(destinationSearchQueryProvider);
  if (query.trim().isEmpty) return [];
  final searchStops = ref.watch(searchStopsProvider);
  return searchStops(query);
});

/// PlanTrip use case provider.
final planTripProvider = Provider<PlanTrip>((ref) {
  return PlanTrip(ref.watch(gtfsRepositoryProvider));
});

/// Trip plan result: resolves nearby stops for origin/dest then plans.
final tripPlanResultProvider =
    FutureProvider<TripPlanResult?>((ref) async {
  final origin = ref.watch(tripOriginProvider);
  final destination = ref.watch(tripDestinationProvider);
  if (origin == null || destination == null) return null;

  final repo = ref.watch(gtfsRepositoryProvider);
  final allStops = await repo.getAllStops();
  final planTrip = ref.watch(planTripProvider);

  // Resolve origin stop IDs
  List<String> originStopIds;
  if (origin.selectedStop != null) {
    // Stop-based: use selected stop + nearby stops within walking distance
    originStopIds = _findNearbyStopIds(allStops, origin.lat, origin.lon);
    if (!originStopIds.contains(origin.selectedStop!.stopId)) {
      originStopIds.insert(0, origin.selectedStop!.stopId);
    }
  } else {
    // GPS-based: all stops within walking distance
    originStopIds = _findNearbyStopIds(allStops, origin.lat, origin.lon);
  }

  // Resolve destination stop IDs (search + nearby)
  final destStopIds = _findNearbyStopIds(
    allStops,
    destination.stopLat,
    destination.stopLon,
  );
  if (!destStopIds.contains(destination.stopId)) {
    destStopIds.insert(0, destination.stopId);
  }

  if (originStopIds.isEmpty || destStopIds.isEmpty) return null;

  return planTrip.callMulti(
    originStopIds: originStopIds,
    destStopIds: destStopIds,
    originName: origin.name,
    destinationName: destination.stopName,
  );
});

/// Helper: find stop IDs within walking distance of a point.
List<String> _findNearbyStopIds(
    List<Stop> allStops, double lat, double lon) {
  final nearby = <({String stopId, double distance})>[];
  for (final stop in allStops) {
    final distance = DistanceUtils.haversineDistance(
      lat, lon, stop.stopLat, stop.stopLon,
    );
    if (distance <= AppConstants.tripPlanNearbyRadiusMeters) {
      nearby.add((stopId: stop.stopId, distance: distance));
    }
  }
  nearby.sort((a, b) => a.distance.compareTo(b.distance));
  return nearby.take(10).map((n) => n.stopId).toList();
}

// ─── Favorite routes ─────────────────────────────────────────────

/// Stream of saved favorite routes.
final favoriteRoutesProvider =
    StreamProvider<List<FavoriteRouteEntity>>((ref) {
  final repo = ref.watch(gtfsRepositoryProvider);
  return repo.watchFavoriteRoutes();
});

// ─── Trip stop times (for trip detail) ────────────────────────────

/// Stop times for a trip (family by tripId).
final tripStopTimesProvider =
    FutureProvider.family<List<StopTimeDetail>, String>(
        (ref, tripId) async {
  final repo = ref.watch(gtfsRepositoryProvider);
  return repo.getStopTimesForTripWithNames(tripId);
});
