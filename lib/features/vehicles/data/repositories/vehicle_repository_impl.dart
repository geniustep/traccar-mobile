import '../../domain/entities/vehicle.dart';
import '../../domain/repositories/vehicle_repository.dart';
import '../datasources/vehicle_remote_datasource.dart';

class VehicleRepositoryImpl implements VehicleRepository {
  const VehicleRepositoryImpl(this._dataSource);

  final VehicleRemoteDataSource _dataSource;

  @override
  Future<List<VehicleEntity>> getVehicles() async {
    final models = await _dataSource.getVehicles();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<VehicleEntity> getVehicle(String id) async {
    final model = await _dataSource.getVehicle(id);
    return model.toEntity();
  }

  @override
  Future<VehicleEntity> getVehicleLive(String id) async {
    final model = await _dataSource.getVehicleLive(id);
    return model.toEntity();
  }
}
