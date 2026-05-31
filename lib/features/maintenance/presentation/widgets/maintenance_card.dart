import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../fleet_domain/fleet_condition_logic.dart';
import '../../domain/entities/maintenance_record.dart';

class MaintenanceCard extends StatelessWidget {
  const MaintenanceCard({
    super.key,
    required this.record,
    required this.status,
    required this.l10n,
    required this.vehicleName,
    required this.onEdit,
    required this.onDelete,
  });

  final MaintenanceRecordEntity record;
  final ElmoMaintenanceSeverity status;
  final AppLocalizations l10n;
  final String vehicleName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String _chip() {
    switch (status) {
      case ElmoMaintenanceSeverity.completed:
        return l10n.maintStatusCompleted;
      case ElmoMaintenanceSeverity.overdue:
        return l10n.maintStatusOverdue;
      case ElmoMaintenanceSeverity.soon:
        return l10n.maintStatusSoon;
      case ElmoMaintenanceSeverity.upcoming:
        return l10n.maintStatusUpcoming;
      default:
        return l10n.maintStatusUnknown;
    }
  }

  Color _color() => switch (status) {
        ElmoMaintenanceSeverity.completed => Colors.blueGrey,
        ElmoMaintenanceSeverity.overdue => Colors.redAccent,
        ElmoMaintenanceSeverity.soon => Colors.orangeAccent,
        ElmoMaintenanceSeverity.upcoming => Colors.greenAccent,
        _ => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    final type = l10n.maintenanceTypeLocalized(
      record.maintenanceTypeCode ?? 'other',
    );

    final due =
        record.dueDate != null ? record.dueDate.toString().split(' ').first : '—';
    final odo = record.dueOdometerKm != null
        ? '${record.dueOdometerKm!.toStringAsFixed(0)} km'
        : '—';

    return Card(
      elevation: 0,
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    vehicleName.isEmpty ? '—' : vehicleName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                ),
                Chip(
                  label: Text(
                    _chip(),
                    style: TextStyle(
                      fontSize: 11,
                      color: readableOn(_color()),
                    ),
                  ),
                  visualDensity: VisualDensity.compact,
                  backgroundColor: _color().withValues(alpha: 0.2),
                  side: BorderSide.none,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text('$type • ${record.name}',
                style: const TextStyle(fontSize: 12)),
            const SizedBox(height: 4),
            Text('${l10n.maintenanceDueDateLabel}: $due',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
            Text('${l10n.maintenanceDueOdometerLabel}: $odo',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Wrap(
                children: [
                  TextButton(onPressed: onEdit, child: Text(l10n.maintenanceEdit)),
                  TextButton(
                    onPressed: onDelete,
                    style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent),
                    child: Text(l10n.maintenanceDelete),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color readableOn(Color bg) =>
      ThemeData.estimateBrightnessForColor(bg) == Brightness.dark
          ? Colors.white
          : Colors.black87;
}
