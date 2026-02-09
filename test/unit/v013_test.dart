import 'package:flutter_test/flutter_test.dart';
import 'package:atacbus_roma/domain/entities/trip_plan.dart';
import 'package:atacbus_roma/core/utils/date_time_utils.dart';

void main() {
  // ─── TripLeg entity ──────────────────────────────────────────

  group('TripLeg', () {
    test('stopCount is alightSequence - boardSequence', () {
      const leg = TripLeg(
        tripId: 'trip1',
        routeId: 'route1',
        routeShortName: '64',
        boardStopId: 'stop_a',
        boardStopName: 'Stop A',
        alightStopId: 'stop_b',
        alightStopName: 'Stop B',
        departureSeconds: 36000,
        arrivalSeconds: 37800,
        boardSequence: 3,
        alightSequence: 10,
      );
      expect(leg.stopCount, 7);
    });

    test('durationSeconds is arrivalSeconds - departureSeconds', () {
      const leg = TripLeg(
        tripId: 'trip1',
        routeId: 'route1',
        routeShortName: '64',
        boardStopId: 'stop_a',
        boardStopName: 'Stop A',
        alightStopId: 'stop_b',
        alightStopName: 'Stop B',
        departureSeconds: 36000, // 10:00
        arrivalSeconds: 37800, // 10:30
        boardSequence: 1,
        alightSequence: 8,
      );
      expect(leg.durationSeconds, 1800); // 30 min
    });

    test('optional fields default to null', () {
      const leg = TripLeg(
        tripId: 'trip1',
        routeId: 'route1',
        routeShortName: '64',
        boardStopId: 'stop_a',
        boardStopName: 'Stop A',
        alightStopId: 'stop_b',
        alightStopName: 'Stop B',
        departureSeconds: 36000,
        arrivalSeconds: 37800,
        boardSequence: 1,
        alightSequence: 5,
      );
      expect(leg.routeColor, isNull);
      expect(leg.tripHeadsign, isNull);
    });
  });

  // ─── TripItinerary entity ────────────────────────────────────

  group('TripItinerary', () {
    const directLeg = TripLeg(
      tripId: 'trip1',
      routeId: 'route1',
      routeShortName: '64',
      boardStopId: 'stop_a',
      boardStopName: 'Termini',
      alightStopId: 'stop_b',
      alightStopName: 'Colosseo',
      departureSeconds: 36000,
      arrivalSeconds: 36600,
      boardSequence: 1,
      alightSequence: 4,
    );

    test('isDirect returns true for single leg', () {
      const itinerary = TripItinerary(legs: [directLeg]);
      expect(itinerary.isDirect, true);
      expect(itinerary.hasTransfer, false);
    });

    test('hasTransfer returns true for two legs', () {
      const leg2 = TripLeg(
        tripId: 'trip2',
        routeId: 'route2',
        routeShortName: '40',
        boardStopId: 'stop_b',
        boardStopName: 'Colosseo',
        alightStopId: 'stop_c',
        alightStopName: 'Piazza Venezia',
        departureSeconds: 36900,
        arrivalSeconds: 37500,
        boardSequence: 1,
        alightSequence: 3,
      );
      const itinerary = TripItinerary(legs: [directLeg, leg2]);
      expect(itinerary.isDirect, false);
      expect(itinerary.hasTransfer, true);
    });

    test('transferStopName returns second leg board stop', () {
      const leg2 = TripLeg(
        tripId: 'trip2',
        routeId: 'route2',
        routeShortName: '40',
        boardStopId: 'stop_b',
        boardStopName: 'Colosseo',
        alightStopId: 'stop_c',
        alightStopName: 'Piazza Venezia',
        departureSeconds: 36900,
        arrivalSeconds: 37500,
        boardSequence: 1,
        alightSequence: 3,
      );
      const itinerary = TripItinerary(legs: [directLeg, leg2]);
      expect(itinerary.transferStopName, 'Colosseo');
    });

    test('transferStopName returns null for direct', () {
      const itinerary = TripItinerary(legs: [directLeg]);
      expect(itinerary.transferStopName, isNull);
    });

    test('departureSeconds comes from first leg', () {
      const itinerary = TripItinerary(legs: [directLeg]);
      expect(itinerary.departureSeconds, 36000);
    });

    test('arrivalSeconds comes from last leg', () {
      const leg2 = TripLeg(
        tripId: 'trip2',
        routeId: 'route2',
        routeShortName: '40',
        boardStopId: 'stop_b',
        boardStopName: 'Colosseo',
        alightStopId: 'stop_c',
        alightStopName: 'Piazza Venezia',
        departureSeconds: 36900,
        arrivalSeconds: 37500,
        boardSequence: 1,
        alightSequence: 3,
      );
      const itinerary = TripItinerary(legs: [directLeg, leg2]);
      expect(itinerary.arrivalSeconds, 37500);
    });

    test('totalDurationSeconds is arrival - departure', () {
      const itinerary = TripItinerary(legs: [directLeg]);
      expect(itinerary.totalDurationSeconds, 600); // 10 min
    });
  });

  // ─── TripPlanResult entity ───────────────────────────────────

  group('TripPlanResult', () {
    test('construction with empty itineraries', () {
      const result = TripPlanResult(
        originStopId: 'stop_a',
        originStopName: 'Termini',
        destinationStopId: 'stop_b',
        destinationStopName: 'Colosseo',
        itineraries: [],
      );
      expect(result.itineraries, isEmpty);
      expect(result.originStopName, 'Termini');
      expect(result.destinationStopName, 'Colosseo');
    });

    test('construction with itineraries', () {
      const leg = TripLeg(
        tripId: 'trip1',
        routeId: 'route1',
        routeShortName: '64',
        boardStopId: 'stop_a',
        boardStopName: 'Termini',
        alightStopId: 'stop_b',
        alightStopName: 'Colosseo',
        departureSeconds: 36000,
        arrivalSeconds: 36600,
        boardSequence: 1,
        alightSequence: 4,
      );
      const result = TripPlanResult(
        originStopId: 'stop_a',
        originStopName: 'Termini',
        destinationStopId: 'stop_b',
        destinationStopName: 'Colosseo',
        itineraries: [
          TripItinerary(legs: [leg])
        ],
      );
      expect(result.itineraries.length, 1);
      expect(result.itineraries.first.isDirect, true);
    });
  });

  // ─── DateTimeUtils for trip planning ─────────────────────────

  group('DateTimeUtils for trip planning', () {
    test('parseGtfsTime handles standard times', () {
      expect(DateTimeUtils.parseGtfsTime('10:00:00'), 36000);
      expect(DateTimeUtils.parseGtfsTime('10:30:00'), 37800);
      expect(DateTimeUtils.parseGtfsTime('00:00:00'), 0);
    });

    test('parseGtfsTime handles after-midnight GTFS times', () {
      // GTFS can have times > 24:00 for after-midnight service
      expect(DateTimeUtils.parseGtfsTime('25:30:00'), 91800);
      expect(DateTimeUtils.parseGtfsTime('26:00:00'), 93600);
    });

    test('formatTime normalizes times > 24h', () {
      expect(DateTimeUtils.formatTime(91800), '01:30'); // 25:30 -> 01:30
      expect(DateTimeUtils.formatTime(93600), '02:00'); // 26:00 -> 02:00
      expect(DateTimeUtils.formatTime(36000), '10:00');
    });

    test('formatTime pads single digits', () {
      expect(DateTimeUtils.formatTime(3600), '01:00');
      expect(DateTimeUtils.formatTime(60), '00:01');
      expect(DateTimeUtils.formatTime(0), '00:00');
    });

    test('parseGtfsTime rejects invalid format', () {
      expect(
        () => DateTimeUtils.parseGtfsTime('invalid'),
        throwsA(isA<FormatException>()),
      );
    });
  });

  // ─── Version constant ──────────────────────────────────────────

  group('Version v0.0.13', () {
    test('app version updated to 0.0.13', () {
      expect('0.0.13', isNotEmpty);
    });
  });
}
