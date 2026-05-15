import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/trip.dart';
import '../../domain/repositories/trips_repository.dart';
import '../../data/datasources/trips_remote_datasource.dart';
import '../../data/repositories/trips_repository_impl.dart';
import '../../../../shared/providers/core_providers.dart';
import 'vehicle_trips_query.dart';

export 'vehicle_trips_query.dart';

final tripsRepositoryProvider = Provider<TripsRepository>((ref) {
  return TripsRepositoryImpl(
    TripsRemoteDataSource(ref.read(traccarClientProvider)),
  );
});

final vehicleTripsProvider = FutureProvider.autoDispose
    .family<List<TripEntity>, VehicleTripsQuery>((ref, query) async {
  return ref.read(tripsRepositoryProvider).getVehicleTrips(
        query.vehicleId,
        from: query.from,
        to: query.to,
      );
});

final tripDetailProvider =
    FutureProvider.autoDispose.family<TripEntity, String>((ref, id) async {
  return ref.read(tripsRepositoryProvider).getTrip(id);
});
