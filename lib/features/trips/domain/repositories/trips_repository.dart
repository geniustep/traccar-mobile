import '../entities/trip.dart';

abstract interface class TripsRepository {
  Future<List<TripEntity>> getVehicleTrips(String vehicleId, {DateTime? from, DateTime? to});
  Future<TripEntity> getTrip(String id);
}
