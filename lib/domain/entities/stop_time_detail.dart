class StopTimeDetail {
  final String stopId;
  final String stopName;
  final String arrivalTime;
  final String departureTime;
  final int stopSequence;
  final double stopLat;
  final double stopLon;

  const StopTimeDetail({
    required this.stopId,
    required this.stopName,
    required this.arrivalTime,
    required this.departureTime,
    required this.stopSequence,
    required this.stopLat,
    required this.stopLon,
  });
}
