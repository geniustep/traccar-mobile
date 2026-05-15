import '../../../auth/domain/entities/user_entity.dart';
import '../../../../core/models/user_role.dart';
import '../../core/route_intelligence_threshold_resolution.dart';

/// Central (platform) Route Intelligence editing for **one vehicle** —
/// allowed for non-readonly users whose app role is not [UserRole.viewer].
///
/// See Phase 6K: `readonly` and viewer cannot mutate `device.attributes`.
bool routeIntelCanEditVehicleCentralThresholds(UserEntity? user) {
  if (user == null) return false;
  if (user.readonly) return false;
  return user.appRole != UserRole.viewer;
}

/// True when at least one resolved field traces to the **device** layer
/// (i.e. this vehicle has `elmo.route.*` overrides on the device).
bool routeIntelResolutionHasDeviceOverride(
  RouteIntelligenceThresholdResolution r,
) {
  bool isDev(RouteIntelligenceThresholdSource s) =>
      s == RouteIntelligenceThresholdSource.device;
  final s = r.sources;
  return isDev(s.stopSpeedEnterKmhSource) ||
      isDev(s.stopSpeedExitKmhSource) ||
      isDev(s.minStopDurationSource) ||
      isDev(s.overspeedThresholdKmhSource) ||
      isDev(s.detectStopsSource) ||
      isDev(s.detectOverspeedSource) ||
      isDev(s.detectIgnitionSource);
}
