import 'package:gtfs_realtime_bindings/gtfs_realtime_bindings.dart';
import '../../domain/entities/vehicle.dart';
import '../../domain/entities/service_alert.dart';
import '../../domain/repositories/realtime_repository.dart';
import '../datasources/remote/gtfs_realtime_api.dart';

class RealtimeRepositoryImpl implements RealtimeRepository {
  final GtfsRealtimeApi _api;

  RealtimeRepositoryImpl(this._api);

  @override
  Future<Map<String, int>> getTripDelays() async {
    final bytes = await _api.fetchTripUpdates();
    final feed = FeedMessage.fromBuffer(bytes);
    final delays = <String, int>{};

    for (final entity in feed.entity) {
      if (entity.hasTripUpdate()) {
        final update = entity.tripUpdate;
        final tripId = update.trip.tripId;

        // Get delay from stop time updates (take the last one as most relevant)
        int? delay;
        for (final stu in update.stopTimeUpdate) {
          if (stu.hasArrival() && stu.arrival.hasDelay()) {
            delay = stu.arrival.delay;
          } else if (stu.hasDeparture() && stu.departure.hasDelay()) {
            delay = stu.departure.delay;
          }
        }

        // Also check trip-level delay
        if (delay == null && update.hasDelay()) {
          delay = update.delay;
        }

        if (delay != null) {
          delays[tripId] = delay;
        }
      }
    }

    return delays;
  }

  @override
  Future<List<Vehicle>> getVehiclePositions() async {
    final bytes = await _api.fetchVehiclePositions();
    final feed = FeedMessage.fromBuffer(bytes);
    final vehicles = <Vehicle>[];

    for (final entity in feed.entity) {
      if (entity.hasVehicle()) {
        final vp = entity.vehicle;
        final tripId = vp.trip.tripId;
        if (tripId.isEmpty) continue;

        vehicles.add(Vehicle(
          vehicleId: vp.vehicle.hasId() ? vp.vehicle.id : null,
          tripId: tripId,
          routeId: vp.trip.hasRouteId() ? vp.trip.routeId : null,
          latitude: vp.hasPosition() ? vp.position.latitude : null,
          longitude: vp.hasPosition() ? vp.position.longitude : null,
          bearing: vp.hasPosition() && vp.position.hasBearing()
              ? vp.position.bearing
              : null,
          speed: vp.hasPosition() && vp.position.hasSpeed()
              ? vp.position.speed
              : null,
          timestamp: vp.hasTimestamp() ? vp.timestamp.toInt() : null,
        ));
      }
    }

    return vehicles;
  }

  @override
  Future<List<ServiceAlert>> getServiceAlerts() async {
    final bytes = await _api.fetchServiceAlerts();
    final feed = FeedMessage.fromBuffer(bytes);
    final alerts = <ServiceAlert>[];

    for (final entity in feed.entity) {
      if (entity.hasAlert()) {
        final alert = entity.alert;

        final routeIds = <String>[];
        final stopIds = <String>[];
        for (final selector in alert.informedEntity) {
          if (selector.hasRouteId()) routeIds.add(selector.routeId);
          if (selector.hasStopId()) stopIds.add(selector.stopId);
        }

        String? headerText;
        if (alert.hasHeaderText()) {
          for (final translation in alert.headerText.translation) {
            headerText = translation.text;
            if (translation.language == 'it') break;
          }
        }

        String? descText;
        if (alert.hasDescriptionText()) {
          for (final translation in alert.descriptionText.translation) {
            descText = translation.text;
            if (translation.language == 'it') break;
          }
        }

        String? url;
        if (alert.hasUrl()) {
          for (final translation in alert.url.translation) {
            url = translation.text;
            break;
          }
        }

        int? periodStart;
        int? periodEnd;
        if (alert.activePeriod.isNotEmpty) {
          final period = alert.activePeriod.first;
          if (period.hasStart()) periodStart = period.start.toInt();
          if (period.hasEnd()) periodEnd = period.end.toInt();
        }

        alerts.add(ServiceAlert(
          alertId: entity.id,
          headerText: headerText,
          descriptionText: descText,
          url: url,
          routeIds: routeIds,
          stopIds: stopIds,
          activePeriodStart: periodStart,
          activePeriodEnd: periodEnd,
        ));
      }
    }

    return alerts;
  }
}
