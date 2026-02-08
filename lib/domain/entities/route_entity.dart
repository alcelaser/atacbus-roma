class RouteEntity {
  final String routeId;
  final String? agencyId;
  final String routeShortName;
  final String routeLongName;
  final int routeType;
  final String? routeColor;
  final String? routeTextColor;

  const RouteEntity({
    required this.routeId,
    this.agencyId,
    required this.routeShortName,
    required this.routeLongName,
    required this.routeType,
    this.routeColor,
    this.routeTextColor,
  });

  /// GTFS route types: 0=Tram, 1=Metro, 2=Rail, 3=Bus, 4=Ferry
  bool get isBus => routeType == 3;
  bool get isTram => routeType == 0;
  bool get isMetro => routeType == 1;
}
