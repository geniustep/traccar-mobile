import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/insight.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';
import '../../../../shared/mock/mock_data.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this._dataSource);

  final DashboardRemoteDataSource _dataSource;

  @override
  Future<DashboardSummary> getSummary() async {
    try {
      final model = await _dataSource.getSummary();
      return model.toEntity();
    } catch (_) {
      // Return mock during development when API is unavailable
      return MockData.summary;
    }
  }

  @override
  Future<List<InsightEntity>> getInsights() async {
    try {
      final models = await _dataSource.getInsights();
      return models.map((m) => m.toEntity()).toList();
    } catch (_) {
      return MockData.insights;
    }
  }
}
