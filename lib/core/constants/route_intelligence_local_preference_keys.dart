/// SharedPreferences keys for optional **local** Route Intelligence overrides
/// (fallback layer: weaker than server-side `attributes` — see thresholds docs).
///
/// Phase 6H: persisted from **`RouteIntelligenceLocalThresholdsEditor`**
/// (**`SettingsScreen`** only — global/local layer editing).
/// Values use the same JSON-friendly shapes as [RouteIntelligenceAttributeKeys]
/// where applicable (string/number/bool); the app stores native num/bool types.
abstract final class RouteIntelligenceLocalPreferenceKeys {
  static const String stopSpeedEnterKmh = 'elmo.local.route.stopSpeedEnterKmh';
  static const String stopSpeedExitKmh = 'elmo.local.route.stopSpeedExitKmh';
  static const String minStopDurationMinutes =
      'elmo.local.route.minStopDurationMinutes';
  static const String overspeedThresholdKmh =
      'elmo.local.route.overspeedThresholdKmh';
  static const String detectStops = 'elmo.local.route.detectStops';
  static const String detectOverspeed = 'elmo.local.route.detectOverspeed';
  static const String detectIgnition = 'elmo.local.route.detectIgnition';

  /// Keys removed by «reset local route intelligence prefs» — **route layer only**.
  static const List<String> allPreferenceKeys = <String>[
    stopSpeedEnterKmh,
    stopSpeedExitKmh,
    minStopDurationMinutes,
    overspeedThresholdKmh,
    detectStops,
    detectOverspeed,
    detectIgnition,
  ];
}
