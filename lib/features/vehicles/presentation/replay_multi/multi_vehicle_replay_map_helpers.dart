import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/maps/map_helper.dart';
import '../../../map/data/datasources/route_datasource.dart';
import 'multi_vehicle_replay_model.dart';

/// Map camera / bounds helpers for multi-vehicle replay (Phase R7).
abstract final class MultiVehicleReplayMapHelpers {
  MultiVehicleReplayMapHelpers._();

  /// Padding so routes are not hidden under the bottom legend + controls.
  static const double fitPadding = 120;

  /// Minimum interval between auto-follow camera updates during playback.
  static const Duration autoFollowThrottle = Duration(milliseconds: 900);

  /// Collects positions for [fitBounds]: visible tracks' routes and/or live markers.
  static List<LatLng> positionsForFit({
    required List<MultiVehicleReplayTrack> tracks,
    required bool Function(String vehicleId) isVisible,
    Map<String, RoutePoint?>? markersAtCurrentTime,
    bool preferMarkersOnly = false,
  }) {
    final out = <LatLng>[];
    for (final t in tracks) {
      if (!isVisible(t.vehicleId)) continue;

      final marker = markersAtCurrentTime?[t.vehicleId];
      if (marker != null) {
        out.add(marker.position);
        if (preferMarkersOnly) continue;
      }

      if (!preferMarkersOnly) {
        for (final p in t.mapPoints) {
          out.add(p.position);
        }
      }
    }
    return out;
  }

  static int countVisible(
    List<MultiVehicleReplayTrack> tracks,
    bool Function(String vehicleId) isVisible,
  ) =>
      tracks.where((t) => isVisible(t.vehicleId)).length;

  static CameraUpdate? cameraUpdateForFit(List<LatLng> positions) {
    if (positions.isEmpty) return null;
    if (positions.length == 1) {
      return CameraUpdate.newLatLngZoom(positions.first, 14);
    }
    return MapHelper.fitPoints(positions, padding: fitPadding);
  }
}
