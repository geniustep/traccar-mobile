import '../entities/analytics_data.dart';

abstract interface class AnalyticsRepository {
  Future<AnalyticsData> getWeeklyAnalytics();
}
