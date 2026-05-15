import '../../core/route_intelligence_thresholds.dart';

/// Parses form input for **[RouteIntelligenceThresholds]** before `.normalized()`
/// clamps inner consistency (exit ≥ enter, overspeed finite, …).
///
/// Returns `thresholds == null` when the user-visible fields are unacceptable
/// (`invalidNumeric == true`); booleans always apply.
typedef RouteIntelLocalFormParseOutcome = ({
  RouteIntelligenceThresholds? thresholds,
  bool invalidNumeric,
});

double? routeIntelParseNonNegativeFiniteDouble(String raw) {
  final t = raw.trim().replaceAll(',', '.');
  if (t.isEmpty) return null;
  final v = double.tryParse(t);
  if (v == null || !v.isFinite || v < 0) return null;
  return v;
}

int? routeIntelParsePositiveMinutes(String raw) {
  final v = int.tryParse(raw.trim());
  if (v == null || v <= 0) return null;
  return v;
}

double? routeIntelParseStrictlyPositiveFiniteDouble(String raw) {
  final v = routeIntelParseNonNegativeFiniteDouble(raw);
  if (v == null || v <= 0) return null;
  return v;
}

RouteIntelLocalFormParseOutcome parseRouteIntelLocalFormInputs({
  required String stopSpeedEnterRaw,
  required String stopSpeedExitRaw,
  required String minStopMinutesRaw,
  required String overspeedRaw,
  required bool detectStops,
  required bool detectOverspeed,
  required bool detectIgnition,
}) {
  final enter = routeIntelParseNonNegativeFiniteDouble(stopSpeedEnterRaw);
  final exitRaw = routeIntelParseNonNegativeFiniteDouble(stopSpeedExitRaw);
  final mins = routeIntelParsePositiveMinutes(minStopMinutesRaw);
  final overspeed = routeIntelParseStrictlyPositiveFiniteDouble(overspeedRaw);

  if (enter == null || exitRaw == null || mins == null || overspeed == null) {
    return (
      thresholds: null,
      invalidNumeric: true,
    );
  }

  return (
    thresholds: RouteIntelligenceThresholds(
      stopSpeedEnterKmh: enter,
      stopSpeedExitKmh: exitRaw,
      minStopDuration: Duration(minutes: mins),
      overspeedThresholdKmh: overspeed,
      detectStops: detectStops,
      detectOverspeed: detectOverspeed,
      detectIgnition: detectIgnition,
    ).normalized(),
    invalidNumeric: false,
  );
}
