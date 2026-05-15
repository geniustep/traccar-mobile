import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../providers/reports_providers.dart';
import 'route_report_map_screen.dart';

/// Phase 8C — focuses the shared route map stack on one segmented trip window.
///
/// Loads points via existing [reportRouteProvider] (+ [ReportFilterParams]) and enables
/// a shortcut to replay the same window ([ReplayReportScreen]).
class TripDetailMapScreen extends StatelessWidget {
  const TripDetailMapScreen({
    super.key,
    required this.params,
    required this.vehicleName,
    required this.subtitleLine,
  });

  final ReportFilterParams params;
  final String vehicleName;
  final String subtitleLine;

  @override
  Widget build(BuildContext context) {
    return RouteReportMapScreen(
      params: params,
      vehicleName: vehicleName,
      contextualSubtitle: subtitleLine,
      onOpenReplayShortcut: () => context.push(
        '/reports/replay',
        extra: <String, dynamic>{
          'params': params,
          'vehicleName': vehicleName,
        },
      ),
    );
  }
}
