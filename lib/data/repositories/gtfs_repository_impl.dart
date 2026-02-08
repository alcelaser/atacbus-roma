import '../../core/utils/date_time_utils.dart';
import '../../domain/entities/stop.dart';
import '../../domain/entities/route_entity.dart';
import '../../domain/entities/departure.dart';
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
    // 1. Determine active service IDs for today (cached per date)
    final serviceDate = DateTimeUtils.getServiceDate();
    final dateStr = DateTimeUtils.toGtfsDate(serviceDate);
    final weekday = serviceDate.weekday;

    var activeServiceIds = await _getCachedServiceIds(dateStr, weekday);

    // 2. Fallback: if calendar doesn't cover today (expired data),
    //    use all service IDs so the user still sees times.
    if (activeServiceIds.isEmpty) {
      activeServiceIds = await _db.getAllServiceIds();
    }

    // 3. Single JOIN query: stop_times + trips + routes
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
      final seconds = DateTimeUtils.parseGtfsTime(row.departureTime);
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
    final results = await _db.getRoutesForStopJoin(stopId);
    return results.map(_mapRoute).toList();
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
