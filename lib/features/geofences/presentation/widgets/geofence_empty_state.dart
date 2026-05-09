import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class GeofenceEmptyState extends StatelessWidget {
  const GeofenceEmptyState({super.key, required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.map_outlined, size: 56, color: AppColors.textMutedOf(context)),
            const SizedBox(height: AppSpacing.md),
            Text(
              l10n.geofencesEmptyTitle,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: AppColors.textPrimaryOf(context),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.geofencesEmptyMessage,
              style: TextStyle(color: AppColors.textSecondaryOf(context)),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
