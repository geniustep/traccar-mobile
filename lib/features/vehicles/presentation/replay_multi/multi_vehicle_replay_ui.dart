import 'package:flutter/material.dart';

import 'multi_vehicle_replay_model.dart';

/// Pure UI helpers for multi-vehicle replay (Phase E). No I/O or timeline logic.
abstract final class MultiVehicleReplayUi {
  MultiVehicleReplayUi._();

  /// Short label for map badges and legend (avoids overflow).
  static String shortVehicleLabel(String name, String vehicleId) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      return vehicleId.length > 10
          ? '${vehicleId.substring(0, 9)}…'
          : vehicleId;
    }
    if (trimmed.length <= 12) return trimmed;
    return '${trimmed.substring(0, 11)}…';
  }

  /// Initials for circular fallback markers (max 2 chars).
  static String markerInitials(String name, String vehicleId) {
    final label = shortVehicleLabel(name, vehicleId);
    final parts =
        label.split(RegExp(r'[\s\-_]+')).where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
    }
    if (label.length >= 2) return label.substring(0, 2).toUpperCase();
    return label.isNotEmpty ? label[0].toUpperCase() : '?';
  }

  /// Rotate marker only when movement suggests a reliable heading.
  static bool shouldRotateMarker({required double speedKmh, double? course}) {
    if (speedKmh < 5) return false;
    if (course == null || course.isNaN) return false;
    return true;
  }

  static Color colorForTrack(MultiVehicleReplayTrack track) => track.color;

  static int colorIndexForTrack(MultiVehicleReplayTrack track) =>
      track.colorIndex;

  /// Legend status token for tests and UI branching.
  static MultiVehicleReplayLegendStatus legendStatus({
    required bool hasData,
    required bool visible,
  }) {
    if (!hasData) return MultiVehicleReplayLegendStatus.noData;
    if (!visible) return MultiVehicleReplayLegendStatus.hidden;
    return MultiVehicleReplayLegendStatus.active;
  }

  static String? formatPointsSubtitle(int pointCount) {
    if (pointCount <= 0) return null;
    return '$pointCount';
  }
}

enum MultiVehicleReplayLegendStatus { active, hidden, noData }
