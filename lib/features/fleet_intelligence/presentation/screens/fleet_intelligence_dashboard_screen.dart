import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/fleet_intelligence_dashboard_state.dart';
import '../../../map/core/fleet_intelligence_metrics_models.dart';
import '../fleet_dashboard_date_preset.dart';
import '../providers/fleet_intelligence_metrics_provider.dart';
import '../widgets/fleet_attention_center_card.dart';
import '../widgets/fleet_attention_details_sheet.dart';
import '../widgets/fleet_attention_routes.dart';
import '../utils/fleet_intelligence_formatters.dart';

/// لوحة ذكاء الأسطول — **Phase 10C–10E** (مزوّد بيانات + فلاتر + مركز متابعة).
class FleetIntelligenceDashboardScreen extends ConsumerWidget {
  const FleetIntelligenceDashboardScreen({super.key});

  Future<void> _pickCustomRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final st = ref.read(fleetDashboardFilterProvider);
    final initial = st.customRange ??
        DateTimeRange(
          start: DateTime(now.year, now.month, now.day),
          end: now,
        );
    final picked = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 400)),
      lastDate: now,
      initialDateRange: initial,
    );
    if (!context.mounted || picked == null) return;
    ref.read(fleetDashboardFilterProvider.notifier).setCustomRange(picked);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final filter = ref.watch(fleetDashboardFilterProvider);
    final snapshotAsync = ref.watch(fleetIntelligenceMetricsProvider);

    Future<void> reload({required String source}) async {
      AppLogger.fleetIntel('Refresh requested: source=$source');
      ref.read(fleetDashboardFilterProvider.notifier).bumpRefreshNonce();
      ref.invalidate(fleetIntelligenceMetricsProvider);
      await ref.read(fleetIntelligenceMetricsProvider.future);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.fleetIntelTitle),
        actions: [
          IconButton(
            tooltip: l10n.fleetIntelRefresh,
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => reload(source: 'app_bar'),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        onRefresh: () => reload(source: 'pull_to_refresh'),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.sm,
                  AppSpacing.screenPadding,
                  AppSpacing.xs,
                ),
                child: Text(
                  l10n.fleetIntelSubtitle,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.65),
                      ),
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenPadding,
                ),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: FleetDashboardDatePreset.values.map((p) {
                    final selected = filter.datePreset == p;
                    final label = switch (p) {
                      FleetDashboardDatePreset.today => l10n.fleetIntelToday,
                      FleetDashboardDatePreset.yesterday =>
                        l10n.fleetIntelYesterday,
                      FleetDashboardDatePreset.last7Days =>
                        l10n.fleetIntelLast7Days,
                      FleetDashboardDatePreset.custom =>
                        l10n.fleetIntelCustomPeriod,
                    };
                    return FilterChip(
                      label: Text(label),
                      selected: selected,
                      onSelected: (_) async {
                        if (p == FleetDashboardDatePreset.custom) {
                          await _pickCustomRange(context, ref);
                        } else {
                          ref
                              .read(fleetDashboardFilterProvider.notifier)
                              .setDatePreset(p, clearCustom: true);
                        }
                      },
                      selectedColor:
                          AppColors.accent.withValues(alpha: 0.22),
                      checkmarkColor: AppColors.accent,
                    );
                  }).toList(),
                ),
              ),
            ),
            snapshotAsync.when(
              loading: () => const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent),
                ),
              ),
              error: (_, __) => SliverFillRemaining(
                hasScrollBody: false,
                child: _FleetIntelMessageCard(
                  text: l10n.fleetIntelError,
                  trailing: TextButton.icon(
                    onPressed: () => reload(source: 'retry'),
                    icon: const Icon(Icons.refresh_rounded),
                    label: Text(l10n.retry),
                  ),
                ),
              ),
              data: (dash) {
                final m = dash.metrics;
                if (dash.hasFleetMembershipIssue) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _FleetIntelMessageCard(text: l10n.fleetIntelNoData),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding,
                    AppSpacing.md,
                    AppSpacing.screenPadding,
                    32,
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      Text(
                        l10n.fleetIntelUpdatedAt(
                          DateFormatter.toDateTime(
                            dash.generatedAtUtc.toLocal(),
                          ),
                        ),
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurface
                                  .withValues(alpha: 0.55),
                            ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      FleetIntelScoreCard(l10n: l10n, metrics: m),
                      const SizedBox(height: AppSpacing.sm),
                      if (dash.sampleIncomplete ||
                          dash.loadInfo.hasOperationalFailures)
                        Padding(
                          padding:
                              const EdgeInsets.only(bottom: AppSpacing.sm),
                          child: _FleetIntelHintsColumn(
                            l10n: l10n,
                            dash: dash,
                          ),
                        ),
                      FleetIntelMetricGrid(l10n: l10n, metrics: m),
                      const SizedBox(height: AppSpacing.md),
                      FleetIntelRiskDistributionCard(
                        l10n: l10n,
                        dist: m.riskDistribution,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FleetIntelRankingSection(
                        l10n: l10n,
                        metrics: m,
                        onVehicleTap: (id) =>
                            context.push('/vehicles/$id/track'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FleetAttentionCenterCard(
                        l10n: l10n,
                        metrics: m,
                        onAttentionItemTap: (item) {
                          showFleetAttentionDetailsSheet(
                            context: context,
                            l10n: l10n,
                            item: item,
                            routes: FleetAttentionRoutes(
                              openVehicleDetail: (id) =>
                                  context.push('/vehicles/$id'),
                              openMap: (id) =>
                                  context.push('/vehicles/$id/track'),
                              openTrips: (id) =>
                                  context.push('/vehicles/$id/trips'),
                            ),
                          );
                        },
                      ),
                    ]),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// بطاقة الدرجة — لا **`Score 0`** ظاهر عند **`!isScorable`**.
class FleetIntelScoreCard extends StatelessWidget {
  const FleetIntelScoreCard({
    super.key,
    required this.l10n,
    required this.metrics,
  });

  final AppLocalizations l10n;
  final FleetIntelligenceMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final headline = FleetIntelUiFormatters.fleetScoreHeadline(l10n, metrics);
    final secondary =
        FleetIntelUiFormatters.fleetScoreSecondary(l10n, metrics);

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
              l10n.fleetIntelScore,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              headline,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                    color:
                        metrics.isScorable ? cs.primary : cs.onSurfaceVariant,
                  ),
            ),
            if (secondary.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                secondary,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.7),
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class FleetIntelMetricGrid extends StatelessWidget {
  const FleetIntelMetricGrid({
    super.key,
    required this.l10n,
    required this.metrics,
  });

  final AppLocalizations l10n;
  final FleetIntelligenceMetrics metrics;

  @override
  Widget build(BuildContext context) {
    final driveFmt = FleetIntelUiFormatters.formatFleetDuration(
      metrics.totalDrivingDuration,
    );

    final gridItems = <(String, String)>[
      ('${metrics.totalVehicles}', l10n.fleetIntelVehicles),
      ('${metrics.activeVehicles}', l10n.fleetIntelActiveVehicles),
      ('${metrics.inactiveVehicles}', l10n.fleetIntelInactiveVehicles),
      ('${metrics.totalTrips}', l10n.fleetIntelTrips),
      (
        FleetIntelUiFormatters.formatFleetDistanceKm(
          l10n,
          metrics.totalDistanceKm,
        ),
        l10n.fleetIntelDistance,
      ),
      ('${metrics.totalOverspeedEvents}', l10n.fleetIntelOverspeed),
      ('${metrics.totalStops}', l10n.fleetIntelStops),
      (driveFmt, l10n.fleetIntelDrivingTime),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: gridItems.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.85,
      ),
      itemBuilder: (context, i) {
        final val = gridItems[i].$1;
        final subtitle = gridItems[i].$2;
        return DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(
                    alpha: 0.12,
                  ),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  val,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant
                            .withValues(alpha: 0.9),
                      ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// قسم المركبات المميزة (**Phase 10B**) — دون تكرار قائمة **مركز المتابعة** (**10E**).
class FleetIntelRankingSection extends StatelessWidget {
  const FleetIntelRankingSection({
    super.key,
    required this.l10n,
    required this.metrics,
    required this.onVehicleTap,
  });

  final AppLocalizations l10n;
  final FleetIntelligenceMetrics metrics;
  final void Function(String vehicleId) onVehicleTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FleetIntelRankTile(
          label: l10n.fleetIntelBestVehicle,
          summary: metrics.bestVehicleSummary,
          l10n: l10n,
          enabled: metrics.bestVehicleSummary != null,
          onTap: metrics.bestVehicleSummary == null
              ? null
              : () => onVehicleTap(metrics.bestVehicleSummary!.vehicleId),
        ),
        _FleetIntelRankTile(
          label: l10n.fleetIntelWorstVehicle,
          summary: metrics.worstVehicleSummary,
          l10n: l10n,
          enabled: metrics.worstVehicleSummary != null,
          onTap: metrics.worstVehicleSummary == null
              ? null
              : () => onVehicleTap(metrics.worstVehicleSummary!.vehicleId),
        ),
        _FleetIntelRankTile(
          label: l10n.fleetIntelMostActiveVehicle,
          summary: metrics.mostActiveVehicleSummary,
          l10n: l10n,
          enabled: metrics.mostActiveVehicleSummary != null,
          onTap: metrics.mostActiveVehicleSummary == null
              ? null
              : () =>
                  onVehicleTap(metrics.mostActiveVehicleSummary!.vehicleId),
        ),
        _FleetIntelRankTile(
          label: l10n.fleetIntelMostOverspeedVehicle,
          summary: metrics.mostOverspeedVehicleSummary,
          l10n: l10n,
          enabled: metrics.mostOverspeedVehicleSummary != null,
          onTap: metrics.mostOverspeedVehicleSummary == null
              ? null
              : () =>
                  onVehicleTap(metrics.mostOverspeedVehicleSummary!.vehicleId),
        ),
        _FleetIntelRankTile(
          label: l10n.fleetIntelMostStoppedVehicle,
          summary: metrics.mostStoppedVehicleSummary,
          l10n: l10n,
          enabled: metrics.mostStoppedVehicleSummary != null,
          onTap: metrics.mostStoppedVehicleSummary == null
              ? null
              : () =>
                  onVehicleTap(metrics.mostStoppedVehicleSummary!.vehicleId),
        ),
      ],
    );
  }
}

class _FleetIntelRankTile extends StatelessWidget {
  const _FleetIntelRankTile({
    required this.label,
    required this.summary,
    required this.l10n,
    required this.enabled,
    this.onTap,
  });

  final String label;
  final FleetVehicleIntelligenceSummary? summary;
  final AppLocalizations l10n;
  final bool enabled;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final name = FleetIntelUiFormatters.vehicleLabel(l10n, summary);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.outline.withValues(alpha: 0.14)),
              color: cs.surfaceContainerHighest.withValues(alpha: 0.22),
            ),
            child: ListTile(
              dense: true,
              title: Text(
                label,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
              ),
              subtitle: Text(name),
              trailing: Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: !enabled
                    ? cs.onSurfaceVariant.withValues(alpha: 0.25)
                    : cs.onSurfaceVariant,
              ),
              onTap: onTap,
              enabled: enabled,
            ),
          ),
        ),
      ),
    );
  }
}

class FleetIntelRiskDistributionCard extends StatelessWidget {
  const FleetIntelRiskDistributionCard({
    super.key,
    required this.l10n,
    required this.dist,
  });

  final AppLocalizations l10n;
  final FleetRiskDistribution dist;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget line(String caption, int n) =>
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            children: [
              Expanded(child: Text(caption)),
              Text(
                '$n',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        );

    return Card(
      elevation: 0,
      color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.fleetIntelRiskDistribution,
              style:
                  Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
            ),
            const SizedBox(height: 8),
            line(l10n.driverScoreExcellent, dist.excellentCount),
            line(l10n.driverScoreGood, dist.goodCount),
            line(l10n.driverScoreModerate, dist.moderateCount),
            line(l10n.driverScoreHighRisk, dist.highRiskCount),
            line(l10n.driverScoreUnknown, dist.unknownCount),
          ],
        ),
      ),
    );
  }
}

class _FleetIntelHintsColumn extends StatelessWidget {
  const _FleetIntelHintsColumn({
    required this.l10n,
    required this.dash,
  });

  final AppLocalizations l10n;
  final FleetIntelligenceDashboardState dash;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final msgs = <String>[];

    if (dash.sampleIncomplete) {
      msgs.add(
        l10n.fleetIntelSampleNote(
          dash.metrics.totalVehicles,
          dash.loadInfo.fleetRegisteredCount,
          dash.query.maxVehicles,
        ),
      );
      msgs.add(
        l10n.fleetIntelLimitedToVehicles(dash.query.maxVehicles),
      );
    }

    if (dash.loadInfo.hasOperationalFailures) {
      msgs.add(l10n.fleetIntelPartialRoutes);
      msgs.add(
        l10n.fleetIntelAnalyzedVehicles(
          dash.loadInfo.routesAnalyzed,
          dash.loadInfo.fleetRegisteredCount,
        ),
      );
      msgs.add(l10n.fleetIntelPartialData);
    } else if (dash.loadInfo.isLimitedSample) {
      msgs.add(
        l10n.fleetIntelAnalyzedVehicles(
          dash.loadInfo.routesAnalyzed,
          dash.loadInfo.fleetRegisteredCount,
        ),
      );
    }

    if (msgs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: msgs.map((text) {
        return Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          margin: const EdgeInsets.only(bottom: 6),
          decoration: BoxDecoration(
            color: cs.primaryContainer.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(text, style: Theme.of(context).textTheme.bodySmall),
        );
      }).toList(),
    );
  }
}

class _FleetIntelMessageCard extends StatelessWidget {
  const _FleetIntelMessageCard({
    required this.text,
    this.trailing,
  });

  final String text;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(text, textAlign: TextAlign.center),
            if (trailing != null) ...[
              const SizedBox(height: AppSpacing.sm),
              trailing!,
            ],
          ],
        ),
      ),
    );
  }
}
