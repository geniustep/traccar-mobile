import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/elmo_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../comparison/vehicle_comparison_formatters.dart';
import '../replay_multi/multi_vehicle_replay_formatters.dart';
import '../replay_multi/multi_vehicle_replay_screen.dart';
import '../comparison/vehicle_comparison_model.dart';
import '../providers/vehicle_comparison_provider.dart';

class VehicleComparisonScreen extends ConsumerStatefulWidget {
  const VehicleComparisonScreen({
    super.key,
    required this.initialVehicleIds,
  });

  final List<String> initialVehicleIds;

  @override
  ConsumerState<VehicleComparisonScreen> createState() =>
      _VehicleComparisonScreenState();
}

class _VehicleComparisonScreenState
    extends ConsumerState<VehicleComparisonScreen> {
  late List<String> _vehicleIds;

  @override
  void initState() {
    super.initState();
    _vehicleIds = List<String>.from(widget.initialVehicleIds);
    AppLogger.comparison(
      'comparison_opened count=${_vehicleIds.length}',
    );
  }

  void _removeVehicle(String vehicleId) {
    AppLogger.comparison('comparison_vehicle_removed vehicleId=$vehicleId');
    setState(() {
      _vehicleIds =
          VehicleComparisonFormatters.removeVehicle(_vehicleIds, vehicleId);
    });
    if (_vehicleIds.length < 2) {
      AppLogger.comparison('comparison_empty_selection');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    if (!VehicleComparisonFormatters.canCompare(_vehicleIds.length)) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.vehicleComparisonTitle)),
        body: _InvalidSelectionBody(
          message: _vehicleIds.isEmpty
              ? l10n.noComparisonData
              : l10n.selectAtLeastTwoVehicles,
          onBackToMap: () => context.go('/map'),
        ),
      );
    }

    final request = VehicleComparisonRequest(vehicleIds: _vehicleIds);
    final comparisonAsync = ref.watch(vehicleComparisonLoaderProvider(request));

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.vehicleComparisonTitle),
      ),
      body: comparisonAsync.when(
        loading: () => _ComparisonLoadingBody(
          vehicleCount: _vehicleIds.length,
        ),
        error: (e, _) => _InvalidSelectionBody(
          message: l10n.comparisonLoadFailed,
          onBackToMap: () => context.go('/map'),
        ),
        data: (state) {
          if (state.hasError) {
            return _InvalidSelectionBody(
              message: l10n.comparisonLoadFailed,
              onBackToMap: () => context.go('/map'),
            );
          }

          if (!VehicleComparisonFormatters.canCompare(_vehicleIds.length)) {
            return _InvalidSelectionBody(
              message: l10n.selectAtLeastTwoVehicles,
              onBackToMap: () => context.go('/map'),
            );
          }

          final highlights = state.highlights;
          final items = state.items;

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(vehicleComparisonLoaderProvider(request));
              await ref.read(vehicleComparisonLoaderProvider(request).future);
            },
            child: ListView(
              padding: const EdgeInsets.all(AppSpacing.md),
              children: [
                Text(
                  l10n.todayComparison,
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textMutedOf(context),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.comparedVehiclesCount(_vehicleIds.length),
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                if (MultiVehicleReplayFormatters.canReplay(_vehicleIds.length) &&
                    _vehicleIds.length <= 5)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => openMultiVehicleReplay(
                          context,
                          vehicleIds: List<String>.from(_vehicleIds),
                        ),
                        icon: const Icon(Icons.play_circle_outline_rounded),
                        label: Text(l10n.replayComparedVehicles),
                      ),
                    ),
                  ),
                _SummaryHighlightsRow(
                  highlights: highlights,
                  items: items,
                ),
                const SizedBox(height: AppSpacing.md),
                ...items.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _ComparisonVehicleCard(
                      item: item,
                      highlights: highlights,
                      onRemove: () => _removeVehicle(item.vehicleId),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Loading with skeleton cards; secondary message after 1s.
class _ComparisonLoadingBody extends StatefulWidget {
  const _ComparisonLoadingBody({required this.vehicleCount});

  final int vehicleCount;

  @override
  State<_ComparisonLoadingBody> createState() => _ComparisonLoadingBodyState();
}

class _ComparisonLoadingBodyState extends State<_ComparisonLoadingBody> {
  bool _showAnalyzingHint = false;

  @override
  void initState() {
    super.initState();
    Future<void>.delayed(const Duration(milliseconds: 1000), () {
      if (mounted) setState(() => _showAnalyzingHint = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final skeletonCount = widget.vehicleCount.clamp(2, 4);

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        const Center(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.accent,
              ),
            ),
          ),
        ),
        Text(
          l10n.comparisonLoading,
          style: AppTextStyles.bodyMedium,
          textAlign: TextAlign.center,
        ),
        if (_showAnalyzingHint) ...[
          const SizedBox(height: 8),
          Text(
            l10n.comparisonLoadingAnalyzing,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textMutedOf(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: AppSpacing.lg),
        ...List.generate(
          skeletonCount,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: ElmoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 16,
                    width: 140,
                    decoration: BoxDecoration(
                      color: AppColors.textMutedOf(context)
                          .withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.textMutedOf(context)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.textMutedOf(context)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _InvalidSelectionBody extends StatelessWidget {
  const _InvalidSelectionBody({
    required this.message,
    required this.onBackToMap,
  });

  final String message;
  final VoidCallback onBackToMap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.compare_arrows_rounded,
              size: 48,
              color: AppColors.textMutedOf(context),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: onBackToMap,
              child: Text(l10n.backToMap),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryHighlightsRow extends StatelessWidget {
  const _SummaryHighlightsRow({
    required this.highlights,
    required this.items,
  });

  final VehicleComparisonHighlights highlights;
  final List<VehicleComparisonItem> items;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _HighlightChip(
                label: l10n.highestDistance,
                vehicleName: VehicleComparisonFormatters.vehicleNameForId(
                  items,
                  highlights.highestDistanceVehicleId,
                ),
                icon: Icons.route_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _HighlightChip(
                label: l10n.highestAlerts,
                vehicleName: VehicleComparisonFormatters.vehicleNameForId(
                  items,
                  highlights.highestAlertsVehicleId,
                ),
                icon: Icons.notifications_active_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _HighlightChip(
                label: l10n.highestStopDuration,
                vehicleName: VehicleComparisonFormatters.vehicleNameForId(
                  items,
                  highlights.highestStopDurationVehicleId,
                ),
                icon: Icons.pause_circle_outline_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _HighlightChip(
                label: l10n.mostRecentUpdate,
                vehicleName: VehicleComparisonFormatters.vehicleNameForId(
                  items,
                  highlights.mostRecentUpdateVehicleId,
                ),
                icon: Icons.update_rounded,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _HighlightChip extends StatelessWidget {
  const _HighlightChip({
    required this.label,
    required this.vehicleName,
    required this.icon,
  });

  final String label;
  final String? vehicleName;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return ElmoCard(
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.accent),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMutedOf(context),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            vehicleName ?? VehicleComparisonFormatters.emptyValue,
            style: AppTextStyles.labelLarge,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ComparisonVehicleCard extends StatelessWidget {
  const _ComparisonVehicleCard({
    required this.item,
    required this.highlights,
    required this.onRemove,
  });

  final VehicleComparisonItem item;
  final VehicleComparisonHighlights highlights;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final id = item.vehicleId;

    bool highlight(String? winnerId) => winnerId == id;

    return ElmoCard(
      borderColor: highlight(highlights.highestDistanceVehicleId) ||
              highlight(highlights.highestAlertsVehicleId) ||
              highlight(highlights.highestStopDurationVehicleId) ||
              highlight(highlights.mostRecentUpdateVehicleId)
          ? AppColors.accent.withValues(alpha: 0.45)
          : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: AppTextStyles.headlineSmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.plate != null && item.plate!.isNotEmpty)
                      Text(
                        item.plate!,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMutedOf(context),
                        ),
                      ),
                  ],
                ),
              ),
              if (item.status != null) ...[
                const SizedBox(width: 4),
                Flexible(
                  child: StatusBadge(
                    status: StatusBadge.fromString(item.status!),
                  ),
                ),
              ],
              IconButton(
                tooltip: l10n.removeFromComparison,
                onPressed: onRemove,
                icon: const Icon(Icons.close_rounded, size: 20),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _MetricGrid(
            metrics: [
              _MetricCell(
                label: l10n.distanceToday,
                value: VehicleComparisonFormatters.formatDistanceKm(
                  item.distanceKm,
                ),
                emphasized: highlight(highlights.highestDistanceVehicleId),
              ),
              _MetricCell(
                label: l10n.tripsToday,
                value: VehicleComparisonFormatters.formatCount(item.tripsCount),
              ),
              _MetricCell(
                label: l10n.stopsToday,
                value: VehicleComparisonFormatters.formatCount(item.stopsCount),
              ),
              _MetricCell(
                label: l10n.alertsToday,
                value: VehicleComparisonFormatters.formatCount(item.alertsToday),
                emphasized: highlight(highlights.highestAlertsVehicleId),
              ),
              _MetricCell(
                label: l10n.maxSpeed,
                value: VehicleComparisonFormatters.formatSpeedKmh(
                  item.maxSpeedKmh,
                ),
              ),
              _MetricCell(
                label: l10n.stopDuration,
                value: VehicleComparisonFormatters.formatDurationSeconds(
                  item.stopDurationSeconds,
                ),
                emphasized:
                    highlight(highlights.highestStopDurationVehicleId),
              ),
              _MetricCell(
                label: l10n.lastUpdate,
                value: VehicleComparisonFormatters.formatLastUpdate(
                  item.lastUpdate,
                ),
                emphasized: highlight(highlights.mostRecentUpdateVehicleId),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({required this.metrics});

  final List<_MetricCell> metrics;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: metrics
          .map(
            (m) => SizedBox(
              width: (MediaQuery.sizeOf(context).width - 48) / 2 - 4,
              child: m,
            ),
          )
          .toList(),
    );
  }
}

class _MetricCell extends StatelessWidget {
  const _MetricCell({
    required this.label,
    required this.value,
    this.emphasized = false,
  });

  final String label;
  final String value;
  final bool emphasized;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: emphasized
            ? AppColors.accent.withValues(alpha: 0.1)
            : AppColors.surfaceOf(context).withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
        border: emphasized
            ? Border.all(color: AppColors.accent.withValues(alpha: 0.35))
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMutedOf(context),
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTextStyles.labelLarge.copyWith(
              fontWeight: emphasized ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
