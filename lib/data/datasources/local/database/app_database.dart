import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

part 'app_database.g.dart';

// ─── Tables ───────────────────────────────────────────────────────

class GtfsStops extends Table {
  TextColumn get stopId => text()();
  TextColumn get stopCode => text().nullable()();
  TextColumn get stopName => text()();
  TextColumn get stopDesc => text().nullable()();
  RealColumn get stopLat => real()();
  RealColumn get stopLon => real()();
  IntColumn get locationType => integer().nullable()();
  TextColumn get parentStation => text().nullable()();

  @override
  Set<Column> get primaryKey => {stopId};
}

class GtfsRoutes extends Table {
  TextColumn get routeId => text()();
  TextColumn get agencyId => text().nullable()();
  TextColumn get routeShortName => text()();
  TextColumn get routeLongName => text()();
  IntColumn get routeType => integer()();
  TextColumn get routeColor => text().nullable()();
  TextColumn get routeTextColor => text().nullable()();
  TextColumn get routeDesc => text().nullable()();

  @override
  Set<Column> get primaryKey => {routeId};
}

class GtfsTrips extends Table {
  TextColumn get tripId => text()();
  TextColumn get routeId => text()();
  TextColumn get serviceId => text()();
  TextColumn get tripHeadsign => text().nullable()();
  TextColumn get tripShortName => text().nullable()();
  IntColumn get directionId => integer().nullable()();
  TextColumn get shapeId => text().nullable()();

  @override
  Set<Column> get primaryKey => {tripId};
}

class GtfsStopTimes extends Table {
  TextColumn get tripId => text()();
  TextColumn get arrivalTime => text()();
  TextColumn get departureTime => text()();
  TextColumn get stopId => text()();
  IntColumn get stopSequence => integer()();
  TextColumn get stopHeadsign => text().nullable()();
  IntColumn get pickupType => integer().nullable()();
  IntColumn get dropOffType => integer().nullable()();

  @override
  Set<Column> get primaryKey => {tripId, stopSequence};
}

class GtfsCalendar extends Table {
  TextColumn get serviceId => text()();
  BoolColumn get monday => boolean()();
  BoolColumn get tuesday => boolean()();
  BoolColumn get wednesday => boolean()();
  BoolColumn get thursday => boolean()();
  BoolColumn get friday => boolean()();
  BoolColumn get saturday => boolean()();
  BoolColumn get sunday => boolean()();
  TextColumn get startDate => text()();
  TextColumn get endDate => text()();

  @override
  Set<Column> get primaryKey => {serviceId};
}

class GtfsCalendarDates extends Table {
  TextColumn get serviceId => text()();
  TextColumn get date => text()();
  IntColumn get exceptionType => integer()();

  @override
  Set<Column> get primaryKey => {serviceId, date};
}

class GtfsShapes extends Table {
  TextColumn get shapeId => text()();
  RealColumn get shapePtLat => real()();
  RealColumn get shapePtLon => real()();
  IntColumn get shapePtSequence => integer()();

  @override
  Set<Column> get primaryKey => {shapeId, shapePtSequence};
}

class FavoriteStops extends Table {
  TextColumn get stopId => text()();
  DateTimeColumn get addedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {stopId};
}

// ─── Departure row (from JOIN query) ────────────────────────────

class DepartureRow {
  final String tripId;
  final String departureTime;
  final String? stopHeadsign;
  final String routeId;
  final String serviceId;
  final String? tripHeadsign;
  final int? directionId;
  final String routeShortName;
  final String? routeColor;

  DepartureRow({
    required this.tripId,
    required this.departureTime,
    this.stopHeadsign,
    required this.routeId,
    required this.serviceId,
    this.tripHeadsign,
    this.directionId,
    required this.routeShortName,
    this.routeColor,
  });
}

// ─── Database ─────────────────────────────────────────────────────

@DriftDatabase(tables: [
  GtfsStops,
  GtfsRoutes,
  GtfsTrips,
  GtfsStopTimes,
  GtfsCalendar,
  GtfsCalendarDates,
  GtfsShapes,
  FavoriteStops,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (Migrator m) async {
          await m.createAll();
          await _createIndexes();
        },
        onUpgrade: (Migrator m, int from, int to) async {
          // Re-create indexes on every upgrade to ensure they exist
          await _createIndexes();
        },
      );

  Future<void> _createIndexes() async {
    // Primary lookup: departures for a stop
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_stop_times_stop_id ON gtfs_stop_times(stop_id)',
    );
    // Composite: stop + departure_time for range scans
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_stop_times_stop_dep ON gtfs_stop_times(stop_id, departure_time)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_stop_times_trip_id ON gtfs_stop_times(trip_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_trips_route_id ON gtfs_trips(route_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_trips_service_id ON gtfs_trips(service_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_stops_name ON gtfs_stops(stop_name COLLATE NOCASE)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_calendar_dates_date ON gtfs_calendar_dates(date)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_calendar_dates_service ON gtfs_calendar_dates(service_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_shapes_shape_id ON gtfs_shapes(shape_id)',
    );
  }

  // ─── Clear all GTFS tables (for re-sync) ─────────────────────

  Future<void> clearGtfsData() async {
    await transaction(() async {
      await delete(gtfsStopTimes).go();
      await delete(gtfsTrips).go();
      await delete(gtfsStops).go();
      await delete(gtfsRoutes).go();
      await delete(gtfsCalendar).go();
      await delete(gtfsCalendarDates).go();
      await delete(gtfsShapes).go();
    });
  }

  // ─── Batch inserts ────────────────────────────────────────────

  Future<void> insertStops(List<GtfsStopsCompanion> rows) async {
    await batch(
        (b) => b.insertAll(gtfsStops, rows, mode: InsertMode.insertOrReplace));
  }

  Future<void> insertRoutes(List<GtfsRoutesCompanion> rows) async {
    await batch(
        (b) => b.insertAll(gtfsRoutes, rows, mode: InsertMode.insertOrReplace));
  }

  Future<void> insertTrips(List<GtfsTripsCompanion> rows) async {
    await batch(
        (b) => b.insertAll(gtfsTrips, rows, mode: InsertMode.insertOrReplace));
  }

  Future<void> insertStopTimes(List<GtfsStopTimesCompanion> rows) async {
    await batch((b) =>
        b.insertAll(gtfsStopTimes, rows, mode: InsertMode.insertOrReplace));
  }

  Future<void> insertCalendar(List<GtfsCalendarCompanion> rows) async {
    await batch((b) =>
        b.insertAll(gtfsCalendar, rows, mode: InsertMode.insertOrReplace));
  }

  Future<void> insertCalendarDates(
      List<GtfsCalendarDatesCompanion> rows) async {
    await batch((b) =>
        b.insertAll(gtfsCalendarDates, rows, mode: InsertMode.insertOrReplace));
  }

  Future<void> insertShapes(List<GtfsShapesCompanion> rows) async {
    await batch(
        (b) => b.insertAll(gtfsShapes, rows, mode: InsertMode.insertOrReplace));
  }

  // ─── Stop queries ─────────────────────────────────────────────

  Future<List<GtfsStop>> searchStopsByName(String query) {
    // Escape LIKE wildcards in user input to prevent unintended matches
    final escaped = query
        .replaceAll('\\', '\\\\')
        .replaceAll('%', '\\%')
        .replaceAll('_', '\\_');
    return (select(gtfsStops)
          ..where((s) => s.stopName.like('%$escaped%'))
          ..limit(50))
        .get();
  }

  Future<GtfsStop?> getStopById(String stopId) {
    return (select(gtfsStops)..where((s) => s.stopId.equals(stopId)))
        .getSingleOrNull();
  }

  Future<List<GtfsStop>> getAllStops() {
    return select(gtfsStops).get();
  }

  // ─── Route queries ────────────────────────────────────────────

  Future<List<GtfsRoute>> getAllRoutes() {
    return (select(gtfsRoutes)
          ..orderBy([(r) => OrderingTerm.asc(r.routeShortName)]))
        .get();
  }

  Future<List<GtfsRoute>> getRoutesByType(int type) {
    return (select(gtfsRoutes)
          ..where((r) => r.routeType.equals(type))
          ..orderBy([(r) => OrderingTerm.asc(r.routeShortName)]))
        .get();
  }

  Future<GtfsRoute?> getRouteById(String routeId) {
    return (select(gtfsRoutes)..where((r) => r.routeId.equals(routeId)))
        .getSingleOrNull();
  }

  // ─── Trip queries ─────────────────────────────────────────────

  Future<List<GtfsTrip>> getTripsByRouteId(String routeId) {
    return (select(gtfsTrips)..where((t) => t.routeId.equals(routeId))).get();
  }

  Future<GtfsTrip?> getTripById(String tripId) {
    return (select(gtfsTrips)..where((t) => t.tripId.equals(tripId)))
        .getSingleOrNull();
  }

  // ─── Stop time queries ────────────────────────────────────────

  Future<List<GtfsStopTime>> getStopTimesForStop(String stopId) {
    return (select(gtfsStopTimes)
          ..where((st) => st.stopId.equals(stopId))
          ..orderBy([(st) => OrderingTerm.asc(st.departureTime)]))
        .get();
  }

  Future<List<GtfsStopTime>> getStopTimesForTrip(String tripId) {
    return (select(gtfsStopTimes)
          ..where((st) => st.tripId.equals(tripId))
          ..orderBy([(st) => OrderingTerm.asc(st.stopSequence)]))
        .get();
  }

  /// Efficient single-query departure lookup using JOIN.
  /// Returns departure data with trip and route info for a given stop.
  /// If serviceIds is non-empty, filters to only those service IDs.
  Future<List<DepartureRow>> getDeparturesForStop(
    String stopId,
    Set<String> serviceIds,
  ) async {
    String query;
    List<Variable> vars;

    if (serviceIds.isNotEmpty) {
      final placeholders = List.filled(serviceIds.length, '?').join(', ');
      query = '''
        SELECT st.trip_id, st.departure_time, st.stop_headsign,
               t.route_id, t.service_id, t.trip_headsign, t.direction_id,
               r.route_short_name, r.route_color
        FROM gtfs_stop_times st
        INNER JOIN gtfs_trips t ON t.trip_id = st.trip_id
        INNER JOIN gtfs_routes r ON r.route_id = t.route_id
        WHERE st.stop_id = ?
          AND t.service_id IN ($placeholders)
        ORDER BY st.departure_time
      ''';
      vars = [
        Variable.withString(stopId),
        ...serviceIds.map((id) => Variable.withString(id)),
      ];
    } else {
      // Fallback: no calendar filtering, return all
      query = '''
        SELECT st.trip_id, st.departure_time, st.stop_headsign,
               t.route_id, t.service_id, t.trip_headsign, t.direction_id,
               r.route_short_name, r.route_color
        FROM gtfs_stop_times st
        INNER JOIN gtfs_trips t ON t.trip_id = st.trip_id
        INNER JOIN gtfs_routes r ON r.route_id = t.route_id
        WHERE st.stop_id = ?
        ORDER BY st.departure_time
      ''';
      vars = [Variable.withString(stopId)];
    }

    final results = await customSelect(query, variables: vars).get();

    return results
        .map((row) => DepartureRow(
              tripId: row.read<String>('trip_id'),
              departureTime: row.read<String>('departure_time'),
              stopHeadsign: row.readNullable<String>('stop_headsign'),
              routeId: row.read<String>('route_id'),
              serviceId: row.read<String>('service_id'),
              tripHeadsign: row.readNullable<String>('trip_headsign'),
              directionId: row.readNullable<int>('direction_id'),
              routeShortName: row.read<String>('route_short_name'),
              routeColor: row.readNullable<String>('route_color'),
            ))
        .toList();
  }

  /// Get all distinct service IDs from trips (used as fallback when
  /// calendar data doesn't cover the current date).
  Future<Set<String>> getAllServiceIds() async {
    final results = await customSelect(
      'SELECT DISTINCT service_id FROM gtfs_trips',
    ).get();
    return results.map((r) => r.read<String>('service_id')).toSet();
  }

  /// Get routes serving a stop efficiently via JOIN.
  Future<List<GtfsRoute>> getRoutesForStopJoin(String stopId) async {
    final results = await customSelect('''
      SELECT DISTINCT r.*
      FROM gtfs_stop_times st
      INNER JOIN gtfs_trips t ON t.trip_id = st.trip_id
      INNER JOIN gtfs_routes r ON r.route_id = t.route_id
      WHERE st.stop_id = ?
      ORDER BY r.route_short_name
    ''', variables: [Variable.withString(stopId)]).get();

    return results
        .map((row) => GtfsRoute(
              routeId: row.read<String>('route_id'),
              agencyId: row.readNullable<String>('agency_id'),
              routeShortName: row.read<String>('route_short_name'),
              routeLongName: row.read<String>('route_long_name'),
              routeType: row.read<int>('route_type'),
              routeColor: row.readNullable<String>('route_color'),
              routeTextColor: row.readNullable<String>('route_text_color'),
              routeDesc: row.readNullable<String>('route_desc'),
            ))
        .toList();
  }

  /// Get stops for a route efficiently via JOIN.
  /// Uses the trip with the most stops (most representative) and returns
  /// stops in stop_sequence order.
  /// If [directionId] is provided, filters to that direction only.
  Future<List<GtfsStop>> getStopsForRouteJoin(String routeId,
      {int? directionId}) async {
    // Find the trip with the most stops for this route (optionally filtered by direction)
    String tripQuery;
    List<Variable> tripVars;
    if (directionId != null) {
      tripQuery = '''
        SELECT st.trip_id, COUNT(*) AS stop_count
        FROM gtfs_stop_times st
        INNER JOIN gtfs_trips t ON t.trip_id = st.trip_id
        WHERE t.route_id = ? AND t.direction_id = ?
        GROUP BY st.trip_id
        ORDER BY stop_count DESC
        LIMIT 1
      ''';
      tripVars = [Variable.withString(routeId), Variable.withInt(directionId)];
    } else {
      tripQuery = '''
        SELECT st.trip_id, COUNT(*) AS stop_count
        FROM gtfs_stop_times st
        INNER JOIN gtfs_trips t ON t.trip_id = st.trip_id
        WHERE t.route_id = ?
        GROUP BY st.trip_id
        ORDER BY stop_count DESC
        LIMIT 1
      ''';
      tripVars = [Variable.withString(routeId)];
    }

    final tripResult =
        await customSelect(tripQuery, variables: tripVars).getSingleOrNull();

    if (tripResult == null) return [];

    final tripId = tripResult.read<String>('trip_id');

    final results = await customSelect('''
      SELECT s.*
      FROM gtfs_stop_times st
      INNER JOIN gtfs_stops s ON s.stop_id = st.stop_id
      WHERE st.trip_id = ?
      ORDER BY st.stop_sequence
    ''', variables: [Variable.withString(tripId)]).get();

    return results
        .map((row) => GtfsStop(
              stopId: row.read<String>('stop_id'),
              stopCode: row.readNullable<String>('stop_code'),
              stopName: row.read<String>('stop_name'),
              stopDesc: row.readNullable<String>('stop_desc'),
              stopLat: row.read<double>('stop_lat'),
              stopLon: row.read<double>('stop_lon'),
              locationType: row.readNullable<int>('location_type'),
              parentStation: row.readNullable<String>('parent_station'),
            ))
        .toList();
  }

  /// Get available direction IDs for a route.
  Future<List<int>> getDirectionsForRoute(String routeId) async {
    final results = await customSelect('''
      SELECT DISTINCT t.direction_id
      FROM gtfs_trips t
      WHERE t.route_id = ? AND t.direction_id IS NOT NULL
      ORDER BY t.direction_id
    ''', variables: [Variable.withString(routeId)]).get();
    return results.map((row) => row.read<int>('direction_id')).toList();
  }

  /// Get the headsign for a route direction.
  Future<String?> getHeadsignForDirection(
      String routeId, int directionId) async {
    final result = await customSelect('''
      SELECT t.trip_headsign
      FROM gtfs_trips t
      WHERE t.route_id = ? AND t.direction_id = ? AND t.trip_headsign IS NOT NULL
      LIMIT 1
    ''', variables: [
      Variable.withString(routeId),
      Variable.withInt(directionId),
    ]).getSingleOrNull();
    return result?.readNullable<String>('trip_headsign');
  }

  // ─── Calendar queries ─────────────────────────────────────────

  Future<GtfsCalendarData?> getCalendarByServiceId(String serviceId) {
    return (select(gtfsCalendar)..where((c) => c.serviceId.equals(serviceId)))
        .getSingleOrNull();
  }

  Future<List<GtfsCalendarData>> getAllCalendar() {
    return select(gtfsCalendar).get();
  }

  Future<List<GtfsCalendarDate>> getCalendarDatesByDate(String date) {
    return (select(gtfsCalendarDates)..where((c) => c.date.equals(date))).get();
  }

  Future<List<GtfsCalendarDate>> getCalendarDatesByServiceId(String serviceId) {
    return (select(gtfsCalendarDates)
          ..where((c) => c.serviceId.equals(serviceId)))
        .get();
  }

  // ─── Shape queries ────────────────────────────────────────────

  Future<List<GtfsShape>> getShapePoints(String shapeId) {
    return (select(gtfsShapes)
          ..where((s) => s.shapeId.equals(shapeId))
          ..orderBy([(s) => OrderingTerm.asc(s.shapePtSequence)]))
        .get();
  }

  // ─── Favorite queries ─────────────────────────────────────────

  Future<List<FavoriteStop>> getAllFavorites() {
    return (select(favoriteStops)
          ..orderBy([(f) => OrderingTerm.desc(f.addedAt)]))
        .get();
  }

  Future<bool> isFavorite(String stopId) async {
    final result = await (select(favoriteStops)
          ..where((f) => f.stopId.equals(stopId)))
        .getSingleOrNull();
    return result != null;
  }

  Future<void> addFavorite(String stopId) async {
    await into(favoriteStops).insertOnConflictUpdate(
      FavoriteStopsCompanion.insert(
        stopId: stopId,
        addedAt: DateTime.now(),
      ),
    );
  }

  Future<void> removeFavorite(String stopId) async {
    await (delete(favoriteStops)..where((f) => f.stopId.equals(stopId))).go();
  }

  Stream<List<FavoriteStop>> watchFavorites() {
    return (select(favoriteStops)
          ..orderBy([(f) => OrderingTerm.desc(f.addedAt)]))
        .watch();
  }

  // ─── Stats (for verifying sync) ───────────────────────────────

  Future<int> countStops() async {
    final result =
        await customSelect('SELECT COUNT(*) AS c FROM gtfs_stops').getSingle();
    return result.read<int>('c');
  }

  Future<int> countRoutes() async {
    final result =
        await customSelect('SELECT COUNT(*) AS c FROM gtfs_routes').getSingle();
    return result.read<int>('c');
  }

  Future<int> countTrips() async {
    final result =
        await customSelect('SELECT COUNT(*) AS c FROM gtfs_trips').getSingle();
    return result.read<int>('c');
  }

  Future<int> countStopTimes() async {
    final result =
        await customSelect('SELECT COUNT(*) AS c FROM gtfs_stop_times')
            .getSingle();
    return result.read<int>('c');
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'atacbus.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
