import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/alert.dart';
import '../../domain/repositories/alerts_repository.dart';
import '../../data/datasources/alerts_remote_datasource.dart';
import '../../data/repositories/alerts_repository_impl.dart';
import '../../../../shared/providers/core_providers.dart';

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return AlertsRepositoryImpl(
    AlertsRemoteDataSource(ref.read(dioClientProvider)),
  );
});

class AlertsNotifier extends StateNotifier<AsyncValue<List<AlertEntity>>> {
  AlertsNotifier(this._repository) : super(const AsyncValue.loading()) {
    load();
  }

  final AlertsRepository _repository;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final alerts = await _repository.getAlerts();
      state = AsyncValue.data(alerts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> markAsRead(String id) async {
    await _repository.markAsRead(id);
    state = state.whenData(
      (alerts) => alerts
          .map((a) => a.id == id ? a.copyWith(isRead: true) : a)
          .toList(),
    );
  }
}

final alertsProvider =
    StateNotifierProvider.autoDispose<AlertsNotifier, AsyncValue<List<AlertEntity>>>(
  (ref) => AlertsNotifier(ref.read(alertsRepositoryProvider)),
);

final vehicleAlertsProvider = FutureProvider.autoDispose
    .family<List<AlertEntity>, String>((ref, vehicleId) async {
  return ref.read(alertsRepositoryProvider).getVehicleAlerts(vehicleId);
});

final unreadAlertsCountProvider = Provider.autoDispose<int>((ref) {
  final alerts = ref.watch(alertsProvider);
  return alerts.whenOrNull(data: (list) => list.where((a) => !a.isRead).length) ?? 0;
});
