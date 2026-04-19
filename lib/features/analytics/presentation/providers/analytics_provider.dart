import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/analytics_data.dart';
import '../../domain/repositories/analytics_repository.dart';
import '../../data/datasources/analytics_remote_datasource.dart';
import '../../data/repositories/analytics_repository_impl.dart';
import '../../../../shared/providers/core_providers.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepositoryImpl(
    AnalyticsRemoteDataSource(ref.read(dioClientProvider)),
  );
});

final analyticsProvider =
    FutureProvider.autoDispose<AnalyticsData>((ref) async {
  return ref.read(analyticsRepositoryProvider).getWeeklyAnalytics();
});
