import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/route_intelligence_thresholds.dart';
import '../providers/route_intelligence_thresholds_write_provider.dart';

/// Persists vehicle Route Intelligence overrides then refreshes dependent providers.
Future<void> saveVehicleRouteIntelCentral(
  WidgetRef ref, {
  required String vehicleId,
  required RouteIntelligenceThresholds thresholds,
}) async {
  await ref
      .read(routeIntelligenceThresholdsWriteRepositoryProvider)
      .saveVehicleThresholds(vehicleId: vehicleId, thresholds: thresholds);
  invalidateAfterVehicleRouteIntelCentralWrite(ref, vehicleId);
}

/// Clears `elmo.route.*` on the device only, then refreshes dependent providers.
Future<void> clearVehicleRouteIntelCentral(
  WidgetRef ref, {
  required String vehicleId,
}) async {
  await ref
      .read(routeIntelligenceThresholdsWriteRepositoryProvider)
      .clearVehicleThresholds(vehicleId: vehicleId);
  invalidateAfterVehicleRouteIntelCentralWrite(ref, vehicleId);
}

/// Logs failures in debug builds only — UI must show generic messages.
void logVehicleRouteIntelCentralError(Object error, StackTrace stackTrace) {
  debugPrint('Vehicle Route Intel central write failed: $error\n$stackTrace');
}
