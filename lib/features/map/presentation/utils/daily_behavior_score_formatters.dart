import '../../../../core/l10n/app_localizations.dart';
import '../../core/daily_behavior_score_models.dart';
import '../../core/trip_segment_models.dart';
import '../../core/trip_segment_summary.dart';
import 'driver_behavior_score_formatters.dart';
import 'trip_formatters.dart';

/// Phase **9E** — localized strings for **`DailyVehicleBehaviorScore`** (no Calculator changes).
abstract final class DailyBehaviorScoreUi {
  DailyBehaviorScoreUi._();

  /// Empty when **`!daily.isScorable`** — callers must not surface a **`0`** period score when unscorable.
  static String periodScoreSummaryLine(
    AppLocalizations l10n,
    DailyVehicleBehaviorScore daily,
  ) {
    if (!daily.isScorable) return '';
    return '${l10n.driverScoreLabel} ${daily.score} · '
        '${DriverBehaviorScoreUi.riskLevelLabel(l10n, daily.riskLevel)}';
  }

  static String periodStatsMidLine(AppLocalizations l10n, DailyVehicleBehaviorScore daily) {
    final kmStr = formatTripDistanceKmValue(daily.totalDistanceKm);
    final parts = <String>[
      l10n.dailyScoreTripCount(daily.totalTrips),
      '$kmStr ${l10n.tripKmUnit}',
      l10n.dailyScoreOverspeed(daily.totalOverspeedEvents),
      l10n.dailyScoreStops(daily.totalStops),
    ];
    return parts.join(' · ');
  }

  static String scorableTripRatioLine(AppLocalizations l10n, DailyVehicleBehaviorScore daily) {
    return l10n.dailyScoreScorableTrips(daily.scorableTrips, daily.totalTrips);
  }

  static String? bestTripLine(AppLocalizations l10n, TripSegment? trip) {
    if (trip == null) return null;
    return l10n.dailyScoreBestTrip(TripUiFormatters.tripTitle(l10n, trip.index));
  }

  static String? worstTripLine(AppLocalizations l10n, TripSegment? trip) {
    if (trip == null) return null;
    return l10n.dailyScoreWorstTrip(TripUiFormatters.tripTitle(l10n, trip.index));
  }

  /// For tests: middot-separated pattern without hard-coded locale punctuation beyond **` · `**.
  static bool periodSummaryLooksScorable(AppLocalizations l10n, String line, int score) {
    return line.contains('$score') &&
        line.contains(l10n.driverScoreLabel) &&
        line.contains('·');
  }

  /// Shown after details when some trips were excluded from the period average (**Phase 9F** sheet).
  static bool shouldShowUnscoredExcludedHint(DailyVehicleBehaviorScore daily) =>
      daily.isScorable && daily.unscorableTrips > 0;

  /// For tests: unscorable summaries must never surface **`<driverScoreLabel> 0`**.
  static bool sheetAvoidsNumericZeroScoreLine(AppLocalizations l10n, String combinedBodyText) =>
      !combinedBodyText.contains('${l10n.driverScoreLabel} 0');
}
