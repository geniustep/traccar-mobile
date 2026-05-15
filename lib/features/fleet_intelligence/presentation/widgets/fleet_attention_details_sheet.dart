import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../map/core/trip_segment_models.dart';
import '../../../map/presentation/utils/driver_behavior_score_formatters.dart';
import '../../../map/presentation/utils/trip_formatters.dart';
import '../utils/fleet_attention_center_logic.dart';
import '../utils/fleet_attention_details_formatters.dart';
import '../utils/fleet_intelligence_formatters.dart';
import 'fleet_attention_routes.dart';

Future<void> showFleetAttentionDetailsSheet({
  required BuildContext context,
  required AppLocalizations l10n,
  required FleetAttentionItem item,
  FleetAttentionRoutes routes = const FleetAttentionRoutes(),
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    barrierColor: Colors.black54,
    builder: (sheetContext) => FleetAttentionDetailsSheet(
      l10n: l10n,
      item: item,
      routes: routes,
      sheetNavigator: Navigator.of(sheetContext),
    ),
  );
}

class FleetAttentionDetailsSheet extends StatelessWidget {
  const FleetAttentionDetailsSheet({
    super.key,
    required this.l10n,
    required this.item,
    required this.routes,
    required this.sheetNavigator,
  });

  final AppLocalizations l10n;
  final FleetAttentionItem item;
  final FleetAttentionRoutes routes;
  final NavigatorState sheetNavigator;

  void _popThen(void Function() action) {
    sheetNavigator.pop();
    Future<void>.delayed(Duration.zero, action);
  }

  @override
  Widget build(BuildContext context) {
    final s = item.summary;
    final name = FleetIntelUiFormatters.vehicleLabel(l10n, s);
    final cs = Theme.of(context).colorScheme;
    final reasonsText =
        FleetAttentionDetailsFormatters.reasonsBulleted(l10n, item.reasons);
    final scoreLine =
        FleetAttentionDetailsFormatters.scoreLineIfScorable(l10n, s);
    final stats = FleetAttentionDetailsFormatters.statRows(l10n, s);

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: MediaQuery.viewInsetsOf(context).bottom +
            AppSpacing.screenPadding +
            AppSpacing.sm,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              l10n.fleetAttentionDetailsTitle,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              DriverBehaviorScoreUi.riskLevelLabel(l10n, s.riskLevel),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Divider(color: cs.outline.withValues(alpha: 0.14)),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.fleetAttentionReasons,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              reasonsText.isEmpty ? '—' : reasonsText,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: AppSpacing.md),
            if (scoreLine != null) ...[
              Text(
                l10n.fleetAttentionScore,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                scoreLine,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
              ),
            ] else ...[
              Text(
                l10n.fleetAttentionNoScore,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              ),
            ],
            const SizedBox(height: AppSpacing.md),
            for (final row in stats)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        row.$1,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                      ),
                    ),
                    Text(
                      row.$2,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ],
                ),
              ),
            ..._tripSection(context, s.bestTrip,
                caption: l10n.dailyScoreBestTripLabel),
            ..._tripSection(context, s.worstTrip,
                caption: l10n.dailyScoreWorstTripLabel),
            const SizedBox(height: AppSpacing.md),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.end,
              children: [
                if (routes.openVehicleDetail != null)
                  FilledButton.tonalIcon(
                    onPressed: () => _popThen(
                      () => routes.openVehicleDetail!(s.vehicleId),
                    ),
                    icon: const Icon(Icons.info_outline_rounded, size: 18),
                    label: Text(l10n.fleetAttentionOpenVehicle),
                  ),
                if (routes.openMap != null)
                  FilledButton.tonalIcon(
                    onPressed: () => _popThen(
                      () => routes.openMap!(s.vehicleId),
                    ),
                    icon: const Icon(Icons.map_rounded, size: 18),
                    label: Text(l10n.fleetAttentionOpenMap),
                  ),
                if (routes.openTrips != null)
                  OutlinedButton.icon(
                    onPressed: () => _popThen(
                      () => routes.openTrips!(s.vehicleId),
                    ),
                    icon: const Icon(Icons.route_rounded, size: 18),
                    label: Text(l10n.fleetAttentionOpenTrips),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _tripSection(
    BuildContext context,
    TripSegment? trip, {
    required String caption,
  }) {
    final t = trip;
    if (t == null) return const [];
    return [
      const SizedBox(height: AppSpacing.sm),
      Divider(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12)),
      const SizedBox(height: AppSpacing.sm),
      Text(
        '$caption · ${l10n.tripTitle(t.index)}',
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      const SizedBox(height: 4),
      Text(
        TripUiFormatters.tripSubtitleLine(l10n, t),
        style: Theme.of(context).textTheme.bodySmall,
      ),
      Text(
        TripUiFormatters.tripTimeRangeHm(l10n, t),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
      ),
    ];
  }
}
