import 'package:flutter/foundation.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/format_utils.dart';
import '../../map/core/route_event_timeline_models.dart';
import '../../map/data/datasources/route_datasource.dart';
import 'replay_route_gap.dart';
import 'replay_sensor_snapshot.dart';

/// Display model for the current replay position (Phase R2).
///
/// Optional fields are null when data should not be shown (not fake placeholders).
@immutable
class ReplayPointSnapshot {
  const ReplayPointSnapshot({
    required this.timeLabel,
    required this.speedLabel,
    required this.progressPercent,
    required this.movementLabel,
    required this.isMoving,
    this.coordinatesLabel,
    this.courseLabel,
    this.address,
    this.ignitionOn,
    this.sensorRows = const [],
    this.afterDataGap = false,
  });

  final String timeLabel;
  final String speedLabel;
  final int progressPercent;
  final String movementLabel;
  final bool isMoving;

  final String? coordinatesLabel;
  final String? courseLabel;
  final String? address;

  /// `null` = do not show ignition row (data not considered available).
  final bool? ignitionOn;

  /// Up to [ReplayPointSensorSnapshot.maxRowsInSnapshot] formatted sensor values.
  final List<ReplaySensorRow> sensorRows;

  final bool afterDataGap;

  bool get hasSensorRows => sensorRows.isNotEmpty;

  bool get hasExpandableDetails =>
      coordinatesLabel != null ||
      courseLabel != null ||
      ignitionOn != null ||
      hasSensorRows;

  bool get hasAddress => address != null && address!.isNotEmpty;
}

/// Speed below this threshold (km/h) is shown as stopped in the snapshot.
const double replaySnapshotStoppedSpeedKmh = 5;

abstract final class ReplayPointSnapshotBuilder {
  ReplayPointSnapshotBuilder._();

  static ReplayPointSnapshot fromRoutePoint({
    required RoutePoint point,
    required AppLocalizations l10n,
    required double progress,
    bool showIgnition = false,
    List<ReplayRouteGap> gaps = const [],
    double stoppedSpeedKmh = replaySnapshotStoppedSpeedKmh,
  }) {
    final moving = point.speed >= stoppedSpeedKmh;
    final addr = point.address?.trim();
    final showAddr = addr != null && addr.isNotEmpty;
    final sensors = ReplaySensorSnapshotBuilder.fromRoutePoint(point);

    return ReplayPointSnapshot(
      timeLabel: _formatTime(point.fixTime),
      speedLabel: FormatUtils.speed(point.speed),
      progressPercent: (progress.clamp(0.0, 1.0) * 100).round(),
      movementLabel: moving ? l10n.moving : l10n.stopped,
      isMoving: moving,
      coordinatesLabel: _coordinatesLabel(point),
      courseLabel: _courseLabel(point, l10n),
      address: showAddr ? addr : null,
      ignitionOn: showIgnition
          ? ReplaySensorIgnition.resolveForDisplay(point)
          : null,
      sensorRows: sensors.primaryRows,
      afterDataGap: _isAfterDataGap(point, gaps),
    );
  }

  static String _formatTime(DateTime t) {
    final h = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    final s = t.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  static String? _coordinatesLabel(RoutePoint point) {
    final p = point.position;
    if (!routeEventTimelineValidPosition(p)) return null;
    return '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
  }

  static String? _courseLabel(RoutePoint point, AppLocalizations l10n) {
    final c = point.course;
    if (!c.isFinite) return null;
    return '${c.round()}°';
  }

  static bool _isAfterDataGap(RoutePoint point, List<ReplayRouteGap> gaps) {
    if (gaps.isEmpty) return false;
    for (final g in gaps) {
      final diffMs =
          point.fixTime.difference(g.gapEndTime).inMilliseconds.abs();
      if (diffMs <= 1500) return true;
    }
    return false;
  }
}
