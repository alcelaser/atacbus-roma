class StopTimeModel {
  final String tripId;
  final String arrivalTime;
  final String departureTime;
  final String stopId;
  final int stopSequence;
  final String? stopHeadsign;
  final int? pickupType;
  final int? dropOffType;

  const StopTimeModel({
    required this.tripId,
    required this.arrivalTime,
    required this.departureTime,
    required this.stopId,
    required this.stopSequence,
    this.stopHeadsign,
    this.pickupType,
    this.dropOffType,
  });

  factory StopTimeModel.fromCsvRow(Map<String, String> row) {
    return StopTimeModel(
      tripId: row['trip_id'] ?? '',
      arrivalTime: row['arrival_time'] ?? '',
      departureTime: row['departure_time'] ?? '',
      stopId: row['stop_id'] ?? '',
      stopSequence: int.tryParse(row['stop_sequence'] ?? '') ?? 0,
      stopHeadsign: row['stop_headsign'],
      pickupType: int.tryParse(row['pickup_type'] ?? ''),
      dropOffType: int.tryParse(row['drop_off_type'] ?? ''),
    );
  }
}
