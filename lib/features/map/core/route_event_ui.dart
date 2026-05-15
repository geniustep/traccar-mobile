import '../../../../core/l10n/app_localizations.dart';
import 'route_event_models.dart';

String _fmtStopDuration(Duration d) {
  final h = d.inHours;
  final m = d.inMinutes.remainder(60);
  if (h > 0) return '${h}h ${m}m';
  return '${m}m';
}

/// One-line summary for light UI (tracking / report panels). Null when nothing to show.
String? formatRouteIntelSummaryLine(
  RouteEventAnalysisResult? analysis,
  AppLocalizations l10n,
) {
  if (analysis == null) return null;
  final s = analysis.summary;
  final parts = <String>[];
  if (s.stopCount > 0) {
    parts.add(
      '${l10n.reportsStops}: ${s.stopCount}'
      '${s.totalStopDuration > Duration.zero ? ' (${_fmtStopDuration(s.totalStopDuration)})' : ''}',
    );
  }
  if (s.overspeedCount > 0) {
    parts.add('${l10n.overspeedEvents}: ${s.overspeedCount}');
  }
  if (analysis.ignitionDataLikelyPresent && s.ignitionTransitionCount > 0) {
    parts.add('Ign: ${s.ignitionTransitionCount}');
  }
  if (parts.isEmpty) return null;
  return parts.join(' · ');
}
