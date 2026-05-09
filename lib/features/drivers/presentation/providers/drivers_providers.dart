import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/core_providers.dart';
import '../../data/datasources/drivers_remote_datasource.dart';
import '../../data/repositories/drivers_repository_impl.dart';
import '../../domain/entities/driver.dart';
import '../../domain/repositories/drivers_repository.dart';

final driversRepositoryProvider = Provider<DriversRepository>((ref) {
  return DriversRepositoryImpl(
    DriversRemoteDataSource(ref.read(traccarClientProvider)),
  );
});

class DriversListNotifier extends AsyncNotifier<List<DriverEntity>> {
  String? _keyword;

  @override
  Future<List<DriverEntity>> build() async {
    return ref.read(driversRepositoryProvider).getDrivers(keyword: _keyword);
  }

  Future<void> refresh({String? keyword}) async {
    _keyword = keyword;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(driversRepositoryProvider).getDrivers(keyword: _keyword),
    );
  }

  Future<void> setKeyword(String? keyword) => refresh(keyword: keyword);
}

final driversListProvider =
    AsyncNotifierProvider<DriversListNotifier, List<DriverEntity>>(
  DriversListNotifier.new,
);

final driverByIdProvider =
    FutureProvider.autoDispose.family<DriverEntity?, int>((ref, id) async {
  return ref.read(driversRepositoryProvider).getDriverById(id);
});
