import '../../../reports/domain/entities/summary_report.dart';

/// Aggregated today KPIs for vehicle detail summary card.
class VehicleTodayDashboard {
  const VehicleTodayDashboard({
    this.summary,
    this.stopsCount = 0,
    this.totalStopSeconds = 0,
    this.alertsTodayCount = 0,
  });

  final SummaryReport? summary;
  final int stopsCount;
  final int totalStopSeconds;
  final int alertsTodayCount;

  bool get hasSummary => summary != null;
}
