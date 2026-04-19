import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/alert_model.dart';

class AlertsRemoteDataSource {
  const AlertsRemoteDataSource(this._client);

  final DioClient _client;

  Future<List<AlertModel>> getAlerts({int page = 1, int pageSize = 20}) async {
    return _client.get<List<AlertModel>>(
      ApiConstants.alerts,
      queryParameters: {'page': page, 'pageSize': pageSize},
      fromJson: (data) => (data as List)
          .map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<AlertModel>> getSmartAlerts() async {
    return _client.get<List<AlertModel>>(
      ApiConstants.smartAlerts,
      fromJson: (data) => (data as List)
          .map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<List<AlertModel>> getVehicleAlerts(String vehicleId) async {
    return _client.get<List<AlertModel>>(
      ApiConstants.vehicleAlerts(vehicleId),
      fromJson: (data) => (data as List)
          .map((e) => AlertModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<void> markAsRead(String alertId) async {
    await _client.patch<void>('${ApiConstants.alerts}/$alertId/read');
  }
}
