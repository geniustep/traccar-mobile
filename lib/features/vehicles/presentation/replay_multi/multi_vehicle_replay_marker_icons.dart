import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/logging/app_logger.dart';
import '../../../../core/maps/marker_builder.dart';
import '../../../map/core/vehicle_marker_factory.dart';
import 'multi_vehicle_replay_model.dart';
import 'multi_vehicle_replay_ui.dart';

/// Cached replay marker bitmaps per color index and label mode.
class MultiVehicleReplayMarkerIcons {
  MultiVehicleReplayMarkerIcons();

  final Map<String, BitmapDescriptor> _cache = {};

  String _cacheKey(int colorIndex, bool withLabels) =>
      '${colorIndex}_${withLabels ? 'lbl' : 'car'}';

  BitmapDescriptor? iconFor(int colorIndex, {required bool withLabels}) =>
      _cache[_cacheKey(colorIndex, withLabels)];

  /// Loads icons for each distinct [colorIndex] among tracks with data.
  Future<void> loadForTracks(
    List<MultiVehicleReplayTrack> tracks, {
    required bool withLabels,
  }) async {
    final indices = <int>{};
    for (final t in tracks) {
      if (t.hasData) indices.add(t.colorIndex);
    }

    var ready = 0;
    for (final index in indices) {
      final key = _cacheKey(index, withLabels);
      if (_cache.containsKey(key)) {
        ready++;
        continue;
      }
      final color = MultiVehicleReplayColors.forIndex(index);
      final track = tracks.firstWhere((t) => t.colorIndex == index);
      try {
        _cache[key] = withLabels
            ? await MarkerBuilder.customCircleMarker(
                label: MultiVehicleReplayUi.markerInitials(
                  track.name,
                  track.vehicleId,
                ),
                backgroundColor: color,
                size: 46,
              )
            : await VehicleMarkerFactory.topDownCarNorthUp(
                bodyColor: color,
                size: 56,
              );
        ready++;
      } catch (e, st) {
        AppLogger.replay('replay_vehicle_marker_icon_failed error=$e');
        debugPrint('$st');
        _cache[key] = BitmapDescriptor.defaultMarkerWithHue(
          fallbackHueForIndex(index),
        );
        ready++;
      }
    }
    AppLogger.replay('replay_vehicle_marker_icon_ready count=$ready');
  }

  static double fallbackHueForIndex(int index) {
    const hues = [
      BitmapDescriptor.hueBlue,
      BitmapDescriptor.hueGreen,
      BitmapDescriptor.hueOrange,
      BitmapDescriptor.hueViolet,
      BitmapDescriptor.hueRed,
    ];
    return hues[index.clamp(0, hues.length - 1)];
  }

  void clear() => _cache.clear();
}
