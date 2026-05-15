import 'dart:math' as math;

import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/maps/map_config.dart';
import '../../../vehicles/domain/entities/vehicle.dart';

/// One spatial bucket on the live map — either a single vehicle or many (cluster).
class LiveMapClusterBucket {
  LiveMapClusterBucket({
    required this.center,
    required this.members,
  });

  final LatLng center;
  final List<VehicleEntity> members;

  bool get isCluster => members.length > 1;
}

double _gridStepDegrees(double zoomLevel) {
  if (zoomLevel >= MapConfig.clusterZoomThreshold) return 0;
  final delta = MapConfig.clusterZoomThreshold - zoomLevel;
  return 0.014 * math.pow(2, delta / 2.4);
}

bool _hasPosition(VehicleEntity v) =>
    v.latitude != 0 || v.longitude != 0;

/// Builds cluster buckets for the current zoom level.
///
/// Selected vehicle is always emitted as its own bucket (never absorbed into a
/// distant cluster) so the navigation-style car marker stays usable.
List<LiveMapClusterBucket> buildLiveMapClusterBuckets({
  required List<VehicleEntity> vehicles,
  required double zoomLevel,
  String? selectedVehicleId,
}) {
  final valid = vehicles.where(_hasPosition).toList();

  VehicleEntity? selected;
  if (selectedVehicleId != null) {
    for (final v in valid) {
      if (v.id == selectedVehicleId) {
        selected = v;
        break;
      }
    }
  }

  final step = _gridStepDegrees(zoomLevel);
  if (step <= 0) {
    return valid
        .map(
          (v) => LiveMapClusterBucket(
            center: LatLng(v.latitude, v.longitude),
            members: [v],
          ),
        )
        .toList();
  }

  final withoutSelected = selected != null
      ? valid.where((v) => v.id != selected!.id).toList()
      : valid;

  final buckets = <String, List<VehicleEntity>>{};
  for (final v in withoutSelected) {
    final gy = (v.latitude / step).floor();
    final gx = (v.longitude / step).floor();
    final key = '$gy|$gx';
    buckets.putIfAbsent(key, () => []).add(v);
  }

  final out = <LiveMapClusterBucket>[];
  for (final list in buckets.values) {
    if (list.length == 1) {
      final v = list.single;
      out.add(LiveMapClusterBucket(
        center: LatLng(v.latitude, v.longitude),
        members: [v],
      ));
    } else {
      final lat =
          list.fold<double>(0, (s, v) => s + v.latitude) / list.length;
      final lng =
          list.fold<double>(0, (s, v) => s + v.longitude) / list.length;
      out.add(LiveMapClusterBucket(
        center: LatLng(lat, lng),
        members: list,
      ));
    }
  }

  if (selected != null && _hasPosition(selected)) {
    out.add(LiveMapClusterBucket(
      center: LatLng(selected.latitude, selected.longitude),
      members: [selected],
    ));
  }

  return out;
}
