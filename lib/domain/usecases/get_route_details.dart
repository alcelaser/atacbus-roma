import '../entities/route_entity.dart';
import '../entities/stop.dart';
import '../repositories/gtfs_repository.dart';

class GetRouteDetails {
  final GtfsRepository _repository;

  GetRouteDetails(this._repository);

  Future<RouteEntity?> getRoute(String routeId) {
    return _repository.getRouteById(routeId);
  }

  Future<List<Stop>> getStopsForRoute(String routeId, {int? directionId}) {
    return _repository.getStopsForRoute(routeId, directionId: directionId);
  }
}
