import '../entities/dashboard_summary.dart';
import '../entities/insight.dart';

abstract interface class DashboardRepository {
  Future<DashboardSummary> getSummary();
  Future<List<InsightEntity>> getInsights();
}
