import '../../core/utils/date_time_utils.dart';
import '../../data/repositories/gtfs_repository_impl.dart';
import '../entities/stop.dart';
import '../entities/trip_plan.dart';

class PlanTrip {
  final GtfsRepositoryImpl _repo;

  PlanTrip(this._repo);

  Future<TripPlanResult?> call(
    String originStopId,
    String destinationStopId,
  ) async {
    final origin = await _repo.getStopById(originStopId);
    final destination = await _repo.getStopById(destinationStopId);
    if (origin == null || destination == null) return null;

    final now = DateTimeUtils.currentTimeAsSeconds();
    final maxTime = now + 3 * 3600; // 3 hours window

    // ─── Direct routes ───────────────────────────────────────
    final directRows = await _repo.findDirectTrips(
      originStopId,
      destinationStopId,
    );

    final directItineraries = <TripItinerary>[];
    final seenRoutes = <String, int>{};

    for (final row in directRows) {
      final depSeconds = DateTimeUtils.parseGtfsTime(row.departureTime);

      // Only future departures within the 3h window
      if (depSeconds < now || depSeconds > maxTime) continue;

      // Limit 2 per route
      final routeCount = seenRoutes[row.routeId] ?? 0;
      if (routeCount >= 2) continue;
      seenRoutes[row.routeId] = routeCount + 1;

      final arrSeconds = DateTimeUtils.parseGtfsTime(row.arrivalTime);

      directItineraries.add(TripItinerary(
        legs: [
          TripLeg(
            tripId: row.tripId,
            routeId: row.routeId,
            routeShortName: row.routeShortName,
            routeColor: row.routeColor,
            tripHeadsign: row.tripHeadsign,
            boardStopId: originStopId,
            boardStopName: origin.stopName,
            alightStopId: destinationStopId,
            alightStopName: destination.stopName,
            departureSeconds: depSeconds,
            arrivalSeconds: arrSeconds,
            boardSequence: row.depSequence,
            alightSequence: row.arrSequence,
          ),
        ],
      ));
    }

    // ─── 1-transfer routes (if < 3 distinct direct routes) ───
    final transferItineraries = <TripItinerary>[];
    if (seenRoutes.length < 3) {
      final transfers = await _findTransferItineraries(
        originStopId,
        destinationStopId,
        origin,
        destination,
        now,
        maxTime,
      );
      transferItineraries.addAll(transfers);
    }

    // ─── Combine & sort ─────────────────────────────────────
    final all = [...directItineraries, ...transferItineraries];
    all.sort((a, b) => a.departureSeconds.compareTo(b.departureSeconds));

    return TripPlanResult(
      originStopId: originStopId,
      originStopName: origin.stopName,
      destinationStopId: destinationStopId,
      destinationStopName: destination.stopName,
      itineraries: all.take(10).toList(),
    );
  }

  Future<List<TripItinerary>> _findTransferItineraries(
    String originStopId,
    String destinationStopId,
    Stop origin,
    Stop destination,
    int now,
    int maxTime,
  ) async {
    // Find routes serving origin and destination
    final originRouteIds = await _repo.getRouteIdsForStop(originStopId);
    final destRouteIds = await _repo.getRouteIdsForStop(destinationStopId);

    if (originRouteIds.isEmpty || destRouteIds.isEmpty) return [];

    // Find all stops reachable from origin routes and destination routes
    final originReachable =
        (await _repo.getStopIdsForRoutes(originRouteIds)).toSet();
    final destReachable =
        (await _repo.getStopIdsForRoutes(destRouteIds)).toSet();

    // Transfer stops are the intersection
    var transferStopIds = originReachable.intersection(destReachable);
    // Exclude origin and destination themselves
    transferStopIds.remove(originStopId);
    transferStopIds.remove(destinationStopId);

    if (transferStopIds.isEmpty) return [];

    // Cap transfer candidates
    final candidates = transferStopIds.take(15).toList();

    final results = <TripItinerary>[];

    for (final transferStopId in candidates) {
      if (results.length >= 5) break;

      // Find leg 1: origin -> transfer
      final leg1Rows = await _repo.findDirectTrips(
        originStopId,
        transferStopId,
      );

      if (leg1Rows.isEmpty) continue;

      // Find leg 2: transfer -> destination
      final leg2Rows = await _repo.findDirectTrips(
        transferStopId,
        destinationStopId,
      );

      if (leg2Rows.isEmpty) continue;

      final transferStop = await _repo.getStopById(transferStopId);
      final transferStopName = transferStop?.stopName ?? transferStopId;

      // Match timed connections
      for (final leg1 in leg1Rows) {
        if (results.length >= 5) break;

        final leg1Dep = DateTimeUtils.parseGtfsTime(leg1.departureTime);
        if (leg1Dep < now || leg1Dep > maxTime) continue;

        final leg1Arr = DateTimeUtils.parseGtfsTime(leg1.arrivalTime);

        // Find earliest leg2 with min 2 min transfer
        final minTransferSeconds = leg1Arr + 120;

        for (final leg2 in leg2Rows) {
          final leg2Dep = DateTimeUtils.parseGtfsTime(leg2.departureTime);
          if (leg2Dep < minTransferSeconds) continue;
          if (leg2Dep > maxTime) break;

          // Skip if same route (that would be a direct route)
          if (leg1.routeId == leg2.routeId) continue;

          final leg2Arr = DateTimeUtils.parseGtfsTime(leg2.arrivalTime);

          results.add(TripItinerary(
            legs: [
              TripLeg(
                tripId: leg1.tripId,
                routeId: leg1.routeId,
                routeShortName: leg1.routeShortName,
                routeColor: leg1.routeColor,
                tripHeadsign: leg1.tripHeadsign,
                boardStopId: originStopId,
                boardStopName: origin.stopName,
                alightStopId: transferStopId,
                alightStopName: transferStopName,
                departureSeconds: leg1Dep,
                arrivalSeconds: leg1Arr,
                boardSequence: leg1.depSequence,
                alightSequence: leg1.arrSequence,
              ),
              TripLeg(
                tripId: leg2.tripId,
                routeId: leg2.routeId,
                routeShortName: leg2.routeShortName,
                routeColor: leg2.routeColor,
                tripHeadsign: leg2.tripHeadsign,
                boardStopId: transferStopId,
                boardStopName: transferStopName,
                alightStopId: destinationStopId,
                alightStopName: destination.stopName,
                departureSeconds: leg2Dep,
                arrivalSeconds: leg2Arr,
                boardSequence: leg2.depSequence,
                alightSequence: leg2.arrSequence,
              ),
            ],
          ));
          break; // best match for this leg1
        }
      }
    }

    return results;
  }
}
