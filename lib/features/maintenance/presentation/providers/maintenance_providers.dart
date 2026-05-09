import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/providers/core_providers.dart';
import '../../data/datasources/maintenance_remote_datasource.dart';
import '../../data/repositories/maintenance_repository_impl.dart';
import '../../domain/entities/maintenance_record.dart';
import '../../domain/repositories/maintenance_repository.dart';

final maintenanceRepositoryProvider = Provider<MaintenanceRepository>((ref) {
  return MaintenanceRepositoryImpl(
    MaintenanceRemoteDataSource(ref.read(traccarClientProvider)),
  );
});

class MaintenanceListNotifier extends AsyncNotifier<List<MaintenanceRecordEntity>> {
  String? _keyword;
  int? _deviceId;

  @override
  Future<List<MaintenanceRecordEntity>> build() async {
    return ref.read(maintenanceRepositoryProvider).getRecords(
          keyword: _keyword,
          deviceId: _deviceId,
        );
  }

  Future<void> refresh({String? keyword, int? deviceId}) async {
    _keyword = keyword;
    _deviceId = deviceId;
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(maintenanceRepositoryProvider).getRecords(
            keyword: _keyword,
            deviceId: _deviceId,
          ),
    );
  }
}

final maintenanceListProvider =
    AsyncNotifierProvider<MaintenanceListNotifier, List<MaintenanceRecordEntity>>(
  MaintenanceListNotifier.new,
);

final maintenanceByIdProvider =
    FutureProvider.autoDispose.family<MaintenanceRecordEntity?, int>((ref, id) async {
  final list = await ref.read(maintenanceRepositoryProvider).getRecords();
  for (final r in list) {
    if (r.id == id) return r;
  }
  return null;
});
