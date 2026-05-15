import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/insight.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../datasources/dashboard_remote_datasource.dart';

class DashboardRepositoryImpl implements DashboardRepository {
  const DashboardRepositoryImpl(this._dataSource);

  final DashboardRemoteDataSource _dataSource;

  @override
  Future<DashboardSummary> getSummary({DateTime? refreshNow}) async {
    final model = await _dataSource.getSummary(refreshNow: refreshNow);
    return model.toEntity();
  }

  @override
  Future<List<InsightEntity>> getInsights({DateTime? refreshNow}) async {
    final models = await _dataSource.getInsights(refreshNow: refreshNow);
    return models.map((m) => m.toEntity()).toList();
  }
}
