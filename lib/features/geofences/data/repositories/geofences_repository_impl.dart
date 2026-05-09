import 'package:flutter/material.dart';

import '../../domain/entities/geofence.dart';
import '../../domain/repositories/geofences_repository.dart';
import '../datasources/geofences_remote_datasource.dart';
import '../models/geofence_model.dart';

class GeofencesRepositoryImpl implements GeofencesRepository {
  const GeofencesRepositoryImpl(this._ds);

  final GeofencesRemoteDataSource _ds;

  @override
  Future<List<GeofenceEntity>> getGeofences() async {
    final list = await _ds.fetchGeofences();
    return list.map((m) => m.toEntity()).toList();
  }

  @override
  Future<GeofenceEntity> createGeofence({
    required String name,
    String? description,
    required String areaWkt,
    required List<int> deviceIds,
    required int fillColorArgb,
  }) async {
    final attrs = GeofenceModel.attrsWithDevicesAndColor(
      {},
      deviceIds,
      Color(fillColorArgb),
    );
    final created = await _ds.createGeofence(
      GeofenceModel(
        id: 0,
        name: name,
        description: description,
        area: areaWkt,
        attributes: attrs,
      ),
    );
    await _ds.setDeviceGeofenceLinks(
      geofenceId: created.id,
      desiredDeviceIds: deviceIds,
      previousDeviceIds: const [],
    );
    return created.toEntity();
  }

  @override
  Future<GeofenceEntity> updateGeofence({
    required GeofenceEntity current,
    required String name,
    String? description,
    required String areaWkt,
    required List<int> deviceIds,
    required int fillColorArgb,
  }) async {
    final attrs = GeofenceModel.attrsWithDevicesAndColor(
      current.attributes,
      deviceIds,
      Color(fillColorArgb),
    );
    final model = GeofenceModel(
      id: current.id,
      name: name,
      description: description,
      area: areaWkt,
      calendarId: current.calendarId,
      attributes: attrs,
    );
    final updated = await _ds.updateGeofence(model);
    await _ds.setDeviceGeofenceLinks(
      geofenceId: current.id,
      desiredDeviceIds: deviceIds,
      previousDeviceIds: current.linkedDeviceIds,
    );
    return updated.toEntity();
  }

  @override
  Future<void> deleteGeofence(int id) => _ds.deleteGeofence(id);

  @override
  Future<({int? enter, int? exit})> ensureSmartNotifications({
    required int userId,
    required GeofenceEntity geofence,
    required List<int> deviceIds,
    bool createEnter = false,
    bool createExit = false,
  }) async {
    if (deviceIds.isEmpty || (!createEnter && !createExit)) {
      return (enter: null, exit: null);
    }

    int? enterId;
    int? exitId;
    final existing = GeofencesRemoteDataSource.parseStoredNotificationIds(
      geofence.attributes,
    );

    if (createEnter) {
      enterId = existing.$1 ??
          await _ds.createGeofenceNotification(
            userId: userId,
            geofenceId: geofence.id,
            type: 'geofenceEnter',
            deviceIds: deviceIds,
          );
    }

    if (createExit) {
      exitId = existing.$2 ??
          await _ds.createGeofenceNotification(
            userId: userId,
            geofenceId: geofence.id,
            type: 'geofenceExit',
            deviceIds: deviceIds,
          );
    }

    final newEnter = createEnter && existing.$1 == null;
    final newExit = createExit && existing.$2 == null;
    if (newEnter || newExit) {
      final attrs = Map<String, dynamic>.from(geofence.attributes);
      if (newEnter && enterId != null) attrs['elmoNotifyEnterId'] = enterId;
      if (newExit && exitId != null) attrs['elmoNotifyExitId'] = exitId;
      await _ds.updateGeofence(
        GeofenceModel(
          id: geofence.id,
          name: geofence.name,
          description: geofence.description,
          area: geofence.area,
          calendarId: geofence.calendarId,
          attributes: attrs,
        ),
      );
    }

    return (enter: enterId, exit: exitId);
  }
}
