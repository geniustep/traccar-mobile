import '../../domain/entities/driver.dart';
import '../../domain/repositories/drivers_repository.dart';
import '../datasources/drivers_remote_datasource.dart';
import '../models/driver_model.dart';

class DriversRepositoryImpl implements DriversRepository {
  DriversRepositoryImpl(this._dataSource);

  final DriversRemoteDataSource _dataSource;

    DriverModel _toModel(DriverEntity e) =>
      DriverModel(
        id: e.id,
        name: e.name,
        uniqueId: e.uniqueId,
        attributes: const {},
        linkedDeviceIds: const [],
      ).copyFromEntity(e);

  @override
  Future<List<DriverEntity>> getDrivers({String? keyword}) async =>
      (await _dataSource.fetchDrivers(keyword: keyword))
          .map((m) => m.toEntity())
          .toList();

  @override
  Future<DriverEntity?> getDriverById(int id) async {
    try {
      return (await _dataSource.fetchDriverById(id)).toEntity();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<DriverEntity> createDriver(DriverEntity draft) async =>
      (await _dataSource.createDriver(_toModel(draft))).toEntity();

  @override
  Future<DriverEntity> updateDriver(DriverEntity driver) async =>
      (await _dataSource.updateDriver(_toModel(driver))).toEntity();

  @override
  Future<void> deleteDriver(int id) => _dataSource.deleteDriver(id);

  @override
  Future<void> syncLinkedDevices({
    required int driverId,
    required List<int> desiredIds,
    required List<int> previousIds,
  }) =>
      _dataSource.syncDeviceLinks(
        driverId: driverId,
        desired: desiredIds,
        previous: previousIds,
      );
}
