import '../../../../core/l10n/app_localizations.dart';
import '../../../map/core/fleet_intelligence_metrics_models.dart';
import 'fleet_attention_center_logic.dart';
import 'fleet_intelligence_formatters.dart';

/// تنسيقات ورقة متابعة مركبة — **Phase 10G** (بدون شبكة؛ مناسبة للاختبارات).
abstract final class FleetAttentionDetailsFormatters {
  FleetAttentionDetailsFormatters._();

  /// تسمية قصيرة لسبب انتباه (توحيد قائمة المركز وورقة التفاصيل).
  static String reasonLabel(AppLocalizations l10n, FleetAttentionReason r) {
    switch (r) {
      case FleetAttentionReason.highRisk:
        return l10n.fleetAttentionHighRisk;
      case FleetAttentionReason.lowScore:
        return l10n.fleetAttentionLowScore;
      case FleetAttentionReason.manyOverspeed:
        return l10n.fleetAttentionManyOverspeed;
      case FleetAttentionReason.manyStops:
        return l10n.fleetAttentionManyStops;
      case FleetAttentionReason.inactive:
        return l10n.fleetAttentionInactive;
      case FleetAttentionReason.insufficientData:
        return l10n.fleetAttentionInsufficientData;
    }
  }

  /// رصاصات لكل سبب؛ إن القائمة فارغة تعيد سلسلة فارغة.
  static String reasonsBulleted(
    AppLocalizations l10n,
    List<FleetAttentionReason> reasons,
  ) =>
      reasons.map((r) => '• ${reasonLabel(l10n, r)}').join('\n');

  /// نص واحد لواجهات عرض واحدة (شرط متعددة).
  static String reasonsInline(
    AppLocalizations l10n,
    Iterable<FleetAttentionReason> reasons,
  ) =>
      reasons.map((r) => reasonLabel(l10n, r)).join(' · ');

  /// لا تُكرِّر **درجة 0** كحقيقة؛ عند **غير قابل للتقييم** ارجِع **`null`**.
  static String? scoreLineIfScorable(
    AppLocalizations l10n,
    FleetVehicleIntelligenceSummary s,
  ) {
    if (!s.isPeriodScorable || s.periodScore == null) return null;
    return '${l10n.fleetAttentionScore}: ${s.periodScore}';
  }

  /// صفوف إحصاء عرض جاهزة (تسمية: قيمة).
  static List<(String label, String value)> statRows(
    AppLocalizations l10n,
    FleetVehicleIntelligenceSummary s,
  ) =>
      [
        (l10n.fleetAttentionTrips, '${s.totalTrips}'),
        (
          l10n.fleetAttentionDistance,
          FleetIntelUiFormatters.formatFleetDistanceKm(l10n, s.totalDistanceKm),
        ),
        (l10n.fleetAttentionOverspeed, '${s.totalOverspeedEvents}'),
        (l10n.fleetAttentionStops, '${s.totalStops}'),
      ];
}
