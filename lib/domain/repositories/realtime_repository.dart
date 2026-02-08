import '../entities/vehicle.dart';
import '../entities/service_alert.dart';

abstract class RealtimeRepository {
  Future<Map<String, int>> getTripDelays();
  Future<List<Vehicle>> getVehiclePositions();
  Future<List<ServiceAlert>> getServiceAlerts();
}
