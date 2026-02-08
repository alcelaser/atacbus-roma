class StopModel {
  final String stopId;
  final String? stopCode;
  final String stopName;
  final String? stopDesc;
  final double stopLat;
  final double stopLon;
  final int? locationType;
  final String? parentStation;

  const StopModel({
    required this.stopId,
    this.stopCode,
    required this.stopName,
    this.stopDesc,
    required this.stopLat,
    required this.stopLon,
    this.locationType,
    this.parentStation,
  });

  factory StopModel.fromCsvRow(Map<String, String> row) {
    return StopModel(
      stopId: row['stop_id'] ?? '',
      stopCode: row['stop_code'],
      stopName: row['stop_name'] ?? '',
      stopDesc: row['stop_desc'],
      stopLat: double.tryParse(row['stop_lat'] ?? '') ?? 0.0,
      stopLon: double.tryParse(row['stop_lon'] ?? '') ?? 0.0,
      locationType: int.tryParse(row['location_type'] ?? ''),
      parentStation: row['parent_station'],
    );
  }
}
