import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:atacbus_roma/data/datasources/local/database/app_database.dart';
import 'package:atacbus_roma/data/datasources/local/gtfs_file_storage.dart';
import 'package:atacbus_roma/data/repositories/gtfs_repository_impl.dart';
import 'package:atacbus_roma/data/repositories/sync_repository_impl.dart';
import 'package:atacbus_roma/domain/usecases/get_stop_departures.dart';
import 'package:atacbus_roma/domain/entities/departure.dart';
import 'package:atacbus_roma/domain/entities/vehicle.dart';
import 'package:atacbus_roma/domain/entities/service_alert.dart';
import 'package:atacbus_roma/domain/repositories/realtime_repository.dart';
import 'package:atacbus_roma/core/utils/date_time_utils.dart';

// ─── RT mock ────────────────────────────────────────────────────
class MockRealtimeRepo implements RealtimeRepository {
  Map<String, int> delays;
  bool shouldThrow;

  MockRealtimeRepo({this.delays = const {}, this.shouldThrow = false});

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
  // 1. Content Hash Service Tests
  // ═══════════════════════════════════════════════════════════════════

  group('GtfsFileStorage.computeContentHash', () {
    test('produces consistent results for same input', () {
      const content = 'stop_id,stop_name\n1,Termini\n2,Colosseo';
      final hash1 = GtfsFileStorage.computeContentHash(content);
      final hash2 = GtfsFileStorage.computeContentHash(content);
      expect(hash1, equals(hash2));
    });

    test('different inputs produce different hashes', () {
      const content1 = 'stop_id,stop_name\n1,Termini';
      const content2 = 'stop_id,stop_name\n1,Termini\n2,Colosseo';
      final hash1 = GtfsFileStorage.computeContentHash(content1);
      final hash2 = GtfsFileStorage.computeContentHash(content2);
      expect(hash1, isNot(equals(hash2)));
    });

    test('empty content produces a valid hash', () {
      final hash = GtfsFileStorage.computeContentHash('');
      expect(hash, isNotEmpty);
      expect(hash, isA<String>());
    });

    test('hash is a hex string', () {
      final hash = GtfsFileStorage.computeContentHash('test content');
      expect(RegExp(r'^[0-9a-f]+$').hasMatch(hash), isTrue);
    });

    test('single character difference produces different hash', () {
      final hash1 = GtfsFileStorage.computeContentHash('stop_name');
      final hash2 = GtfsFileStorage.computeContentHash('stop_namf');
      expect(hash1, isNot(equals(hash2)));
    });

    test('large content produces valid hash without errors', () {
      // Simulate ~10K lines of CSV data
      final buffer = StringBuffer('stop_id,stop_name,stop_lat,stop_lon\n');
      for (var i = 0; i < 10000; i++) {
        buffer.writeln('$i,Stop $i,41.${i % 100},12.${i % 100}');
      }
      final hash = GtfsFileStorage.computeContentHash(buffer.toString());
      expect(hash, isNotEmpty);
    });

    test('whitespace-only difference produces different hash', () {
      final hash1 = GtfsFileStorage.computeContentHash('a,b\n1,2');
      final hash2 = GtfsFileStorage.computeContentHash('a,b\n1, 2');
      expect(hash1, isNot(equals(hash2)));
    });

    test('handles unicode content', () {
      final hash = GtfsFileStorage.computeContentHash(
        'stop_name\nStazione Termini - Uscita Piétre',
      );
      expect(hash, isNotEmpty);
    });

    test('handles BOM prefix', () {
      final withBom = '\uFEFFstop_id,stop_name\n1,Termini';
      final withoutBom = 'stop_id,stop_name\n1,Termini';
      // BOM should produce different hash (raw content differs)
      final hash1 = GtfsFileStorage.computeContentHash(withBom);
      final hash2 = GtfsFileStorage.computeContentHash(withoutBom);
      expect(hash1, isNot(equals(hash2)));
    });

    test('line ending difference produces different hash', () {
      final unix = GtfsFileStorage.computeContentHash('a\nb');
      final windows = GtfsFileStorage.computeContentHash('a\r\nb');
      expect(unix, isNot(equals(windows)));
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // 2. Atomic Table Replace Tests (Database)
  // ═══════════════════════════════════════════════════════════════════

  group('Database: Atomic Table Replace', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('replaceTableAtomically replaces all stops', () async {
      // Insert initial data
      await db.insertStops([
        GtfsStopsCompanion.insert(
          stopId: 'OLD1', stopName: 'Old Stop 1', stopLat: 41.9, stopLon: 12.5,
        ),
        GtfsStopsCompanion.insert(
          stopId: 'OLD2', stopName: 'Old Stop 2', stopLat: 41.8, stopLon: 12.4,
        ),
      ]);
      expect(await db.countStops(), 2);

      // Replace with new data
      await db.replaceTableAtomically<GtfsStopsCompanion>(
        db.clearStops,
        db.insertStops,
        [
          GtfsStopsCompanion.insert(
            stopId: 'NEW1', stopName: 'New Stop 1', stopLat: 41.95, stopLon: 12.55,
          ),
          GtfsStopsCompanion.insert(
            stopId: 'NEW2', stopName: 'New Stop 2', stopLat: 41.85, stopLon: 12.45,
          ),
          GtfsStopsCompanion.insert(
            stopId: 'NEW3', stopName: 'New Stop 3', stopLat: 41.75, stopLon: 12.35,
          ),
        ],
      );

      expect(await db.countStops(), 3);
      final old1 = await db.getStopById('OLD1');
      expect(old1, isNull);
      final new1 = await db.getStopById('NEW1');
      expect(new1, isNotNull);
      expect(new1!.stopName, 'New Stop 1');
    });

    test('replaceTableAtomically replaces routes', () async {
      await db.insertRoutes([
        GtfsRoutesCompanion.insert(
          routeId: 'R_OLD', routeShortName: '99',
          routeLongName: 'Old Route', routeType: 3,
        ),
      ]);
      expect(await db.countRoutes(), 1);

      await db.replaceTableAtomically<GtfsRoutesCompanion>(
        db.clearRoutes,
        db.insertRoutes,
        [
          GtfsRoutesCompanion.insert(
            routeId: 'R_NEW1', routeShortName: '64',
            routeLongName: 'Bus 64', routeType: 3,
          ),
          GtfsRoutesCompanion.insert(
            routeId: 'R_NEW2', routeShortName: 'A',
            routeLongName: 'Metro A', routeType: 1,
          ),
        ],
      );

      expect(await db.countRoutes(), 2);
      expect(await db.getRouteById('R_OLD'), isNull);
      expect(await db.getRouteById('R_NEW1'), isNotNull);
    });

    test('favorites survive stops table replacement', () async {
      await db.insertStops([
        GtfsStopsCompanion.insert(
          stopId: 'S1', stopName: 'Termini', stopLat: 41.9, stopLon: 12.5,
        ),
      ]);
      await db.addFavorite('S1');
      expect(await db.isFavorite('S1'), true);

      // Replace stops — favorites are in a separate table
      await db.replaceTableAtomically<GtfsStopsCompanion>(
        db.clearStops,
        db.insertStops,
        [
          GtfsStopsCompanion.insert(
            stopId: 'S1', stopName: 'Termini Updated', stopLat: 41.9, stopLon: 12.5,
          ),
        ],
      );

      // Favorite should survive
      expect(await db.isFavorite('S1'), true);
    });

    test('per-table clear leaves other tables intact', () async {
      // Insert data in multiple tables
      await db.insertStops([
        GtfsStopsCompanion.insert(
          stopId: 'S1', stopName: 'Termini', stopLat: 41.9, stopLon: 12.5,
        ),
      ]);
      await db.insertRoutes([
        GtfsRoutesCompanion.insert(
          routeId: 'R1', routeShortName: '64',
          routeLongName: 'Bus 64', routeType: 3,
        ),
      ]);
      await db.insertTrips([
        GtfsTripsCompanion.insert(
          tripId: 'T1', routeId: 'R1', serviceId: 'SVC1',
        ),
      ]);

      // Clear only stops
      await db.clearStops();

      expect(await db.countStops(), 0);
      expect(await db.countRoutes(), 1);
      expect(await db.countTrips(), 1);
    });

    test('per-table clear routes leaves stops intact', () async {
      await db.insertStops([
        GtfsStopsCompanion.insert(
          stopId: 'S1', stopName: 'Termini', stopLat: 41.9, stopLon: 12.5,
        ),
      ]);
      await db.insertRoutes([
        GtfsRoutesCompanion.insert(
          routeId: 'R1', routeShortName: '64',
          routeLongName: 'Bus 64', routeType: 3,
        ),
      ]);

      await db.clearRoutes();

      expect(await db.countStops(), 1);
      expect(await db.countRoutes(), 0);
    });

    test('per-table clear stop_times leaves trips intact', () async {
      await db.insertTrips([
        GtfsTripsCompanion.insert(
          tripId: 'T1', routeId: 'R1', serviceId: 'SVC1',
        ),
      ]);
      await db.insertStopTimes([
        GtfsStopTimesCompanion.insert(
          tripId: 'T1', arrivalTime: '08:00:00',
          departureTime: '08:00:00', stopId: 'S1', stopSequence: 1,
        ),
      ]);

      await db.clearStopTimes();

      expect(await db.countTrips(), 1);
      expect(await db.countStopTimes(), 0);
    });

    test('replaceTableAtomically with batch inserts handles large dataset', () async {
      // Generate 12000 stops (more than batch size of 5000)
      final stops = List.generate(
        12000,
        (i) => GtfsStopsCompanion.insert(
          stopId: 'S$i', stopName: 'Stop $i', stopLat: 41.0 + i * 0.001, stopLon: 12.0 + i * 0.001,
        ),
      );

      await db.replaceTableAtomically<GtfsStopsCompanion>(
        db.clearStops,
        db.insertStops,
        stops,
      );

      expect(await db.countStops(), 12000);
      final first = await db.getStopById('S0');
      expect(first, isNotNull);
      final last = await db.getStopById('S11999');
      expect(last, isNotNull);
    });

    test('replaceTableAtomically with empty list clears table', () async {
      await db.insertStops([
        GtfsStopsCompanion.insert(
          stopId: 'S1', stopName: 'Termini', stopLat: 41.9, stopLon: 12.5,
        ),
      ]);

      await db.replaceTableAtomically<GtfsStopsCompanion>(
        db.clearStops,
        db.insertStops,
        [],
      );

      expect(await db.countStops(), 0);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // 3. Data Integrity Validation Tests
  // ═══════════════════════════════════════════════════════════════════

  group('Data Integrity: Referential consistency', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('departure query returns correct data after atomic stop replacement', () async {
      // Set up full chain: stops + routes + trips + stop_times
      await db.insertStops([
        GtfsStopsCompanion.insert(
          stopId: 'S1', stopName: 'Termini', stopLat: 41.9, stopLon: 12.5,
        ),
      ]);
      await db.insertRoutes([
        GtfsRoutesCompanion.insert(
          routeId: 'R64', routeShortName: '64',
          routeLongName: 'Bus 64', routeType: 3,
          routeColor: const Value('FF0000'),
        ),
      ]);
      await db.insertTrips([
        GtfsTripsCompanion.insert(
          tripId: 'T1', routeId: 'R64', serviceId: 'SVC_WK',
          tripHeadsign: const Value('Termini'),
        ),
      ]);
      await db.insertStopTimes([
        GtfsStopTimesCompanion.insert(
          tripId: 'T1', arrivalTime: '08:00:00',
          departureTime: '08:01:00', stopId: 'S1', stopSequence: 1,
        ),
      ]);

      // Query departures
      final rows = await db.getDeparturesForStop('S1', {'SVC_WK'});
      expect(rows.length, 1);
      expect(rows.first.routeShortName, '64');
      expect(rows.first.tripHeadsign, 'Termini');

      // Now atomically replace stops (update name)
      await db.replaceTableAtomically<GtfsStopsCompanion>(
        db.clearStops,
        db.insertStops,
        [
          GtfsStopsCompanion.insert(
            stopId: 'S1', stopName: 'Termini Updated',
            stopLat: 41.9, stopLon: 12.5,
          ),
        ],
      );

      // Departures should still work
      final rowsAfter = await db.getDeparturesForStop('S1', {'SVC_WK'});
      expect(rowsAfter.length, 1);

      // Stop name should be updated
      final stop = await db.getStopById('S1');
      expect(stop!.stopName, 'Termini Updated');
    });

    test('routes-for-stop query works after route table replacement', () async {
      await db.insertStops([
        GtfsStopsCompanion.insert(
          stopId: 'S1', stopName: 'Termini', stopLat: 41.9, stopLon: 12.5,
        ),
      ]);
      await db.insertRoutes([
        GtfsRoutesCompanion.insert(
          routeId: 'R64', routeShortName: '64',
          routeLongName: 'Bus 64', routeType: 3,
        ),
      ]);
      await db.insertTrips([
        GtfsTripsCompanion.insert(
          tripId: 'T1', routeId: 'R64', serviceId: 'SVC_WK',
        ),
      ]);
      await db.insertStopTimes([
        GtfsStopTimesCompanion.insert(
          tripId: 'T1', arrivalTime: '08:00:00',
          departureTime: '08:00:00', stopId: 'S1', stopSequence: 1,
        ),
      ]);

      // Replace routes with updated data (same route + new route)
      await db.replaceTableAtomically<GtfsRoutesCompanion>(
        db.clearRoutes,
        db.insertRoutes,
        [
          GtfsRoutesCompanion.insert(
            routeId: 'R64', routeShortName: '64',
            routeLongName: 'Bus 64 Updated', routeType: 3,
          ),
          GtfsRoutesCompanion.insert(
            routeId: 'R40', routeShortName: '40',
            routeLongName: 'Bus 40', routeType: 3,
          ),
        ],
      );

      // Original route should still serve the stop (via trip + stop_times)
      final routes = await db.getRoutesForStopJoin('S1');
      expect(routes.length, 1);
      expect(routes.first.routeShortName, '64');
      expect(routes.first.routeLongName, 'Bus 64 Updated');
    });

    test('stop_times replacement preserves departure query integrity', () async {
      await db.insertStops([
        GtfsStopsCompanion.insert(
          stopId: 'S1', stopName: 'Termini', stopLat: 41.9, stopLon: 12.5,
        ),
      ]);
      await db.insertRoutes([
        GtfsRoutesCompanion.insert(
          routeId: 'R64', routeShortName: '64',
          routeLongName: 'Bus 64', routeType: 3,
        ),
      ]);
      await db.insertTrips([
        GtfsTripsCompanion.insert(
          tripId: 'T1', routeId: 'R64', serviceId: 'SVC_WK',
        ),
        GtfsTripsCompanion.insert(
          tripId: 'T2', routeId: 'R64', serviceId: 'SVC_WK',
        ),
      ]);

      // Initial stop_times: 1 departure
      await db.insertStopTimes([
        GtfsStopTimesCompanion.insert(
          tripId: 'T1', arrivalTime: '08:00:00',
          departureTime: '08:01:00', stopId: 'S1', stopSequence: 1,
        ),
      ]);

      var deps = await db.getDeparturesForStop('S1', {'SVC_WK'});
      expect(deps.length, 1);

      // Replace stop_times with MORE departures
      await db.clearStopTimes();
      await db.insertStopTimes([
        GtfsStopTimesCompanion.insert(
          tripId: 'T1', arrivalTime: '08:00:00',
          departureTime: '08:01:00', stopId: 'S1', stopSequence: 1,
        ),
        GtfsStopTimesCompanion.insert(
          tripId: 'T2', arrivalTime: '09:00:00',
          departureTime: '09:01:00', stopId: 'S1', stopSequence: 1,
        ),
      ]);

      deps = await db.getDeparturesForStop('S1', {'SVC_WK'});
      expect(deps.length, 2);
    });

    test('calendar replacement updates active service IDs', () async {
      final repo = GtfsRepositoryImpl(db);

      // Insert weekday calendar + trips
      await db.insertCalendar([
        GtfsCalendarCompanion.insert(
          serviceId: 'SVC_WK',
          monday: true, tuesday: true, wednesday: true,
          thursday: true, friday: true, saturday: false, sunday: false,
          startDate: '20240101', endDate: '20271231',
        ),
      ]);
      await db.insertRoutes([
        GtfsRoutesCompanion.insert(
          routeId: 'R1', routeShortName: '64',
          routeLongName: 'Bus 64', routeType: 3,
        ),
      ]);
      await db.insertTrips([
        GtfsTripsCompanion.insert(
          tripId: 'T1', routeId: 'R1', serviceId: 'SVC_WK',
        ),
        GtfsTripsCompanion.insert(
          tripId: 'T2', routeId: 'R1', serviceId: 'SVC_NEW',
        ),
      ]);
      await db.insertStopTimes([
        GtfsStopTimesCompanion.insert(
          tripId: 'T1', arrivalTime: '08:00:00',
          departureTime: '08:00:00', stopId: 'S1', stopSequence: 1,
        ),
        GtfsStopTimesCompanion.insert(
          tripId: 'T2', arrivalTime: '09:00:00',
          departureTime: '09:00:00', stopId: 'S1', stopSequence: 1,
        ),
      ]);

      // Clear cache to pick up new calendar
      repo.clearCache();

      // Replace calendar to add SVC_NEW
      await db.replaceTableAtomically<GtfsCalendarCompanion>(
        db.clearCalendar,
        db.insertCalendar,
        [
          GtfsCalendarCompanion.insert(
            serviceId: 'SVC_WK',
            monday: true, tuesday: true, wednesday: true,
            thursday: true, friday: true, saturday: false, sunday: false,
            startDate: '20240101', endDate: '20271231',
          ),
          GtfsCalendarCompanion.insert(
            serviceId: 'SVC_NEW',
            monday: true, tuesday: true, wednesday: true,
            thursday: true, friday: true, saturday: true, sunday: true,
            startDate: '20240101', endDate: '20271231',
          ),
        ],
      );

      // After calendar update, both service IDs should be resolvable
      final allCal = await db.getAllCalendar();
      expect(allCal.length, 2);
    });

    test('adding stops that were previously missing (the core bug fix)', () async {
      // This tests the scenario where the old sync would CLEAR ALL data
      // then fail partway, leaving an empty DB. The new system should
      // never clear data from Table A when importing Table B.

      // Setup: full working data
      await db.insertStops([
        GtfsStopsCompanion.insert(
          stopId: 'S1', stopName: 'Termini', stopLat: 41.9, stopLon: 12.5,
        ),
        GtfsStopsCompanion.insert(
          stopId: 'S2', stopName: 'Colosseo', stopLat: 41.89, stopLon: 12.49,
        ),
      ]);
      await db.insertRoutes([
        GtfsRoutesCompanion.insert(
          routeId: 'R64', routeShortName: '64',
          routeLongName: 'Bus 64', routeType: 3,
        ),
      ]);
      await db.insertTrips([
        GtfsTripsCompanion.insert(
          tripId: 'T1', routeId: 'R64', serviceId: 'SVC_WK',
        ),
      ]);
      await db.insertStopTimes([
        GtfsStopTimesCompanion.insert(
          tripId: 'T1', arrivalTime: '08:00:00',
          departureTime: '08:01:00', stopId: 'S1', stopSequence: 1,
        ),
      ]);

      // Simulate: replace stops with updated list (adds S3, keeps S1, S2)
      await db.replaceTableAtomically<GtfsStopsCompanion>(
        db.clearStops,
        db.insertStops,
        [
          GtfsStopsCompanion.insert(
            stopId: 'S1', stopName: 'Termini', stopLat: 41.9, stopLon: 12.5,
          ),
          GtfsStopsCompanion.insert(
            stopId: 'S2', stopName: 'Colosseo', stopLat: 41.89, stopLon: 12.49,
          ),
          GtfsStopsCompanion.insert(
            stopId: 'S3', stopName: 'Trastevere', stopLat: 41.88, stopLon: 12.47,
          ),
        ],
      );

      expect(await db.countStops(), 3);
      // Routes, trips, stop_times all still intact
      expect(await db.countRoutes(), 1);
      expect(await db.countTrips(), 1);
      expect(await db.countStopTimes(), 1);

      // Departures for S1 should still work
      final deps = await db.getDeparturesForStop('S1', {'SVC_WK'});
      expect(deps.length, 1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // 4. GetStopDepartures: Data pipeline integration
  // ═══════════════════════════════════════════════════════════════════

  group('GetStopDepartures: after table replacement', () {
    late AppDatabase db;
    late GtfsRepositoryImpl repo;

    setUp(() async {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = GtfsRepositoryImpl(db);

      // Seed standard data
      await db.insertStops([
        GtfsStopsCompanion.insert(
          stopId: 'S1', stopName: 'Termini', stopLat: 41.9, stopLon: 12.5,
        ),
      ]);
      await db.insertRoutes([
        GtfsRoutesCompanion.insert(
          routeId: 'R64', routeShortName: '64',
          routeLongName: 'Bus 64', routeType: 3,
          routeColor: const Value('FF0000'),
        ),
      ]);
      await db.insertCalendar([
        GtfsCalendarCompanion.insert(
          serviceId: 'SVC_WK',
          monday: true, tuesday: true, wednesday: true,
          thursday: true, friday: true, saturday: true, sunday: true,
          startDate: '20240101', endDate: '20271231',
        ),
      ]);
      await db.insertTrips([
        GtfsTripsCompanion.insert(
          tripId: 'T1', routeId: 'R64', serviceId: 'SVC_WK',
          tripHeadsign: const Value('Termini'),
        ),
      ]);
    });

    tearDown(() async {
      await db.close();
    });

    test('departures return after stop_times table is populated', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      await db.insertStopTimes([
        GtfsStopTimesCompanion.insert(
          tripId: 'T1', arrivalTime: '${(now + 600) ~/ 3600}:${((now + 600) % 3600) ~/ 60}:00',
          departureTime: '${(now + 600) ~/ 3600}:${((now + 600) % 3600) ~/ 60}:00',
          stopId: 'S1', stopSequence: 1,
        ),
      ]);

      repo.clearCache();
      final deps = await repo.getScheduledDepartures('S1');
      expect(deps, isNotEmpty);
      expect(deps.first.routeShortName, '64');
    });

    test('cache cleared after table replacement shows new data', () async {
      // Insert initial stop_times
      await db.insertStopTimes([
        GtfsStopTimesCompanion.insert(
          tripId: 'T1', arrivalTime: '08:00:00',
          departureTime: '08:00:00', stopId: 'S1', stopSequence: 1,
        ),
      ]);

      repo.clearCache();
      final deps1 = await repo.getScheduledDepartures('S1');
      final count1 = deps1.length;

      // Add a new trip + stop_time
      await db.insertTrips([
        GtfsTripsCompanion.insert(
          tripId: 'T2', routeId: 'R64', serviceId: 'SVC_WK',
          tripHeadsign: const Value('San Pietro'),
        ),
      ]);
      await db.insertStopTimes([
        GtfsStopTimesCompanion.insert(
          tripId: 'T2', arrivalTime: '09:00:00',
          departureTime: '09:00:00', stopId: 'S1', stopSequence: 1,
        ),
      ]);

      repo.clearCache();
      final deps2 = await repo.getScheduledDepartures('S1');
      expect(deps2.length, greaterThan(count1));
    });

    test('RT merge works correctly with freshly imported data', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final depTime = now + 600; // 10 min from now
      final hours = depTime ~/ 3600;
      final mins = (depTime % 3600) ~/ 60;
      final timeStr = '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}:00';

      await db.insertStopTimes([
        GtfsStopTimesCompanion.insert(
          tripId: 'T1', arrivalTime: timeStr,
          departureTime: timeStr, stopId: 'S1', stopSequence: 1,
        ),
      ]);

      repo.clearCache();

      final mockRt = MockRealtimeRepo(delays: {'T1': 300}); // 5 min late
      final useCase = GetStopDepartures(repo, mockRt);
      final result = await useCase('S1');

      expect(result, isNotEmpty);
      expect(result.first.isRealtime, true);
      expect(result.first.delaySeconds, 300);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // 5. Differential sync logic (unit tests for hash comparison)
  // ═══════════════════════════════════════════════════════════════════

  group('Differential sync: hash comparison logic', () {
    test('identical content produces same hash (unchanged file → skip)', () {
      const csvV1 = 'stop_id,stop_name\n70001,Termini\n70002,Colosseo';
      const csvV1Copy = 'stop_id,stop_name\n70001,Termini\n70002,Colosseo';

      final hash1 = GtfsFileStorage.computeContentHash(csvV1);
      final hash2 = GtfsFileStorage.computeContentHash(csvV1Copy);
      expect(hash1, equals(hash2));
    });

    test('added stop produces different hash (changed file → import)', () {
      const csvV1 = 'stop_id,stop_name\n70001,Termini\n70002,Colosseo';
      const csvV2 = 'stop_id,stop_name\n70001,Termini\n70002,Colosseo\n70003,Trastevere';

      final hash1 = GtfsFileStorage.computeContentHash(csvV1);
      final hash2 = GtfsFileStorage.computeContentHash(csvV2);
      expect(hash1, isNot(equals(hash2)));
    });

    test('modified stop name produces different hash', () {
      const csvV1 = 'stop_id,stop_name\n70001,Termini\n70002,Colosseo';
      const csvV2 = 'stop_id,stop_name\n70001,Roma Termini\n70002,Colosseo';

      final hash1 = GtfsFileStorage.computeContentHash(csvV1);
      final hash2 = GtfsFileStorage.computeContentHash(csvV2);
      expect(hash1, isNot(equals(hash2)));
    });

    test('removed stop produces different hash', () {
      const csvV1 = 'stop_id,stop_name\n70001,Termini\n70002,Colosseo';
      const csvV2 = 'stop_id,stop_name\n70001,Termini';

      final hash1 = GtfsFileStorage.computeContentHash(csvV1);
      final hash2 = GtfsFileStorage.computeContentHash(csvV2);
      expect(hash1, isNot(equals(hash2)));
    });

    test('first sync (no previous hashes) forces full import', () {
      // Simulates: oldFileHashes is empty map, so no filename matches
      final oldFileHashes = <String, String>{};
      const filename = 'stops.txt';
      final content = 'stop_id,stop_name\n1,Termini';
      final contentHash = GtfsFileStorage.computeContentHash(content);

      // No match → should trigger import
      final shouldImport = contentHash != oldFileHashes[filename];
      expect(shouldImport, isTrue);
    });

    test('matching file hash skips import', () {
      const content = 'stop_id,stop_name\n1,Termini';
      final contentHash = GtfsFileStorage.computeContentHash(content);

      final oldFileHashes = {'stops.txt': contentHash};
      final shouldImport = contentHash != oldFileHashes['stops.txt'];
      expect(shouldImport, isFalse);
    });

    test('realistic GTFS data change detection', () {
      // Simulate a real stops.txt update where 1 stop is added
      final buffer1 = StringBuffer('stop_id,stop_name,stop_lat,stop_lon\n');
      for (var i = 0; i < 12000; i++) {
        buffer1.writeln('$i,Stop $i,41.${900 + i ~/ 100},12.${500 + i ~/ 100}');
      }
      final hash1 = GtfsFileStorage.computeContentHash(buffer1.toString());

      final buffer2 = StringBuffer('stop_id,stop_name,stop_lat,stop_lon\n');
      for (var i = 0; i < 12001; i++) {
        buffer2.writeln('$i,Stop $i,41.${900 + i ~/ 100},12.${500 + i ~/ 100}');
      }
      final hash2 = GtfsFileStorage.computeContentHash(buffer2.toString());

      // Single stop addition should be detected
      expect(hash1, isNot(equals(hash2)));
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // 6. SyncProgress model tests
  // ═══════════════════════════════════════════════════════════════════

  group('SyncProgress model', () {
    test('default values', () {
      const p = SyncProgress(stage: SyncStage.downloading);
      expect(p.progress, 0.0);
      expect(p.errorMessage, isNull);
      expect(p.skippedBecauseUpToDate, isFalse);
    });

    test('up-to-date flag', () {
      const p = SyncProgress(
        stage: SyncStage.complete,
        progress: 1.0,
        skippedBecauseUpToDate: true,
      );
      expect(p.skippedBecauseUpToDate, isTrue);
    });

    test('error state', () {
      const p = SyncProgress(
        stage: SyncStage.error,
        errorMessage: 'Download failed',
      );
      expect(p.stage, SyncStage.error);
      expect(p.errorMessage, 'Download failed');
    });

    test('comparing stage exists', () {
      const p = SyncProgress(stage: SyncStage.comparing);
      expect(p.stage, SyncStage.comparing);
    });

    test('all sync stages are covered', () {
      // Verify all stages exist
      expect(SyncStage.values, contains(SyncStage.downloading));
      expect(SyncStage.values, contains(SyncStage.comparing));
      expect(SyncStage.values, contains(SyncStage.extracting));
      expect(SyncStage.values, contains(SyncStage.importingStops));
      expect(SyncStage.values, contains(SyncStage.importingRoutes));
      expect(SyncStage.values, contains(SyncStage.importingTrips));
      expect(SyncStage.values, contains(SyncStage.importingStopTimes));
      expect(SyncStage.values, contains(SyncStage.importingCalendar));
      expect(SyncStage.values, contains(SyncStage.importingCalendarDates));
      expect(SyncStage.values, contains(SyncStage.importingShapes));
      expect(SyncStage.values, contains(SyncStage.complete));
      expect(SyncStage.values, contains(SyncStage.error));
    });
  });
}
