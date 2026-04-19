import '../entities/alert.dart';

abstract interface class AlertsRepository {
  Future<List<AlertEntity>> getAlerts({int page, int pageSize});
  Future<List<AlertEntity>> getSmartAlerts();
  Future<List<AlertEntity>> getVehicleAlerts(String vehicleId);
  Future<void> markAsRead(String alertId);
}
