import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elmogps/features/auth/presentation/providers/auth_provider.dart'
    show currentUserProvider;
import 'package:elmogps/shared/providers/core_providers.dart';
import 'package:elmogps/features/vehicles/domain/entities/vehicle.dart';
import 'package:elmogps/features/vehicles/presentation/providers/vehicles_provider.dart';
import '../../core/route_intelligence_threshold_resolution.dart';
import '../../core/route_intelligence_thresholds_resolver.dart';
import '../../core/route_intelligence_thresholds.dart';
import '../../data/route_intel_local_prefs_reader.dart';
import 'route_intel_group_attributes_map_provider.dart';
import 'tracking_provider.dart';

/// Pure app defaults — **no** user/local merge (unchanged for legacy callers).
///
/// Prefer [routeIntelligenceGlobalThresholdsProvider] when you need **global**
/// context (user + local + defaults). See `docs/route_intelligence_thresholds_source.md`.
final routeIntelligenceThresholdsProvider =
    Provider<RouteIntelligenceThresholds>((ref) {
  return RouteIntelligenceThresholds.defaults;
});

/// **Global context** — for settings preview, generic reports without a vehicle id, etc.
///
/// Merge order (internal): **`defaults` → local prefs → `user.attributes`**.
/// Effective per field: **user** beats **local** beats **defaults**. No device/group.
///
/// Does not throw; while [SharedPreferences] is still loading, the local layer is omitted.
final routeIntelligenceGlobalThresholdsProvider =
    Provider<RouteIntelligenceThresholds>((ref) {
  final layers = _readRouteIntelUserAndLocalLayers(ref);
  return RouteIntelligenceThresholds.mergeGlobalContextAttributes(
    localAttributes: layers.localAttributes,
    userAttributes: layers.userAttributes,
  );
});

/// Global context + **per-field source trace** (Phase 6F). Same merge as
/// [routeIntelligenceGlobalThresholdsProvider]; use this for settings preview / debug.
final routeIntelligenceGlobalThresholdsResolutionProvider =
    Provider<RouteIntelligenceThresholdResolution>((ref) {
  final layers = _readRouteIntelUserAndLocalLayers(ref);
  return RouteIntelligenceThresholdResolution
      .mergeGlobalContextAttributesWithSources(
    localAttributes: layers.localAttributes,
    userAttributes: layers.userAttributes,
  );
});

({Map<String, dynamic>? userAttributes, Map<String, dynamic>? localAttributes})
    _readRouteIntelUserAndLocalLayers(Ref ref) {
  final user = ref.watch(currentUserProvider);
  final userAttributes =
      user == null || user.attributes.isEmpty ? null : user.attributes;

  final prefsAsync = ref.watch(sharedPreferencesProvider);
  final localAttributes = prefsAsync.whenOrNull(
    data: routeIntelLocalAttributesFromSharedPreferences,
  );

  return (
    userAttributes: userAttributes,
    localAttributes: localAttributes,
  );
}

int? _parseGroupId(VehicleEntity? v) {
  final g = v?.groupId;
  if (g == null || g.isEmpty) return null;
  return int.tryParse(g);
}

/// Route analysis thresholds — **vehicle context** (Phase 6D):
/// **`defaults` → local → `user.attributes` → `group.attributes` → `device.attributes`**
/// (device strongest per field).
///
/// Group map loads via [routeIntelGroupAttributesMapProvider] **only when**
/// the resolved vehicle has a valid numeric `groupId`.
///
/// **`vehicleId` empty:** **`RouteIntelligenceThresholds.defaults`** only (no user/local;
/// use [routeIntelligenceGlobalThresholdsProvider] when you need user/local without a vehicle).
///
/// Display thresholds stay in `MapZoomPolicy`, not here.
final routeIntelligenceThresholdsForVehicleProvider = Provider.autoDispose
    .family<RouteIntelligenceThresholds, String>((ref, vehicleId) {
  if (vehicleId.isEmpty) {
    return RouteIntelligenceThresholds.defaults;
  }

  final liveAsync = ref.watch(liveVehicleProvider(vehicleId));
  final fleetAsync = ref.watch(vehiclesListProvider);

  final live = liveAsync.valueOrNull;
  final fleet = fleetAsync.valueOrNull;

  final v = live != null && live.id == vehicleId
      ? live
      : _resolveVehicleFromFleet(vehicleId, fleet);

  final gid = _parseGroupId(v);
  Map<String, dynamic>? groupAttrs;
  if (gid != null) {
    final groupsAsync = ref.watch(routeIntelGroupAttributesMapProvider);
    groupAttrs = groupsAsync.whenOrNull(
      data: (m) => m[gid],
    );
  }

  final layers = _readRouteIntelUserAndLocalLayers(ref);

  return resolveRouteIntelligenceThresholdsForVehicle(
    vehicleId: vehicleId,
    liveVehicle: live,
    fleet: fleet,
    groupAttributes: groupAttrs,
    userAttributes: layers.userAttributes,
    localAttributes: layers.localAttributes,
  );
});

/// Vehicle context thresholds plus [RouteIntelligenceThresholdResolution.sources].
///
/// [RouteIntelligenceThresholdResolution.thresholds] matches
/// [routeIntelligenceThresholdsForVehicleProvider] for the same [vehicleId].
final routeIntelligenceThresholdsResolutionForVehicleProvider =
    Provider.autoDispose.family<RouteIntelligenceThresholdResolution, String>(
        (ref, vehicleId) {
  if (vehicleId.isEmpty) {
    return const RouteIntelligenceThresholdResolution(
      thresholds: RouteIntelligenceThresholds.defaults,
      sources: RouteIntelligenceThresholdSources.allDefaults,
    );
  }

  final liveAsync = ref.watch(liveVehicleProvider(vehicleId));
  final fleetAsync = ref.watch(vehiclesListProvider);

  final live = liveAsync.valueOrNull;
  final fleet = fleetAsync.valueOrNull;

  final v = live != null && live.id == vehicleId
      ? live
      : _resolveVehicleFromFleet(vehicleId, fleet);

  final gid = _parseGroupId(v);
  Map<String, dynamic>? groupAttrs;
  if (gid != null) {
    final groupsAsync = ref.watch(routeIntelGroupAttributesMapProvider);
    groupAttrs = groupsAsync.whenOrNull(
      data: (m) => m[gid],
    );
  }

  final layers = _readRouteIntelUserAndLocalLayers(ref);

  return resolveRouteIntelligenceThresholdsForVehicleWithSources(
    vehicleId: vehicleId,
    liveVehicle: live,
    fleet: fleet,
    groupAttributes: groupAttrs,
    userAttributes: layers.userAttributes,
    localAttributes: layers.localAttributes,
  );
});

VehicleEntity? _resolveVehicleFromFleet(
  String vehicleId,
  List<VehicleEntity>? fleet,
) {
  if (fleet == null) return null;
  for (final x in fleet) {
    if (x.id == vehicleId) return x;
  }
  return null;
}
