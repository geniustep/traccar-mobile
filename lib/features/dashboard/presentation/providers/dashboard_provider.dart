import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/dashboard_summary.dart';
import '../../domain/entities/insight.dart';
import '../../domain/repositories/dashboard_repository.dart';
import '../../data/datasources/dashboard_remote_datasource.dart';
import '../../data/repositories/dashboard_repository_impl.dart';
import '../../../../shared/providers/core_providers.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepositoryImpl(
    DashboardRemoteDataSource(ref.read(dioClientProvider)),
  );
});

final dashboardSummaryProvider =
    FutureProvider.autoDispose<DashboardSummary>((ref) async {
  return ref.read(dashboardRepositoryProvider).getSummary();
});

final dashboardInsightsProvider =
    FutureProvider.autoDispose<List<InsightEntity>>((ref) async {
  return ref.read(dashboardRepositoryProvider).getInsights();
});

// Combined refresh notifier
class DashboardNotifier extends StateNotifier<AsyncValue<void>> {
  DashboardNotifier(this._ref) : super(const AsyncValue.data(null));

  final Ref _ref;

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    try {
      _ref.invalidate(dashboardSummaryProvider);
      _ref.invalidate(dashboardInsightsProvider);
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}

final dashboardNotifierProvider =
    StateNotifierProvider.autoDispose<DashboardNotifier, AsyncValue<void>>((ref) {
  return DashboardNotifier(ref);
});
