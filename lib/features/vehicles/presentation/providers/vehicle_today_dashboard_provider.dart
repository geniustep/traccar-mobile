import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../alerts/presentation/providers/alerts_provider.dart'
    show alertsRepositoryProvider;
import '../../../reports/domain/entities/summary_report.dart';
import '../../../reports/presentation/providers/reports_providers.dart';
import '../../domain/entities/vehicle_today_dashboard.dart';

/// Today's KPI bundle for [VehicleDetailScreen] (summary + stops + alerts).
final vehicleTodayDashboardProvider = FutureProvider.autoDispose
    .family<VehicleTodayDashboard, String>((ref, vehicleId) async {
  final now = DateTime.now();
  final todayStart = DateTime(now.year, now.month, now.day);
  final from = todayStart.toUtc();
  final to = now.toUtc();

  final reportsRepo = ref.read(reportsRepositoryProvider);

  SummaryReport? summary;
  var stopsCount = 0;
  var totalStopSeconds = 0;

  try {
    summary = await reportsRepo.getSummary(
      deviceId: vehicleId,
      from: from,
      to: to,
      trigger: 'vehicle_detail_today',
    );
  } catch (_) {
    summary = null;
  }

  try {
    final stops = await reportsRepo.getStops(
      deviceId: vehicleId,
      from: from,
      to: to,
      trigger: 'vehicle_detail_today',
    );
    stopsCount = stops.length;
    for (final s in stops) {
      totalStopSeconds += s.durationSeconds;
    }
  } catch (_) {
    stopsCount = 0;
    totalStopSeconds = 0;
  }

  var alertsTodayCount = 0;
  try {
    final alerts =
        await ref.read(alertsRepositoryProvider).getVehicleAlerts(vehicleId);
    alertsTodayCount = alerts
        .where((a) =>
            !a.createdAt.isBefore(todayStart) && !a.createdAt.isAfter(now))
        .length;
  } catch (_) {
    alertsTodayCount = 0;
  }

  return VehicleTodayDashboard(
    summary: summary,
    stopsCount: stopsCount,
    totalStopSeconds: totalStopSeconds,
    alertsTodayCount: alertsTodayCount,
  );
});
