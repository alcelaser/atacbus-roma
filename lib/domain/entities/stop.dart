class Stop {
  final String stopId;
  final String? stopCode;
  final String stopName;
  final String? stopDesc;
  final double stopLat;
  final double stopLon;
  final int? locationType;
  final String? parentStation;

  const Stop({
    required this.stopId,
    this.stopCode,
    required this.stopName,
    this.stopDesc,
    required this.stopLat,
    required this.stopLon,
    this.locationType,
    this.parentStation,
  });
}
