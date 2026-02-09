import '../../core/utils/date_time_utils.dart';
import '../../data/repositories/gtfs_repository_impl.dart';
import '../entities/trip_plan.dart';

class PlanTrip {
  final GtfsRepositoryImpl _repo;

  PlanTrip(this._repo);

  /// Plan trip between two specific stops (backward compat).
  Future<TripPlanResult?> call(
    String originStopId,
    String destinationStopId,
  ) async {
    final origin = await _repo.getStopById(originStopId);
    final destination = await _repo.getStopById(destinationStopId);
    if (origin == null || destination == null) return null;

    return callMulti(
      originStopIds: [originStopId],
      destStopIds: [destinationStopId],
      originName: origin.stopName,
      destinationName: destination.stopName,
    );
  }

  /// Plan trip across multiple origin/destination stop pairs.
  /// Used for GPS-based planning where nearby stops are candidates.
  Future<TripPlanResult?> callMulti({
    required List<String> originStopIds,
    required List<String> destStopIds,
    required String originName,
    required String destinationName,
  }) async {
    if (originStopIds.isEmpty || destStopIds.isEmpty) return null;

    final now = DateTimeUtils.currentTimeAsSeconds();
    final maxTime = now + 3 * 3600; // 3 hours window

    final allItineraries = <TripItinerary>[];
    final seenKeys = <String>{};

    // Cap to avoid excessive queries
    final origins = originStopIds.take(10).toList();
    final dests = destStopIds.take(10).toList();

    // Resolve stop names for each stop we'll reference
    final stopNameCache = <String, String>{};

    for (final oId in origins) {
      for (final dId in dests) {
        if (oId == dId) continue;

        // ─── Direct routes ───────────────────────────────────
        final directRows = await _repo.findDirectTrips(oId, dId);
        final seenRoutes = <String, int>{};

        final oName = await _resolveStopName(oId, stopNameCache);
        final dName = await _resolveStopName(dId, stopNameCache);

        for (final row in directRows) {
          final depSeconds = DateTimeUtils.parseGtfsTime(row.departureTime);
          if (depSeconds < now || depSeconds > maxTime) continue;

          final routeCount = seenRoutes[row.routeId] ?? 0;
          if (routeCount >= 2) continue;
          seenRoutes[row.routeId] = routeCount + 1;

          final key = '${row.routeId}:$depSeconds';
          if (seenKeys.contains(key)) continue;
          seenKeys.add(key);

          final arrSeconds = DateTimeUtils.parseGtfsTime(row.arrivalTime);

          allItineraries.add(TripItinerary(
            legs: [
              TripLeg(
                tripId: row.tripId,
                routeId: row.routeId,
                routeShortName: row.routeShortName,
                routeColor: row.routeColor,
                tripHeadsign: row.tripHeadsign,
                boardStopId: oId,
                boardStopName: oName,
                alightStopId: dId,
                alightStopName: dName,
                departureSeconds: depSeconds,
                arrivalSeconds: arrSeconds,
                boardSequence: row.depSequence,
                alightSequence: row.arrSequence,
              ),
            ],
          ));
        }

        // ─── 1-transfer routes (if few direct results) ──────
        if (seenRoutes.length < 3) {
          final transfers = await _findTransferItineraries(
            oId, dId, oName, dName, now, maxTime, seenKeys, stopNameCache,
          );
          allItineraries.addAll(transfers);
        }
      }
    }

    allItineraries
        .sort((a, b) => a.departureSeconds.compareTo(b.departureSeconds));

    return TripPlanResult(
      originName: originName,
      destinationName: destinationName,
      itineraries: allItineraries.take(10).toList(),
    );
  }

  Future<String> _resolveStopName(
      String stopId, Map<String, String> cache) async {
    if (cache.containsKey(stopId)) return cache[stopId]!;
    final stop = await _repo.getStopById(stopId);
    final name = stop?.stopName ?? stopId;
    cache[stopId] = name;
    return name;
  }

  Future<List<TripItinerary>> _findTransferItineraries(
    String originStopId,
    String destinationStopId,
    String originName,
    String destName,
    int now,
    int maxTime,
    Set<String> seenKeys,
    Map<String, String> stopNameCache,
  ) async {
    final originRouteIds = await _repo.getRouteIdsForStop(originStopId);
    final destRouteIds = await _repo.getRouteIdsForStop(destinationStopId);

    if (originRouteIds.isEmpty || destRouteIds.isEmpty) return [];

    final originReachable =
        (await _repo.getStopIdsForRoutes(originRouteIds)).toSet();
    final destReachable =
        (await _repo.getStopIdsForRoutes(destRouteIds)).toSet();

    var transferStopIds = originReachable.intersection(destReachable);
    transferStopIds.remove(originStopId);
    transferStopIds.remove(destinationStopId);

    if (transferStopIds.isEmpty) return [];

    final candidates = transferStopIds.take(15).toList();
    final results = <TripItinerary>[];

    for (final transferStopId in candidates) {
      if (results.length >= 5) break;

      final leg1Rows =
          await _repo.findDirectTrips(originStopId, transferStopId);
      if (leg1Rows.isEmpty) continue;

      final leg2Rows =
          await _repo.findDirectTrips(transferStopId, destinationStopId);
      if (leg2Rows.isEmpty) continue;

      final transferStopName =
          await _resolveStopName(transferStopId, stopNameCache);

      for (final leg1 in leg1Rows) {
        if (results.length >= 5) break;

        final leg1Dep = DateTimeUtils.parseGtfsTime(leg1.departureTime);
        if (leg1Dep < now || leg1Dep > maxTime) continue;

        final leg1Arr = DateTimeUtils.parseGtfsTime(leg1.arrivalTime);
        final minTransferSeconds = leg1Arr + 120;

        for (final leg2 in leg2Rows) {
          final leg2Dep = DateTimeUtils.parseGtfsTime(leg2.departureTime);
          if (leg2Dep < minTransferSeconds) continue;
          if (leg2Dep > maxTime) break;
          if (leg1.routeId == leg2.routeId) continue;

          final key = '${leg1.routeId}:${leg2.routeId}:$leg1Dep';
          if (seenKeys.contains(key)) continue;
          seenKeys.add(key);

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
                boardStopName: originName,
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
                alightStopName: destName,
                departureSeconds: leg2Dep,
                arrivalSeconds: leg2Arr,
                boardSequence: leg2.depSequence,
                alightSequence: leg2.arrSequence,
              ),
            ],
          ));
          break;
        }
      }
    }

    return results;
  }
}
