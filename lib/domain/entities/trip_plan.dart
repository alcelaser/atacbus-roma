/// A single ride on one transit line from boarding stop to alighting stop.
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
  });

  int get stopCount => alightSequence - boardSequence;
  int get durationSeconds => arrivalSeconds - departureSeconds;
}

/// A complete itinerary: 1 leg (direct) or 2 legs (1 transfer).
class TripItinerary {
  final List<TripLeg> legs;

  const TripItinerary({required this.legs});

  bool get isDirect => legs.length == 1;
  bool get hasTransfer => legs.length > 1;

  String? get transferStopName => hasTransfer ? legs[1].boardStopName : null;

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
