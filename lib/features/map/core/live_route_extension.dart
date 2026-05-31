import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../core/maps/map_helper.dart';
import '../../vehicles/domain/entities/vehicle.dart';
import '../data/datasources/route_datasource.dart';
import 'live_route_polyline_log.dart';

/// Appends live GPS points to a historical route polyline without reloading the API.
class LiveRouteExtension {
  LiveRouteExtension({required this.screen});

  final String screen;

  static const double minMoveMeters = 3.0;
  static const Duration rangeEndGrace = Duration(minutes: 2);

  List<RoutePoint> _historical = const [];
  final List<RoutePoint> _liveAppend = [];
  String? _deviceId;
  DateTime? _rangeFrom;
  DateTime? _rangeTo;
  String _historicalKey = '';

  List<RoutePoint> get liveAppendPoints => List.unmodifiable(_liveAppend);

  int get liveAppendCount => _liveAppend.length;

  /// Historical API points + live extension (for map polylines).
  List<RoutePoint> get combinedPoints =>
      _historical.isEmpty && _liveAppend.isEmpty
          ? const []
          : [..._historical, ..._liveAppend];

  void resetLiveExtension({
    required String deviceId,
    required String reason,
  }) {
    if (_liveAppend.isEmpty && _deviceId == deviceId) return;
    _liveAppend.clear();
    LiveRoutePolylineLog.reset(
      screen: screen,
      deviceId: deviceId,
      reason: reason,
    );
  }

  /// Replaces the historical baseline from Route API (clears live append when data changes).
  void loadHistorical({
    required String deviceId,
    required List<RoutePoint> points,
    required DateTime rangeFrom,
    required DateTime rangeTo,
  }) {
    final newKey = points.isEmpty
        ? 'empty'
        : '${points.length}_${points.last.fixTime.millisecondsSinceEpoch}_'
            '${points.first.fixTime.millisecondsSinceEpoch}';
    final rangeChanged = _rangeFrom != rangeFrom || _rangeTo != rangeTo;
    final dataChanged = newKey != _historicalKey;

    if (dataChanged || rangeChanged) {
      _liveAppend.clear();
      if (rangeChanged && !dataChanged && _deviceId == deviceId) {
        LiveRoutePolylineLog.reset(
          screen: screen,
          deviceId: deviceId,
          reason: 'time_range_changed',
        );
      }
    }

    _deviceId = deviceId;
    _rangeFrom = rangeFrom;
    _rangeTo = rangeTo;
    _historicalKey = newKey;
    _historical = List<RoutePoint>.from(points);

    if (dataChanged || rangeChanged) {
      LiveRoutePolylineLog.routeLoaded(
        screen: screen,
        deviceId: deviceId,
        points: points.length,
        from: rangeFrom,
        to: rangeTo,
      );
    }
  }

  /// True when the selected window still includes the live tail (end near now).
  static bool allowsLiveExtension({
    required DateTime rangeFrom,
    required DateTime rangeTo,
    DateTime? now,
  }) {
    final n = now ?? DateTime.now();
    if (rangeTo.isBefore(rangeFrom)) return false;
    if (rangeFrom.isAfter(n.add(rangeEndGrace))) return false;
    return !rangeTo.isBefore(n.subtract(rangeEndGrace));
  }

  /// Tries to append [vehicle]'s latest position to the live extension.
  ///
  /// Returns `true` when a new point was appended (caller may [setState]).
  bool tryAppendFromVehicle({
    required VehicleEntity vehicle,
    required bool liveModeEnabled,
  }) {
    final deviceId = vehicle.id;
    if (!liveModeEnabled) {
      LiveRoutePolylineLog.ignored(
        screen: screen,
        deviceId: deviceId,
        reason: 'live_mode_disabled',
      );
      return false;
    }

    final from = _rangeFrom;
    final to = _rangeTo;
    if (from == null || to == null) {
      LiveRoutePolylineLog.ignored(
        screen: screen,
        deviceId: deviceId,
        reason: 'no_historical_loaded',
      );
      return false;
    }

    if (!allowsLiveExtension(rangeFrom: from, rangeTo: to)) {
      LiveRoutePolylineLog.ignored(
        screen: screen,
        deviceId: deviceId,
        reason: 'outside_selected_range',
      );
      return false;
    }

    if (vehicle.latitude == 0 && vehicle.longitude == 0) {
      LiveRoutePolylineLog.ignored(
        screen: screen,
        deviceId: deviceId,
        reason: 'invalid_position',
      );
      return false;
    }

    final fixTime = vehicle.lastUpdate;
    if (fixTime == null) {
      LiveRoutePolylineLog.ignored(
        screen: screen,
        deviceId: deviceId,
        reason: 'missing_fix_time',
      );
      return false;
    }

    if (!_fixTimeWithinRange(fixTime, from, to)) {
      LiveRoutePolylineLog.ignored(
        screen: screen,
        deviceId: deviceId,
        reason: 'outside_selected_range',
      );
      return false;
    }

    final candidate = RoutePoint(
      position: LatLng(vehicle.latitude, vehicle.longitude),
      speed: vehicle.speed,
      course: vehicle.course ?? 0,
      fixTime: fixTime,
      ignition: vehicle.ignition,
      address: vehicle.address,
    );

    return tryAppendPoint(deviceId: deviceId, candidate: candidate);
  }

  bool tryAppendPoint({
    required String deviceId,
    required RoutePoint candidate,
    bool liveModeEnabled = true,
  }) {
    if (!liveModeEnabled) {
      LiveRoutePolylineLog.ignored(
        screen: screen,
        deviceId: deviceId,
        reason: 'live_mode_disabled',
      );
      return false;
    }

    final last = _lastCombinedPoint;
    if (last != null) {
      if (candidate.fixTime.isBefore(last.fixTime)) {
        LiveRoutePolylineLog.ignored(
          screen: screen,
          deviceId: deviceId,
          reason: 'stale_or_duplicate',
        );
        return false;
      }
      if (candidate.fixTime == last.fixTime &&
          _nearSamePosition(candidate.position, last.position)) {
        LiveRoutePolylineLog.ignored(
          screen: screen,
          deviceId: deviceId,
          reason: 'stale_or_duplicate',
        );
        return false;
      }
      if (_nearSamePosition(candidate.position, last.position)) {
        LiveRoutePolylineLog.ignored(
          screen: screen,
          deviceId: deviceId,
          reason: 'stale_or_duplicate',
        );
        return false;
      }
    }

    _liveAppend.add(candidate);
    LiveRoutePolylineLog.liveAppend(
      screen: screen,
      deviceId: deviceId,
      lat: candidate.position.latitude,
      lon: candidate.position.longitude,
      fixTime: candidate.fixTime,
      totalPoints: combinedPoints.length,
    );
    return true;
  }

  RoutePoint? get _lastCombinedPoint {
    if (_liveAppend.isNotEmpty) return _liveAppend.last;
    if (_historical.isNotEmpty) return _historical.last;
    return null;
  }

  bool _fixTimeWithinRange(DateTime fixTime, DateTime from, DateTime to) {
    if (fixTime.isBefore(from)) return false;
    final graceEnd = to.add(rangeEndGrace);
    return !fixTime.isAfter(graceEnd);
  }

  static bool _nearSamePosition(LatLng a, LatLng b) =>
      MapHelper.distanceMeters(a, b) < minMoveMeters;
}
