import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atacbus_roma/core/constants/app_constants.dart';
import 'package:atacbus_roma/core/theme/color_schemes.dart';
import 'package:atacbus_roma/domain/entities/trip_plan.dart';
import 'package:atacbus_roma/domain/entities/favorite_route.dart';
import 'package:atacbus_roma/domain/entities/stop_time_detail.dart';

void main() {
  // ─── Version ─────────────────────────────────────────────────
  test('version is 0.0.15', () {
    expect(AppConstants.appVersion, '0.0.15');
  });

  test('tripPlanNearbyRadiusMeters is 1000', () {
    expect(AppConstants.tripPlanNearbyRadiusMeters, 1000.0);
  });

  // ─── AMOLED theme ─────────────────────────────────────────────
  group('AMOLED dark theme', () {
    test('dark surface is true black', () {
      final dark = AppColorSchemes.darkColorScheme();
      expect(dark.surface, const Color(0xFF000000));
    });

    test('dark onSurface is pure white', () {
      final dark = AppColorSchemes.darkColorScheme();
      expect(dark.onSurface, const Color(0xFFFFFFFF));
    });

    test('dark primary is vibrant terracotta', () {
      final dark = AppColorSchemes.darkColorScheme();
      expect(dark.primary, const Color(0xFFFF6B5A));
    });

    test('dark surfaceVariant is subtle lift', () {
      final dark = AppColorSchemes.darkColorScheme();
      expect(dark.surfaceVariant, const Color(0xFF1A1A1A));
    });

    test('light theme surface is unchanged', () {
      final light = AppColorSchemes.lightColorScheme();
      // Light scheme should NOT be black
      expect(light.surface, isNot(const Color(0xFF000000)));
    });
  });

  // ─── TripPlanResult v2 (name-based) ────────────────────────────
  group('TripPlanResult v2', () {
    test('uses name-based fields', () {
      const result = TripPlanResult(
        originName: 'My Location',
        destinationName: 'Colosseo',
        itineraries: [],
      );
      expect(result.originName, 'My Location');
      expect(result.destinationName, 'Colosseo');
      expect(result.itineraries, isEmpty);
    });
  });

  // ─── FavoriteRouteEntity ───────────────────────────────────────
  group('FavoriteRouteEntity', () {
    test('construction', () {
      final entity = FavoriteRouteEntity(
        id: 1,
        originLat: 41.9,
        originLon: 12.5,
        originName: 'Via Cavour',
        destStopId: 'stop_123',
        destStopName: 'Colosseo',
        addedAt: DateTime(2025, 1, 1),
      );
      expect(entity.id, 1);
      expect(entity.originName, 'Via Cavour');
      expect(entity.destStopId, 'stop_123');
      expect(entity.destStopName, 'Colosseo');
      expect(entity.originLat, 41.9);
      expect(entity.originLon, 12.5);
    });
  });

  // ─── StopTimeDetail ────────────────────────────────────────────
  group('StopTimeDetail', () {
    test('construction', () {
      const detail = StopTimeDetail(
        stopId: 'stop_1',
        stopName: 'Termini',
        arrivalTime: '10:05:00',
        departureTime: '10:06:00',
        stopSequence: 3,
        stopLat: 41.9,
        stopLon: 12.5,
      );
      expect(detail.stopId, 'stop_1');
      expect(detail.stopName, 'Termini');
      expect(detail.arrivalTime, '10:05:00');
      expect(detail.departureTime, '10:06:00');
      expect(detail.stopSequence, 3);
    });
  });

  // ─── TripItinerary with transfer ──────────────────────────────
  group('TripItinerary transfer details', () {
    test('transfer wait time calculation', () {
      const leg1 = TripLeg(
        tripId: 'trip1',
        routeId: 'route1',
        routeShortName: '64',
        boardStopId: 'A',
        boardStopName: 'Origin',
        alightStopId: 'B',
        alightStopName: 'Transfer Stop',
        departureSeconds: 36000,
        arrivalSeconds: 36600,
        boardSequence: 1,
        alightSequence: 5,
      );
      const leg2 = TripLeg(
        tripId: 'trip2',
        routeId: 'route2',
        routeShortName: '40',
        boardStopId: 'B',
        boardStopName: 'Transfer Stop',
        alightStopId: 'C',
        alightStopName: 'Destination',
        departureSeconds: 36900,
        arrivalSeconds: 37500,
        boardSequence: 1,
        alightSequence: 4,
      );
      const itinerary = TripItinerary(legs: [leg1, leg2]);

      expect(itinerary.hasTransfer, true);
      expect(itinerary.transferStopName, 'Transfer Stop');
      // Wait time = leg2.dep - leg1.arr = 36900 - 36600 = 300s = 5 min
      final waitSeconds =
          itinerary.legs[1].departureSeconds - itinerary.legs[0].arrivalSeconds;
      expect(waitSeconds, 300);
    });
  });
}
