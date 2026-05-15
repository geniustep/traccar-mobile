import '../../../../core/l10n/app_localizations.dart';
import '../../core/route_intelligence_threshold_resolution.dart';

/// Numeric display for speeds (km/h) — keeps integers compact.
String routeIntelFormatKmhNum(double kmh) {
  if (!kmh.isFinite) return '—';
  final r = kmh.roundToDouble();
  if ((kmh - r).abs() < 1e-9) return r.toInt().toString();
  return kmh.toStringAsFixed(1);
}

String routeIntelFormatSpeedDisplay(double kmh, AppLocalizations l10n) {
  return l10n.routeIntelSpeedKmh(routeIntelFormatKmhNum(kmh));
}

String routeIntelFormatMinutes(Duration d, AppLocalizations l10n) {
  final m = d.inMinutes;
  if (m <= 0) return l10n.routeIntelMinutesShort(1);
  return l10n.routeIntelMinutesShort(m);
}

String routeIntelFormatBool(bool v, AppLocalizations l10n) {
  return v ? l10n.routeIntelEnabled : l10n.routeIntelDisabled;
}

String routeIntelFormatSourceLabel(
  RouteIntelligenceThresholdSource src,
  AppLocalizations l10n,
) {
  switch (src) {
    case RouteIntelligenceThresholdSource.device:
      return l10n.routeIntelSourceDevice;
    case RouteIntelligenceThresholdSource.group:
      return l10n.routeIntelSourceGroup;
    case RouteIntelligenceThresholdSource.user:
      return l10n.routeIntelSourceUser;
    case RouteIntelligenceThresholdSource.local:
      return l10n.routeIntelSourceLocal;
    case RouteIntelligenceThresholdSource.defaults:
      return l10n.routeIntelSourceDefault;
  }
}

/// Logical rows for the preview widget / tests (order is UI order).
List<RouteIntelThresholdPreviewRow> routeIntelThresholdPreviewRows(
  RouteIntelligenceThresholdResolution r,
  AppLocalizations l10n,
) {
  final t = r.thresholds;
  final s = r.sources;

  return [
    RouteIntelThresholdPreviewRow(
      label: l10n.routeIntelOverspeedThreshold,
      value: routeIntelFormatSpeedDisplay(t.overspeedThresholdKmh, l10n),
      source: s.overspeedThresholdKmhSource,
    ),
    RouteIntelThresholdPreviewRow(
      label: l10n.routeIntelMinStopDuration,
      value: routeIntelFormatMinutes(t.minStopDuration, l10n),
      source: s.minStopDurationSource,
    ),
    RouteIntelThresholdPreviewRow(
      label: l10n.routeIntelStopEnter,
      value: routeIntelFormatSpeedDisplay(t.stopSpeedEnterKmh, l10n),
      source: s.stopSpeedEnterKmhSource,
    ),
    RouteIntelThresholdPreviewRow(
      label: l10n.routeIntelStopExit,
      value: routeIntelFormatSpeedDisplay(t.stopSpeedExitKmh, l10n),
      source: s.stopSpeedExitKmhSource,
    ),
    RouteIntelThresholdPreviewRow(
      label: l10n.routeIntelDetectStops,
      value: routeIntelFormatBool(t.detectStops, l10n),
      source: s.detectStopsSource,
    ),
    RouteIntelThresholdPreviewRow(
      label: l10n.routeIntelDetectOverspeed,
      value: routeIntelFormatBool(t.detectOverspeed, l10n),
      source: s.detectOverspeedSource,
    ),
    RouteIntelThresholdPreviewRow(
      label: l10n.routeIntelDetectIgnition,
      value: routeIntelFormatBool(t.detectIgnition, l10n),
      source: s.detectIgnitionSource,
    ),
  ];
}

/// One line in the read-only preview.
class RouteIntelThresholdPreviewRow {
  const RouteIntelThresholdPreviewRow({
    required this.label,
    required this.value,
    required this.source,
  });

  final String label;
  final String value;
  final RouteIntelligenceThresholdSource source;
}
