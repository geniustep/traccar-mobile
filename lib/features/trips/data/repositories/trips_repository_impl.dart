import '../../domain/entities/trip.dart';
import '../../domain/repositories/trips_repository.dart';
import '../datasources/trips_remote_datasource.dart';

class TripsRepositoryImpl implements TripsRepository {
  const TripsRepositoryImpl(this._dataSource);

  final TripsRemoteDataSource _dataSource;

  @override
  Future<List<TripEntity>> getVehicleTrips(
    String vehicleId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final models = await _dataSource.getVehicleTrips(
      vehicleId,
      from: from,
      to: to,
    );
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<TripEntity> getTrip(String id) async {
    final model = await _dataSource.getTrip(id);
    return model.toEntity();
  }
}
