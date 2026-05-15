import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/utils/format_utils.dart';
import '../../core/trip_segment_models.dart';
import '../../core/trip_segment_summary.dart';

/// Phase 8B — display helpers (uses [AppLocalizations], no vendor-specific strings).
class TripUiFormatters {
  TripUiFormatters._();

  static String tripTitle(AppLocalizations l10n, int index) =>
      l10n.tripTitle(index);

  /// Start–end labels for a card subtitle (local wall time).
  static String tripTimeRangeHm(AppLocalizations l10n, TripSegment t) {
    final hm = DateFormat.Hm();
    final a = hm.format(t.startTime.toLocal());
    final b = hm.format(t.endTime.toLocal());
    return l10n.tripTimeArrow(a, b);
  }

  static String tripSubtitleLine(AppLocalizations l10n, TripSegment t) {
    final parts = <String>[
      '${formatTripDistanceKmValue(t.distanceKm)} ${l10n.tripKmUnit}',
      formatTripDurationCompact(t.duration),
      l10n.tripStopsCount(t.stopCount),
      l10n.tripOverspeedCount(t.overspeedCount),
    ];
    return parts.join(' · ');
  }

  static String tripMaxSpeedShort(AppLocalizations l10n, TripSegment t) =>
      '${l10n.tripMaxSpeed}: ${FormatUtils.speed(t.maxSpeedKmh)}';

  static String? tripIgnitionLine(AppLocalizations l10n, TripSegment t) {
    if (!t.hasIgnitionData) return null;
    return l10n.tripIgnitionSummary(t.ignitionOnCount, t.ignitionOffCount);
  }

  /// Empty-state copy for trips list panel.
  static String tripsNone(AppLocalizations l10n) => l10n.tripsNoneDetected;
}
