import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:atacbus_roma/core/utils/date_time_utils.dart';
import 'package:atacbus_roma/data/datasources/local/database/app_database.dart';
import 'package:atacbus_roma/domain/entities/departure.dart';
import 'package:atacbus_roma/domain/usecases/get_stop_departures.dart';
import 'package:atacbus_roma/domain/usecases/toggle_favorite.dart';
import 'package:atacbus_roma/domain/entities/stop.dart';
import 'package:atacbus_roma/domain/entities/route_entity.dart';
import 'package:atacbus_roma/domain/entities/vehicle.dart';
import 'package:atacbus_roma/domain/entities/service_alert.dart';
import 'package:atacbus_roma/domain/repositories/gtfs_repository.dart';
import 'package:atacbus_roma/domain/repositories/realtime_repository.dart';

// ─── Test helper: replicate _splitCsvLine from SyncRepositoryImpl ────
// This is public for testing; the actual code is private in SyncRepositoryImpl.

List<String> splitCsvLine(String line) {
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

/// Replicate the fixed _rowsToDepartures logic for testing.
/// This mirrors the fix in GtfsRepositoryImpl._rowsToDepartures.
List<Departure> rowsToDepartures(List<DepartureRow> rows) {
  final departures = <Departure>[];
  for (final row in rows) {
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

// ─── Mock classes ────────────────────────────────────────────────────

class MockGtfsRepo implements GtfsRepository {
  List<Departure> departures;
  bool _isFavorite = false;

  MockGtfsRepo({this.departures = const []});

  @override
  Future<List<Departure>> getScheduledDepartures(String stopId) async =>
      departures;
  @override
  Future<List<Stop>> searchStops(String query) async => [];
  @override
  Future<Stop?> getStopById(String stopId) async => null;
  @override
  Future<List<Stop>> getAllStops() async => [];
  @override
  Future<List<RouteEntity>> getAllRoutes() async => [];
  @override
  Future<List<RouteEntity>> getRoutesByType(int type) async => [];
  @override
  Future<RouteEntity?> getRouteById(String routeId) async => null;
  @override
  Future<List<RouteEntity>> getRoutesForStop(String stopId) async => [];
  @override
  Future<List<Stop>> getStopsForRoute(String routeId) async => [];
  @override
  Future<bool> isFavorite(String stopId) async => _isFavorite;
  @override
  Future<void> addFavorite(String stopId) async { _isFavorite = true; }
  @override
  Future<void> removeFavorite(String stopId) async { _isFavorite = false; }
  @override
  Future<List<String>> getFavoriteStopIds() async =>
      _isFavorite ? ['S1'] : [];
  @override
  Stream<List<String>> watchFavoriteStopIds() => const Stream.empty();
}

class MockRtRepo implements RealtimeRepository {
  Map<String, int> delays;
  bool shouldThrow;

  MockRtRepo({this.delays = const {}, this.shouldThrow = false});

  @override
  Future<Map<String, int>> getTripDelays() async {
    if (shouldThrow) throw Exception('RT error');
    return delays;
  }
  @override
  Future<List<Vehicle>> getVehiclePositions() async => [];
  @override
  Future<List<ServiceAlert>> getServiceAlerts() async => [];
}

void main() {
  // ═══════════════════════════════════════════════════════════════════
  // BUG FIX 1: CSV Header Parsing
  // The _importLargeTable method was using headerLine.split(',')
  // instead of _splitCsvLine(headerLine), which doesn't strip quotes
  // from headers. When GTFS files have quoted headers like
  // "trip_id","arrival_time",..., the map keys include quotes and
  // all lookups fail, producing empty trip_id/stop_id in every row.
  // ═══════════════════════════════════════════════════════════════════

  group('BUG FIX: CSV header parsing (_splitCsvLine vs split)', () {
    test('splitCsvLine strips double-quotes from headers', () {
      const headerLine = '"trip_id","arrival_time","departure_time","stop_id","stop_sequence"';
      final headers = splitCsvLine(headerLine).map((h) => h.trim()).toList();

      expect(headers, ['trip_id', 'arrival_time', 'departure_time', 'stop_id', 'stop_sequence']);
    });

    test('plain split does NOT strip quotes (demonstrates the bug)', () {
      const headerLine = '"trip_id","arrival_time","departure_time","stop_id","stop_sequence"';
      final buggyHeaders = headerLine.split(',').map((h) => h.trim()).toList();

      // Bug: headers contain quotes
      expect(buggyHeaders[0], '"trip_id"');
      expect(buggyHeaders[0], isNot('trip_id'));
    });

    test('splitCsvLine handles unquoted headers correctly', () {
      const headerLine = 'trip_id,arrival_time,departure_time,stop_id,stop_sequence';
      final headers = splitCsvLine(headerLine).map((h) => h.trim()).toList();

      expect(headers, ['trip_id', 'arrival_time', 'departure_time', 'stop_id', 'stop_sequence']);
    });

    test('splitCsvLine handles mixed quoted and unquoted headers', () {
      const headerLine = '"trip_id",arrival_time,"departure_time",stop_id';
      final headers = splitCsvLine(headerLine).map((h) => h.trim()).toList();

      expect(headers, ['trip_id', 'arrival_time', 'departure_time', 'stop_id']);
    });

    test('splitCsvLine handles header with spaces', () {
      const headerLine = ' trip_id , arrival_time , departure_time ';
      final headers = splitCsvLine(headerLine).map((h) => h.trim()).toList();

      expect(headers, ['trip_id', 'arrival_time', 'departure_time']);
    });

    test('splitCsvLine handles escaped quotes in headers', () {
      const headerLine = '"field_with_""quotes""",normal_field';
      final headers = splitCsvLine(headerLine).map((h) => h.trim()).toList();

      expect(headers[0], 'field_with_"quotes"');
      expect(headers[1], 'normal_field');
    });

    test('splitCsvLine handles empty header fields', () {
      const headerLine = 'field1,,field3';
      final headers = splitCsvLine(headerLine).map((h) => h.trim()).toList();

      expect(headers, ['field1', '', 'field3']);
    });

    test('fixed: quoted headers produce correct map key lookups', () {
      const headerLine = '"trip_id","arrival_time","departure_time","stop_id","stop_sequence"';
      const dataLine = 'T001,08:00:00,08:01:00,S001,1';

      final headers = splitCsvLine(headerLine).map((h) => h.trim()).toList();
      final values = splitCsvLine(dataLine);

      final map = <String, String>{};
      for (var j = 0; j < headers.length && j < values.length; j++) {
        map[headers[j]] = values[j];
      }

      // With the fix, these lookups work correctly
      expect(map['trip_id'], 'T001');
      expect(map['arrival_time'], '08:00:00');
      expect(map['departure_time'], '08:01:00');
      expect(map['stop_id'], 'S001');
      expect(map['stop_sequence'], '1');
    });

    test('BUG: buggy split produces broken map lookups', () {
      const headerLine = '"trip_id","arrival_time","departure_time","stop_id","stop_sequence"';
      const dataLine = 'T001,08:00:00,08:01:00,S001,1';

      // Buggy: using split(',') instead of splitCsvLine
      final buggyHeaders = headerLine.split(',').map((h) => h.trim()).toList();
      final values = splitCsvLine(dataLine);

      final map = <String, String>{};
      for (var j = 0; j < buggyHeaders.length && j < values.length; j++) {
        map[buggyHeaders[j]] = values[j];
      }

      // These lookups FAIL — the bug returns null for all expected keys
      expect(map['trip_id'], null); // BUG: key is '"trip_id"', not 'trip_id'
      expect(map['"trip_id"'], 'T001'); // The buggy key with quotes
    });

    test('BOM stripping on header line', () {
      final headerWithBom = '\uFEFFtrip_id,arrival_time,departure_time';
      var headerLine = headerWithBom;
      if (headerLine.isNotEmpty && headerLine.codeUnitAt(0) == 0xFEFF) {
        headerLine = headerLine.substring(1);
      }
      final headers = splitCsvLine(headerLine).map((h) => h.trim()).toList();

      expect(headers, ['trip_id', 'arrival_time', 'departure_time']);
    });

    test('BOM + quoted headers both handled', () {
      final headerLine = '\uFEFF"trip_id","arrival_time","departure_time"';
      var cleaned = headerLine;
      if (cleaned.isNotEmpty && cleaned.codeUnitAt(0) == 0xFEFF) {
        cleaned = cleaned.substring(1);
      }
      final headers = splitCsvLine(cleaned).map((h) => h.trim()).toList();

      expect(headers, ['trip_id', 'arrival_time', 'departure_time']);
    });

    test('no BOM does not break stripping code', () {
      const headerLine = 'trip_id,arrival_time';
      var cleaned = headerLine;
      if (cleaned.isNotEmpty && cleaned.codeUnitAt(0) == 0xFEFF) {
        cleaned = cleaned.substring(1);
      }
      final headers = splitCsvLine(cleaned).map((h) => h.trim()).toList();

      expect(headers, ['trip_id', 'arrival_time']);
    });

    test('full ATAC-style stop_times header with all columns', () {
      const headerLine = '"trip_id","arrival_time","departure_time","stop_id","stop_sequence","stop_headsign","pickup_type","drop_off_type"';
      final headers = splitCsvLine(headerLine).map((h) => h.trim()).toList();

      expect(headers, [
        'trip_id', 'arrival_time', 'departure_time', 'stop_id',
        'stop_sequence', 'stop_headsign', 'pickup_type', 'drop_off_type',
      ]);
    });

    test('end-to-end: quoted headers + data row produce working _parseStopTime input', () {
      const headerLine = '"trip_id","arrival_time","departure_time","stop_id","stop_sequence","stop_headsign","pickup_type","drop_off_type"';
      const dataLine = 'T_12345,08:30:00,08:31:00,70001,5,,0,0';

      final headers = splitCsvLine(headerLine).map((h) => h.trim()).toList();
      final values = splitCsvLine(dataLine);

      final map = <String, String>{};
      for (var j = 0; j < headers.length && j < values.length; j++) {
        map[headers[j]] = values[j];
      }

      // Simulate _parseStopTime lookups
      expect(map['trip_id'], 'T_12345');
      expect(map['arrival_time'], '08:30:00');
      expect(map['departure_time'], '08:31:00');
      expect(map['stop_id'], '70001');
      expect(int.tryParse(map['stop_sequence'] ?? ''), 5);
      expect(map['stop_headsign'], '');
      expect(int.tryParse(map['pickup_type'] ?? ''), 0);
      expect(int.tryParse(map['drop_off_type'] ?? ''), 0);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // BUG FIX 2: parseGtfsTime Error Handling
  // A single malformed departure_time row causes parseGtfsTime to
  // throw FormatException, crashing ALL departures for a stop.
  // The fix adds try-catch in _rowsToDepartures to skip bad rows.
  // ═══════════════════════════════════════════════════════════════════

  group('BUG FIX: parseGtfsTime error handling', () {
    test('parseGtfsTime throws on empty string', () {
      expect(() => DateTimeUtils.parseGtfsTime(''), throwsFormatException);
    });

    test('parseGtfsTime throws on whitespace-only string', () {
      expect(() => DateTimeUtils.parseGtfsTime('   '), throwsFormatException);
    });

    test('parseGtfsTime throws on partial time (HH:MM)', () {
      expect(() => DateTimeUtils.parseGtfsTime('08:30'), throwsFormatException);
    });

    test('parseGtfsTime throws on non-numeric parts', () {
      expect(() => DateTimeUtils.parseGtfsTime('ab:cd:ef'), throwsA(isA<FormatException>()));
    });

    test('parseGtfsTime throws on extra colons', () {
      expect(() => DateTimeUtils.parseGtfsTime('08:30:00:00'), throwsFormatException);
    });

    test('parseGtfsTime handles valid times correctly', () {
      expect(DateTimeUtils.parseGtfsTime('08:30:00'), 30600);
      expect(DateTimeUtils.parseGtfsTime('25:00:00'), 90000);
      expect(DateTimeUtils.parseGtfsTime('00:00:00'), 0);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // BUG FIX 2b: _rowsToDepartures resilience
  // Test the rowsToDepartures logic (replicated from GtfsRepositoryImpl)
  // that now skips malformed departure_time rows instead of crashing.
  // ═══════════════════════════════════════════════════════════════════

  group('BUG FIX: _rowsToDepartures resilience (no DB needed)', () {
    test('good rows are parsed correctly', () {
      final rows = [
        DepartureRow(
          tripId: 'T1', departureTime: '08:00:00',
          routeId: 'R1', serviceId: 'SVC1', routeShortName: '64',
        ),
        DepartureRow(
          tripId: 'T2', departureTime: '12:30:00',
          routeId: 'R1', serviceId: 'SVC1', routeShortName: '64',
        ),
      ];

      final departures = rowsToDepartures(rows);
      expect(departures.length, 2);
      expect(departures[0].scheduledSeconds, 28800);
      expect(departures[1].scheduledSeconds, 45000);
    });

    test('malformed departure_time rows are skipped (not crash)', () {
      final rows = [
        DepartureRow(
          tripId: 'T_GOOD', departureTime: '12:00:00',
          routeId: 'R1', serviceId: 'SVC1', routeShortName: '64',
        ),
        DepartureRow(
          tripId: 'T_BAD', departureTime: 'INVALID',
          routeId: 'R1', serviceId: 'SVC1', routeShortName: '64',
        ),
        DepartureRow(
          tripId: 'T_PARTIAL', departureTime: '08:30',
          routeId: 'R1', serviceId: 'SVC1', routeShortName: '64',
        ),
      ];

      final departures = rowsToDepartures(rows);
      expect(departures.length, 1);
      expect(departures[0].tripId, 'T_GOOD');
    });

    test('empty departure_time rows are skipped', () {
      final rows = [
        DepartureRow(
          tripId: 'T_EMPTY', departureTime: '',
          routeId: 'R1', serviceId: 'SVC1', routeShortName: '64',
        ),
        DepartureRow(
          tripId: 'T_SPACES', departureTime: '   ',
          routeId: 'R1', serviceId: 'SVC1', routeShortName: '64',
        ),
        DepartureRow(
          tripId: 'T_GOOD', departureTime: '10:00:00',
          routeId: 'R1', serviceId: 'SVC1', routeShortName: '64',
        ),
      ];

      final departures = rowsToDepartures(rows);
      expect(departures.length, 1);
      expect(departures[0].tripId, 'T_GOOD');
    });

    test('all malformed rows returns empty list', () {
      final rows = [
        DepartureRow(
          tripId: 'T1', departureTime: 'bad',
          routeId: 'R1', serviceId: 'SVC1', routeShortName: '64',
        ),
        DepartureRow(
          tripId: 'T2', departureTime: '',
          routeId: 'R1', serviceId: 'SVC1', routeShortName: '64',
        ),
      ];

      final departures = rowsToDepartures(rows);
      expect(departures, isEmpty);
    });

    test('after-midnight GTFS times parse correctly', () {
      final rows = [
        DepartureRow(
          tripId: 'T_NIGHT', departureTime: '25:30:00',
          routeId: 'R1', serviceId: 'SVC1', routeShortName: 'N1',
        ),
        DepartureRow(
          tripId: 'T_LATE', departureTime: '27:00:00',
          routeId: 'R1', serviceId: 'SVC1', routeShortName: 'N1',
        ),
      ];

      final departures = rowsToDepartures(rows);
      expect(departures.length, 2);
      expect(departures[0].scheduledSeconds, 91800); // 25:30 = 91800
      expect(departures[1].scheduledSeconds, 97200); // 27:00 = 97200
    });

    test('departures are sorted by scheduledSeconds', () {
      final rows = [
        DepartureRow(
          tripId: 'T3', departureTime: '15:00:00',
          routeId: 'R1', serviceId: 'SVC1', routeShortName: '64',
        ),
        DepartureRow(
          tripId: 'T1', departureTime: '08:00:00',
          routeId: 'R1', serviceId: 'SVC1', routeShortName: '64',
        ),
        DepartureRow(
          tripId: 'T2', departureTime: '12:00:00',
          routeId: 'R1', serviceId: 'SVC1', routeShortName: '64',
        ),
      ];

      final departures = rowsToDepartures(rows);
      expect(departures.map((d) => d.tripId).toList(), ['T1', 'T2', 'T3']);
    });

    test('bad rows interspersed with good rows — only bad ones skipped', () {
      final rows = [
        DepartureRow(tripId: 'T1', departureTime: '08:00:00', routeId: 'R1', serviceId: 'SVC1', routeShortName: '64'),
        DepartureRow(tripId: 'T2', departureTime: 'X', routeId: 'R1', serviceId: 'SVC1', routeShortName: '64'), // bad
        DepartureRow(tripId: 'T3', departureTime: '10:00:00', routeId: 'R1', serviceId: 'SVC1', routeShortName: '64'),
        DepartureRow(tripId: 'T4', departureTime: '', routeId: 'R1', serviceId: 'SVC1', routeShortName: '64'), // bad
        DepartureRow(tripId: 'T5', departureTime: '12:00:00', routeId: 'R1', serviceId: 'SVC1', routeShortName: '64'),
      ];

      final departures = rowsToDepartures(rows);
      expect(departures.length, 3);
      expect(departures.map((d) => d.tripId).toList(), ['T1', 'T3', 'T5']);
    });

    test('tripHeadsign falls back to stopHeadsign', () {
      final rows = [
        DepartureRow(
          tripId: 'T1', departureTime: '12:00:00',
          routeId: 'R1', serviceId: 'SVC1', routeShortName: '64',
          tripHeadsign: null, stopHeadsign: 'Capolinea',
        ),
      ];

      final departures = rowsToDepartures(rows);
      expect(departures[0].tripHeadsign, 'Capolinea');
    });

    test('tripHeadsign takes priority over stopHeadsign', () {
      final rows = [
        DepartureRow(
          tripId: 'T1', departureTime: '12:00:00',
          routeId: 'R1', serviceId: 'SVC1', routeShortName: '64',
          tripHeadsign: 'Termini', stopHeadsign: 'Via Nazionale',
        ),
      ];

      final departures = rowsToDepartures(rows);
      expect(departures[0].tripHeadsign, 'Termini');
    });

    test('routeColor and directionId are preserved', () {
      final rows = [
        DepartureRow(
          tripId: 'T1', departureTime: '12:00:00',
          routeId: 'R1', serviceId: 'SVC1', routeShortName: '64',
          routeColor: 'FF0000', directionId: 0,
        ),
      ];

      final departures = rowsToDepartures(rows);
      expect(departures[0].routeColor, 'FF0000');
      expect(departures[0].directionId, 0);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // BUG FIX 3: Sync Loop (home_screen.dart)
  // valueOrNull == false was triggering during AsyncLoading with stale
  // previous value. The fix adds !hasSync.isLoading check.
  // ═══════════════════════════════════════════════════════════════════

  group('BUG FIX: Sync redirect logic', () {
    test('AsyncData(false) should trigger redirect', () {
      final asyncVal = AsyncValue.data(false);
      final shouldRedirect = !asyncVal.isLoading && asyncVal.valueOrNull == false;
      expect(shouldRedirect, true);
    });

    test('AsyncData(true) should NOT trigger redirect', () {
      final asyncVal = AsyncValue.data(true);
      final shouldRedirect = !asyncVal.isLoading && asyncVal.valueOrNull == false;
      expect(shouldRedirect, false);
    });

    test('AsyncLoading should NOT trigger redirect', () {
      const asyncVal = AsyncValue<bool>.loading();
      final shouldRedirect = !asyncVal.isLoading && asyncVal.valueOrNull == false;
      expect(shouldRedirect, false);
    });

    test('AsyncError should NOT trigger redirect', () {
      final asyncVal = AsyncValue<bool>.error(Exception('test'), StackTrace.empty);
      final shouldRedirect = !asyncVal.isLoading && asyncVal.valueOrNull == false;
      expect(shouldRedirect, false);
    });

    test('fix correctly blocks redirect during any loading state', () {
      const loading = AsyncValue<bool>.loading();
      expect(loading.isLoading, true);
      expect(!loading.isLoading && loading.valueOrNull == false, false);

      final data = AsyncValue.data(false);
      expect(data.isLoading, false);
      expect(!data.isLoading && data.valueOrNull == false, true);

      final dataTrue = AsyncValue.data(true);
      expect(!dataTrue.isLoading && dataTrue.valueOrNull == false, false);
    });

    test('AsyncError with exception does not crash redirect check', () {
      final error = AsyncValue<bool>.error('network_error', StackTrace.empty);
      expect(error.isLoading, false);
      expect(error.valueOrNull, null);
      expect(!error.isLoading && error.valueOrNull == false, false);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // BUG FIX 4: Favorites toggle logic
  // The star button was hidden (SizedBox.shrink) during loading/error.
  // Also, toggle had no try/catch. Test the ToggleFavorite use case.
  // ═══════════════════════════════════════════════════════════════════

  group('BUG FIX: ToggleFavorite use case', () {
    test('toggle adds favorite when not favorite', () async {
      final mockRepo = MockGtfsRepo();
      final toggleFav = ToggleFavorite(mockRepo);

      expect(await mockRepo.isFavorite('S1'), false);

      final result = await toggleFav('S1');
      expect(result, true); // now is favorite
      expect(await mockRepo.isFavorite('S1'), true);
    });

    test('toggle removes favorite when already favorite', () async {
      final mockRepo = MockGtfsRepo();
      final toggleFav = ToggleFavorite(mockRepo);

      // First add
      await toggleFav('S1');
      expect(await mockRepo.isFavorite('S1'), true);

      // Then toggle off
      final result = await toggleFav('S1');
      expect(result, false);
      expect(await mockRepo.isFavorite('S1'), false);
    });

    test('double toggle returns to original state', () async {
      final mockRepo = MockGtfsRepo();
      final toggleFav = ToggleFavorite(mockRepo);

      expect(await mockRepo.isFavorite('S1'), false);
      await toggleFav('S1'); // on
      await toggleFav('S1'); // off
      expect(await mockRepo.isFavorite('S1'), false);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // GetStopDepartures use case: time window and RT merge
  // ═══════════════════════════════════════════════════════════════════

  group('GetStopDepartures: time window filtering', () {
    test('keeps departures within 90-minute window', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final mockGtfs = MockGtfsRepo(departures: [
        Departure(
          tripId: 't_in', routeId: 'r1', routeShortName: '64',
          scheduledTime: '08:00:00', scheduledSeconds: now + 1800,
        ),
      ]);

      final useCase = GetStopDepartures(mockGtfs, null);
      final result = await useCase('stop_1');
      expect(result.length, 1);
    });

    test('filters out past departures', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final mockGtfs = MockGtfsRepo(departures: [
        Departure(
          tripId: 't_past', routeId: 'r1', routeShortName: '64',
          scheduledTime: '06:00:00', scheduledSeconds: now - 1800,
        ),
      ]);

      final useCase = GetStopDepartures(mockGtfs, null);
      final result = await useCase('stop_1');
      expect(result.length, 0);
    });

    test('filters out departures beyond 90 minutes', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final mockGtfs = MockGtfsRepo(departures: [
        Departure(
          tripId: 't_far', routeId: 'r1', routeShortName: '64',
          scheduledTime: '12:00:00', scheduledSeconds: now + 7200,
        ),
      ]);

      final useCase = GetStopDepartures(mockGtfs, null);
      final result = await useCase('stop_1');
      expect(result.length, 0);
    });

    test('mixed past/future keeps only upcoming within 90 min', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final mockGtfs = MockGtfsRepo(departures: [
        Departure(tripId: 't_past', routeId: 'r1', routeShortName: '64',
          scheduledTime: '06:00:00', scheduledSeconds: now - 600),
        Departure(tripId: 't_soon', routeId: 'r1', routeShortName: '64',
          scheduledTime: '07:00:00', scheduledSeconds: now + 60),
        Departure(tripId: 't_later', routeId: 'r1', routeShortName: '40',
          scheduledTime: '07:30:00', scheduledSeconds: now + 1800),
        Departure(tripId: 't_far', routeId: 'r1', routeShortName: '170',
          scheduledTime: '12:00:00', scheduledSeconds: now + 10800),
      ]);

      final useCase = GetStopDepartures(mockGtfs, null);
      final result = await useCase('stop_1');
      expect(result.length, 2);
      expect(result.map((d) => d.tripId).toSet(), {'t_soon', 't_later'});
    });

    test('empty stop returns empty list', () async {
      final mockGtfs = MockGtfsRepo(departures: []);
      final useCase = GetStopDepartures(mockGtfs, null);
      final result = await useCase('empty_stop');
      expect(result, isEmpty);
    });
  });

  group('GetStopDepartures: RT merge', () {
    test('applies positive delay', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final mockGtfs = MockGtfsRepo(departures: [
        Departure(tripId: 't1', routeId: 'r1', routeShortName: '64',
          scheduledTime: '08:00:00', scheduledSeconds: now + 600),
      ]);
      final mockRt = MockRtRepo(delays: {'t1': 300});

      final useCase = GetStopDepartures(mockGtfs, mockRt);
      final result = await useCase('stop_1');

      expect(result[0].isRealtime, true);
      expect(result[0].delaySeconds, 300);
      expect(result[0].estimatedSeconds, now + 600 + 300);
    });

    test('RT failure falls back to scheduled gracefully', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final mockGtfs = MockGtfsRepo(departures: [
        Departure(tripId: 't1', routeId: 'r1', routeShortName: '64',
          scheduledTime: '08:00:00', scheduledSeconds: now + 600),
      ]);
      final mockRt = MockRtRepo(shouldThrow: true);

      final useCase = GetStopDepartures(mockGtfs, mockRt);
      final result = await useCase('stop_1');

      expect(result.length, 1);
      expect(result[0].isRealtime, false);
    });

    test('null RT repository returns scheduled data', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final mockGtfs = MockGtfsRepo(departures: [
        Departure(tripId: 't1', routeId: 'r1', routeShortName: '64',
          scheduledTime: '08:00:00', scheduledSeconds: now + 600),
      ]);

      final useCase = GetStopDepartures(mockGtfs, null);
      final result = await useCase('stop_1');
      expect(result[0].isRealtime, false);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // DepartureRow entity tests
  // ═══════════════════════════════════════════════════════════════════

  group('DepartureRow', () {
    test('creates with all required fields', () {
      final row = DepartureRow(
        tripId: 'trip_1', departureTime: '08:30:00',
        routeId: 'route_64', serviceId: 'svc_weekday', routeShortName: '64',
      );
      expect(row.tripId, 'trip_1');
      expect(row.departureTime, '08:30:00');
      expect(row.stopHeadsign, null);
      expect(row.tripHeadsign, null);
      expect(row.directionId, null);
      expect(row.routeColor, null);
    });

    test('creates with all optional fields', () {
      final row = DepartureRow(
        tripId: 'trip_1', departureTime: '08:30:00',
        stopHeadsign: 'Via Nazionale',
        routeId: 'route_64', serviceId: 'svc_weekday',
        tripHeadsign: 'Termini', directionId: 0,
        routeShortName: '64', routeColor: 'FF0000',
      );
      expect(row.stopHeadsign, 'Via Nazionale');
      expect(row.tripHeadsign, 'Termini');
      expect(row.directionId, 0);
      expect(row.routeColor, 'FF0000');
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // Service date / calendar logic
  // ═══════════════════════════════════════════════════════════════════

  group('Service date logic', () {
    test('before 4 AM → service date is yesterday', () {
      final dt = DateTime(2024, 6, 15, 3, 59);
      expect(DateTimeUtils.getServiceDate(dt), DateTime(2024, 6, 14));
    });

    test('at 4 AM → service date is today', () {
      final dt = DateTime(2024, 6, 15, 4, 0);
      expect(DateTimeUtils.getServiceDate(dt), DateTime(2024, 6, 15));
    });

    test('at midnight → service date is yesterday', () {
      final dt = DateTime(2024, 6, 15, 0, 0);
      expect(DateTimeUtils.getServiceDate(dt), DateTime(2024, 6, 14));
    });

    test('across year boundary (Jan 1 at 1 AM → Dec 31)', () {
      final dt = DateTime(2025, 1, 1, 1, 0);
      expect(DateTimeUtils.getServiceDate(dt), DateTime(2024, 12, 31));
    });
  });
}
