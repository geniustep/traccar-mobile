import '../../../core/models/traccar_position.dart';
import 'map_audit_logger.dart';
import '../../vehicles/domain/entities/vehicle.dart';
import 'traccar_units.dart';
import 'vehicle_status_resolver.dart';
import 'vehicle_status_thresholds.dart';

/// Merges REST [VehicleEntity] rows with the latest WebSocket [TraccarPosition].
class VehicleLiveMerger {
  VehicleLiveMerger._();

  static VehicleEntity mergeSocket(VehicleEntity base, TraccarPosition live) {
    final speedKmh = TraccarUnits.knotsToKmh(live.speed);
    final now = DateTime.now();
    final fixLocal = live.fixTime.toLocal();
    final age = now.difference(fixLocal);
    final posOk = live.valid &&
        (live.latitude.abs() > 1e-6 || live.longitude.abs() > 1e-6);
    if (!posOk) {
      return base.copyWith(
        status: 'offline',
        lastUpdate: live.fixTime,
        ignition: live.ignitionOn,
      );
    }

    final stale = age > VehicleStatusThresholds.maxPositionAgeForLive;

    final status = stale
        ? 'offline'
        : VehicleStatusResolver.fromLiveSocket(
            speedKmh: speedKmh,
            ignitionOn: live.ignitionOn,
          );

    return base.copyWith(
      latitude: live.latitude,
      longitude: live.longitude,
      speed: speedKmh,
      status: status,
      lastUpdate: live.fixTime,
      ignition: live.ignitionOn,
      batteryVoltage: live.batteryVoltage,
      fuelLevel: live.fuelLevel,
      course: live.course,
      address: live.address ?? base.address,
    );
  }

  /// Applies live map when [positions] contains a newer fix for [vehicle.id].
  static VehicleEntity mergeIfPresent(
    VehicleEntity vehicle,
    Map<int, TraccarPosition> positions,
  ) {
    final deviceId = int.tryParse(vehicle.id);
    if (deviceId == null) return vehicle;

    final live = positions[deviceId];
    if (live == null) return vehicle;

    final lastFix = vehicle.lastUpdate;
    if (lastFix != null && live.fixTime.isBefore(lastFix)) {
      MapAuditLogger.staleIgnored(
        screen: 'VehicleLiveMerger',
        deviceId: '$deviceId',
        incomingFix: live.fixTime,
        currentFix: lastFix,
      );
      return vehicle;
    }

    return mergeSocket(vehicle, live);
  }

  static List<VehicleEntity> mergeFleet(
    List<VehicleEntity> vehicles,
    Map<int, TraccarPosition> positions,
  ) {
    if (positions.isEmpty) return vehicles;

    return vehicles.map((v) => mergeIfPresent(v, positions)).toList();
  }
}
