import 'package:flutter_test/flutter_test.dart';
import 'package:atacbus_roma/data/models/realtime/trip_update_model.dart';
import 'package:atacbus_roma/data/models/realtime/vehicle_position_model.dart';
import 'package:atacbus_roma/data/models/realtime/service_alert_model.dart';
import 'package:atacbus_roma/domain/entities/departure.dart';
import 'package:atacbus_roma/domain/entities/vehicle.dart';
import 'package:atacbus_roma/domain/entities/service_alert.dart';
import 'package:atacbus_roma/domain/entities/stop.dart';
import 'package:atacbus_roma/domain/entities/route_entity.dart';
import 'package:atacbus_roma/domain/repositories/gtfs_repository.dart';
import 'package:atacbus_roma/domain/repositories/realtime_repository.dart';
import 'package:atacbus_roma/domain/usecases/get_stop_departures.dart';
import 'package:atacbus_roma/core/utils/date_time_utils.dart';

// Mock RealtimeRepository
class MockRealtimeRepository implements RealtimeRepository {
  Map<String, int> delays;
  List<Vehicle> vehicles;
  List<ServiceAlert> alerts;
  bool shouldThrow;

  MockRealtimeRepository({
    this.delays = const {},
    this.vehicles = const [],
    this.alerts = const [],
    this.shouldThrow = false,
  });

  @override
  Future<Map<String, int>> getTripDelays() async {
    if (shouldThrow) throw Exception('Network error');
    return delays;
  }

  @override
  Future<List<Vehicle>> getVehiclePositions() async {
    if (shouldThrow) throw Exception('Network error');
    return vehicles;
  }

  @override
  Future<List<ServiceAlert>> getServiceAlerts() async {
    if (shouldThrow) throw Exception('Network error');
    return alerts;
  }
}

// Mock GtfsRepository for departure testing
class MockGtfsRepositoryForRT implements GtfsRepository {
  List<Departure> departures;

  MockGtfsRepositoryForRT({this.departures = const []});

  @override
  Future<List<Departure>> getScheduledDepartures(String stopId) async {
    return departures;
  }

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
  Future<List<Stop>> getStopsForRoute(String routeId,
          {int? directionId}) async =>
      [];
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
  group('TripUpdateModel', () {
    test('creates with all fields', () {
      const model = TripUpdateModel(
        tripId: 'trip_123',
        routeId: 'route_A',
        delay: 120,
      );
      expect(model.tripId, 'trip_123');
      expect(model.routeId, 'route_A');
      expect(model.delay, 120);
    });

    test('creates with null optional fields', () {
      const model = TripUpdateModel(tripId: 'trip_456');
      expect(model.tripId, 'trip_456');
      expect(model.routeId, isNull);
      expect(model.delay, isNull);
    });
  });

  group('VehiclePositionModel', () {
    test('creates with all fields', () {
      const model = VehiclePositionModel(
        vehicleId: 'veh_001',
        tripId: 'trip_789',
        routeId: 'route_B',
        latitude: 41.9028,
        longitude: 12.4964,
        bearing: 180.0,
        speed: 30.5,
        timestamp: 1700000000,
      );
      expect(model.vehicleId, 'veh_001');
      expect(model.tripId, 'trip_789');
      expect(model.latitude, 41.9028);
      expect(model.longitude, 12.4964);
      expect(model.bearing, 180.0);
      expect(model.speed, 30.5);
      expect(model.timestamp, 1700000000);
    });

    test('creates with minimal fields', () {
      const model = VehiclePositionModel(tripId: 'trip_min');
      expect(model.tripId, 'trip_min');
      expect(model.vehicleId, isNull);
      expect(model.latitude, isNull);
      expect(model.longitude, isNull);
    });
  });

  group('ServiceAlertModel', () {
    test('creates with all fields', () {
      const model = ServiceAlertModel(
        alertId: 'alert_1',
        headerText: 'Route 64 Disruption',
        descriptionText: 'Route 64 is diverted due to roadworks.',
        url: 'https://example.com/alert',
        routeIds: ['64', '40'],
        stopIds: ['stop_A'],
        activePeriodStart: 1700000000,
        activePeriodEnd: 1700100000,
      );
      expect(model.alertId, 'alert_1');
      expect(model.headerText, 'Route 64 Disruption');
      expect(model.routeIds, ['64', '40']);
      expect(model.stopIds, ['stop_A']);
    });

    test('defaults to empty lists', () {
      const model = ServiceAlertModel();
      expect(model.routeIds, isEmpty);
      expect(model.stopIds, isEmpty);
      expect(model.alertId, isNull);
    });
  });

  group('Vehicle entity', () {
    test('creates with all fields', () {
      const v = Vehicle(
        vehicleId: 'v1',
        tripId: 't1',
        routeId: 'r1',
        latitude: 41.89,
        longitude: 12.49,
        bearing: 90.0,
        speed: 20.0,
        timestamp: 1700000000,
      );
      expect(v.vehicleId, 'v1');
      expect(v.tripId, 't1');
      expect(v.routeId, 'r1');
    });
  });

  group('ServiceAlert entity', () {
    test('creates with all fields', () {
      const a = ServiceAlert(
        alertId: 'a1',
        headerText: 'Test Alert',
        descriptionText: 'Description',
        routeIds: ['64'],
        stopIds: ['s1', 's2'],
      );
      expect(a.alertId, 'a1');
      expect(a.routeIds, ['64']);
      expect(a.stopIds.length, 2);
    });
  });

  group('GetStopDepartures with RT', () {
    test('merges RT delays into scheduled departures', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final mockGtfs = MockGtfsRepositoryForRT(
        departures: [
          Departure(
            tripId: 'trip_A',
            routeId: 'route_1',
            routeShortName: '64',
            scheduledTime: '08:00:00',
            scheduledSeconds: now + 600, // 10 min from now
          ),
          Departure(
            tripId: 'trip_B',
            routeId: 'route_1',
            routeShortName: '64',
            scheduledTime: '08:15:00',
            scheduledSeconds: now + 1500, // 25 min from now
          ),
        ],
      );
      final mockRt = MockRealtimeRepository(
        delays: {'trip_A': 120}, // 2 min late
      );

      final useCase = GetStopDepartures(mockGtfs, mockRt);
      final result = await useCase('stop_123');

      expect(result.length, 2);

      // trip_A should have RT data
      final tripA = result.firstWhere((d) => d.tripId == 'trip_A');
      expect(tripA.isRealtime, true);
      expect(tripA.delaySeconds, 120);
      expect(tripA.estimatedSeconds, now + 600 + 120);

      // trip_B has no RT data
      final tripB = result.firstWhere((d) => d.tripId == 'trip_B');
      expect(tripB.isRealtime, false);
      expect(tripB.estimatedSeconds, isNull);
    });

    test('falls back to scheduled when RT fails', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final mockGtfs = MockGtfsRepositoryForRT(
        departures: [
          Departure(
            tripId: 'trip_C',
            routeId: 'route_2',
            routeShortName: '40',
            scheduledTime: '09:00:00',
            scheduledSeconds: now + 300,
          ),
        ],
      );
      final mockRt = MockRealtimeRepository(shouldThrow: true);

      final useCase = GetStopDepartures(mockGtfs, mockRt);
      final result = await useCase('stop_456');

      expect(result.length, 1);
      expect(result[0].isRealtime, false);
      expect(result[0].estimatedSeconds, isNull);
    });

    test('works without RT repository (offline)', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final mockGtfs = MockGtfsRepositoryForRT(
        departures: [
          Departure(
            tripId: 'trip_D',
            routeId: 'route_3',
            routeShortName: '170',
            scheduledTime: '10:00:00',
            scheduledSeconds: now + 1800,
          ),
        ],
      );

      final useCase = GetStopDepartures(mockGtfs, null);
      final result = await useCase('stop_789');

      expect(result.length, 1);
      expect(result[0].isRealtime, false);
    });

    test('sorts by effectiveSeconds after RT merge', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final mockGtfs = MockGtfsRepositoryForRT(
        departures: [
          Departure(
            tripId: 'trip_early',
            routeId: 'route_1',
            routeShortName: '64',
            scheduledTime: '08:00:00',
            scheduledSeconds: now + 300, // originally first
          ),
          Departure(
            tripId: 'trip_late',
            routeId: 'route_2',
            routeShortName: '40',
            scheduledTime: '08:05:00',
            scheduledSeconds: now + 600, // originally second
          ),
        ],
      );
      // Make trip_early very late, so it should sort after trip_late
      final mockRt = MockRealtimeRepository(
        delays: {'trip_early': 600}, // 10 min late
      );

      final useCase = GetStopDepartures(mockGtfs, mockRt);
      final result = await useCase('stop_sort');

      expect(result.length, 2);
      // trip_late (effective: now+600) should be before trip_early (effective: now+900)
      expect(result[0].tripId, 'trip_late');
      expect(result[1].tripId, 'trip_early');
    });

    test('filters out departures outside 90-minute window', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final mockGtfs = MockGtfsRepositoryForRT(
        departures: [
          Departure(
            tripId: 'trip_soon',
            routeId: 'r1',
            routeShortName: '64',
            scheduledTime: '08:00:00',
            scheduledSeconds: now + 600,
          ),
          Departure(
            tripId: 'trip_far',
            routeId: 'r1',
            routeShortName: '64',
            scheduledTime: '10:00:00',
            scheduledSeconds: now + 7200, // 2 hours away = outside 90 min
          ),
          Departure(
            tripId: 'trip_past',
            routeId: 'r1',
            routeShortName: '64',
            scheduledTime: '07:00:00',
            scheduledSeconds: now - 600, // in the past
          ),
        ],
      );

      final useCase = GetStopDepartures(mockGtfs, null);
      final result = await useCase('stop_window');

      expect(result.length, 1);
      expect(result[0].tripId, 'trip_soon');
    });

    test('handles negative delay (early bus)', () async {
      final now = DateTimeUtils.currentTimeAsSeconds();
      final mockGtfs = MockGtfsRepositoryForRT(
        departures: [
          Departure(
            tripId: 'trip_early_bus',
            routeId: 'r1',
            routeShortName: '100',
            scheduledTime: '08:30:00',
            scheduledSeconds: now + 900,
          ),
        ],
      );
      final mockRt = MockRealtimeRepository(
        delays: {'trip_early_bus': -60}, // 1 min early
      );

      final useCase = GetStopDepartures(mockGtfs, mockRt);
      final result = await useCase('stop_early');

      expect(result.length, 1);
      expect(result[0].isRealtime, true);
      expect(result[0].delaySeconds, -60);
      expect(result[0].estimatedSeconds, now + 900 - 60);
    });
  });

  group('Departure RT fields', () {
    test('effectiveSeconds uses estimated when available', () {
      const dep = Departure(
        tripId: 't1',
        routeId: 'r1',
        routeShortName: '64',
        scheduledTime: '08:00:00',
        scheduledSeconds: 28800,
        estimatedSeconds: 28920,
        delaySeconds: 120,
        isRealtime: true,
      );
      expect(dep.effectiveSeconds, 28920);
      expect(dep.isRealtime, true);
      expect(dep.delaySeconds, 120);
    });

    test('effectiveSeconds falls back to scheduled when no RT', () {
      const dep = Departure(
        tripId: 't2',
        routeId: 'r2',
        routeShortName: '40',
        scheduledTime: '09:00:00',
        scheduledSeconds: 32400,
      );
      expect(dep.effectiveSeconds, 32400);
      expect(dep.isRealtime, false);
      expect(dep.estimatedSeconds, isNull);
    });
  });

  group('MockRealtimeRepository', () {
    test('returns configured delays', () async {
      final repo = MockRealtimeRepository(
        delays: {'t1': 60, 't2': -30},
      );
      final delays = await repo.getTripDelays();
      expect(delays['t1'], 60);
      expect(delays['t2'], -30);
    });

    test('returns configured vehicles', () async {
      final repo = MockRealtimeRepository(
        vehicles: [
          const Vehicle(tripId: 't1', latitude: 41.9, longitude: 12.5),
        ],
      );
      final vehicles = await repo.getVehiclePositions();
      expect(vehicles.length, 1);
      expect(vehicles[0].tripId, 't1');
    });

    test('returns configured alerts', () async {
      final repo = MockRealtimeRepository(
        alerts: [
          const ServiceAlert(
            alertId: 'a1',
            headerText: 'Test',
            routeIds: ['64'],
          ),
        ],
      );
      final alerts = await repo.getServiceAlerts();
      expect(alerts.length, 1);
      expect(alerts[0].routeIds, ['64']);
    });

    test('throws when configured to', () async {
      final repo = MockRealtimeRepository(shouldThrow: true);
      expect(() => repo.getTripDelays(), throwsException);
      expect(() => repo.getVehiclePositions(), throwsException);
      expect(() => repo.getServiceAlerts(), throwsException);
    });
  });
}
