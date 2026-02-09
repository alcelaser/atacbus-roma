import 'search_result.dart';
import 'stop.dart';

/// Sort modes for trip plan results.
enum TripSortMode { fastest, fewestTransfers, earliestDeparture }

/// A single ride on one transit line from boarding stop to alighting stop,
/// or a walking segment between two stops.
class TripLeg {
  final String tripId;
  final String routeId;
  final String routeShortName;
  final String? routeColor;
  final String? tripHeadsign;
  final String boardStopId;
  final String boardStopName;
  final String alightStopId;
  final String alightStopName;
  final int departureSeconds;
  final int arrivalSeconds;
  final int boardSequence;
  final int alightSequence;
  final bool isWalking;
  final double? walkingDistanceMeters;

  const TripLeg({
    required this.tripId,
    required this.routeId,
    required this.routeShortName,
    this.routeColor,
    this.tripHeadsign,
    required this.boardStopId,
    required this.boardStopName,
    required this.alightStopId,
    required this.alightStopName,
    required this.departureSeconds,
    required this.arrivalSeconds,
    required this.boardSequence,
    required this.alightSequence,
    this.isWalking = false,
    this.walkingDistanceMeters,
  });

  int get stopCount => alightSequence - boardSequence;
  int get durationSeconds => arrivalSeconds - departureSeconds;
}

/// A complete itinerary: 1 leg (direct), 2 legs (1 transfer), or
/// 3 legs (transit + walk + transit for walking transfers).
class TripItinerary {
  final List<TripLeg> legs;

  const TripItinerary({required this.legs});

  bool get isDirect => legs.length == 1;
  bool get hasTransfer => legs.length > 1;
  bool get hasWalkingTransfer => legs.any((l) => l.isWalking);

  /// Transit legs only (excludes walking segments).
  List<TripLeg> get transitLegs => legs.where((l) => !l.isWalking).toList();

  /// Number of transfers (0 for direct, 1 for one-transfer, etc.).
  int get transferCount {
    final transit = transitLegs;
    return transit.length <= 1 ? 0 : transit.length - 1;
  }

  String? get transferStopName {
    if (!hasTransfer) return null;
    if (hasWalkingTransfer) {
      final walkLeg = legs.firstWhere((l) => l.isWalking);
      return '${walkLeg.boardStopName} \u2192 ${walkLeg.alightStopName}';
    }
    return legs[1].boardStopName;
  }

  int get departureSeconds => legs.first.departureSeconds;
  int get arrivalSeconds => legs.last.arrivalSeconds;
  int get totalDurationSeconds => arrivalSeconds - departureSeconds;
}

/// Result of a trip plan query.
class TripPlanResult {
  final String originName;
  final String destinationName;
  final List<TripItinerary> itineraries;

  const TripPlanResult({
    required this.originName,
    required this.destinationName,
    required this.itineraries,
  });
}

/// Destination for trip planning — can be a stop or a landmark/location.
class TripDestination {
  final double lat;
  final double lon;
  final String name;
  final String? stopId;

  const TripDestination({
    required this.lat,
    required this.lon,
    required this.name,
    this.stopId,
  });

  TripDestination.fromStop(Stop stop)
      : lat = stop.stopLat,
        lon = stop.stopLon,
        name = stop.stopName,
        stopId = stop.stopId;

  TripDestination.fromSearchResult(SearchResult result)
      : lat = result.lat,
        lon = result.lon,
        name = result.name,
        stopId = result.stopId;
}
