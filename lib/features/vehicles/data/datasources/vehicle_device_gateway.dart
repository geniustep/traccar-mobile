/// Raw Traccar device JSON [GET]/[PUT] round-trip for safe `attributes` updates.
///
/// Implemented by [VehicleRemoteDataSource].
abstract interface class VehicleDeviceGateway {
  Future<Map<String, dynamic>> getDeviceJson(int deviceId);

  Future<void> putDevice(Map<String, dynamic> deviceJson);
}
