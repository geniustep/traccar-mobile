import '../../domain/entities/alert.dart';
import '../../domain/repositories/alerts_repository.dart';
import '../datasources/alerts_remote_datasource.dart';

class AlertsRepositoryImpl implements AlertsRepository {
  const AlertsRepositoryImpl(this._dataSource);

  final AlertsRemoteDataSource _dataSource;

  @override
  Future<List<AlertEntity>> getAlerts({
    String status = 'all',
    int limit = 50,
    int offset = 0,
    int? deviceId,
    DateTime? from,
    DateTime? to,
  }) async {
    final models = await _dataSource.getAlerts(
      status: status,
      limit: limit,
      offset: offset,
      deviceId: deviceId,
      from: from,
      to: to,
    );
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<int> getUnreadCount() => _dataSource.getUnreadCount();

  @override
  Future<AlertEntity> getAlertById(int id) async {
    final model = await _dataSource.getAlertById(id);
    return model.toEntity();
  }

  @override
  Future<void> markAlertRead(int id) => _dataSource.markAlertRead(id);

  @override
  Future<void> markAllAlertsRead({DateTime? before}) =>
      _dataSource.markAllAlertsRead(before: before);

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
  Future<void> markAsRead(String alertId) => _dataSource.markAsRead(alertId);
}
