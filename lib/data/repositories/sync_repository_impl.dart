import 'package:drift/drift.dart';
import '../datasources/local/database/app_database.dart';
import '../datasources/local/gtfs_file_storage.dart';
import '../datasources/local/preferences_storage.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/gtfs_csv_parser.dart';

enum SyncStage {
  downloading,
  extracting,
  importingStops,
  importingRoutes,
  importingTrips,
  importingStopTimes,
  importingCalendar,
  importingCalendarDates,
  importingShapes,
  complete,
  error,
}

class SyncProgress {
  final SyncStage stage;
  final double progress; // 0.0 - 1.0
  final String? errorMessage;

  const SyncProgress({
    required this.stage,
    this.progress = 0.0,
    this.errorMessage,
  });
}

class SyncRepositoryImpl {
  final AppDatabase _db;
  final GtfsFileStorage _fileStorage;
  final PreferencesStorage _preferencesStorage;

  SyncRepositoryImpl({
    required AppDatabase db,
    required GtfsFileStorage fileStorage,
    required PreferencesStorage preferencesStorage,
  })  : _db = db,
        _fileStorage = fileStorage,
        _preferencesStorage = preferencesStorage;

  Stream<SyncProgress> syncGtfsData() async* {
    try {
      // Stage 1: Download
      yield const SyncProgress(stage: SyncStage.downloading, progress: 0.0);
      String extractedDir;
      try {
        extractedDir = await _fileStorage.downloadAndExtractGtfs(
          onProgress: (received, total) {
            // Progress callback - cannot yield from here, but logged
          },
        );
      } catch (e) {
        yield SyncProgress(
          stage: SyncStage.error,
          errorMessage: 'Download failed: $e',
        );
        return;
      }

      yield const SyncProgress(stage: SyncStage.extracting, progress: 0.1);

      // Stage 2: Clear existing data
      await _db.clearGtfsData();

      // Stage 3: Import stops
      yield const SyncProgress(stage: SyncStage.importingStops, progress: 0.15);
      await _importStops(extractedDir);

      // Stage 4: Import routes
      yield const SyncProgress(stage: SyncStage.importingRoutes, progress: 0.25);
      await _importRoutes(extractedDir);

      // Stage 5: Import calendar
      yield const SyncProgress(stage: SyncStage.importingCalendar, progress: 0.30);
      await _importCalendar(extractedDir);

      // Stage 6: Import calendar dates
      yield const SyncProgress(stage: SyncStage.importingCalendarDates, progress: 0.35);
      await _importCalendarDates(extractedDir);

      // Stage 7: Import trips
      yield const SyncProgress(stage: SyncStage.importingTrips, progress: 0.40);
      await _importTrips(extractedDir);

      // Stage 8: Import stop times (largest, ~1M+ rows)
      yield const SyncProgress(stage: SyncStage.importingStopTimes, progress: 0.50);
      await _importStopTimes(extractedDir);

      // Stage 9: Import shapes
      yield const SyncProgress(stage: SyncStage.importingShapes, progress: 0.85);
      await _importShapes(extractedDir);

      // Cleanup extracted files
      await _fileStorage.cleanupExtracted();

      // Save sync date
      await _preferencesStorage.setLastSyncDate(DateTime.now());

      yield const SyncProgress(stage: SyncStage.complete, progress: 1.0);
    } catch (e) {
      yield SyncProgress(
        stage: SyncStage.error,
        errorMessage: 'Sync failed: $e',
      );
    }
  }

  Future<void> _importStops(String dir) async {
    final content = await _fileStorage.readGtfsFile(dir, 'stops.txt');
    final rows = GtfsCsvParser.parse(content);
    final companions = <GtfsStopsCompanion>[];
    for (final row in rows) {
      companions.add(GtfsStopsCompanion.insert(
        stopId: row['stop_id'] ?? '',
        stopCode: Value(row['stop_code']),
        stopName: row['stop_name'] ?? '',
        stopDesc: Value(row['stop_desc']),
        stopLat: double.tryParse(row['stop_lat'] ?? '') ?? 0.0,
        stopLon: double.tryParse(row['stop_lon'] ?? '') ?? 0.0,
        locationType: Value(int.tryParse(row['location_type'] ?? '')),
        parentStation: Value(row['parent_station']),
      ));
    }
    // Batch insert
    for (var i = 0; i < companions.length; i += AppConstants.dbBatchSize) {
      final end = (i + AppConstants.dbBatchSize).clamp(0, companions.length);
      await _db.insertStops(companions.sublist(i, end));
    }
  }
  Future<void> _importRoutes(String dir) async {
    final content = await _fileStorage.readGtfsFile(dir, 'routes.txt');
    final rows = GtfsCsvParser.parse(content);
    final companions = <GtfsRoutesCompanion>[];
    for (final row in rows) {
      companions.add(GtfsRoutesCompanion.insert(
        routeId: row['route_id'] ?? '',
        agencyId: Value(row['agency_id']),
        routeShortName: row['route_short_name'] ?? '',
        routeLongName: row['route_long_name'] ?? '',
        routeType: int.tryParse(row['route_type'] ?? '') ?? 3,
        routeColor: Value(row['route_color']),
        routeTextColor: Value(row['route_text_color']),
        routeDesc: Value(row['route_desc']),
      ));
    }
    // Batch insert
    for (var i = 0; i < companions.length; i += AppConstants.dbBatchSize) {
      final end = (i + AppConstants.dbBatchSize).clamp(0, companions.length);
      await _db.insertRoutes(companions.sublist(i, end));
    }
  }
  Future<void> _importTrips(String dir) async {
    final content = await _fileStorage.readGtfsFile(dir, 'trips.txt');
    final rows = GtfsCsvParser.parse(content);
    final companions = <GtfsTripsCompanion>[];
    for (final row in rows) {
      companions.add(GtfsTripsCompanion.insert(
        tripId: row['trip_id'] ?? '',
        routeId: row['route_id'] ?? '',
        serviceId: row['service_id'] ?? '',
        tripHeadsign: Value(row['trip_headsign']),
        tripShortName: Value(row['trip_short_name']),
        directionId: Value(int.tryParse(row['direction_id'] ?? '')),
        shapeId: Value(row['shape_id']),
      ));
    }
    // Batch insert
    for (var i = 0; i < companions.length; i += AppConstants.dbBatchSize) {
      final end = (i + AppConstants.dbBatchSize).clamp(0, companions.length);
      await _db.insertTrips(companions.sublist(i, end));
    }
  }
  Future<void> _importStopTimes(String dir) async {
    final content = await _fileStorage.readGtfsFile(dir, 'stop_times.txt');
    final rows = GtfsCsvParser.parse(content);
    final companions = <GtfsStopTimesCompanion>[];
    for (final row in rows) {
      companions.add(GtfsStopTimesCompanion.insert(
        tripId: row['trip_id'] ?? '',
        arrivalTime: row['arrival_time'] ?? '',
        departureTime: row['departure_time'] ?? '',
        stopId: row['stop_id'] ?? '',
        stopSequence: int.tryParse(row['stop_sequence'] ?? '') ?? 0,
        stopHeadsign: Value(row['stop_headsign']),
        pickupType: Value(int.tryParse(row['pickup_type'] ?? '')),
        dropOffType: Value(int.tryParse(row['drop_off_type'] ?? '')),
      ));
    }
    // Batch insert
    for (var i = 0; i < companions.length; i += AppConstants.dbBatchSize) {
      final end = (i + AppConstants.dbBatchSize).clamp(0, companions.length);
      await _db.insertStopTimes(companions.sublist(i, end));
    }
  }
  Future<void> _importCalendar(String dir) async {
    if (!await _fileStorage.gtfsFileExists(dir, 'calendar.txt')) return;
    final content = await _fileStorage.readGtfsFile(dir, 'calendar.txt');
    final rows = GtfsCsvParser.parse(content);
    final companions = <GtfsCalendarCompanion>[];
    for (final row in rows) {
      companions.add(GtfsCalendarCompanion.insert(
        serviceId: row['service_id'] ?? '',
        monday: row['monday'] == '1',
        tuesday: row['tuesday'] == '1',
        wednesday: row['wednesday'] == '1',
        thursday: row['thursday'] == '1',
        friday: row['friday'] == '1',
        saturday: row['saturday'] == '1',
        sunday: row['sunday'] == '1',
        startDate: row['start_date'] ?? '',
        endDate: row['end_date'] ?? '',
      ));
    }
    // Batch insert
    for (var i = 0; i < companions.length; i += AppConstants.dbBatchSize) {
      final end = (i + AppConstants.dbBatchSize).clamp(0, companions.length);
      await _db.insertCalendar(companions.sublist(i, end));
    }
  }
  Future<void> _importCalendarDates(String dir) async {
    if (!await _fileStorage.gtfsFileExists(dir, 'calendar_dates.txt')) return;
    final content = await _fileStorage.readGtfsFile(dir, 'calendar_dates.txt');
    final rows = GtfsCsvParser.parse(content);
    final companions = <GtfsCalendarDatesCompanion>[];
    for (final row in rows) {
      companions.add(GtfsCalendarDatesCompanion.insert(
        serviceId: row['service_id'] ?? '',
        date: row['date'] ?? '',
        exceptionType: int.tryParse(row['exception_type'] ?? '') ?? 0,
      ));
    }
    // Batch insert
    for (var i = 0; i < companions.length; i += AppConstants.dbBatchSize) {
      final end = (i + AppConstants.dbBatchSize).clamp(0, companions.length);
      await _db.insertCalendarDates(companions.sublist(i, end));
    }
  }
  Future<void> _importShapes(String dir) async {
    if (!await _fileStorage.gtfsFileExists(dir, 'shapes.txt')) return;
    final content = await _fileStorage.readGtfsFile(dir, 'shapes.txt');
    final rows = GtfsCsvParser.parse(content);
    final companions = <GtfsShapesCompanion>[];
    for (final row in rows) {
      companions.add(GtfsShapesCompanion.insert(
        shapeId: row['shape_id'] ?? '',
        shapePtLat: double.tryParse(row['shape_pt_lat'] ?? '') ?? 0.0,
        shapePtLon: double.tryParse(row['shape_pt_lon'] ?? '') ?? 0.0,
        shapePtSequence: int.tryParse(row['shape_pt_sequence'] ?? '') ?? 0,
      ));
    }
    // Batch insert
    for (var i = 0; i < companions.length; i += AppConstants.dbBatchSize) {
      final end = (i + AppConstants.dbBatchSize).clamp(0, companions.length);
      await _db.insertShapes(companions.sublist(i, end));
    }
  }
}
