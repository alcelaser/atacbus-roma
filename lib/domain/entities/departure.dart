class Departure {
  final String tripId;
  final String routeId;
  final String routeShortName;
  final String? routeColor;
  final String? tripHeadsign;
  final int? directionId;
  final String scheduledTime; // HH:MM:SS (may be >24:00)
  final int scheduledSeconds; // total seconds since midnight
  final int? estimatedSeconds; // from RT, null if no RT data
  final int? delaySeconds; // positive = late, negative = early
  final bool isRealtime;

  const Departure({
    required this.tripId,
    required this.routeId,
    required this.routeShortName,
    this.routeColor,
    this.tripHeadsign,
    this.directionId,
    required this.scheduledTime,
    required this.scheduledSeconds,
    this.estimatedSeconds,
    this.delaySeconds,
    this.isRealtime = false,
  });

  /// The best available arrival time in seconds.
  int get effectiveSeconds => estimatedSeconds ?? scheduledSeconds;
}
