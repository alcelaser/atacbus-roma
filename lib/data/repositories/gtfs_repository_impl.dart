import 'package:drift/drift.dart';
import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/stop.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/entities/departure.dart';
import '../../domain/repositories/gtfs_repository.dart';
import '../datasources/local/database/app_database.dart';

class GtfsRepositoryImpl implements GtfsRepository {
  final AppDatabase _db;

  GtfsRepositoryImpl(this._db);

  // ─── Stop conversion ────────────────────────────────────────

  Stop _mapStop(GtfsStop s) => Stop(
        stopId: s.stopId,
        stopCode: s.stopCode,
        stopName: s.stopName,
        stopDesc: s.stopDesc,
        stopLat: s.stopLat,
        stopLon: s.stopLon,
        locationType: s.locationType,
        parentStation: s.parentStation,
      );

  RouteEntity _mapRoute(GtfsRoute r) => RouteEntity(
        routeId: r.routeId,
        agencyId: r.agencyId,
        routeShortName: r.routeShortName,
        routeLongName: r.routeLongName,
        routeType: r.routeType,
        routeColor: r.routeColor,
        routeTextColor: r.routeTextColor,
      );

  // ─── Stops ──────────────────────────────────────────────────

  @override
  Future<List<Stop>> searchStops(String query) async {
    final results = await _db.searchStopsByName(query);
    return results.map(_mapStop).toList();
  }

  @override
  Future<Stop?> getStopById(String stopId) async {
    final s = await _db.getStopById(stopId);
    return s != null ? _mapStop(s) : null;
  }

  @override
  Future<List<Stop>> getAllStops() async {
    final results = await _db.getAllStops();
    return results.map(_mapStop).toList();
  }

  // ─── Routes ─────────────────────────────────────────────────

  @override
  Future<List<RouteEntity>> getAllRoutes() async {
    final results = await _db.getAllRoutes();
    return results.map(_mapRoute).toList();
  }

  @override
  Future<List<RouteEntity>> getRoutesByType(int type) async {
    final results = await _db.getRoutesByType(type);
    return results.map(_mapRoute).toList();
  }

  @override
  Future<RouteEntity?> getRouteById(String routeId) async {
    final r = await _db.getRouteById(routeId);
    return r != null ? _mapRoute(r) : null;
  }

  // ─── Departures ─────────────────────────────────────────────

  @override
  Future<List<Departure>> getScheduledDepartures(String stopId) async {
    // 1. Determine today's active service IDs
    final serviceDate = DateTimeUtils.getServiceDate();
    final dateStr = DateTimeUtils.toGtfsDate(serviceDate);
    final weekday = serviceDate.weekday;

    final activeServiceIds = await _getActiveServiceIds(dateStr, weekday);
    if (activeServiceIds.isEmpty) return [];

    // 2. Get all stop times for this stop
    final stopTimes = await _db.getStopTimesForStop(stopId);
    if (stopTimes.isEmpty) return [];

    // 3. Get trip IDs and look up routes
    final tripIds = stopTimes.map((st) => st.tripId).toSet();
    final tripRouteMap = <String, GtfsTrip>{};
    for (final tripId in tripIds) {
      final trip = await _db.getTripById(tripId);
      if (trip != null && activeServiceIds.contains(trip.serviceId)) {
        tripRouteMap[tripId] = trip;
      }
    }

    // 4. Build a route cache
    final routeCache = <String, GtfsRoute>{};
    for (final trip in tripRouteMap.values) {
      if (!routeCache.containsKey(trip.routeId)) {
        final route = await _db.getRouteById(trip.routeId);
        if (route != null) routeCache[trip.routeId] = route;
      }
    }

    // 5. Build departures
    final departures = <Departure>[];
    for (final st in stopTimes) {
      final trip = tripRouteMap[st.tripId];
      if (trip == null) continue;

      final route = routeCache[trip.routeId];
      if (route == null) continue;

      final seconds = DateTimeUtils.parseGtfsTime(st.departureTime);

      departures.add(Departure(
        tripId: st.tripId,
        routeId: trip.routeId,
        routeShortName: route.routeShortName,
        routeColor: route.routeColor,
        tripHeadsign: trip.tripHeadsign ?? st.stopHeadsign,
        directionId: trip.directionId,
        scheduledTime: st.departureTime,
        scheduledSeconds: seconds,
      ));
    }

    departures.sort((a, b) => a.scheduledSeconds.compareTo(b.scheduledSeconds));
    return departures;
  }

  Future<Set<String>> _getActiveServiceIds(String dateStr, int weekday) async {
    final activeIds = <String>{};

    // Check calendar table
    final allCalendar = await _db.getAllCalendar();
    for (final cal in allCalendar) {
      final startDate = DateTimeUtils.parseGtfsDate(cal.startDate);
      final endDate = DateTimeUtils.parseGtfsDate(cal.endDate);
      final currentDate = DateTimeUtils.parseGtfsDate(dateStr);

      if (currentDate.isBefore(startDate) || currentDate.isAfter(endDate)) {
        continue;
      }

      bool dayActive;
      switch (weekday) {
        case 1: dayActive = cal.monday; break;
        case 2: dayActive = cal.tuesday; break;
        case 3: dayActive = cal.wednesday; break;
        case 4: dayActive = cal.thursday; break;
        case 5: dayActive = cal.friday; break;
        case 6: dayActive = cal.saturday; break;
        case 7: dayActive = cal.sunday; break;
        default: dayActive = false;
      }

      if (dayActive) {
        activeIds.add(cal.serviceId);
      }
    }

    // Check calendar_dates for exceptions
    final exceptions = await _db.getCalendarDatesByDate(dateStr);
    for (final ex in exceptions) {
      if (ex.exceptionType == 1) {
        activeIds.add(ex.serviceId); // Service added
      } else if (ex.exceptionType == 2) {
        activeIds.remove(ex.serviceId); // Service removed
      }
    }

    return activeIds;
  }

  // ─── Route stops ────────────────────────────────────────────

  @override
  Future<List<Stop>> getStopsForRoute(String routeId) async {
    // Get one trip for this route to determine stop order
    final trips = await _db.getTripsByRouteId(routeId);
    if (trips.isEmpty) return [];

    final stopTimes = await _db.getStopTimesForTrip(trips.first.tripId);
    final stops = <Stop>[];
    for (final st in stopTimes) {
      final stop = await _db.getStopById(st.stopId);
      if (stop != null) stops.add(_mapStop(stop));
    }
    return stops;
  }

  @override
  Future<List<RouteEntity>> getRoutesForStop(String stopId) async {
    // Get all stop_times for this stop, extract unique route IDs via trips
    final stopTimes = await _db.getStopTimesForStop(stopId);
    final routeIds = <String>{};
    for (final st in stopTimes) {
      final trip = await _db.getTripById(st.tripId);
      if (trip != null) routeIds.add(trip.routeId);
    }

    final routes = <RouteEntity>[];
    for (final routeId in routeIds) {
      final route = await _db.getRouteById(routeId);
      if (route != null) routes.add(_mapRoute(route));
    }
    routes.sort((a, b) => a.routeShortName.compareTo(b.routeShortName));
    return routes;
  }

  // ─── Favorites ──────────────────────────────────────────────

  @override
  Future<bool> isFavorite(String stopId) => _db.isFavorite(stopId);

  @override
  Future<void> addFavorite(String stopId) => _db.addFavorite(stopId);

  @override
  Future<void> removeFavorite(String stopId) => _db.removeFavorite(stopId);

  @override
  Future<List<String>> getFavoriteStopIds() async {
    final favs = await _db.getAllFavorites();
    return favs.map((f) => f.stopId).toList();
  }

  @override
  Stream<List<String>> watchFavoriteStopIds() {
    return _db.watchFavorites().map(
      (favs) => favs.map((f) => f.stopId).toList(),
    );
  }
}
