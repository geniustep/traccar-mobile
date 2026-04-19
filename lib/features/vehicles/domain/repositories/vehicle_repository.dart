import '../entities/vehicle.dart';

abstract interface class VehicleRepository {
  Future<List<VehicleEntity>> getVehicles();
  Future<VehicleEntity> getVehicle(String id);
  Future<VehicleEntity> getVehicleLive(String id);
}
