import '../../../../core/constants/route_intelligence_attribute_keys.dart';
import '../../../../core/error/app_exception.dart';
import '../../../vehicles/data/datasources/vehicle_device_gateway.dart';
import '../../core/route_intelligence_thresholds.dart';
import '../../domain/repositories/route_intelligence_thresholds_write_repository.dart';
import '../route_intelligence_attributes_patch.dart';

/// Phase 6J — central **vehicle-only** Route Intelligence writes on `device.attributes`.
///
/// Group / user methods intentionally throw [UnsupportedError] until a later phase.
class RouteIntelligenceThresholdsWriteRepositoryImpl
    implements RouteIntelligenceThresholdsWriteRepository {
  const RouteIntelligenceThresholdsWriteRepositoryImpl(this._devices);

  final VehicleDeviceGateway _devices;

  int _parseVehicleId(String vehicleId) {
    final t = vehicleId.trim();
    if (t.isEmpty) {
      throw const ValidationException(message: 'Invalid vehicle id.');
    }
    final id = int.tryParse(t);
    if (id == null) {
      throw const ValidationException(message: 'Invalid vehicle id.');
    }
    return id;
  }

  /// True when route-layer key values are unchanged (allows `int` vs `double` drift).
  bool _routeIntelLayerUnchanged(
    Map<String, dynamic> before,
    Map<String, dynamic> after,
  ) {
    for (final k in RouteIntelligenceAttributeKeys.allKeys) {
      if (!_routeValueEqual(before[k], after[k])) return false;
    }
    return true;
  }

  bool _routeValueEqual(Object? a, Object? b) {
    if (a == b) return true;
    if (a is num && b is num) return a.toDouble() == b.toDouble();
    return false;
  }

  bool _hasAnyRouteKeys(Map<String, dynamic> attrs) {
    for (final k in RouteIntelligenceAttributeKeys.allKeys) {
      if (attrs.containsKey(k)) return true;
    }
    return false;
  }

  void _assertPersistableNormalized(RouteIntelligenceThresholds n) {
    if (!n.stopSpeedEnterKmh.isFinite ||
        !n.stopSpeedExitKmh.isFinite ||
        !n.overspeedThresholdKmh.isFinite ||
        n.overspeedThresholdKmh <= 0 ||
        n.minStopDuration.inMilliseconds <= 0) {
      throw const ValidationException(message: 'Invalid threshold values.');
    }
  }

  @override
  Future<void> saveVehicleThresholds({
    required String vehicleId,
    required RouteIntelligenceThresholds thresholds,
  }) async {
    final id = _parseVehicleId(vehicleId);
    final normalized = thresholds.normalized();
    _assertPersistableNormalized(normalized);

    final rawDevice = await _devices.getDeviceJson(id);
    final device = Map<String, dynamic>.from(rawDevice);

    final existing = Map<String, dynamic>.from(
      device['attributes'] as Map? ?? {},
    );
    final patch = routeIntelThresholdsToAttributeMap(normalized);
    final merged = mergeRouteIntelligenceIntoAttributes(existing, patch);

    if (_routeIntelLayerUnchanged(existing, merged)) {
      return;
    }

    device['attributes'] = merged;
    await _devices.putDevice(device);
  }

  @override
  Future<void> clearVehicleThresholds({required String vehicleId}) async {
    final id = _parseVehicleId(vehicleId);

    final rawDevice = await _devices.getDeviceJson(id);
    final device = Map<String, dynamic>.from(rawDevice);

    final existing = Map<String, dynamic>.from(
      device['attributes'] as Map? ?? {},
    );
    if (!_hasAnyRouteKeys(existing)) {
      return;
    }

    final cleared = removeRouteIntelligenceKeysFromAttributes(existing);

    if (_routeIntelLayerUnchanged(existing, cleared)) {
      return;
    }

    device['attributes'] = cleared;
    await _devices.putDevice(device);
  }

  @override
  Future<void> saveGroupThresholds({
    required int groupId,
    required RouteIntelligenceThresholds thresholds,
  }) {
    throw UnsupportedError(
      'Group Route Intelligence writes are not implemented yet.',
    );
  }

  @override
  Future<void> clearGroupThresholds({required int groupId}) {
    throw UnsupportedError(
      'Group Route Intelligence writes are not implemented yet.',
    );
  }

  @override
  Future<void> saveUserThresholds({
    required String userId,
    required RouteIntelligenceThresholds thresholds,
  }) {
    throw UnsupportedError(
      'User Route Intelligence writes are not implemented yet.',
    );
  }

  @override
  Future<void> clearUserThresholds({required String userId}) {
    throw UnsupportedError(
      'User Route Intelligence writes are not implemented yet.',
    );
  }
}
