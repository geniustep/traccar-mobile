import '../entities/geofence.dart';

abstract class GeofencesRepository {
  Future<List<GeofenceEntity>> getGeofences();

  Future<GeofenceEntity> createGeofence({
    required String name,
    String? description,
    required String areaWkt,
    required List<int> deviceIds,
    required int fillColorArgb,
  });

  Future<GeofenceEntity> updateGeofence({
    required GeofenceEntity current,
    required String name,
    String? description,
    required String areaWkt,
    required List<int> deviceIds,
    required int fillColorArgb,
  });

  Future<void> deleteGeofence(int id);

  /// Returns created notification ids (enter, exit). Either may be null if not requested.
  Future<({int? enter, int? exit})> ensureSmartNotifications({
    required int userId,
    required GeofenceEntity geofence,
    required List<int> deviceIds,
    bool createEnter = false,
    bool createExit = false,
  });
}
