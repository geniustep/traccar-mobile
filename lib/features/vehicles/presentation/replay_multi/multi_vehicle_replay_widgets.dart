import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../reports/presentation/providers/replay_controller.dart';
import 'multi_vehicle_replay_controller.dart';
import 'multi_vehicle_replay_formatters.dart';
import 'multi_vehicle_replay_model.dart';
import 'multi_vehicle_replay_timeline.dart';
import 'multi_vehicle_replay_ui.dart';

class MultiVehicleReplayTimeCard extends StatelessWidget {
  const MultiVehicleReplayTimeCard({
    super.key,
    required this.currentTime,
    required this.playbackSpeed,
    required this.isPlaying,
  });

  final DateTime? currentTime;
  final PlaybackSpeed playbackSpeed;
  final bool isPlaying;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scheme = Theme.of(context).colorScheme;

    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(10),
      color: scheme.surface.withValues(alpha: 0.94),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isPlaying ? Icons.play_circle_fill : Icons.pause_circle_filled,
              size: 18,
              color: isPlaying ? AppColors.success : AppColors.textMutedOf(context),
            ),
            const SizedBox(width: 6),
            Text(
              MultiVehicleReplayFormatters.formatReplayTime(currentTime),
              style: AppTextStyles.labelMedium.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                playbackSpeed.label,
                style: AppTextStyles.labelSmall.copyWith(
                  color: scheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isPlaying ? l10n.replayPlaying : l10n.replayPaused,
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.textMutedOf(context),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MultiVehicleReplayRecenterButton extends StatelessWidget {
  const MultiVehicleReplayRecenterButton({super.key, required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Material(
      elevation: 3,
      borderRadius: BorderRadius.circular(8),
      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.94),
      child: IconButton(
        icon: const Icon(Icons.center_focus_strong_rounded, size: 22),
        tooltip: l10n.replayRecenter,
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

class MultiVehicleReplayLegend extends StatelessWidget {
  const MultiVehicleReplayLegend({
    super.key,
    required this.tracks,
    required this.playback,
    required this.onVisibility,
    required this.labelsEnabled,
    required this.onToggleLabels,
  });

  final List<MultiVehicleReplayTrack> tracks;
  final MultiVehicleReplayPlaybackState playback;
  final void Function(String vehicleId, bool visible) onVisibility;
  final bool labelsEnabled;
  final VoidCallback onToggleLabels;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return Material(
      elevation: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 6, 4, 0),
            child: Row(
              children: [
                Text(
                  l10n.replayMapLegend,
                  style: AppTextStyles.labelSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMutedOf(context),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    labelsEnabled
                        ? Icons.label_rounded
                        : Icons.label_off_outlined,
                    size: 20,
                  ),
                  tooltip: labelsEnabled
                      ? l10n.replayHideLabels
                      : l10n.replayShowLabels,
                  onPressed: onToggleLabels,
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          ),
          SizedBox(
            height: 76,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.md,
                4,
                AppSpacing.md,
                8,
              ),
              itemCount: tracks.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) =>
                  _LegendTile(
                track: tracks[i],
                playback: playback,
                onVisibility: onVisibility,
                l10n: l10n,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendTile extends StatelessWidget {
  const _LegendTile({
    required this.track,
    required this.playback,
    required this.onVisibility,
    required this.l10n,
  });

  final MultiVehicleReplayTrack track;
  final MultiVehicleReplayPlaybackState playback;
  final void Function(String vehicleId, bool visible) onVisibility;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final visible = playback.vehicleVisible(track.vehicleId);
    final hasData = track.hasData;
    final status = MultiVehicleReplayUi.legendStatus(
      hasData: hasData,
      visible: visible,
    );

    final statusText = switch (status) {
      MultiVehicleReplayLegendStatus.noData => l10n.replayVehicleNoData,
      MultiVehicleReplayLegendStatus.hidden => l10n.replayVehicleHidden,
      MultiVehicleReplayLegendStatus.active => l10n.replayVehicleActive,
    };

    final subtitle = !hasData
        ? null
        : (track.distanceMeters != null
            ? MultiVehicleReplayFormatters.formatDistance(track.distanceMeters)
            : l10n.replayPointsCount(track.allPoints.length));

    return InkWell(
      onTap: hasData ? () => onVisibility(track.vehicleId, !visible) : null,
      borderRadius: BorderRadius.circular(10),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 180),
        opacity: status == MultiVehicleReplayLegendStatus.hidden ? 0.5 : 1,
        child: Container(
          width: 118,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: status == MultiVehicleReplayLegendStatus.hidden
                  ? AppColors.textMutedOf(context).withValues(alpha: 0.35)
                  : track.color.withValues(alpha: 0.45),
            ),
            color: status == MultiVehicleReplayLegendStatus.hidden
                ? AppColors.textMutedOf(context).withValues(alpha: 0.06)
                : track.color.withValues(alpha: 0.08),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                    width: 14,
                    height: 3,
                    decoration: BoxDecoration(
                      color: track.color,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      MultiVehicleReplayUi.shortVehicleLabel(
                        track.name,
                        track.vehicleId,
                      ),
                      style: AppTextStyles.labelSmall.copyWith(
                        decoration: status ==
                                MultiVehicleReplayLegendStatus.hidden
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasData)
                    Icon(
                      visible
                          ? Icons.visibility_rounded
                          : Icons.visibility_off_rounded,
                      size: 16,
                      color: AppColors.textMutedOf(context),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                statusText,
                style: AppTextStyles.bodySmall.copyWith(
                  color: status == MultiVehicleReplayLegendStatus.noData
                      ? AppColors.warning
                      : AppColors.textMutedOf(context),
                  fontSize: 10,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textMutedOf(context),
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class MultiVehicleReplayControlsBar extends StatelessWidget {
  const MultiVehicleReplayControlsBar({
    super.key,
    required this.playback,
    required this.timeline,
    required this.onPlay,
    required this.onPause,
    required this.onReset,
    required this.onSeek,
    required this.onSpeed,
    required this.l10n,
  });

  final MultiVehicleReplayPlaybackState playback;
  final MultiVehicleReplayTimeline? timeline;
  final VoidCallback onPlay;
  final VoidCallback onPause;
  final VoidCallback onReset;
  final ValueChanged<double> onSeek;
  final ValueChanged<PlaybackSpeed> onSpeed;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final start = timeline?.startTime;
    final end = timeline?.endTime;
    final current = playback.currentTime;
    final hasTimeline = timeline != null && !timeline!.isEmpty;

    return SafeArea(
      top: false,
      child: Material(
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      MultiVehicleReplayFormatters.formatReplayTime(start),
                      style: AppTextStyles.bodySmall.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      MultiVehicleReplayFormatters.formatReplayTime(current),
                      style: AppTextStyles.labelMedium.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      MultiVehicleReplayFormatters.formatReplayTime(end),
                      style: AppTextStyles.bodySmall.copyWith(
                        fontFeatures: const [FontFeature.tabularFigures()],
                      ),
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 3,
                  thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
                ),
                child: Slider(
                  value: playback.progress.clamp(0, 1),
                  onChanged: hasTimeline ? onSeek : null,
                ),
              ),
              Row(
                children: [
                  FilledButton.tonalIcon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                    onPressed: !hasTimeline
                        ? null
                        : (playback.isPlaying ? onPause : onPlay),
                    icon: Icon(
                      playback.isPlaying
                          ? Icons.pause_rounded
                          : Icons.play_arrow_rounded,
                      size: 26,
                    ),
                    label: Text(
                      playback.isPlaying ? l10n.replayPause : l10n.replayPlay,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.replay_rounded),
                    tooltip: l10n.replayRestart,
                    onPressed: onReset,
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      reverse: Directionality.of(context) == TextDirection.rtl,
                      child: Row(
                        children: PlaybackSpeed.values.map(
                          (s) => Padding(
                            padding: const EdgeInsetsDirectional.only(
                              start: 4,
                            ),
                            child: ChoiceChip(
                              label: Text(s.label),
                              selected: playback.playbackSpeed == s,
                              onSelected: (_) => onSpeed(s),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                            ),
                          ),
                        ).toList(),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MultiVehicleReplayEmptyBody extends StatelessWidget {
  const MultiVehicleReplayEmptyBody({
    super.key,
    required this.message,
    this.showRetry = false,
    this.onRetry,
  });

  final String message;
  final bool showRetry;
  final VoidCallback? onRetry;

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
              Icons.route_outlined,
              size: 48,
              color: AppColors.textMutedOf(context),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: AppTextStyles.bodyMedium,
              textAlign: TextAlign.center,
            ),
            if (showRetry && onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onRetry,
                child: Text(l10n.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
