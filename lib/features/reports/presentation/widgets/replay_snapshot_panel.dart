import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../core/replay_point_snapshot.dart';
import '../../core/replay_sensor_snapshot.dart';

/// Compact current-position card for Single Vehicle Replay (Phase R2 / UI-2).
class ReplaySnapshotPanel extends StatefulWidget {
  const ReplaySnapshotPanel({
    super.key,
    required this.snapshot,
    this.compact = false,
  });

  final ReplayPointSnapshot snapshot;

  /// Map-first replay: single metrics row; details on tap.
  final bool compact;

  @override
  State<ReplaySnapshotPanel> createState() => _ReplaySnapshotPanelState();
}

class _ReplaySnapshotPanelState extends State<ReplaySnapshotPanel> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final s = widget.snapshot;

    if (widget.compact && !_expanded) {
      return Material(
        color: AppColors.surfaceElevatedOf(context),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: s.hasExpandableDetails
              ? () => setState(() => _expanded = true)
              : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${s.speedLabel} · ${s.movementLabel} · ${s.progressPercent}%',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                ),
                if (s.afterDataGap)
                  Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: Icon(
                      Icons.signal_cellular_connected_no_internet_0_bar_rounded,
                      size: 14,
                      color: AppColors.purple,
                    ),
                  ),
                if (s.hasExpandableDetails) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.expand_more_rounded,
                    size: 18,
                    color: AppColors.accent,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Material(
      color: AppColors.surfaceElevatedOf(context),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: s.hasExpandableDetails
            ? () => setState(() => _expanded = !_expanded)
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderOf(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!widget.compact)
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.replaySnapshotTitle,
                        style: AppTextStyles.labelSmall.copyWith(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMutedOf(context),
                        ),
                      ),
                    ),
                    if (s.hasExpandableDetails)
                      Icon(
                        _expanded
                            ? Icons.expand_less_rounded
                            : Icons.expand_more_rounded,
                        size: 18,
                        color: AppColors.textMutedOf(context),
                      ),
                  ],
                ),
              if (!widget.compact) const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _SnapshotMetric(
                      icon: Icons.schedule_rounded,
                      label: l10n.replaySnapshotTime,
                      value: s.timeLabel,
                      color: AppColors.accent,
                    ),
                  ),
                  Expanded(
                    child: _SnapshotMetric(
                      icon: Icons.speed_rounded,
                      label: l10n.replaySnapshotSpeed,
                      value: s.speedLabel,
                      color: AppColors.emerald,
                    ),
                  ),
                  Expanded(
                    child: _SnapshotMetric(
                      icon: Icons.linear_scale_rounded,
                      label: l10n.replayProgress,
                      value: '${s.progressPercent}%',
                      color: AppColors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _StatusChip(
                    icon: s.isMoving
                        ? Icons.directions_car_rounded
                        : Icons.local_parking_rounded,
                    label: s.movementLabel,
                    color: s.isMoving
                        ? AppColors.emerald
                        : AppColors.textSecondaryOf(context),
                  ),
                  if (s.afterDataGap)
                    _StatusChip(
                      icon: Icons
                          .signal_cellular_connected_no_internet_0_bar_rounded,
                      label: l10n.replayAfterDataGap,
                      color: AppColors.purple,
                    ),
                ],
              ),
              if (_expanded && s.hasExpandableDetails) ...[
                const SizedBox(height: 6),
                const Divider(height: 1),
                const SizedBox(height: 4),
                if (s.hasAddress) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.place_outlined,
                        size: 14,
                        color: AppColors.textMutedOf(context),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          s.address!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.3,
                            color: AppColors.textPrimaryOf(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                ],
                if (s.coordinatesLabel != null)
                  _DetailRow(
                    label: l10n.replaySnapshotCoordinates,
                    value: s.coordinatesLabel!,
                  ),
                if (s.courseLabel != null)
                  _DetailRow(
                    label: l10n.replaySnapshotDirection,
                    value: s.courseLabel!,
                  ),
                if (s.ignitionOn != null)
                  _DetailRow(
                    label: l10n.replaySnapshotIgnition,
                    value: s.ignitionOn!
                        ? l10n.replaySnapshotEngineOn
                        : l10n.replaySnapshotEngineOff,
                  ),
                if (s.hasSensorRows) ...[
                  const SizedBox(height: 4),
                  Text(
                    l10n.replaySensorsTitle,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final row in s.sensorRows)
                    _DetailRow(
                      label: ReplaySensorSnapshotBuilder.labelFor(
                        row.kind,
                        l10n,
                      ),
                      value: row.displayValue,
                    ),
                ],
              ] else if (!widget.compact &&
                  (s.hasExpandableDetails || s.hasAddress)) ...[
                const SizedBox(height: 2),
                Text(
                  l10n.replaySnapshotDetails,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SnapshotMetric extends StatelessWidget {
  const _SnapshotMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(height: 2),
        Text(
          value,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 9,
            color: AppColors.textMutedOf(context),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: AppColors.textMutedOf(context),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimaryOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
