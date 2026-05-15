import '../entities/dashboard_summary.dart';
import '../entities/insight.dart';

abstract interface class DashboardRepository {
  Future<DashboardSummary> getSummary({DateTime? refreshNow});
  Future<List<InsightEntity>> getInsights({DateTime? refreshNow});
}
