import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/elmo_card.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../core/route_intelligence_threshold_resolution.dart';
import '../providers/route_intel_group_attributes_map_provider.dart';
import '../providers/route_intelligence_thresholds_provider.dart';
import '../utils/route_intelligence_threshold_preview_formatting.dart';

/// Read-only list of effective route-analysis thresholds + source chips (Phase 6G).
class RouteIntelligenceThresholdsPreview extends StatelessWidget {
  const RouteIntelligenceThresholdsPreview({
    super.key,
    required this.resolution,
    this.compact = false,
    this.showTitle = true,
    this.showReadOnlyHint = true,
    this.vehicleName,
    this.showLoadingBanner = false,
    this.showGroupLoadWarning = false,
  });

  final RouteIntelligenceThresholdResolution resolution;
  final bool compact;
  final bool showTitle;
  final bool showReadOnlyHint;
  final String? vehicleName;
  final bool showLoadingBanner;
  final bool showGroupLoadWarning;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final rows = routeIntelThresholdPreviewRows(resolution, l10n);
    final pad = compact ? AppSpacing.sm : AppSpacing.md;
    final chipFont = compact ? 10.0 : 11.0;
    final valueStyle =
        compact ? AppTextStyles.bodySmall : AppTextStyles.bodyMedium;

    return ElmoCard(
      padding: EdgeInsets.all(pad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showLoadingBanner) ...[
            _LoadingHint(l10n: l10n, compact: compact),
            SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
          ],
          if (showGroupLoadWarning) ...[
            Text(
              l10n.routeIntelPreviewGroupLoadError,
              style: AppTextStyles.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.error.withValues(alpha: 0.85),
              ),
            ),
            SizedBox(height: compact ? AppSpacing.xs : AppSpacing.sm),
          ],
          if (showTitle) ...[
            Text(
              l10n.routeIntelPreviewTitle,
              style: compact
                  ? AppTextStyles.headlineSmall
                  : AppTextStyles.headlineMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              l10n.routeIntelPreviewReadOnlyHint,
              style: AppTextStyles.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            if (vehicleName != null && vehicleName!.trim().isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                vehicleName!.trim(),
                style: AppTextStyles.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
          ] else if (showReadOnlyHint) ...[
            Text(
              l10n.routeIntelPreviewReadOnlyHint,
              style: AppTextStyles.labelSmall.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: compact ? AppSpacing.sm : AppSpacing.md),
          ],
          ...rows.map(
            (row) => Padding(
              padding: EdgeInsets.only(bottom: compact ? 6 : AppSpacing.sm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Text(
                      row.label,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      row.value,
                      textAlign: TextAlign.end,
                      style: valueStyle,
                    ),
                  ),
                  SizedBox(width: compact ? 6 : AppSpacing.sm),
                  _SourceChip(
                    label: routeIntelFormatSourceLabel(row.source, l10n),
                    fontSize: chipFont,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LoadingHint extends StatelessWidget {
  const _LoadingHint({required this.l10n, required this.compact});

  final AppLocalizations l10n;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: compact ? 14 : 16,
          height: compact ? 14 : 16,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        SizedBox(width: compact ? 6 : AppSpacing.sm),
        Expanded(
          child: Text(
            l10n.routeIntelPreviewLoadingLayers,
            style: AppTextStyles.labelSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.label, required this.fontSize});

  final String label;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cs.outline.withValues(alpha: 0.45)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: cs.onSurfaceVariant,
        ),
      ),
    );
  }
}

/// Vehicle-context preview: watches group map + prefs loading; analysis unchanged.
class RouteIntelligenceVehicleThresholdPreview extends ConsumerWidget {
  const RouteIntelligenceVehicleThresholdPreview({
    super.key,
    required this.vehicleId,
    this.vehicleName,
    this.groupId,
    this.compact = false,
  });

  final String vehicleId;
  final String? vehicleName;
  final String? groupId;
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gid = int.tryParse(groupId ?? '');
    final prefs = ref.watch(sharedPreferencesProvider);
    final groups = ref.watch(routeIntelGroupAttributesMapProvider);
    final resolution = ref.watch(
      routeIntelligenceThresholdsResolutionForVehicleProvider(vehicleId),
    );

    final waitingPrefs = prefs.isLoading;
    final waitingGroups = gid != null && groups.isLoading;
    final groupErr = gid != null && groups.hasError;

    return RouteIntelligenceThresholdsPreview(
      resolution: resolution,
      compact: compact,
      showTitle: true,
      vehicleName: vehicleName,
      showLoadingBanner: waitingPrefs || waitingGroups,
      showGroupLoadWarning: groupErr,
    );
  }
}

/// Global-context preview (user + local + defaults): for Settings.
class RouteIntelligenceGlobalThresholdPreview extends ConsumerWidget {
  const RouteIntelligenceGlobalThresholdPreview({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(sharedPreferencesProvider);
    final resolution =
        ref.watch(routeIntelligenceGlobalThresholdsResolutionProvider);

    final waitingPrefs = prefs.isLoading;

    return RouteIntelligenceThresholdsPreview(
      resolution: resolution,
      compact: compact,
      showTitle: false,
      vehicleName: null,
      showLoadingBanner: waitingPrefs,
      showGroupLoadWarning: false,
    );
  }
}
