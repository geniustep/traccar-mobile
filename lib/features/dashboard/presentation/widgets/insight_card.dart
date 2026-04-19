import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/elmo_card.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../domain/entities/insight.dart';

class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.insight, this.onTap});

  final InsightEntity insight;
  final VoidCallback? onTap;

  static Color _severityColor(String s) => switch (s.toLowerCase()) {
        'critical' => AppColors.severityCritical,
        'high' => AppColors.severityHigh,
        'medium' => AppColors.severityMedium,
        'low' => AppColors.severityLow,
        _ => AppColors.accent,
      };

  static IconData _iconFor(String icon) => switch (icon) {
        'speed' => Icons.speed_rounded,
        'timer' => Icons.timer_rounded,
        'star' => Icons.star_rounded,
        'warning' => Icons.warning_amber_rounded,
        'fuel' => Icons.local_gas_station_rounded,
        'battery' => Icons.battery_alert_rounded,
        _ => Icons.lightbulb_outline_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final color = _severityColor(insight.severity);
    final icon = _iconFor(insight.icon);

    return ElmoCard(
      onTap: onTap,
      borderColor: color.withOpacity(0.2),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(insight.title, style: AppTextStyles.labelLarge),
                const SizedBox(height: 2),
                Text(
                  insight.description,
                  style: AppTextStyles.bodySmall,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            DateFormatter.toRelative(insight.createdAt),
            style: AppTextStyles.labelSmall,
          ),
        ],
      ),
    );
  }
}
