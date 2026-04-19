import '../../domain/entities/analytics_data.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../datasources/analytics_remote_datasource.dart';
import '../../../../shared/mock/mock_data.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  const AnalyticsRepositoryImpl(this._dataSource);

  final AnalyticsRemoteDataSource _dataSource;

  @override
  Future<AnalyticsData> getWeeklyAnalytics() async {
    try {
      final model = await _dataSource.getWeeklyAnalytics();
      return model.toEntity();
    } catch (_) {
      return MockData.analytics;
    }
  }
}
