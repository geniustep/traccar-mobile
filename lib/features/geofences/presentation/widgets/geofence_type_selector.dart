import 'package:flutter/material.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import 'geofence_map_picker.dart';

class GeofenceTypeSelector extends StatelessWidget {
  const GeofenceTypeSelector({
    super.key,
    required this.value,
    required this.onChanged,
    required this.l10n,
  });

  final GeofenceDrawKind value;
  final ValueChanged<GeofenceDrawKind> onChanged;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _KindButton(
            label: l10n.geofenceTypeCircle,
            selected: value == GeofenceDrawKind.circle,
            onTap: () => onChanged(GeofenceDrawKind.circle),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _KindButton(
            label: l10n.geofenceTypePolygon,
            selected: value == GeofenceDrawKind.polygon,
            onTap: () => onChanged(GeofenceDrawKind.polygon),
          ),
        ),
      ],
    );
  }
}

class _KindButton extends StatelessWidget {
  const _KindButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.15)
              : AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.borderOf(context),
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.accent : AppColors.textSecondaryOf(context),
          ),
        ),
      ),
    );
  }
}
