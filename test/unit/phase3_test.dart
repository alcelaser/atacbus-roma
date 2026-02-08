import 'package:flutter_test/flutter_test.dart';
import 'package:atacbus_roma/domain/entities/stop.dart';
import 'package:atacbus_roma/domain/entities/route_entity.dart';
import 'package:atacbus_roma/domain/entities/departure.dart';
import 'package:atacbus_roma/domain/usecases/search_stops.dart';
import 'package:atacbus_roma/domain/usecases/toggle_favorite.dart';
import 'package:atacbus_roma/domain/repositories/gtfs_repository.dart';

// Simple mock repository for testing use cases
class MockGtfsRepository implements GtfsRepository {
  final List<Stop> stops;
  final List<Departure> departures;
  final Set<String> favorites;

  MockGtfsRepository({
    this.stops = const [],
    this.departures = const [],
    Set<String>? favorites,
  }) : favorites = favorites ?? {};

  @override
  Future<List<Stop>> searchStops(String query) async {
    return stops
        .where((s) =>
            s.stopName.toLowerCase().contains(query.toLowerCase()) ||
            (s.stopCode?.toLowerCase().contains(query.toLowerCase()) ?? false))
        .toList();
  }

  @override
  Future<Stop?> getStopById(String stopId) async {
    try {
      return stops.firstWhere((s) => s.stopId == stopId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Stop>> getAllStops() async => stops;

  @override
  Future<List<RouteEntity>> getAllRoutes() async => [];

  @override
  Future<List<RouteEntity>> getRoutesByType(int type) async => [];

  @override
  Future<RouteEntity?> getRouteById(String routeId) async => null;

  @override
  Future<List<Departure>> getScheduledDepartures(String stopId) async =>
      departures;

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
  Future<List<RouteEntity>> getRoutesForStop(String stopId) async => [];

  @override
  Future<bool> isFavorite(String stopId) async => favorites.contains(stopId);

  @override
  Future<void> addFavorite(String stopId) async {
    favorites.add(stopId);
  }

  @override
  Future<void> removeFavorite(String stopId) async {
    favorites.remove(stopId);
  }

  @override
  Future<List<String>> getFavoriteStopIds() async => favorites.toList();

  @override
  Stream<List<String>> watchFavoriteStopIds() =>
      Stream.value(favorites.toList());
}

void main() {
  group('SearchStops use case', () {
    final testStops = [
      const Stop(
          stopId: '1',
          stopName: 'Termini',
          stopCode: 'TRM',
          stopLat: 41.9,
          stopLon: 12.5),
      const Stop(
          stopId: '2',
          stopName: 'Colosseo',
          stopCode: 'COL',
          stopLat: 41.89,
          stopLon: 12.49),
      const Stop(
          stopId: '3',
          stopName: 'Piazza Venezia',
          stopLat: 41.895,
          stopLon: 12.48),
    ];

    test('returns matching stops by name', () async {
      final repo = MockGtfsRepository(stops: testStops);
      final searchStops = SearchStops(repo);
      final results = await searchStops('Termi');
      expect(results.length, 1);
      expect(results.first.stopName, 'Termini');
    });

    test('returns matching stops by code', () async {
      final repo = MockGtfsRepository(stops: testStops);
      final searchStops = SearchStops(repo);
      final results = await searchStops('COL');
      expect(results.length, 1);
      expect(results.first.stopName, 'Colosseo');
    });

    test('returns empty list for empty query', () async {
      final repo = MockGtfsRepository(stops: testStops);
      final searchStops = SearchStops(repo);
      final results = await searchStops('');
      expect(results, isEmpty);
    });

    test('returns empty list for whitespace query', () async {
      final repo = MockGtfsRepository(stops: testStops);
      final searchStops = SearchStops(repo);
      final results = await searchStops('   ');
      expect(results, isEmpty);
    });

    test('returns empty list for no matches', () async {
      final repo = MockGtfsRepository(stops: testStops);
      final searchStops = SearchStops(repo);
      final results = await searchStops('nonexistent');
      expect(results, isEmpty);
    });
  });

  group('ToggleFavorite use case', () {
    test('adds favorite when not favorited', () async {
      final repo = MockGtfsRepository();
      final toggle = ToggleFavorite(repo);
      final result = await toggle('stop1');
      expect(result, true);
      expect(repo.favorites.contains('stop1'), true);
    });

    test('removes favorite when already favorited', () async {
      final repo = MockGtfsRepository(favorites: {'stop1'});
      final toggle = ToggleFavorite(repo);
      final result = await toggle('stop1');
      expect(result, false);
      expect(repo.favorites.contains('stop1'), false);
    });

    test('re-adds favorite after removal', () async {
      final repo = MockGtfsRepository(favorites: {'stop1'});
      final toggle = ToggleFavorite(repo);
      await toggle('stop1'); // remove
      final result = await toggle('stop1'); // re-add
      expect(result, true);
      expect(repo.favorites.contains('stop1'), true);
    });
  });

  group('Departure entity', () {
    test('effectiveSeconds returns estimated when available', () {
      const dep = Departure(
        tripId: 'T1',
        routeId: 'R1',
        routeShortName: '64',
        scheduledTime: '08:30:00',
        scheduledSeconds: 30600,
        estimatedSeconds: 30900,
        delaySeconds: 300,
        isRealtime: true,
      );
      expect(dep.effectiveSeconds, 30900);
    });

    test('effectiveSeconds falls back to scheduled', () {
      const dep = Departure(
        tripId: 'T1',
        routeId: 'R1',
        routeShortName: '64',
        scheduledTime: '08:30:00',
        scheduledSeconds: 30600,
      );
      expect(dep.effectiveSeconds, 30600);
    });
  });

  group('RouteEntity', () {
    test('isBus returns true for type 3', () {
      const route = RouteEntity(
        routeId: 'R1',
        routeShortName: '64',
        routeLongName: 'Test',
        routeType: 3,
      );
      expect(route.isBus, true);
      expect(route.isTram, false);
      expect(route.isMetro, false);
    });

    test('isTram returns true for type 0', () {
      const route = RouteEntity(
        routeId: 'R2',
        routeShortName: '3',
        routeLongName: 'Tram 3',
        routeType: 0,
      );
      expect(route.isTram, true);
      expect(route.isBus, false);
    });

    test('isMetro returns true for type 1', () {
      const route = RouteEntity(
        routeId: 'R3',
        routeShortName: 'A',
        routeLongName: 'Metro A',
        routeType: 1,
      );
      expect(route.isMetro, true);
      expect(route.isBus, false);
    });
  });
}
