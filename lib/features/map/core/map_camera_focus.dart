import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/maps/map_helper.dart';
import '../../vehicles/domain/entities/vehicle.dart';

/// Camera action requested after filter apply or navigation to the map.
enum MapCameraFocusMode { singleVehicle, fitVehicles }

/// Describes how [LiveMapScreen] should move the camera after filter/navigation.
class MapCameraFocusRequest {
  const MapCameraFocusRequest._({
    required this.mode,
    this.vehicleId,
    this.vehicleIds = const {},
  });

  const MapCameraFocusRequest.single(String vehicleId)
      : this._(
          mode: MapCameraFocusMode.singleVehicle,
          vehicleId: vehicleId,
        );

  const MapCameraFocusRequest.fitVehicles(Set<String> vehicleIds)
      : this._(
          mode: MapCameraFocusMode.fitVehicles,
          vehicleIds: vehicleIds,
        );

  final MapCameraFocusMode mode;
  final String? vehicleId;
  final Set<String> vehicleIds;
}

/// Focuses the map on one vehicle at fleet-detail zoom.
CameraUpdate? cameraUpdateForVehicle(
  VehicleEntity vehicle, {
  double zoom = 16.2,
}) {
  if (vehicle.latitude == 0 && vehicle.longitude == 0) return null;
  return CameraUpdate.newCameraPosition(
    CameraPosition(
      target: LatLng(vehicle.latitude, vehicle.longitude),
      zoom: zoom,
    ),
  );
}

/// Fits the camera to show all [vehicles] with map chrome padding.
CameraUpdate? cameraUpdateFitVehicles(
  List<VehicleEntity> vehicles, {
  double padding = 120,
}) {
  final pts = vehicles
      .where((v) => v.latitude != 0 || v.longitude != 0)
      .map((v) => LatLng(v.latitude, v.longitude))
      .toList();
  if (pts.isEmpty) return null;
  if (pts.length == 1) {
    final v = vehicles.firstWhere(
      (e) => e.latitude != 0 || e.longitude != 0,
    );
    return cameraUpdateForVehicle(v);
  }
  return MapHelper.fitPoints(pts, padding: padding);
}
