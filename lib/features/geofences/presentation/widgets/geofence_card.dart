import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/entities/geofence.dart';

class GeofenceCard extends StatelessWidget {
  const GeofenceCard({
    super.key,
    required this.geofence,
    required this.l10n,
    required this.onEdit,
    required this.onDelete,
    required this.onTap,
    this.hasAlerts = false,
  });

  final GeofenceEntity geofence;
  final AppLocalizations l10n;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onTap;
  final bool hasAlerts;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      geofence.name,
                      style: AppTextStyles.labelLarge,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  _TypeChip(
                    label: geofence.isCircle
                        ? l10n.geofenceTypeCircle
                        : l10n.geofenceTypePolygon,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Icon(Icons.directions_car_outlined,
                      size: 14, color: AppColors.textMutedOf(context)),
                  const SizedBox(width: 4),
                  Text(
                    '${geofence.linkedDeviceIds.length}',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(width: 12),
                  if (hasAlerts)
                    Row(
                      children: [
                        const Icon(Icons.notifications_active_outlined,
                            size: 14, color: AppColors.accent),
                        const SizedBox(width: 4),
                        Text(l10n.geofenceAlertStatusOn,
                            style: AppTextStyles.bodySmall
                                .copyWith(color: AppColors.accent)),
                      ],
                    )
                  else
                    Text(
                      l10n.geofenceAlertStatusOff,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMutedOf(context),
                      ),
                    ),
                  const Spacer(),
                  IconButton(
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    tooltip: l10n.geofenceEdit,
                  ),
                  IconButton(
                    onPressed: onDelete,
                    icon: Icon(Icons.delete_outline_rounded,
                        size: 20, color: AppColors.error.withValues(alpha: 0.9)),
                    tooltip: l10n.geofenceDelete,
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

class _TypeChip extends StatelessWidget {
  const _TypeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall.copyWith(color: AppColors.accent),
      ),
    );
  }
}
