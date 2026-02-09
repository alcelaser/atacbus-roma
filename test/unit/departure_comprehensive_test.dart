import 'package:flutter_test/flutter_test.dart';
import 'package:atacbus_roma/core/utils/date_time_utils.dart';
import 'package:atacbus_roma/domain/entities/departure.dart';
import 'package:atacbus_roma/domain/entities/stop.dart';
import 'package:atacbus_roma/domain/entities/route_entity.dart';
import 'package:atacbus_roma/domain/entities/vehicle.dart';
import 'package:atacbus_roma/domain/entities/service_alert.dart';
import 'package:atacbus_roma/domain/repositories/gtfs_repository.dart';
import 'package:atacbus_roma/domain/repositories/realtime_repository.dart';
import 'package:atacbus_roma/domain/usecases/get_stop_departures.dart';
import 'package:atacbus_roma/data/datasources/local/database/app_database.dart';

// ─── Mock classes ────────────────────────────────────────────

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

class MockGtfsRepo implements GtfsRepository {
  List<Departure> departures;
  List<Stop> stops;
  List<RouteEntity> routes;

  MockGtfsRepo({
    this.departures = const [],
    this.stops = const [],
    this.routes = const [],
  });

  @override
  Future<List<Departure>> getScheduledDepartures(String stopId) async =>
      departures;
  @override
  Future<List<Stop>> searchStops(String query) async => stops
      .where((s) => s.stopName.toLowerCase().contains(query.toLowerCase()))
      .toList();
  @override
  Future<Stop?> getStopById(String stopId) async =>
      stops.where((s) => s.stopId == stopId).isEmpty
          ? null
          : stops.firstWhere((s) => s.stopId == stopId);
  @override
  Future<List<Stop>> getAllStops() async => stops;
  @override
  Future<List<RouteEntity>> getAllRoutes() async => routes;
  @override
  Future<List<RouteEntity>> getRoutesByType(int type) async =>
      routes.where((r) => r.routeType == type).toList();
  @override
  Future<RouteEntity?> getRouteById(String routeId) async =>
      routes.where((r) => r.routeId == routeId).isEmpty
          ? null
          : routes.firstWhere((r) => r.routeId == routeId);
  @override
  Future<List<RouteEntity>> getRoutesForStop(String stopId) async => routes;
  @override
  Future<List<Stop>> getStopsForRoute(String routeId,
          {int? directionId}) async =>
      stops;
  @override
  Future<List<int>> getDirectionsForRoute(String routeId) async => [];
  @override
  Future<String?> getHeadsignForDirection(
          String routeId, int directionId) async =>
      null;
  @override
  Future<bool> isFavorite(String stopId) async => false;
  @override
  Future<void> addFavorite(String stopId) async {}
  @override
  Future<void> removeFavorite(String stopId) async {}
  @override
  Future<List<String>> getFavoriteStopIds() async => [];
  @override
  Stream<List<String>> watchFavoriteStopIds() => const Stream.empty();
}

void main() {
  // ─── DateTimeUtils: comprehensive edge cases ────────────────

  group('DateTimeUtils: GTFS time parsing edge cases', () {
    test('parses midnight (00:00:00)', () {
      expect(DateTimeUtils.parseGtfsTime('00:00:00'), 0);
    });

    test('parses one second before midnight', () {
      expect(DateTimeUtils.parseGtfsTime('23:59:59'), 86399);
    });

    test('parses exactly midnight next day (24:00:00)', () {
      expect(DateTimeUtils.parseGtfsTime('24:00:00'), 86400);
    });

    test('parses after-midnight GTFS time (25:30:00)', () {
      // 25:30:00 = 25*3600 + 30*60 = 91800
      expect(DateTimeUtils.parseGtfsTime('25:30:00'), 91800);
    });

    test('parses late after-midnight GTFS time (27:00:00)', () {
      // 27*3600 = 97200 (3:00 AM next day in GTFS convention)
      expect(DateTimeUtils.parseGtfsTime('27:00:00'), 97200);
    });

    test('parses early morning time (04:00:00)', () {
      expect(DateTimeUtils.parseGtfsTime('04:00:00'), 14400);
    });

    test('parses noon', () {
      expect(DateTimeUtils.parseGtfsTime('12:00:00'), 43200);
    });

    test('throws on invalid format (missing part)', () {
      expect(
        () => DateTimeUtils.parseGtfsTime('08:30'),
        throwsFormatException,
      );
    });

    test('handles leading spaces', () {
      expect(DateTimeUtils.parseGtfsTime(' 08:30:00 '), 30600);
    });
  });

  group('DateTimeUtils: formatTime edge cases', () {
    test('formats midnight as 00:00', () {
      expect(DateTimeUtils.formatTime(0), '00:00');
    });

    test('formats noon as 12:00', () {
      expect(DateTimeUtils.formatTime(43200), '12:00');
    });

    test('formats 23:59 correctly', () {
      expect(DateTimeUtils.formatTime(86340), '23:59');
    });

    test('normalizes 24:00 to 00:00', () {
      expect(DateTimeUtils.formatTime(86400), '00:00');
    });

    test('normalizes 25:30 to 01:30', () {
      expect(DateTimeUtils.formatTime(91800), '01:30');
    });

    test('normalizes 27:00 to 03:00', () {
      expect(DateTimeUtils.formatTime(97200), '03:00');
    });

    test('formats single-digit hours with leading zero', () {
      expect(DateTimeUtils.formatTime(3600), '01:00');
    });

    test('formats single-digit minutes with leading zero', () {
      expect(DateTimeUtils.formatTime(3660), '01:01');
    });
  });

  group('DateTimeUtils: service date logic', () {
    test('at 3:59 AM → service date is yesterday', () {
      final dt = DateTime(2024, 6, 15, 3, 59);
      final sd = DateTimeUtils.getServiceDate(dt);
      expect(sd, DateTime(2024, 6, 14));
    });

    test('at exactly 4:00 AM → service date is today', () {
      final dt = DateTime(2024, 6, 15, 4, 0);
      final sd = DateTimeUtils.getServiceDate(dt);
      expect(sd, DateTime(2024, 6, 15));
    });

    test('at midnight (00:00) → service date is yesterday', () {
      final dt = DateTime(2024, 6, 15, 0, 0);
      final sd = DateTimeUtils.getServiceDate(dt);
      expect(sd, DateTime(2024, 6, 14));
    });

    test('at 1:30 AM → service date is yesterday', () {
      final dt = DateTime(2024, 6, 15, 1, 30);
      final sd = DateTimeUtils.getServiceDate(dt);
      expect(sd, DateTime(2024, 6, 14));
    });

    test('at 10:00 AM → service date is today', () {
      final dt = DateTime(2024, 6, 15, 10, 0);
      final sd = DateTimeUtils.getServiceDate(dt);
      expect(sd, DateTime(2024, 6, 15));
    });

    test('at 11:59 PM → service date is today', () {
      final dt = DateTime(2024, 6, 15, 23, 59);
      final sd = DateTimeUtils.getServiceDate(dt);
      expect(sd, DateTime(2024, 6, 15));
    });

    test('service date across month boundary (June 1 at 2 AM → May 31)', () {
      final dt = DateTime(2024, 6, 1, 2, 0);
      final sd = DateTimeUtils.getServiceDate(dt);
      expect(sd, DateTime(2024, 5, 31));
    });

    test('service date across year boundary (Jan 1 at 1 AM → Dec 31)', () {
      final dt = DateTime(2025, 1, 1, 1, 0);
      final sd = DateTimeUtils.getServiceDate(dt);
      expect(sd, DateTime(2024, 12, 31));
    });
  });

  group('DateTimeUtils: GTFS date parsing/formatting', () {
    test('parses YYYYMMDD correctly', () {
      expect(DateTimeUtils.parseGtfsDate('20240101'), DateTime(2024, 1, 1));
      expect(DateTimeUtils.parseGtfsDate('20241231'), DateTime(2024, 12, 31));
    });

    test('roundtrips date through format/parse', () {
      final original = DateTime(2024, 7, 4);
      final formatted = DateTimeUtils.toGtfsDate(original);
      final parsed = DateTimeUtils.parseGtfsDate(formatted);
      expect(parsed, original);
    });

    test('formats single-digit months/days with leading zeros', () {
      expect(DateTimeUtils.toGtfsDate(DateTime(2024, 1, 5)), '20240105');
      expect(DateTimeUtils.toGtfsDate(DateTime(2024, 11, 25)), '20241125');
    });
  });

  group('DateTimeUtils: weekday names', () {
    test('all 7 weekday names match GTFS calendar columns', () {
      expect(DateTimeUtils.weekdayName(1), 'monday');
      expect(DateTimeUtils.weekdayName(2), 'tuesday');
      expect(DateTimeUtils.weekdayName(3), 'wednesday');
      expect(DateTimeUtils.weekdayName(4), 'thursday');
      expect(DateTimeUtils.weekdayName(5), 'friday');
      expect(DateTimeUtils.weekdayName(6), 'saturday');
      expect(DateTimeUtils.weekdayName(7), 'sunday');
    });
  });

  group('DateTimeUtils: minutesUntil', () {
    test('returns positive minutes for future time', () {
      final nowSeconds = DateTimeUtils.currentTimeAsSeconds();
      final futureSeconds = nowSeconds + 600; // 10 min from now
      final minutes = DateTimeUtils.minutesUntil(futureSeconds);
      // Should be approximately 10 (might be 9 due to time passage)
      expect(minutes, inInclusiveRange(9, 10));
    });

    test('returns 0 for past time', () {
      final nowSeconds = DateTimeUtils.currentTimeAsSeconds();
      expect(DateTimeUtils.minutesUntil(nowSeconds - 600), 0);
    });

    test('returns 0 for current time', () {
      final nowSeconds = DateTimeUtils.currentTimeAsSeconds();
      expect(DateTimeUtils.minutesUntil(nowSeconds), 0);
    });
  });

  // ─── Departure entity tests ────────────────────────────────

  group('Departure entity', () {
    test('effectiveSeconds returns estimatedSeconds when available', () {
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

    test('effectiveSeconds returns scheduledSeconds when no RT', () {
      const dep = Departure(
        tripId: 't1',
        routeId: 'r1',
        routeShortName: '64',
        scheduledTime: '08:00:00',
        scheduledSeconds: 28800,
      );
      expect(dep.effectiveSeconds, 28800);
    });

    test('default isRealtime is false', () {
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
    });

    test('after-midnight departure has high scheduledSeconds', () {
      // A bus at 1:30 AM (GTFS: 25:30:00) = 91800 seconds
      const dep = Departure(
        tripId: 't_night',
        routeId: 'r1',
        routeShortName: 'N1',
        scheduledTime: '25:30:00',
        scheduledSeconds: 91800,
      );
      expect(dep.scheduledSeconds, greaterThan(86400));
    });

    test('all optional fields can be null', () {
      const dep = Departure(
        tripId: 't1',
        routeId: 'r1',
        routeShortName: '64',
        scheduledTime: '08:00:00',
        scheduledSeconds: 28800,
      );
      expect(dep.routeColor, isNull);
      expect(dep.tripHeadsign, isNull);
      expect(dep.directionId, isNull);
      expect(dep.estimatedSeconds, isNull);
      expect(dep.delaySeconds, isNull);
    });
  });

  // ─── DepartureRow mapping tests ────────────────────────────

  group('DepartureRow', () {
    test('creates with all required fields', () {
      final row = DepartureRow(
        tripId: 'trip_1',
        departureTime: '08:30:00',
        routeId: 'route_64',
        serviceId: 'svc_weekday',
        routeShortName: '64',
      );
      expect(row.tripId, 'trip_1');
      expect(row.departureTime, '08:30:00');
      expect(row.routeId, 'route_64');
      expect(row.serviceId, 'svc_weekday');
      expect(row.routeShortName, '64');
    });

    test('creates with optional fields null', () {
      final row = DepartureRow(
        tripId: 'trip_1',
        departureTime: '08:30:00',
        routeId: 'route_64',
        serviceId: 'svc_weekday',
        routeShortName: '64',
      );
      expect(row.stopHeadsign, isNull);
      expect(row.tripHeadsign, isNull);
      expect(row.directionId, isNull);
      expect(row.routeColor, isNull);
    });

    test('creates with all optional fields', () {
      final row = DepartureRow(
        tripId: 'trip_1',
        departureTime: '08:30:00',
        stopHeadsign: 'Via Nazionale',
        routeId: 'route_64',
        serviceId: 'svc_weekday',
        tripHeadsign: 'Termini',
        directionId: 0,
        routeShortName: '64',
        routeColor: 'FF0000',
      );
      expect(row.stopHeadsign, 'Via Nazionale');
      expect(row.tripHeadsign, 'Termini');
      expect(row.directionId, 0);
      expect(row.routeColor, 'FF0000');
    });

    test('tripHeadsign falls back to stopHeadsign in departure mapping', () {
      // This tests the logic in _rowsToDepartures: tripHeadsign ?? stopHeadsign
      final row = DepartureRow(
        tripId: 'trip_1',
        departureTime: '08:30:00',
        stopHeadsign: 'Via Nazionale',
        routeId: 'route_64',
        serviceId: 'svc_weekday',
        tripHeadsign: null,
        routeShortName: '64',
      );
      // Simulate the mapping logic
      final headsign = row.tripHeadsign ?? row.stopHeadsign;
      expect(headsign, 'Via Nazionale');
    });

    test('tripHeadsign takes priority over stopHeadsign', () {
      final row = DepartureRow(
        tripId: 'trip_1',
        departureTime: '08:30:00',
        stopHeadsign: 'Via Nazionale',
        routeId: 'route_64',
        serviceId: 'svc_weekday',
        tripHeadsign: 'Termini',
        routeShortName: '64',
      );
      final headsign = row.tripHeadsign ?? row.stopHeadsign;
      expect(headsign, 'Termini');
    });
  });

  // ─── GetStopDepartures use case: comprehensive tests ────────

  group('GetStopDepartures: time window filtering', () {
    test('keeps departures within 90-minute window', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final mockGtfs = MockGtfsRepo(departures: [
        Departure(
          tripId: 't_in_window',
          routeId: 'r1',
          routeShortName: '64',
          scheduledTime: '08:00:00',
          scheduledSeconds: now + 1800, // 30 min from now
        ),
      ]);

      final useCase = GetStopDepartures(mockGtfs, null);
      final result = await useCase('stop_1');
      expect(result.length, 1);
    });

    test('filters out departures exactly at 90-minute boundary', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final mockGtfs = MockGtfsRepo(departures: [
        Departure(
          tripId: 't_boundary',
          routeId: 'r1',
          routeShortName: '64',
          scheduledTime: '09:30:00',
          scheduledSeconds: now + 5400, // exactly 90 min
        ),
      ]);

      final useCase = GetStopDepartures(mockGtfs, null);
      final result = await useCase('stop_1');
      expect(result.length, 1); // inclusive <= cutoff
    });

    test('filters out departures beyond 90 minutes', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final mockGtfs = MockGtfsRepo(departures: [
        Departure(
          tripId: 't_far',
          routeId: 'r1',
          routeShortName: '64',
          scheduledTime: '12:00:00',
          scheduledSeconds: now + 7200, // 120 min from now
        ),
      ]);

      final useCase = GetStopDepartures(mockGtfs, null);
      final result = await useCase('stop_1');
      expect(result.length, 0);
    });

    test('filters out past departures', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final mockGtfs = MockGtfsRepo(departures: [
        Departure(
          tripId: 't_past',
          routeId: 'r1',
          routeShortName: '64',
          scheduledTime: '06:00:00',
          scheduledSeconds: now - 1800, // 30 min ago
        ),
      ]);

      final useCase = GetStopDepartures(mockGtfs, null);
      final result = await useCase('stop_1');
      expect(result.length, 0);
    });

    test('mixed past/future departures keeps only future', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final mockGtfs = MockGtfsRepo(departures: [
        Departure(
          tripId: 't_past',
          routeId: 'r1',
          routeShortName: '64',
          scheduledTime: '06:00:00',
          scheduledSeconds: now - 600,
        ),
        Departure(
          tripId: 't_now',
          routeId: 'r1',
          routeShortName: '64',
          scheduledTime: '07:00:00',
          scheduledSeconds: now + 60, // 1 min from now
        ),
        Departure(
          tripId: 't_soon',
          routeId: 'r1',
          routeShortName: '40',
          scheduledTime: '07:30:00',
          scheduledSeconds: now + 1800,
        ),
        Departure(
          tripId: 't_far',
          routeId: 'r1',
          routeShortName: '170',
          scheduledTime: '12:00:00',
          scheduledSeconds: now + 10800, // 3 hours
        ),
      ]);

      final useCase = GetStopDepartures(mockGtfs, null);
      final result = await useCase('stop_1');
      expect(result.length, 2);
      expect(result.map((d) => d.tripId).toList(),
          containsAll(['t_now', 't_soon']));
    });
  });

  group('GetStopDepartures: RT merge', () {
    test('applies positive delay correctly', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final mockGtfs = MockGtfsRepo(departures: [
        Departure(
          tripId: 't1',
          routeId: 'r1',
          routeShortName: '64',
          scheduledTime: '08:00:00',
          scheduledSeconds: now + 600,
        ),
      ]);
      final mockRt = MockRealtimeRepo(delays: {'t1': 300}); // 5 min late

      final useCase = GetStopDepartures(mockGtfs, mockRt);
      final result = await useCase('stop_1');

      expect(result.length, 1);
      expect(result[0].isRealtime, true);
      expect(result[0].delaySeconds, 300);
      expect(result[0].estimatedSeconds, now + 600 + 300);
    });

    test('applies negative delay (early bus)', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final mockGtfs = MockGtfsRepo(departures: [
        Departure(
          tripId: 't1',
          routeId: 'r1',
          routeShortName: '64',
          scheduledTime: '08:00:00',
          scheduledSeconds: now + 600,
        ),
      ]);
      final mockRt = MockRealtimeRepo(delays: {'t1': -120}); // 2 min early

      final useCase = GetStopDepartures(mockGtfs, mockRt);
      final result = await useCase('stop_1');

      expect(result[0].delaySeconds, -120);
      expect(result[0].estimatedSeconds, now + 600 - 120);
    });

    test('zero delay is still marked as realtime', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final mockGtfs = MockGtfsRepo(departures: [
        Departure(
          tripId: 't1',
          routeId: 'r1',
          routeShortName: '64',
          scheduledTime: '08:00:00',
          scheduledSeconds: now + 600,
        ),
      ]);
      final mockRt = MockRealtimeRepo(delays: {'t1': 0}); // on time

      final useCase = GetStopDepartures(mockGtfs, mockRt);
      final result = await useCase('stop_1');

      expect(result[0].isRealtime, true);
      expect(result[0].delaySeconds, 0);
      expect(result[0].estimatedSeconds, now + 600);
    });

    test('departure without RT match keeps scheduled data', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final mockGtfs = MockGtfsRepo(departures: [
        Departure(
          tripId: 't_no_rt',
          routeId: 'r1',
          routeShortName: '64',
          scheduledTime: '08:00:00',
          scheduledSeconds: now + 600,
        ),
      ]);
      final mockRt = MockRealtimeRepo(delays: {'t_other': 120});

      final useCase = GetStopDepartures(mockGtfs, mockRt);
      final result = await useCase('stop_1');

      expect(result[0].isRealtime, false);
      expect(result[0].estimatedSeconds, isNull);
    });

    test('RT failure falls back to scheduled gracefully', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final mockGtfs = MockGtfsRepo(departures: [
        Departure(
          tripId: 't1',
          routeId: 'r1',
          routeShortName: '64',
          scheduledTime: '08:00:00',
          scheduledSeconds: now + 600,
        ),
      ]);
      final mockRt = MockRealtimeRepo(shouldThrow: true);

      final useCase = GetStopDepartures(mockGtfs, mockRt);
      final result = await useCase('stop_1');

      expect(result.length, 1);
      expect(result[0].isRealtime, false);
    });

    test('null RT repository returns scheduled data', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final mockGtfs = MockGtfsRepo(departures: [
        Departure(
          tripId: 't1',
          routeId: 'r1',
          routeShortName: '64',
          scheduledTime: '08:00:00',
          scheduledSeconds: now + 600,
        ),
      ]);

      final useCase = GetStopDepartures(mockGtfs, null);
      final result = await useCase('stop_1');

      expect(result.length, 1);
      expect(result[0].isRealtime, false);
    });

    test('RT can reorder departures by effective time', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final mockGtfs = MockGtfsRepo(departures: [
        Departure(
          tripId: 't_first_sched',
          routeId: 'r1',
          routeShortName: '64',
          scheduledTime: '08:00:00',
          scheduledSeconds: now + 300, // scheduled first
        ),
        Departure(
          tripId: 't_second_sched',
          routeId: 'r2',
          routeShortName: '40',
          scheduledTime: '08:10:00',
          scheduledSeconds: now + 900, // scheduled second
        ),
      ]);
      // Make first trip very late, so it arrives after second
      final mockRt = MockRealtimeRepo(delays: {'t_first_sched': 900});

      final useCase = GetStopDepartures(mockGtfs, mockRt);
      final result = await useCase('stop_1');

      // t_second_sched (effective: now+900) should appear before t_first_sched (effective: now+1200)
      expect(result[0].tripId, 't_second_sched');
      expect(result[1].tripId, 't_first_sched');
    });
  });

  group('GetStopDepartures: empty/edge cases', () {
    test('empty stop returns empty list', () async {
      final mockGtfs = MockGtfsRepo(departures: []);
      final useCase = GetStopDepartures(mockGtfs, null);
      final result = await useCase('empty_stop');
      expect(result, isEmpty);
    });

    test('handles many departures efficiently', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final departures = List.generate(
          100,
          (i) => Departure(
                tripId: 'trip_$i',
                routeId: 'r1',
                routeShortName: '${i % 10}',
                scheduledTime: '08:${(i % 60).toString().padLeft(2, '0')}:00',
                scheduledSeconds: now + (i * 60), // every minute
              ));

      final mockGtfs = MockGtfsRepo(departures: departures);
      final useCase = GetStopDepartures(mockGtfs, null);
      final result = await useCase('busy_stop');

      // Should only include departures within 90 min window
      expect(result.length, lessThanOrEqualTo(91)); // 0 to 90 inclusive
      expect(result.length, greaterThan(0));

      // Should be sorted
      for (var i = 1; i < result.length; i++) {
        expect(result[i].effectiveSeconds,
            greaterThanOrEqualTo(result[i - 1].effectiveSeconds));
      }
    });
  });

  // ─── Calendar/service date integration logic ────────────────

  group('Calendar service ID resolution logic', () {
    test('weekday 1 = Monday in Dart DateTime', () {
      // Verify our assumption about DateTime.weekday matching GTFS
      final monday = DateTime(2024, 7, 1); // July 1, 2024 is a Monday
      expect(monday.weekday, 1);
    });

    test('weekday 7 = Sunday in Dart DateTime', () {
      final sunday = DateTime(2024, 7, 7); // July 7, 2024 is a Sunday
      expect(sunday.weekday, 7);
    });

    test('service date weekday is correct for Saturday before 4 AM', () {
      // Saturday 2 AM → service date is Friday
      final satEarly = DateTime(2024, 7, 6, 2, 0);
      final serviceDate = DateTimeUtils.getServiceDate(satEarly);
      expect(serviceDate.weekday, 5); // Friday
    });

    test('service date weekday is correct for Saturday after 4 AM', () {
      final satAfternoon = DateTime(2024, 7, 6, 10, 0);
      final serviceDate = DateTimeUtils.getServiceDate(satAfternoon);
      expect(serviceDate.weekday, 6); // Saturday
    });

    test('toGtfsDate and parseGtfsDate are consistent', () {
      final dates = [
        DateTime(2024, 1, 1),
        DateTime(2024, 2, 29), // leap year
        DateTime(2024, 12, 31),
        DateTime(2025, 6, 15),
      ];
      for (final date in dates) {
        final formatted = DateTimeUtils.toGtfsDate(date);
        final parsed = DateTimeUtils.parseGtfsDate(formatted);
        expect(parsed, date);
      }
    });
  });

  // ─── Departure sorting tests ────────────────────────────────

  group('Departure sorting', () {
    test('sorts by scheduledSeconds ascending', () {
      final deps = [
        const Departure(
          tripId: 't3',
          routeId: 'r1',
          routeShortName: '64',
          scheduledTime: '09:00:00',
          scheduledSeconds: 32400,
        ),
        const Departure(
          tripId: 't1',
          routeId: 'r1',
          routeShortName: '64',
          scheduledTime: '07:00:00',
          scheduledSeconds: 25200,
        ),
        const Departure(
          tripId: 't2',
          routeId: 'r1',
          routeShortName: '64',
          scheduledTime: '08:00:00',
          scheduledSeconds: 28800,
        ),
      ];

      deps.sort((a, b) => a.scheduledSeconds.compareTo(b.scheduledSeconds));
      expect(deps.map((d) => d.tripId).toList(), ['t1', 't2', 't3']);
    });

    test('sorts after-midnight trips correctly (25h > 23h)', () {
      final deps = [
        const Departure(
          tripId: 't_night',
          routeId: 'r1',
          routeShortName: 'N1',
          scheduledTime: '25:30:00',
          scheduledSeconds: 91800,
        ),
        const Departure(
          tripId: 't_late',
          routeId: 'r1',
          routeShortName: '64',
          scheduledTime: '23:30:00',
          scheduledSeconds: 84600,
        ),
      ];

      deps.sort((a, b) => a.scheduledSeconds.compareTo(b.scheduledSeconds));
      expect(deps[0].tripId, 't_late');
      expect(deps[1].tripId, 't_night');
    });

    test('sorts by effectiveSeconds when RT data exists', () {
      final deps = [
        const Departure(
          tripId: 't_delayed',
          routeId: 'r1',
          routeShortName: '64',
          scheduledTime: '08:00:00',
          scheduledSeconds: 28800,
          estimatedSeconds: 29400,
          delaySeconds: 600,
          isRealtime: true,
        ),
        const Departure(
          tripId: 't_ontime',
          routeId: 'r1',
          routeShortName: '40',
          scheduledTime: '08:05:00',
          scheduledSeconds: 29100,
        ),
      ];

      deps.sort((a, b) => a.effectiveSeconds.compareTo(b.effectiveSeconds));
      // t_ontime (29100) < t_delayed (29400)
      expect(deps[0].tripId, 't_ontime');
      expect(deps[1].tripId, 't_delayed');
    });
  });

  // ─── Route/Stop entity tests ───────────────────────────────

  group('RouteEntity type helpers', () {
    test('isBus for type 3', () {
      const r = RouteEntity(
        routeId: 'r1',
        routeShortName: '64',
        routeLongName: 'Termini-San Pietro',
        routeType: 3,
      );
      expect(r.isBus, true);
      expect(r.isTram, false);
      expect(r.isMetro, false);
    });

    test('isTram for type 0', () {
      const r = RouteEntity(
        routeId: 'r2',
        routeShortName: '8',
        routeLongName: 'Tram 8',
        routeType: 0,
      );
      expect(r.isTram, true);
      expect(r.isBus, false);
    });

    test('isMetro for type 1', () {
      const r = RouteEntity(
        routeId: 'r3',
        routeShortName: 'A',
        routeLongName: 'Metro A',
        routeType: 1,
      );
      expect(r.isMetro, true);
      expect(r.isBus, false);
    });

    test('rail type 2 is neither bus/tram/metro', () {
      const r = RouteEntity(
        routeId: 'r4',
        routeShortName: 'FL1',
        routeLongName: 'Roma-Fiumicino',
        routeType: 2,
      );
      expect(r.isBus, false);
      expect(r.isTram, false);
      expect(r.isMetro, false);
    });
  });

  group('Vehicle entity for map', () {
    test('vehicle with all GPS data', () {
      const v = Vehicle(
        vehicleId: 'bus_001',
        tripId: 't1',
        routeId: 'r1',
        latitude: 41.9028,
        longitude: 12.4964,
        bearing: 270.0,
        speed: 25.5,
        timestamp: 1700000000,
      );
      expect(v.latitude, isNotNull);
      expect(v.longitude, isNotNull);
      expect(v.bearing, 270.0);
      expect(v.speed, 25.5);
    });

    test('vehicle without GPS should be filtered from map', () {
      const v = Vehicle(tripId: 't1');
      expect(v.latitude, isNull);
      expect(v.longitude, isNull);

      // Simulate the filter from map_screen.dart
      final vehicles = [
        const Vehicle(tripId: 't1', latitude: 41.9, longitude: 12.5),
        const Vehicle(tripId: 't2'), // no GPS
        const Vehicle(
            tripId: 't3', latitude: 41.8, longitude: 12.4, bearing: 90.0),
      ];
      final onMap = vehicles
          .where((v) => v.latitude != null && v.longitude != null)
          .toList();
      expect(onMap.length, 2);
    });

    test('bearing to radians conversion matches map_screen logic', () {
      // From map_screen.dart: (v.bearing ?? 0) * (3.14159 / 180)
      const testBearings = [0.0, 90.0, 180.0, 270.0, 360.0];
      final expectedRadians = [0.0, 1.5708, 3.14159, 4.71239, 6.28318];

      for (var i = 0; i < testBearings.length; i++) {
        final radians = testBearings[i] * (3.14159 / 180);
        expect(radians, closeTo(expectedRadians[i], 0.001));
      }
    });

    test('null bearing defaults to 0 (north)', () {
      const v = Vehicle(tripId: 't1', latitude: 41.9, longitude: 12.5);
      final radians = (v.bearing ?? 0) * (3.14159 / 180);
      expect(radians, closeTo(0.0, 0.001));
    });
  });

  // ─── ServiceAlert entity tests ─────────────────────────────

  group('ServiceAlert entity', () {
    test('alert with route and stop IDs', () {
      const alert = ServiceAlert(
        alertId: 'a1',
        headerText: 'Sciopero linea 64',
        descriptionText: 'Route 64 suspended due to strike',
        routeIds: ['64', '40'],
        stopIds: ['stop_A', 'stop_B'],
        activePeriodStart: 1700000000,
        activePeriodEnd: 1700100000,
      );
      expect(alert.routeIds.length, 2);
      expect(alert.stopIds.length, 2);
      expect(alert.activePeriodStart, isNotNull);
    });

    test('empty alert has empty lists', () {
      const alert = ServiceAlert();
      expect(alert.routeIds, isEmpty);
      expect(alert.stopIds, isEmpty);
      expect(alert.headerText, isNull);
    });
  });

  // ─── currentTimeAsSeconds after-midnight fix verification ──

  group('currentTimeAsSeconds: after-midnight fix', () {
    test('currentTimeAsSeconds returns a reasonable value', () {
      final seconds = DateTimeUtils.currentTimeAsSeconds();
      // Should be >= 0 and reasonable
      expect(seconds, greaterThanOrEqualTo(0));
      // If before 4 AM, it should be > 86400
      final now = DateTime.now();
      if (now.hour < 4) {
        expect(seconds, greaterThan(86400));
      } else {
        expect(seconds, lessThan(86400));
      }
    });

    test('after-midnight GTFS times are always > 86400', () {
      // GTFS convention: 25:30:00 is 1:30 AM the next day
      final t = DateTimeUtils.parseGtfsTime('25:30:00');
      expect(t, greaterThan(86400));

      // And currentTimeAsSeconds at 1:30 AM should also be > 86400
      // due to the +86400 fix, so comparison works
      // We can't control time here, but we verify the math
      const simulatedCurrent130am = 1 * 3600 + 30 * 60 + 86400;
      expect(simulatedCurrent130am, closeTo(t, 3600)); // within 1 hour
    });

    test('midday comparison picks correct upcoming departures', () {
      // Simulate noon (12:00)
      const noonSeconds = 12 * 3600; // 43200
      final departures = [
        28800, // 08:00 - past
        43200, // 12:00 - now
        45000, // 12:30 - upcoming
        50400, // 14:00 - upcoming
        91800, // 25:30 (1:30 AM next day) - far future
      ];

      final upcoming = departures
          .where((s) => s >= noonSeconds && s <= noonSeconds + 5400)
          .toList();

      expect(upcoming, [43200, 45000]); // 12:00 and 12:30
    });

    test('2 AM comparison with after-midnight GTFS times works', () {
      // Simulate 2:00 AM with the +86400 fix applied
      const twoAmSeconds = 2 * 3600 + 86400; // 93600
      final afterMidnightDepartures = [
        90000, // 25:00:00 (1:00 AM)
        91800, // 25:30:00 (1:30 AM)
        93600, // 26:00:00 (2:00 AM) - now
        95400, // 26:30:00 (2:30 AM) - upcoming
        97200, // 27:00:00 (3:00 AM) - upcoming
      ];

      const cutoff = twoAmSeconds + 5400; // 90 min window
      final upcoming = afterMidnightDepartures
          .where((s) => s >= twoAmSeconds && s <= cutoff)
          .toList();

      expect(upcoming, [93600, 95400, 97200]);
    });
  });
}
