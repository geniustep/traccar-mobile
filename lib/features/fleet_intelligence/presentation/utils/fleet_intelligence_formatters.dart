import '../../../../core/l10n/app_localizations.dart';
import '../../../map/core/daily_behavior_score_calculator.dart';
import '../../../map/core/driver_behavior_score_config.dart';
import '../../../map/core/fleet_intelligence_metrics_models.dart';
import '../../../map/core/trip_segment_summary.dart';
import '../../../map/presentation/utils/driver_behavior_score_formatters.dart';

/// ملخصات عرض **لوحة ذكاء الأسطول السلوكية** (**Phase 10B**) — بدون نصوص خام أو أسماء تقنية.
abstract final class FleetIntelUiFormatters {
  FleetIntelUiFormatters._();

  /// لا يُعرض **«درجة 0»** كنتيجة حقيقية؛ إن **`!m.isScorable`** يعاد نص **غير مقيّم**.
  static String fleetScoreHeadline(
    AppLocalizations l10n,
    FleetIntelligenceMetrics m, {
    DriverBehaviorScoreConfig config = DriverBehaviorScoreConfig.defaults,
  }) {
    if (!m.isScorable) return l10n.driverScoreNotScorable;
    final band = DailyVehicleBehaviorScoreCalculator.riskLevelFromPeriodScore(
      m.averageScore,
      config.normalized(),
    );
    return '${l10n.driverScoreLabel} ${m.averageScore} · '
        '${DriverBehaviorScoreUi.riskLevelLabel(l10n, band)}';
  }

  static String fleetScoreSecondary(
    AppLocalizations l10n,
    FleetIntelligenceMetrics m,
  ) {
    if (!m.isScorable) {
      if (m.totalTrips > 0) {
        return l10n.dailyScoreInsufficientData;
      }
      return l10n.fleetIntelNoTripsInPeriod;
    }
    return '';
  }

  static String formatFleetDistanceKm(
    AppLocalizations l10n,
    double km,
  ) =>
      '${formatTripDistanceKmValue(km)} ${l10n.tripKmUnit}';

  static String formatFleetDuration(Duration d) => formatTripDurationCompact(d);

  static String vehicleLabel(
    AppLocalizations l10n,
    FleetVehicleIntelligenceSummary? s,
  ) {
    if (s == null) return l10n.fleetIntelNoData;
    final n = s.vehicleName?.trim();
    if (n != null && n.isNotEmpty) return n;
    return l10n.fleetIntelVehicleFallback(s.vehicleId);
  }

  static FleetVehicleIntelligenceSummary? primaryAttentionVehicle(
    FleetIntelligenceMetrics m,
  ) =>
      m.vehiclesNeedingAttention.isEmpty
          ? null
          : m.vehiclesNeedingAttention.first;

  /// للاختبارات: النص الناتج عند غير قابل للتقييم لا يحتوي **«label 0»**.
  static bool avoidsZeroScoreHeadline(
    AppLocalizations l10n,
    FleetIntelligenceMetrics m,
    String headline,
  ) {
    if (m.isScorable) return true;
    return !headline.contains('${l10n.driverScoreLabel} 0');
  }
}
