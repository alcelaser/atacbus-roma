class ShapeModel {
  final String shapeId;
  final double shapePtLat;
  final double shapePtLon;
  final int shapePtSequence;

  const ShapeModel({
    required this.shapeId,
    required this.shapePtLat,
    required this.shapePtLon,
    required this.shapePtSequence,
  });

  factory ShapeModel.fromCsvRow(Map<String, String> row) {
    return ShapeModel(
      shapeId: row['shape_id'] ?? '',
      shapePtLat: double.tryParse(row['shape_pt_lat'] ?? '') ?? 0.0,
      shapePtLon: double.tryParse(row['shape_pt_lon'] ?? '') ?? 0.0,
      shapePtSequence: int.tryParse(row['shape_pt_sequence'] ?? '') ?? 0,
    );
  }
}
