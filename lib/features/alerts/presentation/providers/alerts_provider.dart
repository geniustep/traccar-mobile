import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/alert.dart';
import '../../domain/repositories/alerts_repository.dart';
import '../../data/datasources/alerts_remote_datasource.dart';
import '../../data/repositories/alerts_repository_impl.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/l10n/locale_provider.dart';
import '../../../drivers/domain/entities/driver.dart';
import '../../../drivers/presentation/providers/drivers_providers.dart';
import '../../../maintenance/domain/entities/maintenance_record.dart';
import '../../../maintenance/presentation/providers/maintenance_providers.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/presentation/providers/vehicles_provider.dart';
import '../../../fleet/presentation/fleet_business_alerts_builder.dart';

final alertsRepositoryProvider = Provider<AlertsRepository>((ref) {
  return AlertsRepositoryImpl(
    AlertsRemoteDataSource(ref.read(traccarClientProvider)),
  );
});

class AlertsNotifier extends StateNotifier<AsyncValue<List<AlertEntity>>> {
  AlertsNotifier(this._repository, this._ref) : super(const AsyncValue.loading()) {
    load();
  }

  final AlertsRepository _repository;
  final Ref _ref;

  Future<void> load() async {
    state = const AsyncValue.loading();
    try {
      final remote = await _repository.getAlerts();
      final synthetic = FleetBusinessAlertsBuilder.build(
        l10n: AppLocalizations(_ref.read(localeProvider)),
        now: DateTime.now(),
        vehicles:
            _ref.read(vehiclesListProvider).valueOrNull ?? const <VehicleEntity>[],
        drivers:
            _ref.read(driversListProvider).valueOrNull ?? const <DriverEntity>[],
        maintenance: _ref.read(maintenanceListProvider).valueOrNull ??
            const <MaintenanceRecordEntity>[],
      );
      final merged = [...synthetic, ...remote]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      state = AsyncValue.data(merged);
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
  (ref) => AlertsNotifier(ref.read(alertsRepositoryProvider), ref),
);

final vehicleAlertsProvider = FutureProvider.autoDispose
    .family<List<AlertEntity>, String>((ref, vehicleId) async {
  final remote = await ref.read(alertsRepositoryProvider).getVehicleAlerts(vehicleId);
  final synthetic = FleetBusinessAlertsBuilder.build(
    l10n: AppLocalizations(ref.read(localeProvider)),
    now: DateTime.now(),
    vehicles: ref.read(vehiclesListProvider).valueOrNull ?? const [],
    drivers: ref.read(driversListProvider).valueOrNull ?? const [],
    maintenance: ref.read(maintenanceListProvider).valueOrNull ?? const [],
  );
  final local = synthetic
      .where((a) => a.vehicleId == vehicleId)
      .toList();
  final merged = [...local, ...remote]
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  return merged;
});

final unreadAlertsCountProvider = Provider.autoDispose<int>((ref) {
  final alerts = ref.watch(alertsProvider);
  return alerts.whenOrNull(data: (list) => list.where((a) => !a.isRead).length) ?? 0;
});
