import 'package:flutter/material.dart';

import '../../../map/data/datasources/route_datasource.dart';
import 'multi_vehicle_replay_model.dart';
import 'multi_vehicle_replay_ui.dart';

/// Compact per-vehicle status at the current replay time (Phase R7).
@immutable
class MultiVehicleReplayVehicleCardData {
  const MultiVehicleReplayVehicleCardData({
    required this.track,
    required this.visible,
    required this.isActive,
    required this.pointAtTime,
    required this.movementLabel,
    required this.speedLabel,
    required this.timeLabel,
    required this.progressPercent,
  });

  final MultiVehicleReplayTrack track;
  final bool visible;
  final bool isActive;
  final RoutePoint? pointAtTime;
  final String movementLabel;
  final String speedLabel;
  final String timeLabel;
  final int? progressPercent;

  bool get hasPointAtTime => pointAtTime != null;

  bool get hasData => track.hasData;
}

abstract final class MultiVehicleReplayVehicleCardBuilder {
  MultiVehicleReplayVehicleCardBuilder._();

  static const double stoppedSpeedKmh = 5;

  static MultiVehicleReplayVehicleCardData build({
    required MultiVehicleReplayTrack track,
    required bool visible,
    required bool isActive,
    required RoutePoint? pointAtTime,
    required String movingLabel,
    required String stoppedLabel,
    required String noFixLabel,
    int? progressPercent,
  }) {
    final pt = pointAtTime;
    final moving = pt != null && pt.speed >= stoppedSpeedKmh;

    return MultiVehicleReplayVehicleCardData(
      track: track,
      visible: visible,
      isActive: isActive,
      pointAtTime: pt,
      movementLabel: pt == null ? noFixLabel : (moving ? movingLabel : stoppedLabel),
      speedLabel: pt == null ? '—' : '${pt.speed.round()} km/h',
      timeLabel: pt == null
          ? '—'
          : _hm(pt.fixTime),
      progressPercent: progressPercent,
    );
  }

  static String _hm(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  static List<MultiVehicleReplayVehicleCardData> forTracks({
    required List<MultiVehicleReplayTrack> tracks,
    required Map<String, RoutePoint?> markersAtTime,
    required bool Function(String id) isVisible,
    required String? activeVehicleId,
    required String movingLabel,
    required String stoppedLabel,
    required String noFixLabel,
  }) {
    return tracks
        .map(
          (t) => build(
            track: t,
            visible: isVisible(t.vehicleId),
            isActive: activeVehicleId == t.vehicleId,
            pointAtTime: markersAtTime[t.vehicleId],
            movingLabel: movingLabel,
            stoppedLabel: stoppedLabel,
            noFixLabel: noFixLabel,
          ),
        )
        .toList();
  }

  static MultiVehicleReplayLegendStatus legendStatusFor(MultiVehicleReplayVehicleCardData d) {
    if (!d.hasData) return MultiVehicleReplayLegendStatus.noData;
    if (!d.visible) return MultiVehicleReplayLegendStatus.hidden;
    if (d.isActive) return MultiVehicleReplayLegendStatus.activeSelected;
    return MultiVehicleReplayLegendStatus.active;
  }
}
