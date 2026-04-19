import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/dashboard_summary_model.dart';
import '../models/insight_model.dart';

class DashboardRemoteDataSource {
  const DashboardRemoteDataSource(this._client);

  final DioClient _client;

  Future<DashboardSummaryModel> getSummary() async {
    return _client.get<DashboardSummaryModel>(
      ApiConstants.dashboardSummary,
      fromJson: (data) => DashboardSummaryModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<List<InsightModel>> getInsights() async {
    return _client.get<List<InsightModel>>(
      ApiConstants.dashboardInsights,
      fromJson: (data) => (data as List)
          .map((e) => InsightModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
