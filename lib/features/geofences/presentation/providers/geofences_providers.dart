import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/core_providers.dart';
import '../../data/datasources/geofences_remote_datasource.dart';
import '../../data/repositories/geofences_repository_impl.dart';
import '../../domain/entities/geofence.dart';
import '../../domain/repositories/geofences_repository.dart';

final geofencesRepositoryProvider = Provider<GeofencesRepository>((ref) {
  return GeofencesRepositoryImpl(
    GeofencesRemoteDataSource(ref.read(traccarClientProvider)),
  );
});

class GeofencesNotifier extends AsyncNotifier<List<GeofenceEntity>> {
  @override
  Future<List<GeofenceEntity>> build() =>
      ref.read(geofencesRepositoryProvider).getGeofences();

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(geofencesRepositoryProvider).getGeofences(),
    );
  }
}

final geofencesListProvider =
    AsyncNotifierProvider<GeofencesNotifier, List<GeofenceEntity>>(
  GeofencesNotifier.new,
);

final geofenceNameMapProvider = Provider<Map<int, String>>((ref) {
  final list = ref.watch(geofencesListProvider);
  return list.whenOrNull(
        data: (rows) => {for (final g in rows) g.id: g.name},
      ) ??
      {};
});

final mapGeofencesDataProvider = Provider<AsyncValue<List<GeofenceEntity>>>((ref) {
  return ref.watch(geofencesListProvider);
});

final showGeofencesOnMapProvider = StateProvider<bool>((ref) => true);
