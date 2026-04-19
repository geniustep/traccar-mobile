import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/utils/date_formatter.dart';
import '../models/trip_model.dart';

class TripsRemoteDataSource {
  const TripsRemoteDataSource(this._client);

  final DioClient _client;

  Future<List<TripModel>> getVehicleTrips(
    String vehicleId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final params = <String, dynamic>{};
    if (from != null) params['from'] = DateFormatter.toApiDate(from);
    if (to != null) params['to'] = DateFormatter.toApiDate(to);

    return _client.get<List<TripModel>>(
      ApiConstants.vehicleTrips(vehicleId),
      queryParameters: params.isEmpty ? null : params,
      fromJson: (data) => (data as List)
          .map((e) => TripModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<TripModel> getTrip(String id) async {
    return _client.get<TripModel>(
      ApiConstants.tripById(id),
      fromJson: (data) => TripModel.fromJson(data as Map<String, dynamic>),
    );
  }
}
