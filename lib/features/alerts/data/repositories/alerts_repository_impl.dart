import '../../domain/entities/alert.dart';
import '../../domain/repositories/alerts_repository.dart';
import '../datasources/alerts_remote_datasource.dart';
import '../../../../shared/mock/mock_data.dart';

class AlertsRepositoryImpl implements AlertsRepository {
  const AlertsRepositoryImpl(this._dataSource);

  final AlertsRemoteDataSource _dataSource;

  @override
  Future<List<AlertEntity>> getAlerts({int page = 1, int pageSize = 20}) async {
    try {
      final models = await _dataSource.getAlerts(page: page, pageSize: pageSize);
      return models.map((m) => m.toEntity()).toList();
    } catch (_) {
      return MockData.alerts;
    }
  }

  @override
  Future<List<AlertEntity>> getSmartAlerts() async {
    try {
      final models = await _dataSource.getSmartAlerts();
      return models.map((m) => m.toEntity()).toList();
    } catch (_) {
      return MockData.alerts.where((a) => a.isCritical).toList();
    }
  }

  @override
  Future<List<AlertEntity>> getVehicleAlerts(String vehicleId) async {
    try {
      final models = await _dataSource.getVehicleAlerts(vehicleId);
      return models.map((m) => m.toEntity()).toList();
    } catch (_) {
      return MockData.alerts.where((a) => a.vehicleId == vehicleId).toList();
    }
  }

  @override
  Future<void> markAsRead(String alertId) async {
    try {
      await _dataSource.markAsRead(alertId);
    } catch (_) {}
  }
}
