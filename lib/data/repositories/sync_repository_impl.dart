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
            // Progress callback - cannot yield from here
          },
        );
      } catch (e) {
        yield SyncProgress(
          stage: SyncStage.error,
          errorMessage: 'Download failed: $e',
        );
        return;
      }

      yield const SyncProgress(stage: SyncStage.extracting, progress: 0.10);

      // Stage 2: Clear existing data
      await _db.clearGtfsData();

      // Stage 3: Import stops
      yield const SyncProgress(stage: SyncStage.importingStops, progress: 0.12);
      await _importTable(extractedDir, 'stops.txt', _parseStop, _db.insertStops);

      // Stage 4: Import routes
      yield const SyncProgress(stage: SyncStage.importingRoutes, progress: 0.18);
      await _importTable(extractedDir, 'routes.txt', _parseRoute, _db.insertRoutes);

      // Stage 5: Import calendar
      yield const SyncProgress(stage: SyncStage.importingCalendar, progress: 0.22);
      if (await _fileStorage.gtfsFileExists(extractedDir, 'calendar.txt')) {
        await _importTable(extractedDir, 'calendar.txt', _parseCalendar, _db.insertCalendar);
      }

      // Stage 6: Import calendar dates
      yield const SyncProgress(stage: SyncStage.importingCalendarDates, progress: 0.26);
      if (await _fileStorage.gtfsFileExists(extractedDir, 'calendar_dates.txt')) {
        await _importTable(extractedDir, 'calendar_dates.txt', _parseCalendarDate, _db.insertCalendarDates);
      }

      // Stage 7: Import trips
      yield const SyncProgress(stage: SyncStage.importingTrips, progress: 0.30);
      await _importTable(extractedDir, 'trips.txt', _parseTrip, _db.insertTrips);

      // Stage 8: Import stop times (largest table, ~1M+ rows)
      // Uses streaming line-by-line approach to avoid holding the full
      // parsed dataset in memory and to keep the UI responsive.
      yield const SyncProgress(stage: SyncStage.importingStopTimes, progress: 0.38);
      await for (final fraction in _importLargeTable(
        extractedDir, 'stop_times.txt', _parseStopTime, _db.insertStopTimes,
      )) {
        // Map fraction (0.0-1.0) to progress range 0.38-0.82
        yield SyncProgress(
          stage: SyncStage.importingStopTimes,
          progress: 0.38 + (fraction * 0.44),
        );
      }

      // Stage 9: Import shapes (can also be large)
      yield const SyncProgress(stage: SyncStage.importingShapes, progress: 0.84);
      if (await _fileStorage.gtfsFileExists(extractedDir, 'shapes.txt')) {
        await for (final fraction in _importLargeTable(
          extractedDir, 'shapes.txt', _parseShape, _db.insertShapes,
        )) {
          yield SyncProgress(
            stage: SyncStage.importingShapes,
            progress: 0.84 + (fraction * 0.12),
          );
        }
      }

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

  // ─── Generic small-table import ──────────────────────────────────

  Future<void> _importTable<T>(
    String dir,
    String filename,
    T Function(Map<String, String> row) parse,
    Future<void> Function(List<T> rows) insert,
  ) async {
    final content = await _fileStorage.readGtfsFile(dir, filename);
    final rows = GtfsCsvParser.parse(content);
    final companions = rows.map(parse).toList();
    for (var i = 0; i < companions.length; i += AppConstants.dbBatchSize) {
      final end = (i + AppConstants.dbBatchSize).clamp(0, companions.length);
      await insert(companions.sublist(i, end));
    }
  }

  // ─── Streaming large-table import (stop_times, shapes) ──────────
  //
  // Reads the file, splits into lines, parses and inserts in batches.
  // Yields a fraction (0.0-1.0) after each batch insert so the caller
  // can update progress. Uses Future.delayed(Duration.zero) between
  // batches to yield to the event loop and keep the UI responsive.

  Stream<double> _importLargeTable<T>(
    String dir,
    String filename,
    T Function(Map<String, String> row) parse,
    Future<void> Function(List<T> rows) insert,
  ) async* {
    final content = await _fileStorage.readGtfsFile(dir, filename);

    // Normalize line endings
    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n');
    if (lines.isEmpty) return;

    // Parse header
    final headerLine = lines.first;
    final headers = headerLine.split(',').map((h) => h.trim()).toList();

    final totalDataLines = lines.length - 1; // minus header
    if (totalDataLines <= 0) return;

    var batch = <T>[];
    var processed = 0;

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      // Fast CSV parse for each row (handles quoted fields)
      final values = _splitCsvLine(line);
      final map = <String, String>{};
      for (var j = 0; j < headers.length && j < values.length; j++) {
        map[headers[j]] = values[j];
      }

      batch.add(parse(map));
      processed++;

      if (batch.length >= AppConstants.dbBatchSize) {
        await insert(batch);
        batch = <T>[];
        yield processed / totalDataLines;
        // Yield to event loop so UI can repaint
        await Future<void>.delayed(Duration.zero);
      }
    }

    // Insert remaining
    if (batch.isNotEmpty) {
      await insert(batch);
    }
    yield 1.0;
  }

  /// Fast CSV line splitter that handles quoted fields.
  static List<String> _splitCsvLine(String line) {
    final result = <String>[];
    var current = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final ch = line[i];
      if (ch == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          current.write('"');
          i++; // skip escaped quote
        } else {
          inQuotes = !inQuotes;
        }
      } else if (ch == ',' && !inQuotes) {
        result.add(current.toString().trim());
        current = StringBuffer();
      } else {
        current.write(ch);
      }
    }
    result.add(current.toString().trim());
    return result;
  }

  // ─── Row parsers ─────────────────────────────────────────────────

  static GtfsStopsCompanion _parseStop(Map<String, String> row) {
    return GtfsStopsCompanion.insert(
      stopId: row['stop_id'] ?? '',
      stopCode: Value(row['stop_code']),
      stopName: row['stop_name'] ?? '',
      stopDesc: Value(row['stop_desc']),
      stopLat: double.tryParse(row['stop_lat'] ?? '') ?? 0.0,
      stopLon: double.tryParse(row['stop_lon'] ?? '') ?? 0.0,
      locationType: Value(int.tryParse(row['location_type'] ?? '')),
      parentStation: Value(row['parent_station']),
    );
  }

  static GtfsRoutesCompanion _parseRoute(Map<String, String> row) {
    return GtfsRoutesCompanion.insert(
      routeId: row['route_id'] ?? '',
      agencyId: Value(row['agency_id']),
      routeShortName: row['route_short_name'] ?? '',
      routeLongName: row['route_long_name'] ?? '',
      routeType: int.tryParse(row['route_type'] ?? '') ?? 3,
      routeColor: Value(row['route_color']),
      routeTextColor: Value(row['route_text_color']),
      routeDesc: Value(row['route_desc']),
    );
  }

  static GtfsTripsCompanion _parseTrip(Map<String, String> row) {
    return GtfsTripsCompanion.insert(
      tripId: row['trip_id'] ?? '',
      routeId: row['route_id'] ?? '',
      serviceId: row['service_id'] ?? '',
      tripHeadsign: Value(row['trip_headsign']),
      tripShortName: Value(row['trip_short_name']),
      directionId: Value(int.tryParse(row['direction_id'] ?? '')),
      shapeId: Value(row['shape_id']),
    );
  }

  static GtfsStopTimesCompanion _parseStopTime(Map<String, String> row) {
    return GtfsStopTimesCompanion.insert(
      tripId: row['trip_id'] ?? '',
      arrivalTime: row['arrival_time'] ?? '',
      departureTime: row['departure_time'] ?? '',
      stopId: row['stop_id'] ?? '',
      stopSequence: int.tryParse(row['stop_sequence'] ?? '') ?? 0,
      stopHeadsign: Value(row['stop_headsign']),
      pickupType: Value(int.tryParse(row['pickup_type'] ?? '')),
      dropOffType: Value(int.tryParse(row['drop_off_type'] ?? '')),
    );
  }

  static GtfsCalendarCompanion _parseCalendar(Map<String, String> row) {
    return GtfsCalendarCompanion.insert(
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
    );
  }

  static GtfsCalendarDatesCompanion _parseCalendarDate(Map<String, String> row) {
    return GtfsCalendarDatesCompanion.insert(
      serviceId: row['service_id'] ?? '',
      date: row['date'] ?? '',
      exceptionType: int.tryParse(row['exception_type'] ?? '') ?? 0,
    );
  }

  static GtfsShapesCompanion _parseShape(Map<String, String> row) {
    return GtfsShapesCompanion.insert(
      shapeId: row['shape_id'] ?? '',
      shapePtLat: double.tryParse(row['shape_pt_lat'] ?? '') ?? 0.0,
      shapePtLon: double.tryParse(row['shape_pt_lon'] ?? '') ?? 0.0,
      shapePtSequence: int.tryParse(row['shape_pt_sequence'] ?? '') ?? 0,
    );
  }
}
