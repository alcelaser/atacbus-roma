class FavoriteRouteEntity {
  final int id;
  final double originLat;
  final double originLon;
  final String originName;
  final String destStopId;
  final String destStopName;
  final DateTime addedAt;

  const FavoriteRouteEntity({
    required this.id,
    required this.originLat,
    required this.originLon,
    required this.originName,
    required this.destStopId,
    required this.destStopName,
    required this.addedAt,
  });
}
