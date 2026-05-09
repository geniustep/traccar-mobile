import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../fleet_domain/fleet_condition_logic.dart';
import '../../domain/entities/driver.dart';

class DriverCard extends StatelessWidget {
  const DriverCard({
    super.key,
    required this.driver,
    required this.licenseStatus,
    required this.l10n,
    required this.onDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final DriverEntity driver;
  final DriverLicenseStatus licenseStatus;
  final AppLocalizations l10n;
  final VoidCallback onDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  String _licenseChip() {
    switch (licenseStatus) {
      case DriverLicenseStatus.expired:
        return l10n.licenseStatusExpired;
      case DriverLicenseStatus.expiringSoon:
        return l10n.licenseStatusSoon;
      case DriverLicenseStatus.valid:
        return l10n.licenseStatusValid;
      default:
        return l10n.licenseStatusUnknown;
    }
  }

  Color _licenseColor() => switch (licenseStatus) {
        DriverLicenseStatus.expired => Colors.redAccent,
        DriverLicenseStatus.expiringSoon => Colors.orangeAccent,
        DriverLicenseStatus.valid => Colors.greenAccent,
        _ => AppColors.textMuted,
      };

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColors.cardBackground,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.divider),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        driver.uniqueId,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: _licenseColor().withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _licenseChip(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _licenseColor(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (driver.phone != null && driver.phone!.trim().isNotEmpty)
              Row(
                children: [
                  const Icon(Icons.phone_rounded, size: 14, color: AppColors.accent),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      driver.phone!,
                      style: const TextStyle(fontSize: 12),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            Text(
              '${l10n.driversLinkedVehicles}: ${driver.linkedDeviceIds.length}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Wrap(
                spacing: 4,
                children: [
                  TextButton(
                    onPressed: onDetails,
                    child: Text(l10n.detailsLabel),
                  ),
                  TextButton(onPressed: onEdit, child: Text(l10n.driversEdit)),
                  TextButton(
                    onPressed: onDelete,
                    style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
                    child: Text(l10n.driversDelete),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
