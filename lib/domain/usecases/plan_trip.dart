import '../../core/constants/app_constants.dart';
import '../../core/utils/date_time_utils.dart';
import '../../core/utils/distance_utils.dart';
import '../../data/repositories/gtfs_repository_impl.dart';
import '../entities/stop.dart';
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

    final allStops = await _repo.getAllStops();
    return callMulti(
      originStopIds: [originStopId],
      destStopIds: [destinationStopId],
      originName: origin.stopName,
      destinationName: destination.stopName,
      allStops: allStops,
    );
  }

  /// Plan trip across multiple origin/destination stop pairs.
  /// Used for GPS-based planning where nearby stops are candidates.
  Future<TripPlanResult?> callMulti({
    required List<String> originStopIds,
    required List<String> destStopIds,
    required String originName,
    required String destinationName,
    required List<Stop> allStops,
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

        try {
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

          // ─── 1-transfer routes ──────────────────────────────
          final transfers = await _findTransferItineraries(
            oId, dId, oName, dName, now, maxTime, seenKeys, stopNameCache,
            allStops,
          );
          allItineraries.addAll(transfers);
        } catch (_) {
          // Skip this origin-dest pair on error and continue
          continue;
        }
      }
    }

    allItineraries
        .sort((a, b) => a.departureSeconds.compareTo(b.departureSeconds));

    return TripPlanResult(
      originName: originName,
      destinationName: destinationName,
      itineraries: allItineraries.take(AppConstants.maxTripResults).toList(),
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
    List<Stop> allStops,
  ) async {
    final originRouteIds = await _repo.getRouteIdsForStop(originStopId);
    final destRouteIds = await _repo.getRouteIdsForStop(destinationStopId);

    if (originRouteIds.isEmpty || destRouteIds.isEmpty) return [];

    final originReachable =
        (await _repo.getStopIdsForRoutes(originRouteIds)).toSet();
    final destReachable =
        (await _repo.getStopIdsForRoutes(destRouteIds)).toSet();

    final results = <TripItinerary>[];

    // ─── Same-stop transfers ─────────────────────────────────
    var transferStopIds = originReachable.intersection(destReachable);
    transferStopIds.remove(originStopId);
    transferStopIds.remove(destinationStopId);

    if (transferStopIds.isNotEmpty) {
      final candidates = transferStopIds.take(15).toList();
      await _findSameStopTransfers(
        candidates, originStopId, destinationStopId,
        originName, destName, now, maxTime, seenKeys, stopNameCache, results,
      );
    }

    // ─── Walking transfers ───────────────────────────────────
    if (results.length < 5) {
      await _findWalkingTransfers(
        originReachable, destReachable, transferStopIds,
        originStopId, destinationStopId,
        originName, destName, now, maxTime, seenKeys, stopNameCache, allStops,
        results,
      );
    }

    return results;
  }

  Future<void> _findSameStopTransfers(
    List<String> candidates,
    String originStopId,
    String destinationStopId,
    String originName,
    String destName,
    int now,
    int maxTime,
    Set<String> seenKeys,
    Map<String, String> stopNameCache,
    List<TripItinerary> results,
  ) async {
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
  }

  Future<void> _findWalkingTransfers(
    Set<String> originReachable,
    Set<String> destReachable,
    Set<String> sameStopTransfers,
    String originStopId,
    String destinationStopId,
    String originName,
    String destName,
    int now,
    int maxTime,
    Set<String> seenKeys,
    Map<String, String> stopNameCache,
    List<Stop> allStops,
    List<TripItinerary> results,
  ) async {
    // Build coordinate lookup for reachable stops
    final stopCoords = <String, ({double lat, double lon})>{};
    for (final stop in allStops) {
      if (originReachable.contains(stop.stopId) ||
          destReachable.contains(stop.stopId)) {
        stopCoords[stop.stopId] = (lat: stop.stopLat, lon: stop.stopLon);
      }
    }

    // Find walking pairs: stopA (origin-reachable) near stopB (dest-reachable)
    final walkingPairs = <({String stopA, String stopB, double distance})>[];

    for (final aId in originReachable) {
      if (aId == originStopId || aId == destinationStopId) continue;
      final aCoord = stopCoords[aId];
      if (aCoord == null) continue;

      for (final bId in destReachable) {
        if (bId == aId) continue; // same-stop handled above
        if (bId == originStopId || bId == destinationStopId) continue;
        if (sameStopTransfers.contains(aId) && sameStopTransfers.contains(bId)) continue;
        final bCoord = stopCoords[bId];
        if (bCoord == null) continue;

        final distance = DistanceUtils.haversineDistance(
          aCoord.lat, aCoord.lon, bCoord.lat, bCoord.lon,
        );

        if (distance <= AppConstants.walkingTransferMaxMeters) {
          walkingPairs.add((stopA: aId, stopB: bId, distance: distance));
        }
      }
    }

    // Sort by distance (prefer shorter walks), cap at 10
    walkingPairs.sort((a, b) => a.distance.compareTo(b.distance));
    final candidates = walkingPairs.take(10);

    for (final pair in candidates) {
      if (results.length >= 5) break;

      final leg1Rows =
          await _repo.findDirectTrips(originStopId, pair.stopA);
      if (leg1Rows.isEmpty) continue;

      final leg2Rows =
          await _repo.findDirectTrips(pair.stopB, destinationStopId);
      if (leg2Rows.isEmpty) continue;

      final aName = await _resolveStopName(pair.stopA, stopNameCache);
      final bName = await _resolveStopName(pair.stopB, stopNameCache);

      final walkSeconds =
          (pair.distance / AppConstants.walkingSpeedMps).ceil();

      for (final leg1 in leg1Rows) {
        if (results.length >= 5) break;

        final leg1Dep = DateTimeUtils.parseGtfsTime(leg1.departureTime);
        if (leg1Dep < now || leg1Dep > maxTime) continue;

        final leg1Arr = DateTimeUtils.parseGtfsTime(leg1.arrivalTime);
        // Walking time + 60s buffer before next departure
        final minTransferSeconds = leg1Arr + walkSeconds + 60;

        for (final leg2 in leg2Rows) {
          final leg2Dep = DateTimeUtils.parseGtfsTime(leg2.departureTime);
          if (leg2Dep < minTransferSeconds) continue;
          if (leg2Dep > maxTime) break;
          if (leg1.routeId == leg2.routeId) continue;

          final key = 'w:${leg1.routeId}:${leg2.routeId}:$leg1Dep';
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
                alightStopId: pair.stopA,
                alightStopName: aName,
                departureSeconds: leg1Dep,
                arrivalSeconds: leg1Arr,
                boardSequence: leg1.depSequence,
                alightSequence: leg1.arrSequence,
              ),
              TripLeg(
                tripId: '',
                routeId: '',
                routeShortName: '',
                boardStopId: pair.stopA,
                boardStopName: aName,
                alightStopId: pair.stopB,
                alightStopName: bName,
                departureSeconds: leg1Arr,
                arrivalSeconds: leg1Arr + walkSeconds,
                boardSequence: 0,
                alightSequence: 0,
                isWalking: true,
                walkingDistanceMeters: pair.distance,
              ),
              TripLeg(
                tripId: leg2.tripId,
                routeId: leg2.routeId,
                routeShortName: leg2.routeShortName,
                routeColor: leg2.routeColor,
                tripHeadsign: leg2.tripHeadsign,
                boardStopId: pair.stopB,
                boardStopName: bName,
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
  }
}
