import '../entities/maintenance_record.dart';

abstract class MaintenanceRepository {
  Future<List<MaintenanceRecordEntity>> getRecords({String? keyword, int? deviceId});
  Future<MaintenanceRecordEntity> createRecord(MaintenanceRecordEntity draft);
  Future<MaintenanceRecordEntity> updateRecord(MaintenanceRecordEntity record);
  Future<void> deleteRecord(int id);
}
