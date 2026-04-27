import '../../domain/entities/analytics_data.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../datasources/analytics_remote_datasource.dart';

class AnalyticsRepositoryImpl implements AnalyticsRepository {
  const AnalyticsRepositoryImpl(this._dataSource);

  final AnalyticsRemoteDataSource _dataSource;

  @override
  Future<AnalyticsData> getWeeklyAnalytics() async {
    final model = await _dataSource.getWeeklyAnalytics();
    return model.toEntity();
  }
}
