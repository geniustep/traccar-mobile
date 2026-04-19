import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/analytics_model.dart';

class AnalyticsRemoteDataSource {
  const AnalyticsRemoteDataSource(this._client);

  final DioClient _client;

  Future<AnalyticsModel> getWeeklyAnalytics() async {
    return _client.get<AnalyticsModel>(
      ApiConstants.analyticsWeekly,
      fromJson: (data) => AnalyticsModel.fromJson(data as Map<String, dynamic>),
    );
  }
}
