class TripModel {
  final String tripId;
  final String routeId;
  final String serviceId;
  final String? tripHeadsign;
  final String? tripShortName;
  final int? directionId;
  final String? shapeId;

  const TripModel({
    required this.tripId,
    required this.routeId,
    required this.serviceId,
    this.tripHeadsign,
    this.tripShortName,
    this.directionId,
    this.shapeId,
  });

  factory TripModel.fromCsvRow(Map<String, String> row) {
    return TripModel(
      tripId: row['trip_id'] ?? '',
      routeId: row['route_id'] ?? '',
      serviceId: row['service_id'] ?? '',
      tripHeadsign: row['trip_headsign'],
      tripShortName: row['trip_short_name'],
      directionId: int.tryParse(row['direction_id'] ?? ''),
      shapeId: row['shape_id'],
    );
  }
}
