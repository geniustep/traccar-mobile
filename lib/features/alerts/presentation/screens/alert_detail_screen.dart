import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/elmo_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/utils/date_formatter.dart';
import '../providers/alerts_provider.dart';

class AlertDetailScreen extends ConsumerWidget {
  const AlertDetailScreen({super.key, required this.alertId});

  final String alertId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsAsync = ref.watch(alertsProvider);

    final alert = alertsAsync.whenOrNull(
      data: (alerts) => alerts.where((a) => a.id == alertId).firstOrNull,
    );

    if (alert == null) {
      return Scaffold(        appBar: AppBar(          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: () => context.pop(),
          ),
          title: const Text('Alert Detail'),
        ),
        body: const Center(
          child: Text('Alert not found', style: AppTextStyles.bodyMedium),
        ),
      );
    }

    return Scaffold(      appBar: AppBar(        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Alert Detail'),
        actions: [
          if (!alert.isRead)
            TextButton(
              onPressed: () =>
                  ref.read(alertsProvider.notifier).markAsRead(alert.id),
              child: const Text('Mark read'),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ElmoCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      SeverityBadge(severity: alert.severity),
                      const SizedBox(width: 8),
                      Text(
                        alert.type.toUpperCase(),
                        style: AppTextStyles.labelSmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(alert.title, style: AppTextStyles.headlineMedium),
                  const SizedBox(height: 8),
                  Text(
                    alert.description,
                    style: AppTextStyles.bodyMedium
                        .copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ElmoCard(
              child: Column(
                children: [
                  _InfoRow(
                    label: 'Vehicle',
                    value: alert.vehicleName,
                    icon: Icons.directions_car_rounded,
                    onTap: () => context.push('/vehicles/${alert.vehicleId}'),
                  ),
                  const Divider(height: 16, thickness: 0.5),
                  _InfoRow(
                    label: 'Time',
                    value: DateFormatter.toDateTime(alert.createdAt),
                    icon: Icons.access_time_rounded,
                  ),
                  if (alert.hasLocation) ...[
                    const Divider(height: 16, thickness: 0.5),
                    _InfoRow(
                      label: 'Location',
                      value:
                          '${alert.latitude!.toStringAsFixed(4)}, ${alert.longitude!.toStringAsFixed(4)}',
                      icon: Icons.location_on_rounded,
                    ),
                  ],
                ],
              ),
            ),
            if (alert.attributes.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.md),
              Text('Details', style: AppTextStyles.headlineSmall),
              const SizedBox(height: AppSpacing.sm),
              ElmoCard(
                child: Column(
                  children: alert.attributes.entries.map((e) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: AppSpacing.xs),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            e.key,
                            style: AppTextStyles.bodySmall,
                          ),
                          Text(
                            e.value.toString(),
                            style: AppTextStyles.labelLarge.copyWith(
                                fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
    required this.icon,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.accent),
          const SizedBox(width: AppSpacing.sm),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTextStyles.labelSmall),
              Text(
                value,
                style: AppTextStyles.bodyMedium.copyWith(
                  color: onTap != null ? AppColors.accent : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          if (onTap != null) ...[
            const Spacer(),
            const Icon(Icons.chevron_right_rounded,
                size: 16, color: AppColors.textMuted),
          ],
        ],
      ),
    );
  }
}
