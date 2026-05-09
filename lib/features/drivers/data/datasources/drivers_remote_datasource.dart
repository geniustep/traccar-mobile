import '../../../../core/api/traccar_endpoints.dart';
import '../../../../core/network/traccar_client.dart';

import '../models/driver_model.dart';

class DriversRemoteDataSource {
  const DriversRemoteDataSource(this._client);

  final TraccarClient _client;

  static Map<String, dynamic> _permissionResponse(dynamic json) {
    if (json is Map<String, dynamic>) return json;
    if (json is Map) return Map<String, dynamic>.from(json);
    return <String, dynamic>{};
  }

  Future<List<DriverModel>> fetchDrivers({String? keyword}) async {
    final query = <String, dynamic>{
      if (keyword != null && keyword.trim().isNotEmpty)
        'keyword': keyword.trim(),
    };

    final rows = (await _client.get<List<Map<String, dynamic>>>(
      TraccarEndpoints.drivers,
      query: query.isEmpty ? null : query,
      fromJson: (j) =>
          (j as List).whereType<Map<String, dynamic>>().toList(),
    )).getOrThrow();

    return rows.map(DriverModel.fromJson).toList();
  }

  Future<DriverModel> fetchDriverById(int id) async {
    final res = await _client.get<Map<String, dynamic>>(
      TraccarEndpoints.driverById(id),
      fromJson: (j) => j as Map<String, dynamic>,
    );

    final data = res.valueOrNull;
    if (data != null &&
        data['id'] != null &&
        (data['id'] as num).toInt() == id) {
      return DriverModel.fromJson(data);
    }

    /// إن لم تدع نقطة واحدة ذلك، أو رُفض بحكم الصلاحية، ترجمة التجربة الموحدة تجمع القائمة.
    final fallback = await fetchDrivers();
    for (final d in fallback) {
      if (d.id == id) return d;
    }

    throw StateError(
      'تعذر تحميل بيانات السائق المراد بالمعرِّف المتاح لمستعملك؛ '
      'يُستخدم أخيرًا إسقاط حقوق طرفية خارجية؛ أعد المصادقة.',
    );
  }

  Future<DriverModel> createDriver(DriverModel model) async {
    final json = (await _client.post<Map<String, dynamic>>(
      TraccarEndpoints.driverCreate,
      data: model.toCreatePayload(),
      fromJson: (j) => j as Map<String, dynamic>,
    )).getOrThrow();

    return DriverModel.fromJson(json);
  }

  Future<DriverModel> updateDriver(DriverModel model) async {
    final json = (await _client.put<Map<String, dynamic>>(
      TraccarEndpoints.driverUpdate(model.id),
      data: model.toUpdatePayload(),
      fromJson: (j) => j as Map<String, dynamic>,
    )).getOrThrow();

    return DriverModel.fromJson(json);
  }

  Future<void> deleteDriver(int id) async =>
      (await _client.delete(TraccarEndpoints.driverDelete(id))).getOrThrow();

  Future<void> syncDeviceLinks({
    required int driverId,
    required Iterable<int> desired,
    required Iterable<int> previous,
  }) async {
    final desiredSet = desired.toSet();
    final prevSet = previous.toSet();

    for (final id in desiredSet.difference(prevSet)) {
      (await _client.post<Map<String, dynamic>>(
        TraccarEndpoints.permissionCreate,
        data: {'deviceId': id, 'driverId': driverId},
        fromJson: _permissionResponse,
      )).getOrThrow();
    }

    for (final id in prevSet.difference(desiredSet)) {
      (await _client.delete(
        TraccarEndpoints.permissionDelete,
        data: {'deviceId': id, 'driverId': driverId},
      )).getOrThrow();
    }
  }
}
