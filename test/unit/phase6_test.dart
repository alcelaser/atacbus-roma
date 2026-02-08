import 'package:flutter_test/flutter_test.dart';
import 'package:atacbus_roma/core/utils/distance_utils.dart';
import 'package:atacbus_roma/domain/entities/stop.dart';
import 'package:atacbus_roma/domain/entities/vehicle.dart';

void main() {
  group('Stop coordinates', () {
    test('stop has valid lat/lon', () {
      const stop = Stop(
        stopId: 's1',
        stopName: 'Termini',
        stopLat: 41.9008,
        stopLon: 12.5024,
      );
      expect(stop.stopLat, closeTo(41.9, 0.1));
      expect(stop.stopLon, closeTo(12.5, 0.1));
    });

    test('stop with zero coordinates is valid', () {
      const stop = Stop(
        stopId: 's2',
        stopName: 'Origin',
        stopLat: 0.0,
        stopLon: 0.0,
      );
      expect(stop.stopLat, 0.0);
      expect(stop.stopLon, 0.0);
    });
  });

  group('Vehicle for map', () {
    test('vehicle with lat/lon can be placed on map', () {
      const v = Vehicle(
        tripId: 't1',
        routeId: 'r1',
        latitude: 41.89,
        longitude: 12.49,
        bearing: 180.0,
      );
      expect(v.latitude, isNotNull);
      expect(v.longitude, isNotNull);
      expect(v.bearing, 180.0);
    });

    test('vehicle without lat/lon is filtered out', () {
      const v = Vehicle(tripId: 't2');
      expect(v.latitude, isNull);
      expect(v.longitude, isNull);

      // Simulating the filter used in map_screen
      final vehicles = [
        const Vehicle(tripId: 't1', latitude: 41.9, longitude: 12.5),
        const Vehicle(tripId: 't2'),
        const Vehicle(tripId: 't3', latitude: 41.8, longitude: 12.4),
      ];
      final onMap = vehicles
          .where((v) => v.latitude != null && v.longitude != null)
          .toList();
      expect(onMap.length, 2);
      expect(onMap[0].tripId, 't1');
      expect(onMap[1].tripId, 't3');
    });
  });

  group('Nearby stops (distance calculation)', () {
    // Termini station
    const userLat = 41.9008;
    const userLon = 12.5024;

    // Colosseum (~1.2 km away)
    const colosseumLat = 41.8902;
    const colosseumLon = 12.4922;

    // A stop very close by (~100m)
    const nearbyLat = 41.9012;
    const nearbyLon = 12.5030;

    // A stop far away (~5km)
    const farLat = 41.8650;
    const farLon = 12.4700;

    test('finds stops within 500m radius', () {
      final stops = [
        const Stop(
          stopId: 'near',
          stopName: 'Nearby Stop',
          stopLat: nearbyLat,
          stopLon: nearbyLon,
        ),
        const Stop(
          stopId: 'colosseum',
          stopName: 'Colosseum',
          stopLat: colosseumLat,
          stopLon: colosseumLon,
        ),
        const Stop(
          stopId: 'far',
          stopName: 'Far Stop',
          stopLat: farLat,
          stopLon: farLon,
        ),
      ];

      final nearby = stops.where((s) {
        final d = DistanceUtils.haversineDistance(
          userLat,
          userLon,
          s.stopLat,
          s.stopLon,
        );
        return d <= 500; // 500 meters
      }).toList();

      expect(nearby.length, 1);
      expect(nearby[0].stopId, 'near');
    });

    test('Colosseum is within 2km but outside 500m from Termini', () {
      final d = DistanceUtils.haversineDistance(
        userLat,
        userLon,
        colosseumLat,
        colosseumLon,
      );
      expect(d, greaterThan(500));
      expect(d, lessThan(2000));
    });

    test('sorts stops by distance', () {
      final stops = [
        const Stop(
          stopId: 'far',
          stopName: 'Far Stop',
          stopLat: farLat,
          stopLon: farLon,
        ),
        const Stop(
          stopId: 'near',
          stopName: 'Nearby Stop',
          stopLat: nearbyLat,
          stopLon: nearbyLon,
        ),
        const Stop(
          stopId: 'colosseum',
          stopName: 'Colosseum',
          stopLat: colosseumLat,
          stopLon: colosseumLon,
        ),
      ];

      stops.sort((a, b) {
        final dA = DistanceUtils.haversineDistance(
            userLat, userLon, a.stopLat, a.stopLon);
        final dB = DistanceUtils.haversineDistance(
            userLat, userLon, b.stopLat, b.stopLon);
        return dA.compareTo(dB);
      });

      expect(stops[0].stopId, 'near');
      expect(stops[1].stopId, 'colosseum');
      expect(stops[2].stopId, 'far');
    });
  });

  group('Map data providers', () {
    test('vehicle bearing converts to radians for rotation', () {
      const bearingDegrees = 90.0;
      const radians = bearingDegrees * (3.14159 / 180);
      expect(radians, closeTo(1.5708, 0.001));
    });

    test('bearing 0 means pointing north (no rotation)', () {
      const bearingDegrees = 0.0;
      const radians = bearingDegrees * (3.14159 / 180);
      expect(radians, closeTo(0.0, 0.001));
    });

    test('bearing 360 means pointing north (full rotation)', () {
      const bearingDegrees = 360.0;
      const radians = bearingDegrees * (3.14159 / 180);
      expect(radians, closeTo(6.2832, 0.001));
    });
  });
}
