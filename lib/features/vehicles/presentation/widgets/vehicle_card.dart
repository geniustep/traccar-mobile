import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/elmo_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/format_utils.dart';
import '../../domain/entities/vehicle.dart';

class VehicleCard extends StatelessWidget {
  const VehicleCard({super.key, required this.vehicle, this.onTap});

  final VehicleEntity vehicle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final status = StatusBadge.fromString(vehicle.status);

    return ElmoCard(
      onTap: onTap,
      child: Row(
        children: [
          _VehicleTypeIcon(type: vehicle.type, status: status),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        vehicle.name,
                        style: AppTextStyles.headlineSmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    StatusBadge(status: status),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  vehicle.plateNumber,
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _InfoChip(
                      icon: Icons.speed_rounded,
                      label: FormatUtils.speed(vehicle.speed),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    if (vehicle.ignition)
                      _InfoChip(
                        icon: Icons.power_settings_new_rounded,
                        label: 'ON',
                        color: AppColors.statusMoving,
                      ),
                    const Spacer(),
                    if (vehicle.lastUpdate != null)
                      Text(
                        DateFormatter.toRelative(vehicle.lastUpdate!),
                        style: AppTextStyles.labelSmall,
                      ),
                  ],
                ),
                if (vehicle.address != null && vehicle.address!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined,
                          size: 12, color: AppColors.textMuted),
                      const SizedBox(width: 3),
                      Expanded(
                        child: Text(
                          vehicle.address!,
                          style: AppTextStyles.labelSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.textMuted,
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _VehicleTypeIcon extends StatelessWidget {
  const _VehicleTypeIcon({required this.type, required this.status});

  final String type;
  final VehicleStatus status;

  @override
  Widget build(BuildContext context) {
    final color = switch (status) {
      VehicleStatus.moving => AppColors.statusMoving,
      VehicleStatus.stopped => AppColors.statusStopped,
      VehicleStatus.idle => AppColors.statusIdle,
      VehicleStatus.offline => AppColors.statusOffline,
    };

    final icon = switch (type.toLowerCase()) {
      'truck' => Icons.local_shipping_rounded,
      'van' => Icons.airport_shuttle_rounded,
      'bus' => Icons.directions_bus_rounded,
      'motorcycle' => Icons.two_wheeler_rounded,
      _ => Icons.directions_car_rounded,
    };

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Icon(icon, color: color, size: 24),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label, this.color});

  final IconData icon;
  final String label;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: color ?? AppColors.textMuted),
        const SizedBox(width: 3),
        Text(
          label,
          style: AppTextStyles.labelSmall
              .copyWith(color: color ?? AppColors.textMuted),
        ),
      ],
    );
  }
}
