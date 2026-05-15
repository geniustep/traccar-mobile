import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../map/core/fleet_intelligence_metrics_config.dart';
import '../../../map/core/fleet_intelligence_metrics_models.dart';
import '../utils/fleet_attention_center_logic.dart';
import '../utils/fleet_attention_details_formatters.dart';
import '../utils/fleet_intelligence_formatters.dart';

/// مركز المتابعة — **Phase 10E**.
class FleetAttentionCenterCard extends StatelessWidget {
  const FleetAttentionCenterCard({
    super.key,
    required this.l10n,
    required this.metrics,
    this.onAttentionItemTap,
    FleetIntelligenceMetricsConfig config =
        FleetIntelligenceMetricsConfig.defaults,
  }) : config = config;

  final AppLocalizations l10n;
  final FleetIntelligenceMetrics metrics;
  final void Function(FleetAttentionItem item)? onAttentionItemTap;
  final FleetIntelligenceMetricsConfig config;

  @override
  Widget build(BuildContext context) {
    final items = FleetAttentionCenterLogic.buildItems(
      summaries: metrics.vehicleSummaries,
      config: config,
    );

    final cs = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              l10n.fleetAttentionTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: AppSpacing.sm),
            if (items.isEmpty)
              Text(
                l10n.fleetAttentionNone,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
              )
            else
              ...items.map((e) => _AttentionTile(
                    l10n: l10n,
                    item: e,
                    onTap: onAttentionItemTap == null
                        ? null
                        : () => onAttentionItemTap!(e),
                  )),
          ],
        ),
      ),
    );
  }
}

class _AttentionTile extends StatelessWidget {
  const _AttentionTile({
    required this.l10n,
    required this.item,
    this.onTap,
  });

  final AppLocalizations l10n;
  final FleetAttentionItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final s = item.summary;
    final name = FleetIntelUiFormatters.vehicleLabel(l10n, s);
    final reasons =
        FleetAttentionDetailsFormatters.reasonsInline(l10n, item.reasons);
    final scoreLine = s.isPeriodScorable && s.periodScore != null
        ? '${l10n.driverScoreLabel} ${s.periodScore}'
        : null;

    final distShort = FleetIntelUiFormatters.formatFleetDistanceKm(
      l10n,
      s.totalDistanceKm,
    );

    final cs = Theme.of(context).colorScheme;

    final subtitle = [
      reasons,
      if (scoreLine != null) scoreLine,
      '${s.totalTrips} ${l10n.fleetIntelTrips} · $distShort',
    ].join('\n');

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
              color: cs.surface.withValues(alpha: 0.4),
            ),
            child: ListTile(
              dense: true,
              title: Text(
                name,
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              subtitle: Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      height: 1.35,
                      color: cs.onSurface.withValues(alpha: 0.75),
                    ),
              ),
              trailing: Tooltip(
                message: l10n.fleetAttentionDetailsTitle,
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.accent.withValues(alpha: 0.9),
                ),
              ),
              onTap: onTap,
              enabled: onTap != null,
            ),
          ),
        ),
      ),
    );
  }
}
