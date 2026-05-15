import '../../core/route_intelligence_thresholds.dart';

/// Contract for **central** persistence of Route Intelligence thresholds on the
/// platform `attributes` maps (device / group / user). Local prefs remain the
/// Phase 6H `SharedPreferences` layer (`route_intel_local_prefs_writer.dart`).
///
/// **Phase 6J:** vehicle [saveVehicleThresholds] / [clearVehicleThresholds] are
/// implemented (guarded device GET → merge → PUT). Group/user methods throw
/// [UnsupportedError] until a later phase.
///
/// Docs: `docs/route_intelligence_thresholds_write_policy.md`
abstract interface class RouteIntelligenceThresholdsWriteRepository {
  /// Replaces or sets all `elmo.route.*` keys on the device after read-merge.
  Future<void> saveVehicleThresholds({
    required String vehicleId,
    required RouteIntelligenceThresholds thresholds,
  });

  /// Drops device-level Route Intelligence overrides only (other attributes unchanged).
  Future<void> clearVehicleThresholds({required String vehicleId});

  Future<void> saveGroupThresholds({
    required int groupId,
    required RouteIntelligenceThresholds thresholds,
  });

  Future<void> clearGroupThresholds({required int groupId});

  Future<void> saveUserThresholds({
    required String userId,
    required RouteIntelligenceThresholds thresholds,
  });

  Future<void> clearUserThresholds({required String userId});
}
