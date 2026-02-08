class TripUpdateModel {
  final String tripId;
  final String? routeId;
  final int? delay; // seconds

  const TripUpdateModel({
    required this.tripId,
    this.routeId,
    this.delay,
  });
}
