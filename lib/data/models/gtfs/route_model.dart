class RouteModel {
  final String routeId;
  final String? agencyId;
  final String routeShortName;
  final String routeLongName;
  final int routeType;
  final String? routeColor;
  final String? routeTextColor;
  final String? routeDesc;

  const RouteModel({
    required this.routeId,
    this.agencyId,
    required this.routeShortName,
    required this.routeLongName,
    required this.routeType,
    this.routeColor,
    this.routeTextColor,
    this.routeDesc,
  });

  factory RouteModel.fromCsvRow(Map<String, String> row) {
    return RouteModel(
      routeId: row['route_id'] ?? '',
      agencyId: row['agency_id'],
      routeShortName: row['route_short_name'] ?? '',
      routeLongName: row['route_long_name'] ?? '',
      routeType: int.tryParse(row['route_type'] ?? '') ?? 3,
      routeColor: row['route_color'],
      routeTextColor: row['route_text_color'],
      routeDesc: row['route_desc'],
    );
  }
}
