import '../../core/utils/date_time_utils.dart';
import '../entities/departure.dart';
import '../repositories/gtfs_repository.dart';
import '../repositories/realtime_repository.dart';

class GetStopDepartures {
  final GtfsRepository _gtfsRepository;
  final RealtimeRepository? _realtimeRepository;

  GetStopDepartures(this._gtfsRepository, [this._realtimeRepository]);

  /// Get upcoming departures for a stop, merging RT data when available.
  Future<List<Departure>> call(String stopId) async {
    // 1. Get scheduled departures
    final scheduled = await _gtfsRepository.getScheduledDepartures(stopId);

    // 2. Filter to upcoming times (within next 90 minutes)
    final nowSeconds = DateTimeUtils.currentTimeAsSeconds();
    final cutoff = nowSeconds + (90 * 60);
    final upcoming = scheduled.where((d) {
      return d.scheduledSeconds >= nowSeconds && d.scheduledSeconds <= cutoff;
    }).toList();

    // 3. Try to overlay RT delays
    if (_realtimeRepository != null) {
      try {
        final delays = await _realtimeRepository!.getTripDelays();
        final merged = upcoming.map((dep) {
          final delay = delays[dep.tripId];
          if (delay != null) {
            return Departure(
              tripId: dep.tripId,
              routeId: dep.routeId,
              routeShortName: dep.routeShortName,
              routeColor: dep.routeColor,
              tripHeadsign: dep.tripHeadsign,
              directionId: dep.directionId,
              scheduledTime: dep.scheduledTime,
              scheduledSeconds: dep.scheduledSeconds,
              estimatedSeconds: dep.scheduledSeconds + delay,
              delaySeconds: delay,
              isRealtime: true,
            );
          }
          return dep;
        }).toList();
        merged.sort((a, b) => a.effectiveSeconds.compareTo(b.effectiveSeconds));
        return merged;
      } catch (_) {
        // RT unavailable, fall back to scheduled
      }
    }

    upcoming.sort((a, b) => a.effectiveSeconds.compareTo(b.effectiveSeconds));
    return upcoming;
  }
}
