import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../datasources/vehicle_remote_datasource.dart';
import '../../../../shared/mock/mock_data.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  const VehicleRepositoryImpl(this._dataSource);

  final VehicleRemoteDataSource _dataSource;

  @override
  Future<List<VehicleEntity>> getVehicles() async {
    try {
      final models = await _dataSource.getVehicles();
      return models.map((m) => m.toEntity()).toList();
    } catch (_) {
      return MockData.vehicles;
    }
  }

  @override
  Future<VehicleEntity> getVehicle(String id) async {
    try {
      final model = await _dataSource.getVehicle(id);
      return model.toEntity();
    } catch (_) {
      return MockData.vehicles.firstWhere(
        (v) => v.id == id,
        orElse: () => MockData.vehicles.first,
      );
    }
  }

  @override
  Future<VehicleEntity> getVehicleLive(String id) async {
    try {
      final model = await _dataSource.getVehicleLive(id);
      return model.toEntity();
    } catch (_) {
      return getVehicle(id);
    }
  }
}
