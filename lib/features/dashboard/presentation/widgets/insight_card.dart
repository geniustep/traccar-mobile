import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cs = Theme.of(context).colorScheme;
    final color = _severityColor(insight.severity);
    final icon = _iconFor(insight.icon);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(
            color: color.withValues(alpha: isDark ? 0.22 : 0.16),
            width: 0.8,
          ),
          color: isDark
              ? AppColors.surface.withValues(alpha: 0.9)
              : Colors.white.withValues(alpha: 0.95),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: isDark ? 0.08 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    insight.title,
                    style: AppTextStyles.labelLarge.copyWith(
                      color: cs.onSurface,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    insight.description,
                    style: TextStyle(
                      fontSize: 12,
                      height: 1.3,
                      color: cs.onSurface.withValues(alpha: 0.52),
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  DateFormatter.toRelative(insight.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface.withValues(alpha: 0.38),
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
