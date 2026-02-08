import '../entities/route_entity.dart';
import '../repositories/gtfs_repository.dart';

class GetRoutesForStop {
  final GtfsRepository _repository;

  GetRoutesForStop(this._repository);

  Future<List<RouteEntity>> call(String stopId) {
    return _repository.getRoutesForStop(stopId);
  }
}
