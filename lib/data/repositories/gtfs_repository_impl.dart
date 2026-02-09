import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/stop.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/entities/departure.dart';
import '../../domain/entities/favorite_route.dart';
import '../../domain/entities/stop_time_detail.dart';
import '../../domain/repositories/gtfs_repository.dart';
import '../datasources/local/database/app_database.dart';

class GtfsRepositoryImpl implements GtfsRepository {
  final AppDatabase _db;

  GtfsRepositoryImpl(this._db);

  // ─── In-memory caches ─────────────────────────────────────
  // Service IDs only change when the date rolls over, so cache
  // them keyed by the GTFS date string (YYYYMMDD).
  String? _cachedServiceDate;
  Set<String>? _cachedServiceIds;

  // All-stops / all-routes are large but static between syncs.
  List<Stop>? _cachedAllStops;
  List<RouteEntity>? _cachedAllRoutes;

  /// Clear all caches (call after a re-sync).
  void clearCache() {
    _cachedServiceDate = null;
    _cachedServiceIds = null;
    _cachedAllStops = null;
    _cachedAllRoutes = null;
  }

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

  // ─── Service ID resolution ─────────────────────────────────

  /// Resolves today's active service IDs with fallback.
  Future<Set<String>> _getActiveServiceIdsForToday() async {
    final serviceDate = DateTimeUtils.getServiceDate();
    final dateStr = DateTimeUtils.toGtfsDate(serviceDate);
    final weekday = serviceDate.weekday;

    var activeServiceIds = await _getCachedServiceIds(dateStr, weekday);
    if (activeServiceIds.isEmpty) {
      activeServiceIds = await _db.getAllServiceIds();
    }
    return activeServiceIds;
  }

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
    if (_cachedAllStops != null) return _cachedAllStops!;
    final results = await _db.getAllStops();
    _cachedAllStops = results.map(_mapStop).toList();
    return _cachedAllStops!;
  }

  // ─── Routes ─────────────────────────────────────────────────

  @override
  Future<List<RouteEntity>> getAllRoutes() async {
    if (_cachedAllRoutes != null) return _cachedAllRoutes!;
    final results = await _db.getAllRoutes();
    _cachedAllRoutes = results.map(_mapRoute).toList();
    return _cachedAllRoutes!;
  }

  @override
  Future<List<RouteEntity>> getRoutesByType(int type) async {
    // Leverage the allRoutes cache if available
    final all = await getAllRoutes();
    return all.where((r) => r.routeType == type).toList();
  }

  @override
  Future<RouteEntity?> getRouteById(String routeId) async {
    // Try cache first
    final all = await getAllRoutes();
    final matches = all.where((r) => r.routeId == routeId);
    return matches.isNotEmpty ? matches.first : null;
  }

  // ─── Departures (single JOIN query) ───────────────────────────

  @override
  Future<List<Departure>> getScheduledDepartures(String stopId) async {
    final activeServiceIds = await _getActiveServiceIdsForToday();

    // Single JOIN query: stop_times + trips + routes
    final rows = await _db.getDeparturesForStop(stopId, activeServiceIds);
    if (rows.isEmpty) {
      // Last resort: try with no service filter at all
      final allRows = await _db.getDeparturesForStop(stopId, {});
      return _rowsToDepartures(allRows);
    }

    return _rowsToDepartures(rows);
  }

  List<Departure> _rowsToDepartures(List<DepartureRow> rows) {
    final departures = <Departure>[];
    for (final row in rows) {
      // Skip rows with empty or malformed departure_time rather than
      // letting a single bad row crash all departures for this stop.
      if (row.departureTime.trim().isEmpty) continue;
      final int seconds;
      try {
        seconds = DateTimeUtils.parseGtfsTime(row.departureTime);
      } catch (_) {
        continue; // malformed time — skip this row
      }
      departures.add(Departure(
        tripId: row.tripId,
        routeId: row.routeId,
        routeShortName: row.routeShortName,
        routeColor: row.routeColor,
        tripHeadsign: row.tripHeadsign ?? row.stopHeadsign,
        directionId: row.directionId,
        scheduledTime: row.departureTime,
        scheduledSeconds: seconds,
      ));
    }
    departures.sort((a, b) => a.scheduledSeconds.compareTo(b.scheduledSeconds));
    return departures;
  }

  /// Returns cached service IDs for the given date, refreshing only
  /// when the date changes (typically once per day).
  Future<Set<String>> _getCachedServiceIds(String dateStr, int weekday) async {
    if (_cachedServiceDate == dateStr && _cachedServiceIds != null) {
      return _cachedServiceIds!;
    }
    _cachedServiceIds = await _getActiveServiceIds(dateStr, weekday);
    _cachedServiceDate = dateStr;
    return _cachedServiceIds!;
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
        case 1:
          dayActive = cal.monday;
          break;
        case 2:
          dayActive = cal.tuesday;
          break;
        case 3:
          dayActive = cal.wednesday;
          break;
        case 4:
          dayActive = cal.thursday;
          break;
        case 5:
          dayActive = cal.friday;
          break;
        case 6:
          dayActive = cal.saturday;
          break;
        case 7:
          dayActive = cal.sunday;
          break;
        default:
          dayActive = false;
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
  Future<List<Stop>> getStopsForRoute(String routeId,
      {int? directionId}) async {
    final stops =
        await _db.getStopsForRouteJoin(routeId, directionId: directionId);
    return stops.map(_mapStop).toList();
  }

  @override
  Future<List<int>> getDirectionsForRoute(String routeId) async {
    return _db.getDirectionsForRoute(routeId);
  }

  @override
  Future<String?> getHeadsignForDirection(
      String routeId, int directionId) async {
    return _db.getHeadsignForDirection(routeId, directionId);
  }

  @override
  Future<List<RouteEntity>> getRoutesForStop(String stopId) async {
    final results = await _db.getRoutesForStopJoin(stopId);
    return results.map(_mapRoute).toList();
  }

  // ─── Trip planning ────────────────────────────────────────────

  /// Find direct trips between two stops for today's service.
  Future<List<DirectTripRow>> findDirectTrips(
    String originStopId,
    String destinationStopId,
  ) async {
    final serviceIds = await _getActiveServiceIdsForToday();
    return _db.findDirectTrips(originStopId, destinationStopId, serviceIds);
  }

  /// Get route IDs serving a stop for today's service.
  Future<List<String>> getRouteIdsForStop(String stopId) async {
    final serviceIds = await _getActiveServiceIdsForToday();
    return _db.getRouteIdsForStop(stopId, serviceIds);
  }

  /// Get stop IDs reachable from a set of routes for today's service.
  Future<List<String>> getStopIdsForRoutes(List<String> routeIds) async {
    final serviceIds = await _getActiveServiceIdsForToday();
    return _db.getStopIdsForRoutes(routeIds, serviceIds);
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

  // ─── Favorite routes ───────────────────────────────────────────

  Future<List<FavoriteRouteEntity>> getAllFavoriteRoutes() async {
    final rows = await _db.getAllFavoriteRoutes();
    return rows
        .map((r) => FavoriteRouteEntity(
              id: r.id,
              originLat: r.originLat,
              originLon: r.originLon,
              originName: r.originName,
              destStopId: r.destStopId,
              destStopName: r.destStopName,
              addedAt: r.addedAt,
            ))
        .toList();
  }

  Stream<List<FavoriteRouteEntity>> watchFavoriteRoutes() {
    return _db.watchFavoriteRoutes().map((rows) => rows
        .map((r) => FavoriteRouteEntity(
              id: r.id,
              originLat: r.originLat,
              originLon: r.originLon,
              originName: r.originName,
              destStopId: r.destStopId,
              destStopName: r.destStopName,
              addedAt: r.addedAt,
            ))
        .toList());
  }

  Future<int> addFavoriteRoute({
    required double originLat,
    required double originLon,
    required String originName,
    required String destStopId,
    required String destStopName,
  }) {
    return _db.addFavoriteRoute(
      originLat: originLat,
      originLon: originLon,
      originName: originName,
      destStopId: destStopId,
      destStopName: destStopName,
    );
  }

  Future<void> removeFavoriteRoute(int id) => _db.removeFavoriteRoute(id);

  // ─── Stop times for trip detail ────────────────────────────────

  Future<List<StopTimeDetail>> getStopTimesForTripWithNames(
      String tripId) async {
    final rows = await _db.getStopTimesForTripWithNames(tripId);
    return rows
        .map((r) => StopTimeDetail(
              stopId: r.stopId,
              stopName: r.stopName,
              arrivalTime: r.arrivalTime,
              departureTime: r.departureTime,
              stopSequence: r.stopSequence,
              stopLat: r.stopLat,
              stopLon: r.stopLon,
            ))
        .toList();
  }
}
