import '../../../core/logging/app_logger.dart';

/// Debug logs for historical route load + live polyline extension.
abstract final class LiveRoutePolylineLog {
  LiveRoutePolylineLog._();

  static void routeLoaded({
    required String screen,
    required String deviceId,
    required int points,
    required DateTime from,
    required DateTime to,
  }) {
    AppLogger.map(
      '[RoutePolyline] screen=$screen deviceId=$deviceId '
      'loaded points=$points '
      'from=${from.toIso8601String()} to=${to.toIso8601String()}',
    );
  }

  static void liveAppend({
    required String screen,
    required String deviceId,
    required double lat,
    required double lon,
    required DateTime fixTime,
    required int totalPoints,
  }) {
    AppLogger.map(
      '[LiveRouteAppend] screen=$screen deviceId=$deviceId '
      'lat=${lat.toStringAsFixed(5)} lon=${lon.toStringAsFixed(5)} '
      'fixTime=${fixTime.toUtc().toIso8601String()} totalPoints=$totalPoints',
    );
  }

  static void ignored({
    required String screen,
    required String deviceId,
    required String reason,
  }) {
    AppLogger.map(
      '[LiveRouteAppend] screen=$screen deviceId=$deviceId '
      'ignored reason=$reason',
    );
  }

  static void reset({
    required String screen,
    required String deviceId,
    required String reason,
  }) {
    AppLogger.map(
      '[LiveRouteReset] screen=$screen deviceId=$deviceId reason=$reason',
    );
  }
}
