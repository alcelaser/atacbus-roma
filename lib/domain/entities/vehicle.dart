class Vehicle {
  final String? vehicleId;
  final String tripId;
  final String? routeId;
  final double? latitude;
  final double? longitude;
  final double? bearing;
  final double? speed;
  final int? timestamp;

  const Vehicle({
    this.vehicleId,
    required this.tripId,
    this.routeId,
    this.latitude,
    this.longitude,
    this.bearing,
    this.speed,
    this.timestamp,
  });
}
