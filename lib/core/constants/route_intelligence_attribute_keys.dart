/// Traccar `device.attributes` keys for Route Intelligence (ELMO namespaced).
///
/// JSON shape example — see `docs/route_intelligence_thresholds_source.md`.
abstract final class RouteIntelligenceAttributeKeys {
  static const String stopSpeedEnterKmh = 'elmo.route.stopSpeedEnterKmh';
  static const String stopSpeedExitKmh = 'elmo.route.stopSpeedExitKmh';
  static const String minStopDurationMinutes = 'elmo.route.minStopDurationMinutes';
  static const String overspeedThresholdKmh = 'elmo.route.overspeedThresholdKmh';
  static const String detectStops = 'elmo.route.detectStops';
  static const String detectOverspeed = 'elmo.route.detectOverspeed';
  static const String detectIgnition = 'elmo.route.detectIgnition';

  /// Keys removed by «clear Route Intelligence on entity» — **Route Intelligence only**.
  static const List<String> allKeys = <String>[
    stopSpeedEnterKmh,
    stopSpeedExitKmh,
    minStopDurationMinutes,
    overspeedThresholdKmh,
    detectStops,
    detectOverspeed,
    detectIgnition,
  ];
}
