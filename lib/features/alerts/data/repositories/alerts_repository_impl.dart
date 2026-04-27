import '../../domain/entities/alert.dart';
import '../../domain/repositories/alerts_repository.dart';
import '../datasources/alerts_remote_datasource.dart';

class AlertsRepositoryImpl implements AlertsRepository {
  const AlertsRepositoryImpl(this._dataSource);

  final AlertsRemoteDataSource _dataSource;

  @override
  Future<List<AlertEntity>> getAlerts({
    int page = 1,
    int pageSize = 20,
  }) async {
    final models = await _dataSource.getAlerts(page: page, pageSize: pageSize);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<AlertEntity>> getSmartAlerts() async {
    final models = await _dataSource.getSmartAlerts();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<AlertEntity>> getVehicleAlerts(String vehicleId) async {
    final models = await _dataSource.getVehicleAlerts(vehicleId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<void> markAsRead(String alertId) async {
    await _dataSource.markAsRead(alertId);
  }
}
