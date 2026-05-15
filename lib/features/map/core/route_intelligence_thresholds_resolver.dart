import '../../vehicles/domain/entities/vehicle.dart';
import 'route_intelligence_threshold_resolution.dart';
import 'route_intelligence_thresholds.dart';

VehicleEntity? _resolveVehicle({
  required String vehicleId,
  VehicleEntity? liveVehicle,
  List<VehicleEntity>? fleet,
}) {
  if (liveVehicle != null && liveVehicle.id == vehicleId) {
    return liveVehicle;
  }
  if (fleet != null) {
    for (final x in fleet) {
      if (x.id == vehicleId) return x;
    }
  }
  return null;
}

/// Pure resolution for [routeIntelligenceThresholdsForVehicleProvider] —
/// testable without HTTP / Riverpod.
///
/// [liveVehicle] is preferred when it matches [vehicleId], else scans [fleet].
///
/// Merge order (**strongest last**): `defaults` → **[localAttributes]** →
/// **[userAttributes]** → **[groupAttributes]** → **[device.attributes]**.
///
/// Empty [vehicleId] or missing vehicle → **`RouteIntelligenceThresholds.defaults`**
/// (no user/local overlays — preserves Phase 6B behaviour).
RouteIntelligenceThresholds resolveRouteIntelligenceThresholdsForVehicle({
  required String vehicleId,
  VehicleEntity? liveVehicle,
  List<VehicleEntity>? fleet,
  Map<String, dynamic>? groupAttributes,
  Map<String, dynamic>? userAttributes,
  Map<String, dynamic>? localAttributes,
}) {
  if (vehicleId.isEmpty) {
    return RouteIntelligenceThresholds.defaults;
  }

  final v = _resolveVehicle(
    vehicleId: vehicleId,
    liveVehicle: liveVehicle,
    fleet: fleet,
  );
  if (v == null) {
    return RouteIntelligenceThresholds.defaults;
  }

  return RouteIntelligenceThresholds.mergeLayeredAttributes(
    localAttributes: localAttributes,
    userAttributes: userAttributes,
    groupAttributes: groupAttributes,
    deviceAttributes: v.deviceAttributes,
  );
}

/// Same inputs as [resolveRouteIntelligenceThresholdsForVehicle], plus a
/// [RouteIntelligenceThresholdResolution.sources] trace (Phase 6F).
RouteIntelligenceThresholdResolution
    resolveRouteIntelligenceThresholdsForVehicleWithSources({
  required String vehicleId,
  VehicleEntity? liveVehicle,
  List<VehicleEntity>? fleet,
  Map<String, dynamic>? groupAttributes,
  Map<String, dynamic>? userAttributes,
  Map<String, dynamic>? localAttributes,
}) {
  if (vehicleId.isEmpty) {
    return const RouteIntelligenceThresholdResolution(
      thresholds: RouteIntelligenceThresholds.defaults,
      sources: RouteIntelligenceThresholdSources.allDefaults,
    );
  }

  final v = _resolveVehicle(
    vehicleId: vehicleId,
    liveVehicle: liveVehicle,
    fleet: fleet,
  );
  if (v == null) {
    return const RouteIntelligenceThresholdResolution(
      thresholds: RouteIntelligenceThresholds.defaults,
      sources: RouteIntelligenceThresholdSources.allDefaults,
    );
  }

  return RouteIntelligenceThresholdResolution.mergeLayeredAttributesWithSources(
    localAttributes: localAttributes,
    userAttributes: userAttributes,
    groupAttributes: groupAttributes,
    deviceAttributes: v.deviceAttributes,
  );
}
