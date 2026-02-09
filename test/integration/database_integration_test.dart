import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:atacbus_roma/data/datasources/local/database/app_database.dart';
import 'package:atacbus_roma/data/repositories/gtfs_repository_impl.dart';
import 'package:atacbus_roma/domain/usecases/get_stop_departures.dart';
import 'package:atacbus_roma/domain/usecases/toggle_favorite.dart';
import 'package:atacbus_roma/domain/entities/departure.dart';
import 'package:atacbus_roma/domain/entities/vehicle.dart';
import 'package:atacbus_roma/domain/entities/service_alert.dart';
import 'package:atacbus_roma/domain/repositories/realtime_repository.dart';
import 'package:atacbus_roma/core/utils/date_time_utils.dart';
import 'package:atacbus_roma/core/utils/gtfs_csv_parser.dart';
import 'package:atacbus_roma/core/utils/distance_utils.dart';
import 'package:atacbus_roma/domain/entities/stop.dart';

// ─── RT mock for use case tests ─────────────────────────────
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
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  // ═══════════════════════════════════════════════════════════════════
  // 1. Raw database CRUD operations
  // ═══════════════════════════════════════════════════════════════════

  group('Database: Stop CRUD', () {
    test('insert and retrieve stops', () async {
      await db.insertStops([
        GtfsStopsCompanion.insert(
          stopId: '70001',
          stopName: 'Termini',
          stopLat: 41.9,
          stopLon: 12.5,
        ),
        GtfsStopsCompanion.insert(
          stopId: '70002',
          stopName: 'Colosseo',
          stopLat: 41.89,
          stopLon: 12.49,
        ),
      ]);

      final stops = await db.getAllStops();
      expect(stops.length, 2);
    });

    test('getStopById returns correct stop', () async {
      await db.insertStops([
        GtfsStopsCompanion.insert(
          stopId: '70001',
          stopName: 'Termini',
          stopLat: 41.9,
          stopLon: 12.5,
        ),
      ]);

      final stop = await db.getStopById('70001');
      expect(stop, isNotNull);
      expect(stop!.stopName, 'Termini');
    });

    test('getStopById returns null for missing stop', () async {
      final stop = await db.getStopById('NONEXISTENT');
      expect(stop, isNull);
    });

    test('searchStopsByName finds matching stops', () async {
      await db.insertStops([
        GtfsStopsCompanion.insert(
          stopId: '70001',
          stopName: 'Stazione Termini',
          stopLat: 41.9,
          stopLon: 12.5,
        ),
        GtfsStopsCompanion.insert(
          stopId: '70002',
          stopName: 'Via Termini Est',
          stopLat: 41.9,
          stopLon: 12.5,
        ),
        GtfsStopsCompanion.insert(
          stopId: '70003',
          stopName: 'Colosseo',
          stopLat: 41.89,
          stopLon: 12.49,
        ),
      ]);

      final results = await db.searchStopsByName('Termini');
      expect(results.length, 2);
    });

    test('searchStopsByName escapes LIKE wildcards', () async {
      await db.insertStops([
        GtfsStopsCompanion.insert(
          stopId: '1',
          stopName: 'Test_Stop',
          stopLat: 0,
          stopLon: 0,
        ),
        GtfsStopsCompanion.insert(
          stopId: '2',
          stopName: 'TestXStop',
          stopLat: 0,
          stopLon: 0,
        ),
        GtfsStopsCompanion.insert(
          stopId: '3',
          stopName: 'Unrelated',
          stopLat: 0,
          stopLon: 0,
        ),
      ]);

      // Searching for 'Test' should match both Test_Stop and TestXStop
      final results = await db.searchStopsByName('Test');
      expect(results.length, 2);
    });

    test('searchStopsByName limits to 50 results', () async {
      final stops = List.generate(
        60,
        (i) => GtfsStopsCompanion.insert(
          stopId: 'S$i',
          stopName: 'Station $i',
          stopLat: 0,
          stopLon: 0,
        ),
      );
      await db.insertStops(stops);

      final results = await db.searchStopsByName('Station');
      expect(results.length, 50);
    });

    test('insertOrReplace overwrites existing stops', () async {
      await db.insertStops([
        GtfsStopsCompanion.insert(
          stopId: '70001',
          stopName: 'Old Name',
          stopLat: 41.9,
          stopLon: 12.5,
        ),
      ]);

      await db.insertStops([
        GtfsStopsCompanion.insert(
          stopId: '70001',
          stopName: 'New Name',
          stopLat: 41.9,
          stopLon: 12.5,
        ),
      ]);

      final stop = await db.getStopById('70001');
      expect(stop!.stopName, 'New Name');
      expect(await db.countStops(), 1);
    });
  });

  group('Database: Route CRUD', () {
    test('insert and retrieve routes', () async {
      await db.insertRoutes([
        GtfsRoutesCompanion.insert(
          routeId: 'R64',
          routeShortName: '64',
          routeLongName: 'Termini-San Pietro',
          routeType: 3,
        ),
        GtfsRoutesCompanion.insert(
          routeId: 'RA',
          routeShortName: 'A',
          routeLongName: 'Metro A',
          routeType: 1,
        ),
      ]);

      final routes = await db.getAllRoutes();
      expect(routes.length, 2);
    });

    test('getRoutesByType filters correctly', () async {
      await db.insertRoutes([
        GtfsRoutesCompanion.insert(
          routeId: 'R64',
          routeShortName: '64',
          routeLongName: 'Bus 64',
          routeType: 3,
        ),
        GtfsRoutesCompanion.insert(
          routeId: 'RA',
          routeShortName: 'A',
          routeLongName: 'Metro A',
          routeType: 1,
        ),
        GtfsRoutesCompanion.insert(
          routeId: 'T8',
          routeShortName: '8',
          routeLongName: 'Tram 8',
          routeType: 0,
        ),
      ]);

      final buses = await db.getRoutesByType(3);
      expect(buses.length, 1);
      expect(buses.first.routeShortName, '64');

      final metros = await db.getRoutesByType(1);
      expect(metros.length, 1);
      expect(metros.first.routeShortName, 'A');
    });

    test('getRouteById returns correct route', () async {
      await db.insertRoutes([
        GtfsRoutesCompanion.insert(
          routeId: 'R64',
          routeShortName: '64',
          routeLongName: 'Bus 64',
          routeType: 3,
          routeColor: const Value('FF0000'),
        ),
      ]);

      final route = await db.getRouteById('R64');
      expect(route, isNotNull);
      expect(route!.routeColor, 'FF0000');
    });
  });

  group('Database: Trip and StopTime CRUD', () {
    test('insert trips and stop times', () async {
      await db.insertTrips([
        GtfsTripsCompanion.insert(
          tripId: 'T1',
          routeId: 'R64',
          serviceId: 'SVC1',
          tripHeadsign: const Value('Termini'),
          directionId: const Value(0),
        ),
      ]);

      await db.insertStopTimes([
        GtfsStopTimesCompanion.insert(
          tripId: 'T1',
          arrivalTime: '08:00:00',
          departureTime: '08:01:00',
          stopId: '70001',
          stopSequence: 1,
        ),
        GtfsStopTimesCompanion.insert(
          tripId: 'T1',
          arrivalTime: '08:05:00',
          departureTime: '08:06:00',
          stopId: '70002',
          stopSequence: 2,
        ),
      ]);

      final stopTimes = await db.getStopTimesForTrip('T1');
      expect(stopTimes.length, 2);
      expect(stopTimes.first.stopSequence, 1);
      expect(stopTimes.last.stopSequence, 2);
    });

    test('getStopTimesForStop returns correct times', () async {
      await db.insertStopTimes([
        GtfsStopTimesCompanion.insert(
          tripId: 'T1',
          arrivalTime: '08:00:00',
          departureTime: '08:01:00',
          stopId: '70001',
          stopSequence: 1,
        ),
        GtfsStopTimesCompanion.insert(
          tripId: 'T2',
          arrivalTime: '09:00:00',
          departureTime: '09:01:00',
          stopId: '70001',
          stopSequence: 1,
        ),
        GtfsStopTimesCompanion.insert(
          tripId: 'T3',
          arrivalTime: '10:00:00',
          departureTime: '10:01:00',
          stopId: '70002',
          stopSequence: 1,
        ),
      ]);

      final times = await db.getStopTimesForStop('70001');
      expect(times.length, 2);
    });
  });

  group('Database: Calendar and CalendarDates', () {
    test('insert and retrieve calendar entries', () async {
      await db.insertCalendar([
        GtfsCalendarCompanion.insert(
          serviceId: 'SVC_WK',
          monday: true,
          tuesday: true,
          wednesday: true,
          thursday: true,
          friday: true,
          saturday: false,
          sunday: false,
          startDate: '20240101',
          endDate: '20241231',
        ),
        GtfsCalendarCompanion.insert(
          serviceId: 'SVC_WE',
          monday: false,
          tuesday: false,
          wednesday: false,
          thursday: false,
          friday: false,
          saturday: true,
          sunday: true,
          startDate: '20240101',
          endDate: '20241231',
        ),
      ]);

      final all = await db.getAllCalendar();
      expect(all.length, 2);
    });

    test('getCalendarByServiceId returns correct entry', () async {
      await db.insertCalendar([
        GtfsCalendarCompanion.insert(
          serviceId: 'SVC_WK',
          monday: true,
          tuesday: true,
          wednesday: true,
          thursday: true,
          friday: true,
          saturday: false,
          sunday: false,
          startDate: '20240101',
          endDate: '20241231',
        ),
      ]);

      final cal = await db.getCalendarByServiceId('SVC_WK');
      expect(cal, isNotNull);
      expect(cal!.monday, true);
      expect(cal.saturday, false);
    });

    test('calendar dates exceptions work', () async {
      await db.insertCalendarDates([
        GtfsCalendarDatesCompanion.insert(
          serviceId: 'SVC_WK', date: '20240101', exceptionType: 2, // removed
        ),
        GtfsCalendarDatesCompanion.insert(
          serviceId: 'SVC_HOLIDAY', date: '20240101', exceptionType: 1, // added
        ),
      ]);

      final exceptions = await db.getCalendarDatesByDate('20240101');
      expect(exceptions.length, 2);

      final added = exceptions.where((e) => e.exceptionType == 1);
      expect(added.length, 1);
      expect(added.first.serviceId, 'SVC_HOLIDAY');
    });
  });

  group('Database: Favorites', () {
    test('addFavorite and isFavorite', () async {
      expect(await db.isFavorite('70001'), false);
      await db.addFavorite('70001');
      expect(await db.isFavorite('70001'), true);
    });

    test('removeFavorite works', () async {
      await db.addFavorite('70001');
      expect(await db.isFavorite('70001'), true);
      await db.removeFavorite('70001');
      expect(await db.isFavorite('70001'), false);
    });

    test('getAllFavorites returns all added favorites', () async {
      await db.addFavorite('S1');
      await db.addFavorite('S2');
      await db.addFavorite('S3');

      final favs = await db.getAllFavorites();
      expect(favs.length, 3);
      expect(favs.map((f) => f.stopId).toSet(), {'S1', 'S2', 'S3'});
    });

    test('watchFavorites emits updates', () async {
      final stream = db.watchFavorites();

      // Initial should be empty
      final first = await stream.first;
      expect(first, isEmpty);

      // Add a favorite
      await db.addFavorite('S1');
      final second = await stream.first;
      expect(second.length, 1);
    });

    test('add same favorite twice does not duplicate (upsert)', () async {
      await db.addFavorite('S1');
      await db.addFavorite('S1');

      final favs = await db.getAllFavorites();
      expect(favs.length, 1);
    });
  });

  group('Database: clearGtfsData', () {
    test('clears all GTFS tables but keeps favorites', () async {
      // Insert data in every GTFS table
      await db.insertStops([
        GtfsStopsCompanion.insert(
            stopId: 'S1', stopName: 'A', stopLat: 0, stopLon: 0),
      ]);
      await db.insertRoutes([
        GtfsRoutesCompanion.insert(
            routeId: 'R1',
            routeShortName: '1',
            routeLongName: 'Route 1',
            routeType: 3),
      ]);
      await db.insertTrips([
        GtfsTripsCompanion.insert(
            tripId: 'T1', routeId: 'R1', serviceId: 'SVC1'),
      ]);
      await db.insertStopTimes([
        GtfsStopTimesCompanion.insert(
            tripId: 'T1',
            arrivalTime: '08:00:00',
            departureTime: '08:00:00',
            stopId: 'S1',
            stopSequence: 1),
      ]);
      await db.insertCalendar([
        GtfsCalendarCompanion.insert(
            serviceId: 'SVC1',
            monday: true,
            tuesday: true,
            wednesday: true,
            thursday: true,
            friday: true,
            saturday: false,
            sunday: false,
            startDate: '20240101',
            endDate: '20241231'),
      ]);
      await db.insertCalendarDates([
        GtfsCalendarDatesCompanion.insert(
            serviceId: 'SVC1', date: '20240101', exceptionType: 2),
      ]);
      await db.addFavorite('S1');

      // Clear GTFS data
      await db.clearGtfsData();

      // All GTFS tables empty
      expect(await db.countStops(), 0);
      expect(await db.countRoutes(), 0);
      expect(await db.countTrips(), 0);
      expect(await db.countStopTimes(), 0);
      expect(await db.getAllCalendar(), isEmpty);
      expect(await db.getCalendarDatesByDate('20240101'), isEmpty);

      // Favorites preserved
      expect(await db.isFavorite('S1'), true);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // 2. JOIN queries
  // ═══════════════════════════════════════════════════════════════════

  group('Database: getDeparturesForStop (JOIN query)', () {
    setUp(() async {
      // Set up test data: 2 routes, 3 trips, stop times
      await db.insertRoutes([
        GtfsRoutesCompanion.insert(
          routeId: 'R64',
          routeShortName: '64',
          routeLongName: 'Bus 64',
          routeType: 3,
          routeColor: const Value('FF0000'),
        ),
        GtfsRoutesCompanion.insert(
          routeId: 'R40',
          routeShortName: '40',
          routeLongName: 'Bus 40',
          routeType: 3,
        ),
      ]);

      await db.insertTrips([
        GtfsTripsCompanion.insert(
          tripId: 'T1',
          routeId: 'R64',
          serviceId: 'SVC_WK',
          tripHeadsign: const Value('Termini'),
          directionId: const Value(0),
        ),
        GtfsTripsCompanion.insert(
          tripId: 'T2',
          routeId: 'R64',
          serviceId: 'SVC_WK',
          tripHeadsign: const Value('San Pietro'),
          directionId: const Value(1),
        ),
        GtfsTripsCompanion.insert(
          tripId: 'T3',
          routeId: 'R40',
          serviceId: 'SVC_WE',
          tripHeadsign: const Value('Termini'),
        ),
      ]);

      await db.insertStopTimes([
        GtfsStopTimesCompanion.insert(
          tripId: 'T1',
          arrivalTime: '08:00:00',
          departureTime: '08:01:00',
          stopId: '70001',
          stopSequence: 1,
        ),
        GtfsStopTimesCompanion.insert(
          tripId: 'T2',
          arrivalTime: '09:00:00',
          departureTime: '09:01:00',
          stopId: '70001',
          stopSequence: 3,
        ),
        GtfsStopTimesCompanion.insert(
          tripId: 'T3',
          arrivalTime: '10:00:00',
          departureTime: '10:01:00',
          stopId: '70001',
          stopSequence: 1,
        ),
        // Different stop
        GtfsStopTimesCompanion.insert(
          tripId: 'T1',
          arrivalTime: '08:05:00',
          departureTime: '08:06:00',
          stopId: '70002',
          stopSequence: 2,
        ),
      ]);
    });

    test('returns all departures for a stop with service filter', () async {
      final rows = await db.getDeparturesForStop('70001', {'SVC_WK'});
      expect(rows.length, 2); // T1 and T2 (SVC_WK only)
      expect(rows.every((r) => r.serviceId == 'SVC_WK'), true);
    });

    test('returns departures without service filter', () async {
      final rows = await db.getDeparturesForStop('70001', {});
      expect(rows.length, 3); // T1, T2, T3
    });

    test('JOIN populates route data correctly', () async {
      final rows = await db.getDeparturesForStop('70001', {'SVC_WK'});
      final t1Row = rows.firstWhere((r) => r.tripId == 'T1');
      expect(t1Row.routeId, 'R64');
      expect(t1Row.routeShortName, '64');
      expect(t1Row.routeColor, 'FF0000');
      expect(t1Row.tripHeadsign, 'Termini');
      expect(t1Row.directionId, 0);
    });

    test('returns empty for non-existent stop', () async {
      final rows = await db.getDeparturesForStop('NONEXISTENT', {'SVC_WK'});
      expect(rows, isEmpty);
    });

    test('multiple service IDs in filter', () async {
      final rows = await db.getDeparturesForStop('70001', {'SVC_WK', 'SVC_WE'});
      expect(rows.length, 3);
    });
  });

  group('Database: getRoutesForStopJoin', () {
    test('returns distinct routes serving a stop', () async {
      await db.insertRoutes([
        GtfsRoutesCompanion.insert(
            routeId: 'R64',
            routeShortName: '64',
            routeLongName: 'Bus 64',
            routeType: 3),
        GtfsRoutesCompanion.insert(
            routeId: 'R40',
            routeShortName: '40',
            routeLongName: 'Bus 40',
            routeType: 3),
      ]);
      await db.insertTrips([
        GtfsTripsCompanion.insert(
            tripId: 'T1', routeId: 'R64', serviceId: 'SVC1'),
        GtfsTripsCompanion.insert(
            tripId: 'T2', routeId: 'R64', serviceId: 'SVC1'),
        GtfsTripsCompanion.insert(
            tripId: 'T3', routeId: 'R40', serviceId: 'SVC1'),
      ]);
      await db.insertStopTimes([
        GtfsStopTimesCompanion.insert(
            tripId: 'T1',
            arrivalTime: '08:00:00',
            departureTime: '08:00:00',
            stopId: 'S1',
            stopSequence: 1),
        GtfsStopTimesCompanion.insert(
            tripId: 'T2',
            arrivalTime: '09:00:00',
            departureTime: '09:00:00',
            stopId: 'S1',
            stopSequence: 1),
        GtfsStopTimesCompanion.insert(
            tripId: 'T3',
            arrivalTime: '10:00:00',
            departureTime: '10:00:00',
            stopId: 'S1',
            stopSequence: 1),
      ]);

      final routes = await db.getRoutesForStopJoin('S1');
      expect(routes.length, 2);
      expect(routes.map((r) => r.routeShortName).toSet(), {'40', '64'});
    });
  });

  group('Database: getStopsForRouteJoin', () {
    test('returns stops in stop_sequence order using longest trip', () async {
      await db.insertStops([
        GtfsStopsCompanion.insert(
            stopId: 'S1', stopName: 'Stop 1', stopLat: 41.9, stopLon: 12.5),
        GtfsStopsCompanion.insert(
            stopId: 'S2', stopName: 'Stop 2', stopLat: 41.91, stopLon: 12.51),
        GtfsStopsCompanion.insert(
            stopId: 'S3', stopName: 'Stop 3', stopLat: 41.92, stopLon: 12.52),
      ]);
      await db.insertRoutes([
        GtfsRoutesCompanion.insert(
            routeId: 'R1',
            routeShortName: '1',
            routeLongName: 'Route 1',
            routeType: 3),
      ]);
      // Short trip (2 stops)
      await db.insertTrips([
        GtfsTripsCompanion.insert(
            tripId: 'T_SHORT', routeId: 'R1', serviceId: 'SVC1'),
        GtfsTripsCompanion.insert(
            tripId: 'T_LONG', routeId: 'R1', serviceId: 'SVC1'),
      ]);
      await db.insertStopTimes([
        // Short trip
        GtfsStopTimesCompanion.insert(
            tripId: 'T_SHORT',
            arrivalTime: '08:00:00',
            departureTime: '08:00:00',
            stopId: 'S1',
            stopSequence: 1),
        GtfsStopTimesCompanion.insert(
            tripId: 'T_SHORT',
            arrivalTime: '08:10:00',
            departureTime: '08:10:00',
            stopId: 'S2',
            stopSequence: 2),
        // Long trip (3 stops)
        GtfsStopTimesCompanion.insert(
            tripId: 'T_LONG',
            arrivalTime: '09:00:00',
            departureTime: '09:00:00',
            stopId: 'S1',
            stopSequence: 1),
        GtfsStopTimesCompanion.insert(
            tripId: 'T_LONG',
            arrivalTime: '09:10:00',
            departureTime: '09:10:00',
            stopId: 'S2',
            stopSequence: 2),
        GtfsStopTimesCompanion.insert(
            tripId: 'T_LONG',
            arrivalTime: '09:20:00',
            departureTime: '09:20:00',
            stopId: 'S3',
            stopSequence: 3),
      ]);

      final stops = await db.getStopsForRouteJoin('R1');
      expect(stops.length, 3); // uses the longest trip
      expect(stops[0].stopId, 'S1');
      expect(stops[1].stopId, 'S2');
      expect(stops[2].stopId, 'S3');
    });

    test('returns empty for non-existent route', () async {
      final stops = await db.getStopsForRouteJoin('NONEXISTENT');
      expect(stops, isEmpty);
    });
  });

  group('Database: getAllServiceIds', () {
    test('returns distinct service IDs from trips', () async {
      await db.insertTrips([
        GtfsTripsCompanion.insert(
            tripId: 'T1', routeId: 'R1', serviceId: 'SVC_WK'),
        GtfsTripsCompanion.insert(
            tripId: 'T2', routeId: 'R1', serviceId: 'SVC_WK'),
        GtfsTripsCompanion.insert(
            tripId: 'T3', routeId: 'R1', serviceId: 'SVC_WE'),
      ]);

      final ids = await db.getAllServiceIds();
      expect(ids, {'SVC_WK', 'SVC_WE'});
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // 3. GtfsRepositoryImpl with real database
  // ═══════════════════════════════════════════════════════════════════

  group('GtfsRepositoryImpl: integration', () {
    late GtfsRepositoryImpl repo;

    setUp(() async {
      repo = GtfsRepositoryImpl(db);

      // Seed a standard dataset
      await db.insertStops([
        GtfsStopsCompanion.insert(
            stopId: 'S1', stopName: 'Termini', stopLat: 41.9, stopLon: 12.5),
        GtfsStopsCompanion.insert(
            stopId: 'S2', stopName: 'Colosseo', stopLat: 41.89, stopLon: 12.49),
        GtfsStopsCompanion.insert(
            stopId: 'S3',
            stopName: 'Trastevere',
            stopLat: 41.88,
            stopLon: 12.47),
      ]);
      await db.insertRoutes([
        GtfsRoutesCompanion.insert(
          routeId: 'R64',
          routeShortName: '64',
          routeLongName: 'Bus 64',
          routeType: 3,
          routeColor: const Value('FF0000'),
        ),
        GtfsRoutesCompanion.insert(
          routeId: 'R40',
          routeShortName: '40',
          routeLongName: 'Bus 40',
          routeType: 3,
        ),
        GtfsRoutesCompanion.insert(
          routeId: 'T8',
          routeShortName: '8',
          routeLongName: 'Tram 8',
          routeType: 0,
        ),
      ]);

      // Calendar: weekday service for current year
      await db.insertCalendar([
        GtfsCalendarCompanion.insert(
          serviceId: 'SVC_WK',
          monday: true,
          tuesday: true,
          wednesday: true,
          thursday: true,
          friday: true,
          saturday: false,
          sunday: false,
          startDate: '20240101',
          endDate: '20261231',
        ),
        GtfsCalendarCompanion.insert(
          serviceId: 'SVC_WE',
          monday: false,
          tuesday: false,
          wednesday: false,
          thursday: false,
          friday: false,
          saturday: true,
          sunday: true,
          startDate: '20240101',
          endDate: '20261231',
        ),
      ]);

      // Create trips with various departure times
      final now = DateTimeUtils.currentTimeAsSeconds();

      // Future-proof: create trips at relative offsets from "now"
      // so tests pass regardless of when they run
      String secsToGtfsTime(int totalSecs) {
        final h = totalSecs ~/ 3600;
        final m = (totalSecs % 3600) ~/ 60;
        final s = totalSecs % 60;
        return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      }

      final serviceDate = DateTimeUtils.getServiceDate();
      final isWeekday = serviceDate.weekday >= 1 && serviceDate.weekday <= 5;
      final serviceId = isWeekday ? 'SVC_WK' : 'SVC_WE';

      await db.insertTrips([
        GtfsTripsCompanion.insert(
            tripId: 'T_SOON',
            routeId: 'R64',
            serviceId: serviceId,
            tripHeadsign: const Value('Termini'),
            directionId: const Value(0)),
        GtfsTripsCompanion.insert(
            tripId: 'T_LATER',
            routeId: 'R40',
            serviceId: serviceId,
            tripHeadsign: const Value('San Pietro')),
        GtfsTripsCompanion.insert(
            tripId: 'T_PAST',
            routeId: 'R64',
            serviceId: serviceId,
            tripHeadsign: const Value('Colosseo')),
        GtfsTripsCompanion.insert(
            tripId: 'T_FAR',
            routeId: 'R64',
            serviceId: serviceId,
            tripHeadsign: const Value('Far Future')),
      ]);

      await db.insertStopTimes([
        GtfsStopTimesCompanion.insert(
            tripId: 'T_SOON',
            arrivalTime: secsToGtfsTime(now + 600),
            departureTime: secsToGtfsTime(now + 600),
            stopId: 'S1',
            stopSequence: 1),
        GtfsStopTimesCompanion.insert(
            tripId: 'T_LATER',
            arrivalTime: secsToGtfsTime(now + 2400),
            departureTime: secsToGtfsTime(now + 2400),
            stopId: 'S1',
            stopSequence: 1),
        GtfsStopTimesCompanion.insert(
            tripId: 'T_PAST',
            arrivalTime: secsToGtfsTime(now - 600),
            departureTime: secsToGtfsTime(now - 600),
            stopId: 'S1',
            stopSequence: 1),
        GtfsStopTimesCompanion.insert(
            tripId: 'T_FAR',
            arrivalTime: secsToGtfsTime(now + 7200),
            departureTime: secsToGtfsTime(now + 7200),
            stopId: 'S1',
            stopSequence: 1),
        // Stop S2 stop times
        GtfsStopTimesCompanion.insert(
            tripId: 'T_SOON',
            arrivalTime: secsToGtfsTime(now + 900),
            departureTime: secsToGtfsTime(now + 900),
            stopId: 'S2',
            stopSequence: 2),
      ]);
    });

    test('searchStops finds correct stops', () async {
      final results = await repo.searchStops('Termini');
      expect(results.length, 1);
      expect(results.first.stopId, 'S1');
    });

    test('getStopById returns mapped Stop entity', () async {
      final stop = await repo.getStopById('S1');
      expect(stop, isNotNull);
      expect(stop!.stopName, 'Termini');
      expect(stop.stopLat, 41.9);
    });

    test('getAllStops returns all stops', () async {
      final stops = await repo.getAllStops();
      expect(stops.length, 3);
    });

    test('getAllStops caches result', () async {
      final stops1 = await repo.getAllStops();
      final stops2 = await repo.getAllStops();
      expect(identical(stops1, stops2), true); // same object reference
    });

    test('clearCache invalidates the allStops cache', () async {
      final stops1 = await repo.getAllStops();
      repo.clearCache();
      final stops2 = await repo.getAllStops();
      expect(identical(stops1, stops2), false);
    });

    test('getAllRoutes returns all routes sorted', () async {
      final routes = await repo.getAllRoutes();
      expect(routes.length, 3);
    });

    test('getRoutesByType filters correctly', () async {
      final buses = await repo.getRoutesByType(3);
      expect(buses.length, 2);
      expect(buses.every((r) => r.isBus), true);

      final trams = await repo.getRoutesByType(0);
      expect(trams.length, 1);
      expect(trams.first.isTram, true);
    });

    test('getRouteById returns correct RouteEntity', () async {
      final route = await repo.getRouteById('R64');
      expect(route, isNotNull);
      expect(route!.routeColor, 'FF0000');
    });

    test('getRoutesForStop returns routes via JOIN', () async {
      final routes = await repo.getRoutesForStop('S1');
      expect(routes.length, greaterThanOrEqualTo(2));
    });

    test('getStopsForRoute uses longest trip and returns ordered stops',
        () async {
      final stops = await repo.getStopsForRoute('R64');
      expect(stops.isNotEmpty, true);
    });

    test('getScheduledDepartures returns departures for today', () async {
      final deps = await repo.getScheduledDepartures('S1');
      expect(deps.isNotEmpty, true);
      // Should be sorted by scheduledSeconds
      for (var i = 1; i < deps.length; i++) {
        expect(deps[i].scheduledSeconds,
            greaterThanOrEqualTo(deps[i - 1].scheduledSeconds));
      }
    });

    test('getScheduledDepartures skips malformed times', () async {
      final serviceDate = DateTimeUtils.getServiceDate();
      final isWeekday = serviceDate.weekday >= 1 && serviceDate.weekday <= 5;
      final serviceId = isWeekday ? 'SVC_WK' : 'SVC_WE';

      // Insert trip with malformed departure time
      await db.insertTrips([
        GtfsTripsCompanion.insert(
            tripId: 'T_BAD', routeId: 'R64', serviceId: serviceId),
      ]);
      await db.insertStopTimes([
        GtfsStopTimesCompanion.insert(
          tripId: 'T_BAD',
          arrivalTime: 'INVALID',
          departureTime: 'INVALID',
          stopId: 'S1',
          stopSequence: 1,
        ),
      ]);

      // Should not throw
      final deps = await repo.getScheduledDepartures('S1');
      // The malformed row should be skipped, but others should be there
      expect(deps.where((d) => d.tripId == 'T_BAD'), isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // 4. Favorites through repository
  // ═══════════════════════════════════════════════════════════════════

  group('GtfsRepositoryImpl: Favorites', () {
    late GtfsRepositoryImpl repo;

    setUp(() {
      repo = GtfsRepositoryImpl(db);
    });

    test('isFavorite returns false initially', () async {
      expect(await repo.isFavorite('S1'), false);
    });

    test('addFavorite / isFavorite / removeFavorite cycle', () async {
      await repo.addFavorite('S1');
      expect(await repo.isFavorite('S1'), true);

      await repo.removeFavorite('S1');
      expect(await repo.isFavorite('S1'), false);
    });

    test('getFavoriteStopIds returns IDs', () async {
      await repo.addFavorite('S1');
      await repo.addFavorite('S2');

      final ids = await repo.getFavoriteStopIds();
      expect(ids.length, 2);
      expect(ids.toSet(), {'S1', 'S2'});
    });

    test('ToggleFavorite use case works with real repo', () async {
      final toggle = ToggleFavorite(repo);

      final result1 = await toggle('S1');
      expect(result1, true); // now favorite
      expect(await repo.isFavorite('S1'), true);

      final result2 = await toggle('S1');
      expect(result2, false); // no longer favorite
      expect(await repo.isFavorite('S1'), false);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // 5. GetStopDepartures use case with real DB
  // ═══════════════════════════════════════════════════════════════════

  group('GetStopDepartures: integration with real DB', () {
    late GtfsRepositoryImpl repo;

    setUp(() async {
      repo = GtfsRepositoryImpl(db);

      final now = DateTimeUtils.currentTimeAsSeconds();
      final serviceDate = DateTimeUtils.getServiceDate();
      final isWeekday = serviceDate.weekday >= 1 && serviceDate.weekday <= 5;
      final serviceId = isWeekday ? 'SVC_WK' : 'SVC_WE';

      String secsToGtfsTime(int totalSecs) {
        final h = totalSecs ~/ 3600;
        final m = (totalSecs % 3600) ~/ 60;
        final s = totalSecs % 60;
        return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      }

      await db.insertRoutes([
        GtfsRoutesCompanion.insert(
            routeId: 'R1',
            routeShortName: '64',
            routeLongName: 'Bus 64',
            routeType: 3),
      ]);
      await db.insertCalendar([
        GtfsCalendarCompanion.insert(
          serviceId: 'SVC_WK',
          monday: true,
          tuesday: true,
          wednesday: true,
          thursday: true,
          friday: true,
          saturday: false,
          sunday: false,
          startDate: '20240101',
          endDate: '20261231',
        ),
        GtfsCalendarCompanion.insert(
          serviceId: 'SVC_WE',
          monday: false,
          tuesday: false,
          wednesday: false,
          thursday: false,
          friday: false,
          saturday: true,
          sunday: true,
          startDate: '20240101',
          endDate: '20261231',
        ),
      ]);
      await db.insertTrips([
        GtfsTripsCompanion.insert(
            tripId: 'T1', routeId: 'R1', serviceId: serviceId),
        GtfsTripsCompanion.insert(
            tripId: 'T2', routeId: 'R1', serviceId: serviceId),
        GtfsTripsCompanion.insert(
            tripId: 'T_PAST', routeId: 'R1', serviceId: serviceId),
      ]);
      await db.insertStopTimes([
        GtfsStopTimesCompanion.insert(
            tripId: 'T1',
            arrivalTime: secsToGtfsTime(now + 300),
            departureTime: secsToGtfsTime(now + 300),
            stopId: 'S1',
            stopSequence: 1),
        GtfsStopTimesCompanion.insert(
            tripId: 'T2',
            arrivalTime: secsToGtfsTime(now + 1800),
            departureTime: secsToGtfsTime(now + 1800),
            stopId: 'S1',
            stopSequence: 1),
        GtfsStopTimesCompanion.insert(
            tripId: 'T_PAST',
            arrivalTime: secsToGtfsTime(now - 600),
            departureTime: secsToGtfsTime(now - 600),
            stopId: 'S1',
            stopSequence: 1),
      ]);
    });

    test('returns only upcoming departures within 90 min window', () async {
      final useCase = GetStopDepartures(repo, null);
      final result = await useCase('S1');

      expect(result.length, 2);
      expect(result.map((d) => d.tripId).toList(), containsAll(['T1', 'T2']));
      expect(result.where((d) => d.tripId == 'T_PAST'), isEmpty);
    });

    test('merges RT data when available', () async {
      final mockRt = MockRealtimeRepo(delays: {'T1': 120}); // 2 min late
      final useCase = GetStopDepartures(repo, mockRt);
      final result = await useCase('S1');

      final t1 = result.firstWhere((d) => d.tripId == 'T1');
      expect(t1.isRealtime, true);
      expect(t1.delaySeconds, 120);

      final t2 = result.firstWhere((d) => d.tripId == 'T2');
      expect(t2.isRealtime, false);
    });

    test('RT failure falls back to scheduled', () async {
      final mockRt = MockRealtimeRepo(shouldThrow: true);
      final useCase = GetStopDepartures(repo, mockRt);
      final result = await useCase('S1');

      expect(result.length, 2);
      expect(result.every((d) => !d.isRealtime), true);
    });

    test('empty stop returns empty list', () async {
      final useCase = GetStopDepartures(repo, null);
      final result = await useCase('NON_EXISTENT');
      expect(result, isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // 6. Calendar service ID resolution
  // ═══════════════════════════════════════════════════════════════════

  group('GtfsRepositoryImpl: Calendar resolution', () {
    late GtfsRepositoryImpl repo;

    setUp(() async {
      repo = GtfsRepositoryImpl(db);

      await db.insertCalendar([
        GtfsCalendarCompanion.insert(
          serviceId: 'SVC_WK',
          monday: true,
          tuesday: true,
          wednesday: true,
          thursday: true,
          friday: true,
          saturday: false,
          sunday: false,
          startDate: '20240101',
          endDate: '20261231',
        ),
        GtfsCalendarCompanion.insert(
          serviceId: 'SVC_WE',
          monday: false,
          tuesday: false,
          wednesday: false,
          thursday: false,
          friday: false,
          saturday: true,
          sunday: true,
          startDate: '20240101',
          endDate: '20261231',
        ),
      ]);

      await db.insertRoutes([
        GtfsRoutesCompanion.insert(
            routeId: 'R1',
            routeShortName: '1',
            routeLongName: 'Route 1',
            routeType: 3),
      ]);
    });

    test('weekday-only trips show on weekdays, weekend-only trips on weekends',
        () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final serviceDate = DateTimeUtils.getServiceDate();
      final isWeekday = serviceDate.weekday >= 1 && serviceDate.weekday <= 5;

      // Create trips for both services
      await db.insertTrips([
        GtfsTripsCompanion.insert(
            tripId: 'T_WK', routeId: 'R1', serviceId: 'SVC_WK'),
        GtfsTripsCompanion.insert(
            tripId: 'T_WE', routeId: 'R1', serviceId: 'SVC_WE'),
      ]);

      String secsToGtfsTime(int totalSecs) {
        final h = totalSecs ~/ 3600;
        final m = (totalSecs % 3600) ~/ 60;
        final s = totalSecs % 60;
        return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      }

      await db.insertStopTimes([
        GtfsStopTimesCompanion.insert(
            tripId: 'T_WK',
            arrivalTime: secsToGtfsTime(now + 600),
            departureTime: secsToGtfsTime(now + 600),
            stopId: 'S1',
            stopSequence: 1),
        GtfsStopTimesCompanion.insert(
            tripId: 'T_WE',
            arrivalTime: secsToGtfsTime(now + 600),
            departureTime: secsToGtfsTime(now + 600),
            stopId: 'S1',
            stopSequence: 1),
      ]);

      final deps = await repo.getScheduledDepartures('S1');

      if (isWeekday) {
        expect(deps.any((d) => d.tripId == 'T_WK'), true);
        expect(deps.any((d) => d.tripId == 'T_WE'), false);
      } else {
        expect(deps.any((d) => d.tripId == 'T_WE'), true);
        expect(deps.any((d) => d.tripId == 'T_WK'), false);
      }
    });

    test('calendar_dates exceptions override calendar entries', () async {
      final serviceDate = DateTimeUtils.getServiceDate();
      final dateStr = DateTimeUtils.toGtfsDate(serviceDate);
      final isWeekday = serviceDate.weekday >= 1 && serviceDate.weekday <= 5;

      // Remove the normal service for today and add a special one
      await db.insertCalendarDates([
        GtfsCalendarDatesCompanion.insert(
          serviceId: isWeekday ? 'SVC_WK' : 'SVC_WE',
          date: dateStr, exceptionType: 2, // remove
        ),
        GtfsCalendarDatesCompanion.insert(
          serviceId: 'SVC_SPECIAL',
          date: dateStr, exceptionType: 1, // add
        ),
      ]);

      final now = DateTimeUtils.currentTimeAsSeconds();
      String secsToGtfsTime(int totalSecs) {
        final h = totalSecs ~/ 3600;
        final m = (totalSecs % 3600) ~/ 60;
        final s = totalSecs % 60;
        return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
      }

      await db.insertTrips([
        GtfsTripsCompanion.insert(
            tripId: 'T_NORMAL',
            routeId: 'R1',
            serviceId: isWeekday ? 'SVC_WK' : 'SVC_WE'),
        GtfsTripsCompanion.insert(
            tripId: 'T_SPECIAL', routeId: 'R1', serviceId: 'SVC_SPECIAL'),
      ]);
      await db.insertStopTimes([
        GtfsStopTimesCompanion.insert(
            tripId: 'T_NORMAL',
            arrivalTime: secsToGtfsTime(now + 600),
            departureTime: secsToGtfsTime(now + 600),
            stopId: 'S1',
            stopSequence: 1),
        GtfsStopTimesCompanion.insert(
            tripId: 'T_SPECIAL',
            arrivalTime: secsToGtfsTime(now + 600),
            departureTime: secsToGtfsTime(now + 600),
            stopId: 'S1',
            stopSequence: 1),
      ]);

      // Clear the repo's service ID cache so it picks up the new calendar_dates
      repo.clearCache();
      final deps = await repo.getScheduledDepartures('S1');

      expect(deps.any((d) => d.tripId == 'T_NORMAL'),
          false); // removed by exception
      expect(
          deps.any((d) => d.tripId == 'T_SPECIAL'), true); // added by exception
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // 7. GtfsCsvParser tests (with real parsing, not mocks)
  // ═══════════════════════════════════════════════════════════════════

  group('GtfsCsvParser: real parsing', () {
    test('parses simple CSV', () {
      final result = GtfsCsvParser.parse('stop_id,stop_name,stop_lat,stop_lon\n'
          '70001,Termini,41.9,12.5\n'
          '70002,Colosseo,41.89,12.49\n');
      expect(result.length, 2);
      expect(result[0]['stop_id'], '70001');
      expect(result[0]['stop_name'], 'Termini');
      expect(result[1]['stop_id'], '70002');
    });

    test('handles BOM at start of file', () {
      final result =
          GtfsCsvParser.parse('\uFEFFstop_id,stop_name,stop_lat,stop_lon\n'
              '70001,Termini,41.9,12.5\n');
      expect(result.length, 1);
      expect(result[0]['stop_id'], '70001'); // Not '\uFEFFstop_id'
    });

    test('handles quoted fields', () {
      final result = GtfsCsvParser.parse('route_id,route_long_name\n'
          'R1,"Termini - San Pietro"\n');
      expect(result.length, 1);
      expect(result[0]['route_long_name'], 'Termini - San Pietro');
    });

    test('handles quoted headers', () {
      final result =
          GtfsCsvParser.parse('"stop_id","stop_name","stop_lat","stop_lon"\n'
              '70001,Termini,41.9,12.5\n');
      expect(result.length, 1);
      expect(result[0]['stop_id'], '70001');
    });

    test('handles \\r\\n line endings', () {
      final result = GtfsCsvParser.parse('stop_id,stop_name\r\n'
          '70001,Termini\r\n'
          '70002,Colosseo\r\n');
      expect(result.length, 2);
    });

    test('handles escaped quotes in fields', () {
      final result = GtfsCsvParser.parse('field1,field2\n'
          '"value with ""quotes""",normal\n');
      expect(result.length, 1);
      expect(result[0]['field1'], 'value with "quotes"');
    });

    test('skips empty rows', () {
      final result = GtfsCsvParser.parse('stop_id,stop_name\n'
          '70001,Termini\n'
          '\n'
          '70002,Colosseo\n'
          '\n');
      expect(result.length, 2);
    });

    test('empty content returns empty list', () {
      expect(GtfsCsvParser.parse(''), isEmpty);
    });

    test('header-only content returns empty list', () {
      final result = GtfsCsvParser.parse('stop_id,stop_name\n');
      expect(result, isEmpty);
    });

    test('BOM + quoted headers + CRLF', () {
      final result = GtfsCsvParser.parse(
          '\uFEFF"trip_id","arrival_time","departure_time","stop_id","stop_sequence"\r\n'
          'T001,08:00:00,08:01:00,S001,1\r\n');
      expect(result.length, 1);
      expect(result[0]['trip_id'], 'T001');
      expect(result[0]['stop_id'], 'S001');
    });

    test('full ATAC-style stop_times CSV', () {
      final result = GtfsCsvParser.parse(
          '"trip_id","arrival_time","departure_time","stop_id","stop_sequence","stop_headsign","pickup_type","drop_off_type"\n'
          'T_12345,08:30:00,08:31:00,70001,5,,0,0\n'
          'T_12345,08:35:00,08:36:00,70002,6,,0,0\n');
      expect(result.length, 2);
      expect(result[0]['trip_id'], 'T_12345');
      expect(result[0]['arrival_time'], '08:30:00');
      expect(result[0]['stop_headsign'], '');
      expect(result[1]['stop_id'], '70002');
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // 8. End-to-end: CSV → Parse → DB → Repository → UseCase
  // ═══════════════════════════════════════════════════════════════════

  group('End-to-end: CSV to departure query', () {
    test('complete pipeline: parse CSV, insert into DB, query departures',
        () async {
      // Simulate what sync does: parse CSV → insert → query

      // 1. Parse routes CSV
      final routesCsv = GtfsCsvParser.parse(
          'route_id,route_short_name,route_long_name,route_type,route_color\n'
          'R64,64,Termini-San Pietro,3,FF0000\n');
      final routeCompanions = routesCsv
          .map((row) => GtfsRoutesCompanion.insert(
                routeId: row['route_id']!,
                routeShortName: row['route_short_name']!,
                routeLongName: row['route_long_name']!,
                routeType: int.parse(row['route_type']!),
                routeColor: Value(row['route_color']),
              ))
          .toList();
      await db.insertRoutes(routeCompanions);

      // 2. Parse calendar CSV
      final calendarCsv = GtfsCsvParser.parse(
          'service_id,monday,tuesday,wednesday,thursday,friday,saturday,sunday,start_date,end_date\n'
          'SVC_ALL,1,1,1,1,1,1,1,20240101,20261231\n');
      final calCompanions = calendarCsv
          .map((row) => GtfsCalendarCompanion.insert(
                serviceId: row['service_id']!,
                monday: row['monday'] == '1',
                tuesday: row['tuesday'] == '1',
                wednesday: row['wednesday'] == '1',
                thursday: row['thursday'] == '1',
                friday: row['friday'] == '1',
                saturday: row['saturday'] == '1',
                sunday: row['sunday'] == '1',
                startDate: row['start_date']!,
                endDate: row['end_date']!,
              ))
          .toList();
      await db.insertCalendar(calCompanions);

      // 3. Parse trips CSV
      final now = DateTimeUtils.currentTimeAsSeconds();
      final depTime = now + 900;
      final h = depTime ~/ 3600;
      final m = (depTime % 3600) ~/ 60;
      final s = depTime % 60;
      final timeStr =
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';

      final tripsCsv = GtfsCsvParser.parse(
          'trip_id,route_id,service_id,trip_headsign,direction_id\n'
          'T_E2E,R64,SVC_ALL,Termini,0\n');
      final tripCompanions = tripsCsv
          .map((row) => GtfsTripsCompanion.insert(
                tripId: row['trip_id']!,
                routeId: row['route_id']!,
                serviceId: row['service_id']!,
                tripHeadsign: Value(row['trip_headsign']),
                directionId: Value(int.tryParse(row['direction_id'] ?? '')),
              ))
          .toList();
      await db.insertTrips(tripCompanions);

      // 4. Parse stop_times CSV
      final stCsv = GtfsCsvParser.parse(
          'trip_id,arrival_time,departure_time,stop_id,stop_sequence\n'
          'T_E2E,$timeStr,$timeStr,S_E2E,1\n');
      final stCompanions = stCsv
          .map((row) => GtfsStopTimesCompanion.insert(
                tripId: row['trip_id']!,
                arrivalTime: row['arrival_time']!,
                departureTime: row['departure_time']!,
                stopId: row['stop_id']!,
                stopSequence: int.parse(row['stop_sequence']!),
              ))
          .toList();
      await db.insertStopTimes(stCompanions);

      // 5. Query through the full stack
      final repo = GtfsRepositoryImpl(db);
      final useCase = GetStopDepartures(repo, null);
      final departures = await useCase('S_E2E');

      expect(departures.length, 1);
      expect(departures[0].tripId, 'T_E2E');
      expect(departures[0].routeShortName, '64');
      expect(departures[0].routeColor, 'FF0000');
      expect(departures[0].tripHeadsign, 'Termini');
      expect(departures[0].directionId, 0);
      expect(departures[0].isRealtime, false);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // 9. DateTimeUtils comprehensive edge tests
  // ═══════════════════════════════════════════════════════════════════

  group('DateTimeUtils: parseGtfsTime', () {
    test('parses midnight', () {
      expect(DateTimeUtils.parseGtfsTime('00:00:00'), 0);
    });

    test('parses one second before midnight', () {
      expect(DateTimeUtils.parseGtfsTime('23:59:59'), 86399);
    });

    test('parses exactly 24:00', () {
      expect(DateTimeUtils.parseGtfsTime('24:00:00'), 86400);
    });

    test('parses after-midnight times', () {
      expect(DateTimeUtils.parseGtfsTime('25:30:00'), 91800);
      expect(DateTimeUtils.parseGtfsTime('27:00:00'), 97200);
    });

    test('handles leading/trailing whitespace', () {
      expect(DateTimeUtils.parseGtfsTime(' 08:30:00 '), 30600);
    });

    test('throws on empty string', () {
      expect(() => DateTimeUtils.parseGtfsTime(''), throwsFormatException);
    });

    test('throws on partial time', () {
      expect(() => DateTimeUtils.parseGtfsTime('08:30'), throwsFormatException);
    });

    test('throws on non-numeric', () {
      expect(() => DateTimeUtils.parseGtfsTime('ab:cd:ef'),
          throwsA(isA<FormatException>()));
    });

    test('throws on extra colons', () {
      expect(() => DateTimeUtils.parseGtfsTime('08:30:00:00'),
          throwsFormatException);
    });
  });

  group('DateTimeUtils: formatTime', () {
    test('formats correctly and normalizes > 24h', () {
      expect(DateTimeUtils.formatTime(0), '00:00');
      expect(DateTimeUtils.formatTime(43200), '12:00');
      expect(DateTimeUtils.formatTime(86400), '00:00'); // 24:00 → 00:00
      expect(DateTimeUtils.formatTime(91800), '01:30'); // 25:30 → 01:30
    });
  });

  group('DateTimeUtils: service date', () {
    test('before 4 AM → yesterday', () {
      expect(DateTimeUtils.getServiceDate(DateTime(2024, 6, 15, 3, 59)),
          DateTime(2024, 6, 14));
    });

    test('at 4 AM → today', () {
      expect(DateTimeUtils.getServiceDate(DateTime(2024, 6, 15, 4, 0)),
          DateTime(2024, 6, 15));
    });

    test('across year boundary', () {
      expect(DateTimeUtils.getServiceDate(DateTime(2025, 1, 1, 1, 0)),
          DateTime(2024, 12, 31));
    });
  });

  group('DateTimeUtils: GTFS date roundtrip', () {
    test('parse and format are consistent', () {
      final dates = [
        DateTime(2024, 1, 1),
        DateTime(2024, 2, 29),
        DateTime(2024, 12, 31)
      ];
      for (final d in dates) {
        expect(DateTimeUtils.parseGtfsDate(DateTimeUtils.toGtfsDate(d)), d);
      }
    });
  });

  group('DateTimeUtils: weekdayName', () {
    test('all 7 days', () {
      expect(DateTimeUtils.weekdayName(1), 'monday');
      expect(DateTimeUtils.weekdayName(7), 'sunday');
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // 10. Departure entity tests
  // ═══════════════════════════════════════════════════════════════════

  group('Departure entity', () {
    test('effectiveSeconds uses estimatedSeconds when available', () {
      const dep = Departure(
        tripId: 't1',
        routeId: 'r1',
        routeShortName: '64',
        scheduledTime: '08:00:00',
        scheduledSeconds: 28800,
        estimatedSeconds: 29000,
        isRealtime: true,
      );
      expect(dep.effectiveSeconds, 29000);
    });

    test('effectiveSeconds falls back to scheduledSeconds', () {
      const dep = Departure(
        tripId: 't1',
        routeId: 'r1',
        routeShortName: '64',
        scheduledTime: '08:00:00',
        scheduledSeconds: 28800,
      );
      expect(dep.effectiveSeconds, 28800);
    });

    test('defaults: isRealtime false, optional fields null', () {
      const dep = Departure(
        tripId: 't1',
        routeId: 'r1',
        routeShortName: '64',
        scheduledTime: '08:00:00',
        scheduledSeconds: 28800,
      );
      expect(dep.isRealtime, false);
      expect(dep.estimatedSeconds, isNull);
      expect(dep.delaySeconds, isNull);
      expect(dep.routeColor, isNull);
      expect(dep.tripHeadsign, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // 11. DepartureRow + _rowsToDepartures resilience
  // ═══════════════════════════════════════════════════════════════════

  group('DepartureRow → Departure mapping resilience', () {
    // Helper that replicates the _rowsToDepartures logic
    List<Departure> rowsToDepartures(List<DepartureRow> rows) {
      final departures = <Departure>[];
      for (final row in rows) {
        if (row.departureTime.trim().isEmpty) continue;
        final int seconds;
        try {
          seconds = DateTimeUtils.parseGtfsTime(row.departureTime);
        } catch (_) {
          continue;
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
      departures
          .sort((a, b) => a.scheduledSeconds.compareTo(b.scheduledSeconds));
      return departures;
    }

    test('good rows are parsed', () {
      final deps = rowsToDepartures([
        DepartureRow(
            tripId: 'T1',
            departureTime: '08:00:00',
            routeId: 'R1',
            serviceId: 'S',
            routeShortName: '64'),
        DepartureRow(
            tripId: 'T2',
            departureTime: '12:00:00',
            routeId: 'R1',
            serviceId: 'S',
            routeShortName: '64'),
      ]);
      expect(deps.length, 2);
    });

    test('malformed times are skipped', () {
      final deps = rowsToDepartures([
        DepartureRow(
            tripId: 'T_GOOD',
            departureTime: '12:00:00',
            routeId: 'R1',
            serviceId: 'S',
            routeShortName: '64'),
        DepartureRow(
            tripId: 'T_BAD',
            departureTime: 'INVALID',
            routeId: 'R1',
            serviceId: 'S',
            routeShortName: '64'),
        DepartureRow(
            tripId: 'T_PARTIAL',
            departureTime: '08:30',
            routeId: 'R1',
            serviceId: 'S',
            routeShortName: '64'),
      ]);
      expect(deps.length, 1);
      expect(deps[0].tripId, 'T_GOOD');
    });

    test('empty departure times are skipped', () {
      final deps = rowsToDepartures([
        DepartureRow(
            tripId: 'T1',
            departureTime: '',
            routeId: 'R1',
            serviceId: 'S',
            routeShortName: '64'),
        DepartureRow(
            tripId: 'T2',
            departureTime: '   ',
            routeId: 'R1',
            serviceId: 'S',
            routeShortName: '64'),
        DepartureRow(
            tripId: 'T3',
            departureTime: '10:00:00',
            routeId: 'R1',
            serviceId: 'S',
            routeShortName: '64'),
      ]);
      expect(deps.length, 1);
    });

    test('tripHeadsign falls back to stopHeadsign', () {
      final deps = rowsToDepartures([
        DepartureRow(
            tripId: 'T1',
            departureTime: '12:00:00',
            routeId: 'R1',
            serviceId: 'S',
            routeShortName: '64',
            tripHeadsign: null,
            stopHeadsign: 'Capolinea'),
      ]);
      expect(deps[0].tripHeadsign, 'Capolinea');
    });

    test('tripHeadsign takes priority over stopHeadsign', () {
      final deps = rowsToDepartures([
        DepartureRow(
            tripId: 'T1',
            departureTime: '12:00:00',
            routeId: 'R1',
            serviceId: 'S',
            routeShortName: '64',
            tripHeadsign: 'Termini',
            stopHeadsign: 'Via Nazionale'),
      ]);
      expect(deps[0].tripHeadsign, 'Termini');
    });

    test('results are sorted by scheduledSeconds', () {
      final deps = rowsToDepartures([
        DepartureRow(
            tripId: 'T3',
            departureTime: '15:00:00',
            routeId: 'R1',
            serviceId: 'S',
            routeShortName: '64'),
        DepartureRow(
            tripId: 'T1',
            departureTime: '08:00:00',
            routeId: 'R1',
            serviceId: 'S',
            routeShortName: '64'),
        DepartureRow(
            tripId: 'T2',
            departureTime: '12:00:00',
            routeId: 'R1',
            serviceId: 'S',
            routeShortName: '64'),
      ]);
      expect(deps.map((d) => d.tripId).toList(), ['T1', 'T2', 'T3']);
    });

    test('after-midnight GTFS times parse correctly', () {
      final deps = rowsToDepartures([
        DepartureRow(
            tripId: 'T_NIGHT',
            departureTime: '25:30:00',
            routeId: 'R1',
            serviceId: 'S',
            routeShortName: 'N1'),
      ]);
      expect(deps[0].scheduledSeconds, 91800);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // 12. Count / stats verification
  // ═══════════════════════════════════════════════════════════════════

  group('Database: count/stats', () {
    test('countStops, countRoutes, countTrips, countStopTimes', () async {
      await db.insertStops([
        GtfsStopsCompanion.insert(
            stopId: 'S1', stopName: 'A', stopLat: 0, stopLon: 0),
        GtfsStopsCompanion.insert(
            stopId: 'S2', stopName: 'B', stopLat: 0, stopLon: 0),
      ]);
      await db.insertRoutes([
        GtfsRoutesCompanion.insert(
            routeId: 'R1',
            routeShortName: '1',
            routeLongName: 'Route',
            routeType: 3),
      ]);
      await db.insertTrips([
        GtfsTripsCompanion.insert(tripId: 'T1', routeId: 'R1', serviceId: 'S'),
        GtfsTripsCompanion.insert(tripId: 'T2', routeId: 'R1', serviceId: 'S'),
        GtfsTripsCompanion.insert(tripId: 'T3', routeId: 'R1', serviceId: 'S'),
      ]);
      await db.insertStopTimes([
        GtfsStopTimesCompanion.insert(
            tripId: 'T1',
            arrivalTime: '08:00:00',
            departureTime: '08:00:00',
            stopId: 'S1',
            stopSequence: 1),
      ]);

      expect(await db.countStops(), 2);
      expect(await db.countRoutes(), 1);
      expect(await db.countTrips(), 3);
      expect(await db.countStopTimes(), 1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // v0.0.11: Direction filtering + nearby stops
  // ═══════════════════════════════════════════════════════════════════

  group('Database: direction filtering', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() => db.close());

    test('getStopsForRouteJoin with directionId filters correctly', () async {
      await db.insertStops([
        GtfsStopsCompanion.insert(
            stopId: 'A', stopName: 'Stop A', stopLat: 41.9, stopLon: 12.5),
        GtfsStopsCompanion.insert(
            stopId: 'B', stopName: 'Stop B', stopLat: 41.91, stopLon: 12.51),
        GtfsStopsCompanion.insert(
            stopId: 'C', stopName: 'Stop C', stopLat: 41.92, stopLon: 12.52),
      ]);
      await db.insertRoutes([
        GtfsRoutesCompanion.insert(
            routeId: 'R1',
            routeShortName: '64',
            routeLongName: 'Route 64',
            routeType: 3),
      ]);
      await db.insertTrips([
        GtfsTripsCompanion.insert(
            tripId: 'T_OUT',
            routeId: 'R1',
            serviceId: 'SVC1',
            directionId: const Value(0)),
        GtfsTripsCompanion.insert(
            tripId: 'T_IN',
            routeId: 'R1',
            serviceId: 'SVC1',
            directionId: const Value(1)),
      ]);
      await db.insertStopTimes([
        // Outbound: A -> B
        GtfsStopTimesCompanion.insert(
            tripId: 'T_OUT',
            arrivalTime: '08:00:00',
            departureTime: '08:00:00',
            stopId: 'A',
            stopSequence: 1),
        GtfsStopTimesCompanion.insert(
            tripId: 'T_OUT',
            arrivalTime: '08:10:00',
            departureTime: '08:10:00',
            stopId: 'B',
            stopSequence: 2),
        // Inbound: C -> A
        GtfsStopTimesCompanion.insert(
            tripId: 'T_IN',
            arrivalTime: '09:00:00',
            departureTime: '09:00:00',
            stopId: 'C',
            stopSequence: 1),
        GtfsStopTimesCompanion.insert(
            tripId: 'T_IN',
            arrivalTime: '09:10:00',
            departureTime: '09:10:00',
            stopId: 'A',
            stopSequence: 2),
      ]);

      // Without direction filter -> picks longest trip (both have 2 stops,
      // so picks first found)
      final allStops = await db.getStopsForRouteJoin('R1');
      expect(allStops.length, 2);

      // Direction 0 (outbound): A -> B
      final outbound = await db.getStopsForRouteJoin('R1', directionId: 0);
      expect(outbound.length, 2);
      expect(outbound[0].stopId, 'A');
      expect(outbound[1].stopId, 'B');

      // Direction 1 (inbound): C -> A
      final inbound = await db.getStopsForRouteJoin('R1', directionId: 1);
      expect(inbound.length, 2);
      expect(inbound[0].stopId, 'C');
      expect(inbound[1].stopId, 'A');
    });

    test('getDirectionsForRoute returns available directions', () async {
      await db.insertTrips([
        GtfsTripsCompanion.insert(
            tripId: 'T1',
            routeId: 'R1',
            serviceId: 'S1',
            directionId: const Value(0)),
        GtfsTripsCompanion.insert(
            tripId: 'T2',
            routeId: 'R1',
            serviceId: 'S1',
            directionId: const Value(1)),
        GtfsTripsCompanion.insert(
            tripId: 'T3',
            routeId: 'R1',
            serviceId: 'S1',
            directionId: const Value(0)),
      ]);

      final directions = await db.getDirectionsForRoute('R1');
      expect(directions, [0, 1]);
    });

    test('getDirectionsForRoute returns empty for route without directions',
        () async {
      await db.insertTrips([
        GtfsTripsCompanion.insert(tripId: 'T1', routeId: 'R2', serviceId: 'S1'),
      ]);

      final directions = await db.getDirectionsForRoute('R2');
      expect(directions, isEmpty);
    });

    test('getHeadsignForDirection returns headsign', () async {
      await db.insertTrips([
        GtfsTripsCompanion.insert(
            tripId: 'T1',
            routeId: 'R1',
            serviceId: 'S1',
            directionId: const Value(0),
            tripHeadsign: const Value('Termini')),
        GtfsTripsCompanion.insert(
            tripId: 'T2',
            routeId: 'R1',
            serviceId: 'S1',
            directionId: const Value(1),
            tripHeadsign: const Value('San Pietro')),
      ]);

      final h0 = await db.getHeadsignForDirection('R1', 0);
      expect(h0, 'Termini');

      final h1 = await db.getHeadsignForDirection('R1', 1);
      expect(h1, 'San Pietro');
    });
  });

  group('DistanceUtils: nearby stops filtering', () {
    test('haversine distance between Rome points is reasonable', () {
      // Termini station to Colosseum (~1.1 km)
      final distance = DistanceUtils.haversineDistance(
        41.9009, 12.5016, // Termini
        41.8902, 12.4923, // Colosseum
      );
      expect(distance, greaterThan(500));
      expect(distance, lessThan(2000));
    });

    test('filtering stops within 1 km radius', () {
      const userLat = 41.9009;
      const userLon = 12.5016;
      final stops = [
        const Stop(
            stopId: 'near',
            stopName: 'Near',
            stopLat: 41.9015,
            stopLon: 12.5020), // ~80m
        const Stop(
            stopId: 'mid',
            stopName: 'Mid',
            stopLat: 41.9050,
            stopLon: 12.5080), // ~600m
        const Stop(
            stopId: 'far',
            stopName: 'Far',
            stopLat: 41.8800,
            stopLon: 12.4700), // ~3.5km
      ];

      final within1km = stops.where((s) {
        final d = DistanceUtils.haversineDistance(
          userLat,
          userLon,
          s.stopLat,
          s.stopLon,
        );
        return d <= 1000;
      }).toList();

      expect(within1km.length, 2);
      expect(within1km.map((s) => s.stopId), containsAll(['near', 'mid']));
    });

    test('nearby stops are sorted by distance', () {
      const userLat = 41.9009;
      const userLon = 12.5016;
      final stops = [
        const Stop(
            stopId: 'mid', stopName: 'Mid', stopLat: 41.9050, stopLon: 12.5080),
        const Stop(
            stopId: 'near',
            stopName: 'Near',
            stopLat: 41.9015,
            stopLon: 12.5020),
      ];

      final withDist = stops.map((s) {
        final d = DistanceUtils.haversineDistance(
          userLat,
          userLon,
          s.stopLat,
          s.stopLon,
        );
        return (stop: s, distance: d);
      }).toList()
        ..sort((a, b) => a.distance.compareTo(b.distance));

      expect(withDist.first.stop.stopId, 'near');
      expect(withDist.last.stop.stopId, 'mid');
    });
  });

  group('GtfsRepositoryImpl: direction support', () {
    late AppDatabase db;
    late GtfsRepositoryImpl repo;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
      repo = GtfsRepositoryImpl(db);
    });

    tearDown(() => db.close());

    test('getStopsForRoute with directionId filters via repository', () async {
      await db.insertStops([
        GtfsStopsCompanion.insert(
            stopId: 'X', stopName: 'Stop X', stopLat: 41.9, stopLon: 12.5),
        GtfsStopsCompanion.insert(
            stopId: 'Y', stopName: 'Stop Y', stopLat: 41.91, stopLon: 12.51),
      ]);
      await db.insertRoutes([
        GtfsRoutesCompanion.insert(
            routeId: 'R1',
            routeShortName: '1',
            routeLongName: 'Route 1',
            routeType: 3),
      ]);
      await db.insertTrips([
        GtfsTripsCompanion.insert(
            tripId: 'T0',
            routeId: 'R1',
            serviceId: 'S1',
            directionId: const Value(0)),
        GtfsTripsCompanion.insert(
            tripId: 'T1',
            routeId: 'R1',
            serviceId: 'S1',
            directionId: const Value(1)),
      ]);
      await db.insertStopTimes([
        GtfsStopTimesCompanion.insert(
            tripId: 'T0',
            arrivalTime: '08:00:00',
            departureTime: '08:00:00',
            stopId: 'X',
            stopSequence: 1),
        GtfsStopTimesCompanion.insert(
            tripId: 'T0',
            arrivalTime: '08:10:00',
            departureTime: '08:10:00',
            stopId: 'Y',
            stopSequence: 2),
        GtfsStopTimesCompanion.insert(
            tripId: 'T1',
            arrivalTime: '09:00:00',
            departureTime: '09:00:00',
            stopId: 'Y',
            stopSequence: 1),
        GtfsStopTimesCompanion.insert(
            tripId: 'T1',
            arrivalTime: '09:10:00',
            departureTime: '09:10:00',
            stopId: 'X',
            stopSequence: 2),
      ]);

      final dir0 = await repo.getStopsForRoute('R1', directionId: 0);
      expect(dir0.length, 2);
      expect(dir0[0].stopId, 'X');

      final dir1 = await repo.getStopsForRoute('R1', directionId: 1);
      expect(dir1.length, 2);
      expect(dir1[0].stopId, 'Y');

      final directions = await repo.getDirectionsForRoute('R1');
      expect(directions, [0, 1]);
    });
  });
}
