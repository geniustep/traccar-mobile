import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../providers/reports_providers.dart';
import '../widgets/speed_chart.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ChartsReportScreen
// Full-screen speed chart for a given route.
// ─────────────────────────────────────────────────────────────────────────────

class ChartsReportScreen extends ConsumerWidget {
  const ChartsReportScreen({
    super.key,
    required this.params,
    required this.vehicleName,
  });

  final ReportFilterParams params;
  final String vehicleName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final routeAsync = ref.watch(reportRouteProvider(params));

    return Scaffold(
      backgroundColor: AppColors.backgroundOf(context),
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(l10n.speedChartTitle),
            Text(
              '$vehicleName · ${DateFormatter.toDate(params.from.toLocal())} → ${DateFormatter.toDate(params.to.toLocal())}',
              style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.show_chart_rounded,
                      size: 12, color: AppColors.accent),
                  SizedBox(width: 4),
                  Text(
                    'km/h',
                    style: TextStyle(
                        fontSize: 10,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      body: routeAsync.when(
        loading: () => LoadingView(message: l10n.loadingRoute),
        error: (e, _) => ErrorView(
          message: l10n.errorLoadingRoute,
          onRetry: () => ref.invalidate(reportRouteProvider(params)),
        ),
        data: (points) => SpeedChartWidget(points: points),
      ),
    );
  }
}
