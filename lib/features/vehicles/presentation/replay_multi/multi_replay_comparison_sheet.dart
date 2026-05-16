import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import 'multi_replay_kpi.dart';
import 'multi_replay_kpi_formatters.dart';
import 'multi_vehicle_replay_controller.dart';
import 'multi_vehicle_replay_model.dart';
import 'multi_vehicle_replay_ui.dart';

/// Bottom sheet for multi-replay KPI comparison (Phase R8).
abstract final class MultiReplayComparisonSheet {
  MultiReplayComparisonSheet._();

  static Future<void> show(
    BuildContext context, {
    required MultiReplayComparisonSummary summary,
    required List<MultiVehicleReplayTrack> tracks,
    required MultiVehicleReplayPlaybackState playback,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => _MultiReplayComparisonBody(
        summary: summary,
        tracks: tracks,
        playback: playback,
      ),
    );
  }
}

class _MultiReplayComparisonBody extends StatelessWidget {
  const _MultiReplayComparisonBody({
    required this.summary,
    required this.tracks,
    required this.playback,
  });

  final MultiReplayComparisonSummary summary;
  final List<MultiVehicleReplayTrack> tracks;
  final MultiVehicleReplayPlaybackState playback;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final eligible = summary.withEnoughData();
    final maxHeight = MediaQuery.sizeOf(context).height * 0.72;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  8,
                ),
                child: Text(
                  l10n.multiReplayComparison,
                  style: AppTextStyles.labelLarge.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text(
                  l10n.multiReplayKpiLoadedNote,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMutedOf(context),
                  ),
                ),
              ),
              if (eligible.length < 2) ...[
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Text(
                    l10n.multiReplayInsufficientData,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
              ],
              if (summary.insights.isNotEmpty) ...[
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Text(
                    l10n.multiReplaySummary,
                    style: AppTextStyles.labelMedium.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                SizedBox(
                  height: 72,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      8,
                      AppSpacing.md,
                      8,
                    ),
                    itemCount: summary.insights.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, i) =>
                        _InsightChip(insight: summary.insights[i]),
                  ),
                ),
              ],
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.md,
                    4,
                    AppSpacing.md,
                    AppSpacing.md,
                  ),
                  itemCount: tracks.length,
                  itemBuilder: (context, i) {
                    final track = tracks[i];
                    final kpi = summary.kpisByVehicleId[track.vehicleId];
                    if (kpi == null) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _VehicleKpiCard(
                        track: track,
                        kpi: kpi,
                        isActive: playback.activeVehicleId == track.vehicleId,
                        isHidden: !playback.vehicleVisible(track.vehicleId),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.md,
                  0,
                  AppSpacing.md,
                  8,
                ),
                child: Text(
                  l10n.multiReplayDistanceApproxNote,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMutedOf(context),
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightChip extends StatelessWidget {
  const _InsightChip({required this.insight});

  final MultiReplayComparisonInsight insight;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final label = switch (insight.kind) {
      MultiReplayInsightKind.longestDistance => l10n.highestDistance,
      MultiReplayInsightKind.longestStoppedTime =>
        l10n.multiReplayInsightLongestStop,
      MultiReplayInsightKind.highestMaxSpeed =>
        l10n.multiReplayInsightHighestSpeed,
      MultiReplayInsightKind.mostOverspeeds =>
        l10n.multiReplayInsightMostOverspeed,
      MultiReplayInsightKind.firstMovement =>
        l10n.multiReplayInsightFirstMovement,
      MultiReplayInsightKind.earliestRouteEnd =>
        l10n.multiReplayInsightEarliestEnd,
    };

    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.textMutedOf(context).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: AppColors.textMutedOf(context).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMutedOf(context),
              fontSize: 10,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            MultiVehicleReplayUi.shortVehicleLabel(
              insight.vehicleName,
              insight.vehicleId,
            ),
            style: AppTextStyles.labelMedium.copyWith(
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _VehicleKpiCard extends StatelessWidget {
  const _VehicleKpiCard({
    required this.track,
    required this.kpi,
    required this.isActive,
    required this.isHidden,
  });

  final MultiVehicleReplayTrack track;
  final MultiReplayKpi kpi;
  final bool isActive;
  final bool isHidden;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Opacity(
      opacity: isHidden ? 0.55 : 1,
      child: Material(
        elevation: 1,
        borderRadius: BorderRadius.circular(12),
        color: isActive
            ? track.color.withValues(alpha: 0.1)
            : Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isActive
                  ? track.color
                  : track.color.withValues(alpha: 0.35),
              width: isActive ? 2 : 1,
            ),
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 16,
                    height: 4,
                    decoration: BoxDecoration(
                      color: track.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      MultiVehicleReplayUi.shortVehicleLabel(
                        track.name,
                        track.vehicleId,
                      ),
                      style: AppTextStyles.labelLarge.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  if (isActive)
                    Text(
                      l10n.multiReplayActiveVehicle,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: track.color,
                        fontWeight: FontWeight.w700,
                        fontSize: 10,
                      ),
                    ),
                  if (isHidden)
                    Text(
                      l10n.multiReplayHiddenVehicle,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textMutedOf(context),
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
              if (!kpi.hasEnoughData) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.multiReplayInsufficientData,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.warning,
                  ),
                ),
              ] else ...[
                const SizedBox(height: 10),
                _KpiGrid(kpi: kpi),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _KpiGrid extends StatelessWidget {
  const _KpiGrid({required this.kpi});

  final MultiReplayKpi kpi;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: [
        _KpiCell(
          label: l10n.distanceLabel,
          value: MultiReplayKpiFormatters.distanceKm(kpi.totalDistanceKm),
        ),
        _KpiCell(
          label: l10n.multiReplayMovingTime,
          value: MultiReplayKpiFormatters.duration(kpi.movingDuration),
        ),
        _KpiCell(
          label: l10n.multiReplayStoppedTime,
          value: MultiReplayKpiFormatters.duration(kpi.stoppedDuration),
        ),
        _KpiCell(
          label: l10n.maxSpeed,
          value: MultiReplayKpiFormatters.speedKmh(kpi.maxSpeedKmh),
        ),
        _KpiCell(
          label: l10n.averageSpeed,
          value: MultiReplayKpiFormatters.speedKmh(kpi.averageMovingSpeedKmh),
        ),
        _KpiCell(
          label: l10n.stopsCountLabel,
          value: MultiReplayKpiFormatters.count(kpi.stopsCount),
        ),
        _KpiCell(
          label: l10n.overspeedEvents,
          value: MultiReplayKpiFormatters.count(kpi.overspeedCount),
        ),
        _KpiCell(
          label: l10n.multiReplayRouteStart,
          value: MultiReplayKpiFormatters.time(kpi.firstPointTime),
        ),
        _KpiCell(
          label: l10n.multiReplayRouteEnd,
          value: MultiReplayKpiFormatters.time(kpi.lastPointTime),
        ),
      ],
    );
  }
}

class _KpiCell extends StatelessWidget {
  const _KpiCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMutedOf(context),
              fontSize: 10,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
