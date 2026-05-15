import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../vehicles/domain/entities/vehicle.dart';
import '../../core/vehicle_marker_factory.dart';
import '../../core/vehicle_marker_style.dart';

/// Backwards-compatible entry points — implementations live in [VehicleMarkerFactory].
class LiveMapMarkerBitmaps {
  LiveMapMarkerBitmaps._();

  static Color pinColor(VehicleEntity v, Set<String> alertVehicleIds) =>
      VehicleMarkerFactory.pinBodyColor(
        v: v,
        alertVehicleIds: alertVehicleIds,
        style: VehicleMarkerStyle.fleet,
      );

  static Color clusterColorForMembers(
    List<VehicleEntity> members,
    Set<String> alertVehicleIds,
  ) =>
      VehicleMarkerFactory.clusterColorForMembers(members, alertVehicleIds);

  static Future<BitmapDescriptor> clusterDisc({
    required int count,
    required Color fill,
    required Color border,
  }) =>
      VehicleMarkerFactory.clusterDisc(
        count: count,
        fill: fill,
        border: border,
      );

  static Future<BitmapDescriptor> topDownCar({
    required Color bodyColor,
    double courseDeg = 0,
    double size = 80,
  }) =>
      VehicleMarkerFactory.topDownCar(
        bodyColor: bodyColor,
        courseDeg: courseDeg,
        size: size,
      );
}
