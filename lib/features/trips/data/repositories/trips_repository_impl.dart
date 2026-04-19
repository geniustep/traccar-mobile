import '../../domain/entities/trip.dart';
import '../../domain/repositories/trips_repository.dart';
import '../datasources/trips_remote_datasource.dart';
import '../../../../shared/mock/mock_data.dart';

class TripsRepositoryImpl implements TripsRepository {
  const TripsRepositoryImpl(this._dataSource);

  final TripsRemoteDataSource _dataSource;

  @override
  Future<List<TripEntity>> getVehicleTrips(
    String vehicleId, {
    DateTime? from,
    DateTime? to,
  }) async {
    try {
      final models = await _dataSource.getVehicleTrips(vehicleId, from: from, to: to);
      return models.map((m) => m.toEntity()).toList();
    } catch (_) {
      return MockData.trips.where((t) => t.vehicleId == vehicleId).toList();
    }
  }

  @override
  Future<TripEntity> getTrip(String id) async {
    try {
      final model = await _dataSource.getTrip(id);
      return model.toEntity();
    } catch (_) {
      return MockData.trips.firstWhere(
        (t) => t.id == id,
        orElse: () => MockData.trips.first,
      );
    }
  }
}
