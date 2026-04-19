import '../../../../core/network/dio_client.dart';
import '../../../../core/constants/api_constants.dart';
import '../models/vehicle_model.dart';

class VehicleRemoteDataSource {
  const VehicleRemoteDataSource(this._client);

  final DioClient _client;

  Future<List<VehicleModel>> getVehicles() async {
    return _client.get<List<VehicleModel>>(
      ApiConstants.vehicles,
      fromJson: (data) => (data as List)
          .map((e) => VehicleModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Future<VehicleModel> getVehicle(String id) async {
    return _client.get<VehicleModel>(
      ApiConstants.vehicleById(id),
      fromJson: (data) => VehicleModel.fromJson(data as Map<String, dynamic>),
    );
  }

  Future<VehicleModel> getVehicleLive(String id) async {
    return _client.get<VehicleModel>(
      ApiConstants.vehicleLive(id),
      fromJson: (data) => VehicleModel.fromJson(data as Map<String, dynamic>),
    );
  }
}
