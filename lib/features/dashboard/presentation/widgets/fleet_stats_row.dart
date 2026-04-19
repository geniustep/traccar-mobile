import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/elmo_card.dart';
import '../../domain/entities/dashboard_summary.dart';

class FleetStatsRow extends StatelessWidget {
  const FleetStatsRow({super.key, required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 1.55,
      ),
      children: [
        _StatCard(
          label: 'Total',
          value: summary.totalVehicles,
          icon: Icons.directions_car_rounded,
          color: AppColors.accent,
        ),
        _StatCard(
          label: 'Moving',
          value: summary.movingVehicles,
          icon: Icons.play_arrow_rounded,
          color: AppColors.statusMoving,
        ),
        _StatCard(
          label: 'Stopped',
          value: summary.stoppedVehicles,
          icon: Icons.stop_rounded,
          color: AppColors.statusStopped,
        ),
        _StatCard(
          label: 'Offline',
          value: summary.offlineVehicles,
          icon: Icons.signal_wifi_off_rounded,
          color: AppColors.statusOffline,
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final int value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return ElmoCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              Text(
                label,
                style: AppTextStyles.labelSmall.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          Text(
            value.toString(),
            style: AppTextStyles.statNumber.copyWith(fontSize: 24, color: color),
          ),
        ],
      ),
    );
  }
}

class AlertSummaryRow extends StatelessWidget {
  const AlertSummaryRow({super.key, required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: ElmoCard(
            borderColor: AppColors.error.withOpacity(0.3),
            gradient: LinearGradient(
              colors: [
                AppColors.error.withOpacity(0.06),
                AppColors.cardBackground,
              ],
            ),
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.warning_amber_rounded,
                      color: AppColors.error, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${summary.criticalAlerts}',
                      style: AppTextStyles.headlineMedium
                          .copyWith(color: AppColors.error),
                    ),
                    Text('Critical', style: AppTextStyles.labelSmall),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: ElmoCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.route_rounded,
                      color: AppColors.accent, size: 20),
                ),
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${summary.tripsToday}',
                      style: AppTextStyles.headlineMedium,
                    ),
                    Text('Trips today', style: AppTextStyles.labelSmall),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
