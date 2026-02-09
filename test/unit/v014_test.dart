import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:atacbus_roma/core/constants/app_constants.dart';
import 'package:atacbus_roma/core/constants/rome_landmarks.dart';
import 'package:atacbus_roma/core/theme/color_schemes.dart';
import 'package:atacbus_roma/domain/entities/search_result.dart';
import 'package:atacbus_roma/domain/entities/trip_plan.dart';
import 'package:atacbus_roma/domain/entities/favorite_route.dart';
import 'package:atacbus_roma/domain/entities/stop_time_detail.dart';

void main() {
  // ─── Version ─────────────────────────────────────────────────
  test('version is 0.0.17', () {
    expect(AppConstants.appVersion, '0.0.17');
  });

  test('walkingTransferMaxMeters is 700', () {
    expect(AppConstants.walkingTransferMaxMeters, 700.0);
  });

  test('walkingSpeedMps is 1.2', () {
    expect(AppConstants.walkingSpeedMps, 1.2);
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

  // ─── Walking transfer ───────────────────────────────────────────
  group('Walking transfer', () {
    test('TripLeg isWalking construction', () {
      const walkLeg = TripLeg(
        tripId: '',
        routeId: '',
        routeShortName: '',
        boardStopId: 'X',
        boardStopName: 'Stop X',
        alightStopId: 'Y',
        alightStopName: 'Stop Y',
        departureSeconds: 36600,
        arrivalSeconds: 37183,
        boardSequence: 0,
        alightSequence: 0,
        isWalking: true,
        walkingDistanceMeters: 700.0,
      );
      expect(walkLeg.isWalking, true);
      expect(walkLeg.walkingDistanceMeters, 700.0);
      expect(walkLeg.tripId, '');
      expect(walkLeg.boardStopName, 'Stop X');
      expect(walkLeg.alightStopName, 'Stop Y');
    });

    test('TripItinerary hasWalkingTransfer', () {
      const transit1 = TripLeg(
        tripId: 'trip1',
        routeId: 'r1',
        routeShortName: '64',
        boardStopId: 'A',
        boardStopName: 'Origin',
        alightStopId: 'X',
        alightStopName: 'Stop X',
        departureSeconds: 36000,
        arrivalSeconds: 36600,
        boardSequence: 1,
        alightSequence: 5,
      );
      const walk = TripLeg(
        tripId: '',
        routeId: '',
        routeShortName: '',
        boardStopId: 'X',
        boardStopName: 'Stop X',
        alightStopId: 'Y',
        alightStopName: 'Stop Y',
        departureSeconds: 36600,
        arrivalSeconds: 37183,
        boardSequence: 0,
        alightSequence: 0,
        isWalking: true,
        walkingDistanceMeters: 700.0,
      );
      const transit2 = TripLeg(
        tripId: 'trip2',
        routeId: 'r2',
        routeShortName: '40',
        boardStopId: 'Y',
        boardStopName: 'Stop Y',
        alightStopId: 'C',
        alightStopName: 'Destination',
        departureSeconds: 37260,
        arrivalSeconds: 37860,
        boardSequence: 1,
        alightSequence: 4,
      );
      const itinerary = TripItinerary(legs: [transit1, walk, transit2]);

      expect(itinerary.hasWalkingTransfer, true);
      expect(itinerary.hasTransfer, true);
      expect(itinerary.isDirect, false);
      expect(itinerary.legs.length, 3);
      // transitLegs should exclude the walking leg
      expect(itinerary.transitLegs.length, 2);
    });

    test('walking duration estimation (700m / 1.2 m/s)', () {
      const distance = 700.0;
      const speed = AppConstants.walkingSpeedMps; // 1.2
      final walkSeconds = (distance / speed).round();
      // 700 / 1.2 = 583.33... ≈ 583s
      expect(walkSeconds, 583);
    });

    test('non-walking itinerary hasWalkingTransfer is false', () {
      const leg1 = TripLeg(
        tripId: 'trip1',
        routeId: 'r1',
        routeShortName: '64',
        boardStopId: 'A',
        boardStopName: 'Origin',
        alightStopId: 'B',
        alightStopName: 'Transfer',
        departureSeconds: 36000,
        arrivalSeconds: 36600,
        boardSequence: 1,
        alightSequence: 5,
      );
      const leg2 = TripLeg(
        tripId: 'trip2',
        routeId: 'r2',
        routeShortName: '40',
        boardStopId: 'B',
        boardStopName: 'Transfer',
        alightStopId: 'C',
        alightStopName: 'Destination',
        departureSeconds: 36900,
        arrivalSeconds: 37500,
        boardSequence: 1,
        alightSequence: 4,
      );
      const itinerary = TripItinerary(legs: [leg1, leg2]);
      expect(itinerary.hasWalkingTransfer, false);
      expect(itinerary.transitLegs.length, 2);
    });
  });

  // ─── v0.0.17: maxTripResults ──────────────────────────────────
  test('maxTripResults is 20', () {
    expect(AppConstants.maxTripResults, 20);
  });

  // ─── v0.0.17: TripSortMode ───────────────────────────────────
  group('TripSortMode', () {
    test('has three values', () {
      expect(TripSortMode.values.length, 3);
      expect(TripSortMode.values, contains(TripSortMode.fastest));
      expect(TripSortMode.values, contains(TripSortMode.fewestTransfers));
      expect(TripSortMode.values, contains(TripSortMode.earliestDeparture));
    });
  });

  // ─── v0.0.17: TripItinerary.transferCount ─────────────────────
  group('TripItinerary.transferCount', () {
    test('direct itinerary has 0 transfers', () {
      const leg = TripLeg(
        tripId: 'trip1',
        routeId: 'r1',
        routeShortName: '64',
        boardStopId: 'A',
        boardStopName: 'Origin',
        alightStopId: 'B',
        alightStopName: 'Dest',
        departureSeconds: 36000,
        arrivalSeconds: 36600,
        boardSequence: 1,
        alightSequence: 5,
      );
      const itinerary = TripItinerary(legs: [leg]);
      expect(itinerary.transferCount, 0);
    });

    test('1-transfer itinerary has transferCount 1', () {
      const leg1 = TripLeg(
        tripId: 'trip1',
        routeId: 'r1',
        routeShortName: '64',
        boardStopId: 'A',
        boardStopName: 'Origin',
        alightStopId: 'B',
        alightStopName: 'Transfer',
        departureSeconds: 36000,
        arrivalSeconds: 36600,
        boardSequence: 1,
        alightSequence: 5,
      );
      const leg2 = TripLeg(
        tripId: 'trip2',
        routeId: 'r2',
        routeShortName: '40',
        boardStopId: 'B',
        boardStopName: 'Transfer',
        alightStopId: 'C',
        alightStopName: 'Dest',
        departureSeconds: 36900,
        arrivalSeconds: 37500,
        boardSequence: 1,
        alightSequence: 4,
      );
      const itinerary = TripItinerary(legs: [leg1, leg2]);
      expect(itinerary.transferCount, 1);
    });

    test('walking transfer itinerary has transferCount 1', () {
      const transit1 = TripLeg(
        tripId: 'trip1',
        routeId: 'r1',
        routeShortName: '64',
        boardStopId: 'A',
        boardStopName: 'Origin',
        alightStopId: 'X',
        alightStopName: 'Stop X',
        departureSeconds: 36000,
        arrivalSeconds: 36600,
        boardSequence: 1,
        alightSequence: 5,
      );
      const walk = TripLeg(
        tripId: '',
        routeId: '',
        routeShortName: '',
        boardStopId: 'X',
        boardStopName: 'Stop X',
        alightStopId: 'Y',
        alightStopName: 'Stop Y',
        departureSeconds: 36600,
        arrivalSeconds: 37183,
        boardSequence: 0,
        alightSequence: 0,
        isWalking: true,
        walkingDistanceMeters: 500.0,
      );
      const transit2 = TripLeg(
        tripId: 'trip2',
        routeId: 'r2',
        routeShortName: '40',
        boardStopId: 'Y',
        boardStopName: 'Stop Y',
        alightStopId: 'C',
        alightStopName: 'Dest',
        departureSeconds: 37260,
        arrivalSeconds: 37860,
        boardSequence: 1,
        alightSequence: 4,
      );
      const itinerary = TripItinerary(legs: [transit1, walk, transit2]);
      // transitLegs excludes walk, so transferCount = 2 transit - 1 = 1
      expect(itinerary.transferCount, 1);
    });
  });

  // ─── v0.0.17: Landmark ──────────────────────────────────────────
  group('Landmark', () {
    test('romeLandmarks list is populated', () {
      expect(romeLandmarks.length, 24);
    });

    test('landmark construction', () {
      final colosseo = romeLandmarks.first;
      expect(colosseo.id, 'lm_colosseo');
      expect(colosseo.nameEn, 'Colosseum');
      expect(colosseo.nameIt, 'Colosseo');
      expect(colosseo.lat, closeTo(41.89, 0.01));
      expect(colosseo.lon, closeTo(12.49, 0.01));
    });

    test('all landmarks have valid coordinates', () {
      for (final lm in romeLandmarks) {
        expect(lm.lat, greaterThan(41.0));
        expect(lm.lat, lessThan(42.5));
        expect(lm.lon, greaterThan(12.0));
        expect(lm.lon, lessThan(13.0));
        expect(lm.id, isNotEmpty);
        expect(lm.nameEn, isNotEmpty);
        expect(lm.nameIt, isNotEmpty);
      }
    });
  });

  // ─── v0.0.17: SearchResult ──────────────────────────────────────
  group('SearchResult', () {
    test('stop type construction', () {
      const result = SearchResult(
        id: 'stop_123',
        name: 'Colosseo',
        lat: 41.89,
        lon: 12.49,
        type: SearchResultType.stop,
        stopId: 'stop_123',
      );
      expect(result.type, SearchResultType.stop);
      expect(result.stopId, 'stop_123');
      expect(result.name, 'Colosseo');
    });

    test('station type construction', () {
      const result = SearchResult(
        id: 'station_1',
        name: 'Roma Termini',
        lat: 41.90,
        lon: 12.50,
        type: SearchResultType.station,
        stopId: 'station_1',
      );
      expect(result.type, SearchResultType.station);
      expect(result.stopId, 'station_1');
    });

    test('landmark type construction (no stopId)', () {
      const result = SearchResult(
        id: 'lm_colosseo',
        name: 'Colosseum',
        lat: 41.8902,
        lon: 12.4922,
        type: SearchResultType.landmark,
      );
      expect(result.type, SearchResultType.landmark);
      expect(result.stopId, isNull);
    });

    test('SearchResultType has three values', () {
      expect(SearchResultType.values.length, 3);
    });
  });

  // ─── v0.0.17: TripDestination ───────────────────────────────────
  group('TripDestination', () {
    test('construction with stopId', () {
      const dest = TripDestination(
        lat: 41.89,
        lon: 12.49,
        name: 'Colosseo',
        stopId: 'stop_123',
      );
      expect(dest.lat, 41.89);
      expect(dest.lon, 12.49);
      expect(dest.name, 'Colosseo');
      expect(dest.stopId, 'stop_123');
    });

    test('construction without stopId (landmark)', () {
      const dest = TripDestination(
        lat: 41.8902,
        lon: 12.4922,
        name: 'Colosseum',
      );
      expect(dest.name, 'Colosseum');
      expect(dest.stopId, isNull);
    });

    test('fromSearchResult', () {
      const result = SearchResult(
        id: 'lm_colosseo',
        name: 'Colosseum',
        lat: 41.8902,
        lon: 12.4922,
        type: SearchResultType.landmark,
      );
      final dest = TripDestination.fromSearchResult(result);
      expect(dest.lat, 41.8902);
      expect(dest.lon, 12.4922);
      expect(dest.name, 'Colosseum');
      expect(dest.stopId, isNull);
    });
  });
}
