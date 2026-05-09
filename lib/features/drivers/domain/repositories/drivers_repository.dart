import '../entities/driver.dart';

abstract class DriversRepository {
  Future<List<DriverEntity>> getDrivers({String? keyword});
  Future<DriverEntity?> getDriverById(int id);
  Future<DriverEntity> createDriver(DriverEntity draft);
  Future<DriverEntity> updateDriver(DriverEntity driver);
  Future<void> deleteDriver(int id);

  /// يضبط حقوق الربط التفاعلية وفق نقطة نقطة؛ يعتمد مستودع تنفيذه على نقطة طرفية الأذونات.
  Future<void> syncLinkedDevices({
    required int driverId,
    required List<int> desiredIds,
    required List<int> previousIds,
  });
}
