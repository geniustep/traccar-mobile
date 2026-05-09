import '../../../../core/api/traccar_endpoints.dart';
import '../../../../core/network/traccar_client.dart';
import '../models/maintenance_record_model.dart';

class MaintenanceRemoteDataSource {
  const MaintenanceRemoteDataSource(this._client);

  final TraccarClient _client;

  Future<List<MaintenanceRecordModel>> fetch({
    String? keyword,
    int? deviceId,
  }) async {
    final query = <String, dynamic>{
      if (keyword != null && keyword.trim().isNotEmpty) 'keyword': keyword.trim(),
      if (deviceId != null) 'deviceId': deviceId,
    };

    final rows = (await _client.get<List<Map<String, dynamic>>>(
      TraccarEndpoints.maintenance,
      query: query.isEmpty ? null : query,
      fromJson: (j) =>
          (j as List).whereType<Map<String, dynamic>>().toList(),
    )).getOrThrow();

    return rows.map(MaintenanceRecordModel.fromJson).toList();
  }

  Future<MaintenanceRecordModel> create(MaintenanceRecordModel model) async {
    final json = (await _client.post<Map<String, dynamic>>(
      TraccarEndpoints.maintenanceCreate,
      data: model.toCreatePayload(),
      fromJson: (j) => j as Map<String, dynamic>,
    )).getOrThrow();
    return MaintenanceRecordModel.fromJson(json);
  }

  Future<MaintenanceRecordModel> update(MaintenanceRecordModel model) async {
    final json = (await _client.put<Map<String, dynamic>>(
      TraccarEndpoints.maintenanceUpdate(model.id),
      data: model.toUpdatePayload(),
      fromJson: (j) => j as Map<String, dynamic>,
    )).getOrThrow();
    return MaintenanceRecordModel.fromJson(json);
  }

  Future<void> deleteRecord(int id) async =>
      (await _client.delete(TraccarEndpoints.maintenanceDelete(id)))
          .getOrThrow();
}
