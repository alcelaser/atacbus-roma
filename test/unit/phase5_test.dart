import 'package:flutter_test/flutter_test.dart';
import 'package:atacbus_roma/domain/entities/route_entity.dart';
import 'package:atacbus_roma/domain/entities/stop.dart';
import 'package:atacbus_roma/domain/usecases/get_route_details.dart';
import 'package:atacbus_roma/domain/usecases/get_routes_for_stop.dart';
import 'package:atacbus_roma/domain/entities/departure.dart';
import 'package:atacbus_roma/domain/repositories/gtfs_repository.dart';

// Mock GtfsRepository for route tests
class MockGtfsRepositoryForRoutes implements GtfsRepository {
  final List<RouteEntity> routes;
  final Map<String, List<Stop>> routeStops;
  final Map<String, List<RouteEntity>> stopRoutes;

  MockGtfsRepositoryForRoutes({
    this.routes = const [],
    this.routeStops = const {},
    this.stopRoutes = const {},
  });

  @override
  Future<List<RouteEntity>> getAllRoutes() async => routes;
  @override
  Future<List<RouteEntity>> getRoutesByType(int type) async =>
      routes.where((r) => r.routeType == type).toList();
  @override
  Future<RouteEntity?> getRouteById(String routeId) async =>
      routes.where((r) => r.routeId == routeId).firstOrNull;
  @override
  Future<List<Stop>> getStopsForRoute(String routeId) async =>
      routeStops[routeId] ?? [];
  @override
  Future<List<RouteEntity>> getRoutesForStop(String stopId) async =>
      stopRoutes[stopId] ?? [];

  @override
  Future<List<Stop>> searchStops(String query) async => [];
  @override
  Future<Stop?> getStopById(String stopId) async => null;
  @override
  Future<List<Stop>> getAllStops() async => [];
  @override
  Future<List<Departure>> getScheduledDepartures(String stopId) async => [];
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
  // Test data
  const busRoute64 = RouteEntity(
    routeId: 'route_64',
    routeShortName: '64',
    routeLongName: 'Termini - San Pietro',
    routeType: 3,
    routeColor: 'FF0000',
  );
  const busRoute40 = RouteEntity(
    routeId: 'route_40',
    routeShortName: '40',
    routeLongName: 'Termini - Castel Sant\'Angelo',
    routeType: 3,
    routeColor: '0000FF',
  );
  const tramRoute8 = RouteEntity(
    routeId: 'route_8',
    routeShortName: '8',
    routeLongName: 'Casaletto - Piazza Venezia',
    routeType: 0,
    routeColor: '00FF00',
  );
  const metroA = RouteEntity(
    routeId: 'route_MA',
    routeShortName: 'MA',
    routeLongName: 'Metro A: Battistini - Anagnina',
    routeType: 1,
    routeColor: 'FF6600',
  );

  const stop1 = Stop(
    stopId: 's1',
    stopName: 'Termini',
    stopLat: 41.9,
    stopLon: 12.5,
    stopCode: '70015',
  );
  const stop2 = Stop(
    stopId: 's2',
    stopName: 'Piazza Venezia',
    stopLat: 41.89,
    stopLon: 12.48,
  );
  const stop3 = Stop(
    stopId: 's3',
    stopName: 'San Pietro',
    stopLat: 41.88,
    stopLon: 12.45,
  );

  group('RouteEntity type filtering', () {
    test('getRoutesByType returns only buses', () async {
      final repo = MockGtfsRepositoryForRoutes(
        routes: [busRoute64, busRoute40, tramRoute8, metroA],
      );
      final busRoutes = await repo.getRoutesByType(3);
      expect(busRoutes.length, 2);
      expect(busRoutes.every((r) => r.isBus), true);
    });

    test('getRoutesByType returns only trams', () async {
      final repo = MockGtfsRepositoryForRoutes(
        routes: [busRoute64, tramRoute8, metroA],
      );
      final trams = await repo.getRoutesByType(0);
      expect(trams.length, 1);
      expect(trams[0].isTram, true);
      expect(trams[0].routeShortName, '8');
    });

    test('getRoutesByType returns only metro', () async {
      final repo = MockGtfsRepositoryForRoutes(
        routes: [busRoute64, tramRoute8, metroA],
      );
      final metros = await repo.getRoutesByType(1);
      expect(metros.length, 1);
      expect(metros[0].isMetro, true);
    });

    test('getRoutesByType returns empty for missing type', () async {
      final repo = MockGtfsRepositoryForRoutes(
        routes: [busRoute64],
      );
      final ferries = await repo.getRoutesByType(4);
      expect(ferries, isEmpty);
    });
  });

  group('GetRouteDetails', () {
    test('returns route and stops', () async {
      final repo = MockGtfsRepositoryForRoutes(
        routes: [busRoute64],
        routeStops: {
          'route_64': [stop1, stop2, stop3],
        },
      );
      final useCase = GetRouteDetails(repo);

      final route = await useCase.getRoute('route_64');
      expect(route, isNotNull);
      expect(route!.routeShortName, '64');

      final stops = await useCase.getStopsForRoute('route_64');
      expect(stops.length, 3);
      expect(stops[0].stopName, 'Termini');
      expect(stops[2].stopName, 'San Pietro');
    });

    test('returns null for non-existent route', () async {
      final repo = MockGtfsRepositoryForRoutes(routes: []);
      final useCase = GetRouteDetails(repo);

      final route = await useCase.getRoute('nonexistent');
      expect(route, isNull);
    });

    test('returns empty stops for route without stops', () async {
      final repo = MockGtfsRepositoryForRoutes(
        routes: [busRoute64],
        routeStops: {},
      );
      final useCase = GetRouteDetails(repo);

      final stops = await useCase.getStopsForRoute('route_64');
      expect(stops, isEmpty);
    });
  });

  group('GetRoutesForStop', () {
    test('returns routes serving a stop', () async {
      final repo = MockGtfsRepositoryForRoutes(
        stopRoutes: {
          's1': [busRoute64, busRoute40],
        },
      );
      final useCase = GetRoutesForStop(repo);

      final routes = await useCase('s1');
      expect(routes.length, 2);
      expect(routes.map((r) => r.routeShortName).toList(), ['64', '40']);
    });

    test('returns empty for stop with no routes', () async {
      final repo = MockGtfsRepositoryForRoutes(stopRoutes: {});
      final useCase = GetRoutesForStop(repo);

      final routes = await useCase('unknown_stop');
      expect(routes, isEmpty);
    });
  });

  group('RouteEntity properties', () {
    test('routeColor and routeTextColor are optional', () {
      const route = RouteEntity(
        routeId: 'r1',
        routeShortName: '100',
        routeLongName: 'Test Route',
        routeType: 3,
      );
      expect(route.routeColor, isNull);
      expect(route.routeTextColor, isNull);
      expect(route.agencyId, isNull);
    });

    test('routeLongName can be empty', () {
      const route = RouteEntity(
        routeId: 'r2',
        routeShortName: '200',
        routeLongName: '',
        routeType: 3,
      );
      expect(route.routeLongName.isEmpty, true);
    });

    test('all route type flags', () {
      expect(busRoute64.isBus, true);
      expect(busRoute64.isTram, false);
      expect(busRoute64.isMetro, false);

      expect(tramRoute8.isTram, true);
      expect(tramRoute8.isBus, false);

      expect(metroA.isMetro, true);
      expect(metroA.isBus, false);
    });
  });

  group('Stop entity', () {
    test('stopCode is optional', () {
      expect(stop1.stopCode, '70015');
      expect(stop2.stopCode, isNull);
    });
  });
}
