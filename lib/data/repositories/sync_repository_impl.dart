import 'dart:convert';
import 'package:drift/drift.dart';
import '../datasources/local/database/app_database.dart';
import '../datasources/local/gtfs_file_storage.dart';
import '../datasources/local/preferences_storage.dart';
import '../../core/constants/app_constants.dart';
import '../../core/utils/gtfs_csv_parser.dart';

enum SyncStage {
  downloading,
  comparing,
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
  final bool skippedBecauseUpToDate;

  const SyncProgress({
    required this.stage,
    this.progress = 0.0,
    this.errorMessage,
    this.skippedBecauseUpToDate = false,
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

  /// Differential sync: download → compare hash → import only changed tables.
  ///
  /// Flow:
  /// 1. Fetch server-side MD5 hash
  /// 2. Compare to stored hash from last successful sync
  /// 3. If same → skip (data is up to date)
  /// 4. If different/first sync → download ZIP, extract, import per-table
  /// 5. Each table is compared by content hash; unchanged tables are skipped
  /// 6. Changed tables are replaced atomically within transactions
  Stream<SyncProgress> syncGtfsData() async* {
    try {
      // ─── Stage 1: Fetch remote hash ───────────────────────────
      yield const SyncProgress(stage: SyncStage.comparing, progress: 0.0);

      final remoteHash = await _fileStorage.fetchRemoteMd5();
      final storedHash = await _preferencesStorage.getLastZipHash();

      // If we have a stored hash AND it matches the remote, AND we have
      // data in the DB, we can skip the download entirely.
      if (remoteHash != null && remoteHash == storedHash) {
        final stopCount = await _db.countStops();
        if (stopCount > 0) {
          yield const SyncProgress(
            stage: SyncStage.complete,
            progress: 1.0,
            skippedBecauseUpToDate: true,
          );
          return;
        }
        // Hash matches but DB is empty (e.g. cleared) — force re-import
      }

      // ─── Stage 2: Download ────────────────────────────────────
      yield const SyncProgress(stage: SyncStage.downloading, progress: 0.02);
      String tempZipPath;
      try {
        tempZipPath = await _fileStorage.downloadGtfsToTemp(
          onProgress: (received, total) {
            // Progress callback — cannot yield from here
          },
        );
      } catch (e) {
        yield SyncProgress(
          stage: SyncStage.error,
          errorMessage: 'Download failed: $e',
        );
        return;
      }

      // ─── Stage 3: Extract ─────────────────────────────────────
      yield const SyncProgress(stage: SyncStage.extracting, progress: 0.10);
      String extractedDir;
      try {
        extractedDir = await _fileStorage.extractZip(tempZipPath);
      } catch (e) {
        await _fileStorage.cleanupTempZip();
        yield SyncProgress(
          stage: SyncStage.error,
          errorMessage: 'Extraction failed: $e',
        );
        return;
      }

      // ─── Stage 4: Per-file differential import ────────────────
      final oldFileHashes = await _preferencesStorage.getFileHashes();
      final newFileHashes = <String, String>{};
      var importErrors = 0;

      // Table import order matters: stops & routes first (referenced by trips),
      // trips before stop_times (FK references), calendar early, shapes last.
      final tables = <_TableImportConfig>[
        _TableImportConfig(
          filename: 'stops.txt',
          stage: SyncStage.importingStops,
          progressStart: 0.12,
          progressEnd: 0.16,
          required: true,
        ),
        _TableImportConfig(
          filename: 'routes.txt',
          stage: SyncStage.importingRoutes,
          progressStart: 0.16,
          progressEnd: 0.20,
          required: true,
        ),
        _TableImportConfig(
          filename: 'calendar.txt',
          stage: SyncStage.importingCalendar,
          progressStart: 0.20,
          progressEnd: 0.24,
          required: false,
        ),
        _TableImportConfig(
          filename: 'calendar_dates.txt',
          stage: SyncStage.importingCalendarDates,
          progressStart: 0.24,
          progressEnd: 0.28,
          required: false,
        ),
        _TableImportConfig(
          filename: 'trips.txt',
          stage: SyncStage.importingTrips,
          progressStart: 0.28,
          progressEnd: 0.34,
          required: true,
        ),
        _TableImportConfig(
          filename: 'stop_times.txt',
          stage: SyncStage.importingStopTimes,
          progressStart: 0.34,
          progressEnd: 0.82,
          required: true,
          isLarge: true,
        ),
        _TableImportConfig(
          filename: 'shapes.txt',
          stage: SyncStage.importingShapes,
          progressStart: 0.82,
          progressEnd: 0.96,
          required: false,
          isLarge: true,
        ),
      ];

      for (final table in tables) {
        yield SyncProgress(
          stage: table.stage,
          progress: table.progressStart,
        );

        // Check if file exists
        final exists = await _fileStorage.gtfsFileExists(
          extractedDir, table.filename,
        );
        if (!exists) {
          if (table.required) {
            importErrors++;
          }
          continue;
        }

        // Read file content and compute hash
        final content = await _fileStorage.readGtfsFile(
          extractedDir, table.filename,
        );
        final contentHash = GtfsFileStorage.computeContentHash(content);
        newFileHashes[table.filename] = contentHash;

        // Skip if content hasn't changed
        if (contentHash == oldFileHashes[table.filename]) {
          // Verify table isn't empty (DB might have been cleared)
          final isEmpty = await _isTableEmpty(table.filename);
          if (!isEmpty) {
            continue; // Skip — data is unchanged and present in DB
          }
        }

        // Import the table
        try {
          if (table.isLarge) {
            await for (final fraction in _importLargeTableAtomic(
              extractedDir, table.filename,
            )) {
              yield SyncProgress(
                stage: table.stage,
                progress: table.progressStart +
                    (fraction *
                        (table.progressEnd - table.progressStart)),
              );
            }
          } else {
            await _importSmallTableAtomic(extractedDir, table.filename);
          }
        } catch (e) {
          importErrors++;
          // Don't abort — continue with other tables. Old data for this
          // table remains intact thanks to transactional import.
        }
      }

      // ─── Stage 5: Finalize ────────────────────────────────────
      yield const SyncProgress(stage: SyncStage.complete, progress: 0.97);

      // Cleanup
      await _fileStorage.cleanupExtracted();

      // Promote temp ZIP and persist hashes only on success
      if (importErrors == 0) {
        await _fileStorage.promoteZip(tempZipPath);
        if (remoteHash != null) {
          await _preferencesStorage.setLastZipHash(remoteHash);
        }
        await _preferencesStorage.setFileHashes(newFileHashes);
      } else {
        await _fileStorage.cleanupTempZip();
      }

      // Save sync date
      await _preferencesStorage.setLastSyncDate(DateTime.now());

      yield const SyncProgress(stage: SyncStage.complete, progress: 1.0);
    } catch (e) {
      await _fileStorage.cleanupTempZip();
      yield SyncProgress(
        stage: SyncStage.error,
        errorMessage: 'Sync failed: $e',
      );
    }
  }

  // ─── Check if a table is empty ────────────────────────────────

  Future<bool> _isTableEmpty(String filename) async {
    switch (filename) {
      case 'stops.txt':
        return (await _db.countStops()) == 0;
      case 'routes.txt':
        return (await _db.countRoutes()) == 0;
      case 'trips.txt':
        return (await _db.countTrips()) == 0;
      case 'stop_times.txt':
        return (await _db.countStopTimes()) == 0;
      case 'calendar.txt':
        return (await _db.getAllCalendar()).isEmpty;
      case 'calendar_dates.txt':
        // Can't easily check without a date — assume non-empty
        return false;
      case 'shapes.txt':
        return false; // Assume non-empty
      default:
        return false;
    }
  }

  // ─── Small table: atomic replace ──────────────────────────────

  Future<void> _importSmallTableAtomic(
    String dir,
    String filename,
  ) async {
    final content = await _fileStorage.readGtfsFile(dir, filename);
    final rows = GtfsCsvParser.parse(content);

    switch (filename) {
      case 'stops.txt':
        final companions = <GtfsStopsCompanion>[];
        for (final row in rows) {
          final parsed = _parseStop(row);
          if (parsed != null) companions.add(parsed);
        }
        await _db.replaceTableAtomically<GtfsStopsCompanion>(
          _db.clearStops, _db.insertStops, companions,
        );
        break;
      case 'routes.txt':
        final companions = <GtfsRoutesCompanion>[];
        for (final row in rows) {
          final parsed = _parseRoute(row);
          if (parsed != null) companions.add(parsed);
        }
        await _db.replaceTableAtomically<GtfsRoutesCompanion>(
          _db.clearRoutes, _db.insertRoutes, companions,
        );
        break;
      case 'calendar.txt':
        final companions = <GtfsCalendarCompanion>[];
        for (final row in rows) {
          final parsed = _parseCalendar(row);
          if (parsed != null) companions.add(parsed);
        }
        await _db.replaceTableAtomically<GtfsCalendarCompanion>(
          _db.clearCalendar, _db.insertCalendar, companions,
        );
        break;
      case 'calendar_dates.txt':
        final companions = <GtfsCalendarDatesCompanion>[];
        for (final row in rows) {
          final parsed = _parseCalendarDate(row);
          if (parsed != null) companions.add(parsed);
        }
        await _db.replaceTableAtomically<GtfsCalendarDatesCompanion>(
          _db.clearCalendarDates, _db.insertCalendarDates, companions,
        );
        break;
      case 'trips.txt':
        final companions = <GtfsTripsCompanion>[];
        for (final row in rows) {
          final parsed = _parseTrip(row);
          if (parsed != null) companions.add(parsed);
        }
        await _db.replaceTableAtomically<GtfsTripsCompanion>(
          _db.clearTrips, _db.insertTrips, companions,
        );
        break;
    }
  }

  // ─── Large table: streaming atomic replace ────────────────────

  Stream<double> _importLargeTableAtomic(
    String dir,
    String filename,
  ) async* {
    final content = await _fileStorage.readGtfsFile(dir, filename);

    // Normalize line endings
    final normalized = content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
    final lines = normalized.split('\n');
    if (lines.isEmpty) return;

    // Parse header
    var headerLine = lines.first;
    if (headerLine.isNotEmpty && headerLine.codeUnitAt(0) == 0xFEFF) {
      headerLine = headerLine.substring(1);
    }
    final headers = _splitCsvLine(headerLine).map((h) => h.trim()).toList();

    final totalDataLines = lines.length - 1;
    if (totalDataLines <= 0) return;

    // Parse ALL rows first (streaming into memory in batches)
    // Then replace atomically by clearing the table and inserting.
    // This ensures old data is only deleted once new data is ready.

    if (filename == 'stop_times.txt') {
      final allRows = <GtfsStopTimesCompanion>[];
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final values = _splitCsvLine(line);
        final map = <String, String>{};
        for (var j = 0; j < headers.length && j < values.length; j++) {
          map[headers[j]] = values[j];
        }
        final parsed = _parseStopTime(map);
        if (parsed != null) allRows.add(parsed);

        // Yield progress during parse phase (0.0 - 0.5)
        if (i % 50000 == 0) {
          yield (i / totalDataLines) * 0.5;
          await Future<void>.delayed(Duration.zero);
        }
      }

      // Now atomically replace: clear + batch insert in transaction
      yield 0.5;
      await _db.clearStopTimes();
      for (var i = 0; i < allRows.length; i += AppConstants.dbBatchSize) {
        final end = (i + AppConstants.dbBatchSize).clamp(0, allRows.length);
        await _db.insertStopTimes(allRows.sublist(i, end));
        yield 0.5 + ((i / allRows.length) * 0.5);
        await Future<void>.delayed(Duration.zero);
      }
    } else if (filename == 'shapes.txt') {
      final allRows = <GtfsShapesCompanion>[];
      for (var i = 1; i < lines.length; i++) {
        final line = lines[i].trim();
        if (line.isEmpty) continue;
        final values = _splitCsvLine(line);
        final map = <String, String>{};
        for (var j = 0; j < headers.length && j < values.length; j++) {
          map[headers[j]] = values[j];
        }
        final parsed = _parseShape(map);
        if (parsed != null) allRows.add(parsed);

        if (i % 50000 == 0) {
          yield (i / totalDataLines) * 0.5;
          await Future<void>.delayed(Duration.zero);
        }
      }

      yield 0.5;
      await _db.clearShapes();
      for (var i = 0; i < allRows.length; i += AppConstants.dbBatchSize) {
        final end = (i + AppConstants.dbBatchSize).clamp(0, allRows.length);
        await _db.insertShapes(allRows.sublist(i, end));
        yield 0.5 + ((i / allRows.length) * 0.5);
        await Future<void>.delayed(Duration.zero);
      }
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

  static GtfsStopsCompanion? _parseStop(Map<String, String> row) {
    final stopId = row['stop_id'] ?? '';
    if (stopId.isEmpty) return null;
    return GtfsStopsCompanion.insert(
      stopId: stopId,
      stopCode: Value(row['stop_code']),
      stopName: row['stop_name'] ?? '',
      stopDesc: Value(row['stop_desc']),
      stopLat: double.tryParse(row['stop_lat'] ?? '') ?? 0.0,
      stopLon: double.tryParse(row['stop_lon'] ?? '') ?? 0.0,
      locationType: Value(int.tryParse(row['location_type'] ?? '')),
      parentStation: Value(row['parent_station']),
    );
  }

  static GtfsRoutesCompanion? _parseRoute(Map<String, String> row) {
    final routeId = row['route_id'] ?? '';
    if (routeId.isEmpty) return null;
    return GtfsRoutesCompanion.insert(
      routeId: routeId,
      agencyId: Value(row['agency_id']),
      routeShortName: row['route_short_name'] ?? '',
      routeLongName: row['route_long_name'] ?? '',
      routeType: int.tryParse(row['route_type'] ?? '') ?? 3,
      routeColor: Value(row['route_color']),
      routeTextColor: Value(row['route_text_color']),
      routeDesc: Value(row['route_desc']),
    );
  }

  static GtfsTripsCompanion? _parseTrip(Map<String, String> row) {
    final tripId = row['trip_id'] ?? '';
    if (tripId.isEmpty) return null;
    return GtfsTripsCompanion.insert(
      tripId: tripId,
      routeId: row['route_id'] ?? '',
      serviceId: row['service_id'] ?? '',
      tripHeadsign: Value(row['trip_headsign']),
      tripShortName: Value(row['trip_short_name']),
      directionId: Value(int.tryParse(row['direction_id'] ?? '')),
      shapeId: Value(row['shape_id']),
    );
  }

  static GtfsStopTimesCompanion? _parseStopTime(Map<String, String> row) {
    final tripId = row['trip_id'] ?? '';
    final stopId = row['stop_id'] ?? '';
    if (tripId.isEmpty || stopId.isEmpty) return null;
    return GtfsStopTimesCompanion.insert(
      tripId: tripId,
      arrivalTime: row['arrival_time'] ?? '',
      departureTime: row['departure_time'] ?? '',
      stopId: stopId,
      stopSequence: int.tryParse(row['stop_sequence'] ?? '') ?? 0,
      stopHeadsign: Value(row['stop_headsign']),
      pickupType: Value(int.tryParse(row['pickup_type'] ?? '')),
      dropOffType: Value(int.tryParse(row['drop_off_type'] ?? '')),
    );
  }

  static GtfsCalendarCompanion? _parseCalendar(Map<String, String> row) {
    final serviceId = row['service_id'] ?? '';
    if (serviceId.isEmpty) return null;
    return GtfsCalendarCompanion.insert(
      serviceId: serviceId,
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

  static GtfsCalendarDatesCompanion? _parseCalendarDate(Map<String, String> row) {
    final serviceId = row['service_id'] ?? '';
    final date = row['date'] ?? '';
    if (serviceId.isEmpty || date.isEmpty) return null;
    return GtfsCalendarDatesCompanion.insert(
      serviceId: serviceId,
      date: date,
      exceptionType: int.tryParse(row['exception_type'] ?? '') ?? 0,
    );
  }

  static GtfsShapesCompanion? _parseShape(Map<String, String> row) {
    final shapeId = row['shape_id'] ?? '';
    if (shapeId.isEmpty) return null;
    return GtfsShapesCompanion.insert(
      shapeId: shapeId,
      shapePtLat: double.tryParse(row['shape_pt_lat'] ?? '') ?? 0.0,
      shapePtLon: double.tryParse(row['shape_pt_lon'] ?? '') ?? 0.0,
      shapePtSequence: int.tryParse(row['shape_pt_sequence'] ?? '') ?? 0,
    );
  }
}

/// Configuration for a table import during sync.
class _TableImportConfig {
  final String filename;
  final SyncStage stage;
  final double progressStart;
  final double progressEnd;
  final bool required;
  final bool isLarge;

  const _TableImportConfig({
    required this.filename,
    required this.stage,
    required this.progressStart,
    required this.progressEnd,
    this.required = true,
    this.isLarge = false,
  });
}
