import '../entities/stop.dart';
import '../entities/route_entity.dart';
import '../entities/departure.dart';

abstract class GtfsRepository {
  Future<List<Stop>> searchStops(String query);
  Future<Stop?> getStopById(String stopId);
  Future<List<Stop>> getAllStops();
  Future<List<RouteEntity>> getAllRoutes();
  Future<List<RouteEntity>> getRoutesByType(int type);
  Future<RouteEntity?> getRouteById(String routeId);
  Future<List<Departure>> getScheduledDepartures(String stopId);
  Future<List<Stop>> getStopsForRoute(String routeId, {int? directionId});
  Future<List<int>> getDirectionsForRoute(String routeId);
  Future<String?> getHeadsignForDirection(String routeId, int directionId);
  Future<List<RouteEntity>> getRoutesForStop(String stopId);
  Future<bool> isFavorite(String stopId);
  Future<void> addFavorite(String stopId);
  Future<void> removeFavorite(String stopId);
  Future<List<String>> getFavoriteStopIds();
  Stream<List<String>> watchFavoriteStopIds();
}
