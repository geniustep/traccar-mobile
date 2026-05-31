import '../../../core/logging/app_logger.dart';
import '../../../core/models/traccar_position.dart';
import '../../vehicles/domain/entities/vehicle.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/// Structured debug logs for Android map live-update audits (debug builds only).
abstract final class MapAuditLogger {
  MapAuditLogger._();

  static void screenOpened(String screen, {String? extra}) {
    AppLogger.map(
      '[MapAudit] screen=$screen opened${extra != null ? ' $extra' : ''}',
    );
  }

  static void screenDisposed(
    String screen, {
    String? subscriptions,
    String? timers,
  }) {
    final parts = <String>[
      '[Dispose] screen=$screen',
      if (subscriptions != null) 'subscriptions=$subscriptions',
      if (timers != null) 'timers=$timers',
    ];
    AppLogger.map(parts.join(' '));
  }

  static void livePosition({
    required String screen,
    required String deviceId,
    required double lat,
    required double lon,
    double? speed,
    DateTime? fixTime,
    String? source,
  }) {
    final fix = fixTime?.toUtc().toIso8601String() ?? 'null';
    final spd = speed?.toStringAsFixed(1) ?? 'null';
    AppLogger.map(
      '[LivePosition] screen=$screen deviceId=$deviceId '
      'lat=${lat.toStringAsFixed(5)} lon=${lon.toStringAsFixed(5)} '
      'speed=$spd fixTime=$fix${source != null ? ' source=$source' : ''}',
    );
    if (fixTime != null) {
      liveDelay(deviceId: deviceId, fixTime: fixTime);
    }
  }

  static void liveDelay({
    required String deviceId,
    required DateTime fixTime,
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    final fixLocal = fixTime.toLocal();
    final delaySeconds = n.difference(fixLocal).inMilliseconds / 1000.0;
    AppLogger.map(
      '[LiveDelay] deviceId=$deviceId '
      'fixTime=${fixTime.toUtc().toIso8601String()} '
      'now=${n.toUtc().toIso8601String()} '
      'delaySeconds=${delaySeconds.toStringAsFixed(1)}',
    );
  }

  static void markerUpdate({
    required String screen,
    required String deviceId,
    LatLng? oldLatLng,
    LatLng? newLatLng,
  }) {
    String fmt(LatLng? p) =>
        p == null ? 'null' : '${p.latitude.toStringAsFixed(5)},${p.longitude.toStringAsFixed(5)}';
    AppLogger.map(
      '[MarkerUpdate] screen=$screen deviceId=$deviceId '
      'oldLatLng=${fmt(oldLatLng)} newLatLng=${fmt(newLatLng)}',
    );
  }

  static void followMode({
    required String screen,
    required bool enabled,
    required bool cameraAnimated,
  }) {
    AppLogger.map(
      '[FollowMode] screen=$screen enabled=$enabled cameraAnimated=$cameraAnimated',
    );
  }

  static void polling({
    required String screen,
    required String action,
    String? reason,
    bool? socketConnected,
    double? lastLivePositionAgeSeconds,
  }) {
    final stateSuffix = socketConnected != null
        ? ' socketConnected=$socketConnected '
            'lastLivePositionAgeSeconds='
            '${lastLivePositionAgeSeconds?.toStringAsFixed(1) ?? 'null'}'
        : '';
    AppLogger.map(
      '[Polling] screen=$screen $action'
      '${reason != null ? ' reason=$reason' : ''}'
      '$stateSuffix',
    );
  }

  static void websocketPosition(TraccarPosition pos) {
    AppLogger.websocket(
      '[WebSocket] position received deviceId=${pos.deviceId} '
      'fixTime=${pos.fixTime.toUtc().toIso8601String()}',
    );
  }

  static void staleIgnored({
    required String screen,
    required String deviceId,
    required DateTime incomingFix,
    required DateTime currentFix,
  }) {
    AppLogger.liveSyncStale(
      '[MapAudit] screen=$screen stale ignored deviceId=$deviceId '
      'incoming=${incomingFix.toUtc().toIso8601String()} '
      'current=${currentFix.toUtc().toIso8601String()}',
    );
  }

  static void logVehicleIfMoved({
    required String screen,
    required VehicleEntity v,
    required Map<String, LatLng> lastByDevice,
    String source = 'provider',
  }) {
    final id = v.id;
    final next = LatLng(v.latitude, v.longitude);
    if (v.latitude == 0 && v.longitude == 0) return;
    final prev = lastByDevice[id];
    if (prev == null ||
        (prev.latitude - next.latitude).abs() > 1e-7 ||
        (prev.longitude - next.longitude).abs() > 1e-7) {
      markerUpdate(
        screen: screen,
        deviceId: id,
        oldLatLng: prev,
        newLatLng: next,
      );
      livePosition(
        screen: screen,
        deviceId: id,
        lat: v.latitude,
        lon: v.longitude,
        speed: v.speed,
        fixTime: v.lastUpdate,
        source: source,
      );
      lastByDevice[id] = next;
    }
  }
}
