import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../alerts/domain/entities/alert.dart';
import '../../../alerts/presentation/providers/alerts_provider.dart';
import '../../core/replay_external_event.dart';
import '../../core/replay_external_event_mapper.dart';
import 'reports_providers.dart';

/// Fetches report events + backend alerts once for the replay period (Phase R4).
final replayPeriodExternalEventsProvider = FutureProvider.autoDispose
    .family<List<ReplayExternalEvent>, ReportFilterParams>((ref, params) async {
  final events = await ref.watch(eventsReportProvider(params).future);

  final deviceId = int.tryParse(params.vehicleId);
  final alerts = deviceId == null
      ? const <AlertEntity>[]
      : await ref.read(alertsRepositoryProvider).getAlerts(
            deviceId: deviceId,
            from: params.from,
            to: params.to,
            limit: ReplayExternalEventMapper.maxBackendAlerts,
            status: 'all',
          );

  return ReplayExternalEventMapper.mergeSources(
    reportEvents: events,
    alerts: alerts,
  );
});
