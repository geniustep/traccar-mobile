import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

enum VehicleStatus { moving, stopped, idle, offline }

class StatusBadge extends StatelessWidget {
  const StatusBadge({super.key, required this.status});

  final VehicleStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final (label, color) = switch (status) {
      VehicleStatus.moving  => (l10n.filterMoving,  AppColors.statusMoving),
      VehicleStatus.stopped => (l10n.filterStopped, AppColors.statusStopped),
      VehicleStatus.idle    => (l10n.filterIdle,    AppColors.statusIdle),
      VehicleStatus.offline => (l10n.filterOffline, AppColors.statusOffline),
    };

    final bgAlpha   = (!isDark && status == VehicleStatus.offline) ? 0.18 : 0.15;
    final brdAlpha  = (!isDark && status == VehicleStatus.offline) ? 0.60 : 0.50;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: bgAlpha),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: brdAlpha), width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  static VehicleStatus fromString(String? s) {
    return switch (s?.toLowerCase()) {
      'moving'  => VehicleStatus.moving,
      'stopped' => VehicleStatus.stopped,
      'idle'    => VehicleStatus.idle,
      _         => VehicleStatus.offline,
    };
  }
}

class SeverityBadge extends StatelessWidget {
  const SeverityBadge({super.key, required this.severity});

  final String severity;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (severity.toLowerCase()) {
      'critical' => ('Critical', AppColors.severityCritical),
      'high'     => ('High',     AppColors.severityHigh),
      'medium'   => ('Medium',   AppColors.severityMedium),
      'low'      => ('Low',      AppColors.severityLow),
      _          => ('Info',     AppColors.severityInfo),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4), width: 0.5),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
