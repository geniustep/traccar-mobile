import '../../../../core/api/traccar_endpoints.dart';
import '../../../../core/network/traccar_client.dart';
import '../models/geofence_model.dart';

class GeofencesRemoteDataSource {
  const GeofencesRemoteDataSource(this._client);

  final TraccarClient _client;

  /// Traccar returns HTTP 200 with an empty body for some `POST /permissions` calls.
  static Map<String, dynamic> _permissionResponse(dynamic json) {
    if (json is Map<String, dynamic>) return json;
    if (json is Map) return Map<String, dynamic>.from(json);
    return <String, dynamic>{};
  }

  Future<List<GeofenceModel>> fetchGeofences() async {
    final rows = (await _client.get<List<Map<String, dynamic>>>(
      TraccarEndpoints.geofences,
      fromJson: (j) =>
          (j as List).whereType<Map<String, dynamic>>().toList(),
    )).getOrThrow();
    return rows.map(GeofenceModel.fromJson).toList();
  }

  Future<GeofenceModel> createGeofence(GeofenceModel model) async {
    final json = (await _client.post<Map<String, dynamic>>(
      TraccarEndpoints.geofenceCreate,
      data: model.toCreateJson(),
      fromJson: (j) => j as Map<String, dynamic>,
    )).getOrThrow();
    return GeofenceModel.fromJson(json);
  }

  Future<GeofenceModel> updateGeofence(GeofenceModel model) async {
    final json = (await _client.put<Map<String, dynamic>>(
      TraccarEndpoints.geofenceUpdate(model.id),
      data: model.toJson(),
      fromJson: (j) => j as Map<String, dynamic>,
    )).getOrThrow();
    return GeofenceModel.fromJson(json);
  }

  Future<void> deleteGeofence(int id) async {
    (await _client.delete(TraccarEndpoints.geofenceDelete(id))).getOrThrow();
  }

  /// Links or unlinks devices to a geofence using `POST/DELETE /permissions`.
  Future<void> setDeviceGeofenceLinks({
    required int geofenceId,
    required List<int> desiredDeviceIds,
    required List<int> previousDeviceIds,
  }) async {
    final desired = desiredDeviceIds.toSet();
    final prev = previousDeviceIds.toSet();
    for (final id in desired.difference(prev)) {
      (await _client.post<Map<String, dynamic>>(
        TraccarEndpoints.permissionCreate,
        data: {'deviceId': id, 'geofenceId': geofenceId},
        fromJson: _permissionResponse,
      )).getOrThrow();
    }
    for (final id in prev.difference(desired)) {
      (await _client.delete(
        TraccarEndpoints.permissionDelete,
        data: {'deviceId': id, 'geofenceId': geofenceId},
      )).getOrThrow();
    }
  }

  /// Creates a Traccar notification and links it to the current user, geofence,
  /// and the given devices. Uses `"web"` notificator (always available).
  Future<int> createGeofenceNotification({
    required int userId,
    required int geofenceId,
    required String type,
    required List<int> deviceIds,
  }) async {
    final created = (await _client.post<Map<String, dynamic>>(
      TraccarEndpoints.notificationCreate,
      data: {
        'type': type,
        'always': true,
        'notificators': 'web',
        'attributes': <String, dynamic>{},
      },
      fromJson: (j) => j as Map<String, dynamic>,
    )).getOrThrow();
    final notificationId = (created['id'] as num).toInt();

    Future<void> perm(Map<String, dynamic> body) async {
      (await _client.post<Map<String, dynamic>>(
        TraccarEndpoints.permissionCreate,
        data: body,
        fromJson: _permissionResponse,
      )).getOrThrow();
    }

    await perm({'userId': userId, 'notificationId': notificationId});
    await perm({'notificationId': notificationId, 'geofenceId': geofenceId});
    for (final d in deviceIds) {
      await perm({'notificationId': notificationId, 'deviceId': d});
    }

    return notificationId;
  }

  /// Reads optional notification ids stored by the app on the geofence.
  static (int?, int?) parseStoredNotificationIds(Map<String, dynamic> attrs) {
    int? p(String key) {
      final v = attrs[key];
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    return (p('elmoNotifyEnterId'), p('elmoNotifyExitId'));
  }
}
