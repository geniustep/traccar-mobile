import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/elmo_card.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../geofences/presentation/providers/geofences_providers.dart';
import '../providers/alerts_provider.dart';
import '../../domain/entities/alert.dart';

class AlertDetailScreen extends ConsumerStatefulWidget {
  const AlertDetailScreen({super.key, required this.alertId});

  final String alertId;

  @override
  ConsumerState<AlertDetailScreen> createState() => _AlertDetailScreenState();
}

class _AlertDetailScreenState extends ConsumerState<AlertDetailScreen> {
  bool _markedRead = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLogger.alerts('Detail opened: alertId=${widget.alertId}');
    });
  }

  void _markReadOnce(AlertEntity alert) {
    if (_markedRead || alert.isRead) return;
    _markedRead = true;
    // Fire-and-forget: mark read on backend and update local state
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(alertsProvider.notifier).markAlertReadById(
            int.tryParse(widget.alertId) ?? 0,
          );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final alertAsync = ref.watch(alertDetailProvider(widget.alertId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.alertDetail),
      ),
      body: SafeArea(
        top: false,
        child: alertAsync.when(
          data: (alert) {
            if (alert == null) {
              return Center(
                child: Text(
                  l10n.alertNotFound,
                  style: AppTextStyles.bodyMedium,
                ),
              );
            }
            _markReadOnce(alert);
            return _AlertDetailBody(alert: alert, l10n: l10n);
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => _AlertDetailError(
            error: e,
            l10n: l10n,
            onRetry: () => ref.invalidate(alertDetailProvider(widget.alertId)),
          ),
        ),
      ),
    );
  }
}

// ── Body ──────────────────────────────────────────────────────────────────────

class _AlertDetailBody extends ConsumerWidget {
  const _AlertDetailBody({required this.alert, required this.l10n});

  final AlertEntity alert;
  final AppLocalizations l10n;

  String _typeLabel(String type) => switch (type.toLowerCase()) {
        'overspeed' || 'deviceoverspeed' => 'Excès de vitesse',
        'geofenceenter' => 'Entrée zone',
        'geofenceexit' => 'Sortie zone',
        'idle' => 'Ralenti',
        'maintenance' => 'Maintenance',
        'battery' => 'Batterie',
        'offline' || 'deviceoffline' => 'Hors ligne',
        'alarm' => 'Alarme',
        _ => 'Alerte',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final names = ref.watch(geofenceNameMapProvider);

    final String title;
    final String body;
    switch (alert.type) {
      case 'geofenceEnter':
        final zn =
            alert.geofenceId != null ? names[alert.geofenceId!] : null;
        title = zn != null
            ? '${l10n.geofenceZoneEntry} · $zn'
            : l10n.geofenceZoneEntry;
        body = alert.vehicleName.isNotEmpty ? alert.vehicleName : alert.description;
      case 'geofenceExit':
        final zn =
            alert.geofenceId != null ? names[alert.geofenceId!] : null;
        title = zn != null
            ? '${l10n.geofenceZoneExit} · $zn'
            : l10n.geofenceZoneExit;
        body = alert.vehicleName.isNotEmpty ? alert.vehicleName : alert.description;
      default:
        title = alert.title;
        body = alert.description;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header card
          ElmoCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    SeverityBadge(severity: alert.severity),
                    const SizedBox(width: 8),
                    Text(
                      _typeLabel(alert.type),
                      style: AppTextStyles.labelSmall,
                    ),
                    if (!alert.isRead) ...[
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF4757).withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Non lue',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFFFF4757),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(title, style: AppTextStyles.headlineMedium),
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    body,
                    style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.textSecondaryOf(context)),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Info card
          ElmoCard(
            child: Column(
              children: [
                if (alert.vehicleName.isNotEmpty) ...[
                  _InfoRow(
                    label: l10n.vehicleLabel,
                    value: alert.vehicleName,
                    icon: Icons.directions_car_rounded,
                    onTap: alert.vehicleId.isNotEmpty
                        ? () => context.push('/vehicles/${alert.vehicleId}')
                        : null,
                  ),
                  const Divider(height: 16, thickness: 0.5),
                ],
                _InfoRow(
                  label: l10n.timeLabel,
                  value: DateFormatter.toDateTime(alert.createdAt),
                  icon: Icons.access_time_rounded,
                ),
                if (alert.readAt != null) ...[
                  const Divider(height: 16, thickness: 0.5),
                  _InfoRow(
                    label: 'Lu le',
                    value: DateFormatter.toDateTime(alert.readAt!),
                    icon: Icons.done_all_rounded,
                  ),
                ],
                if (alert.hasLocation) ...[
                  const Divider(height: 16, thickness: 0.5),
                  _InfoRow(
                    label: l10n.locationLabel,
                    value:
                        '${alert.latitude!.toStringAsFixed(4)}, ${alert.longitude!.toStringAsFixed(4)}',
                    icon: Icons.location_on_rounded,
                  ),
                ],
              ],
            ),
          ),

          // Metadata / attributes card
          if (alert.attributes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Text(l10n.detailsLabel, style: AppTextStyles.headlineSmall),
            const SizedBox(height: AppSpacing.sm),
            ElmoCard(
              child: Column(
                children: alert.attributes.entries.map((e) {
                  return Padding(
                    padding:
                        const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(e.key, style: AppTextStyles.bodySmall),
                        Text(
                          e.value.toString(),
                          style:
                              AppTextStyles.labelLarge.copyWith(fontSize: 13),
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
    );
  }
}

// ── Error state ───────────────────────────────────────────────────────────────

class _AlertDetailError extends StatelessWidget {
  const _AlertDetailError({
    required this.error,
    required this.l10n,
    required this.onRetry,
  });

  final Object error;
  final AppLocalizations l10n;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isNotFound = error.toString().contains('NOT_FOUND') ||
        error.toString().contains('404');

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_off_rounded,
                  size: 30, color: AppColors.error),
            ),
            const SizedBox(height: 16),
            Text(
              isNotFound ? l10n.alertNotFound : 'Impossible de charger l\'alerte',
              style: AppTextStyles.labelLarge,
              textAlign: TextAlign.center,
            ),
            if (!isNotFound) ...[
              const SizedBox(height: 20),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.accent,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                ),
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Réessayer'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────

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
                  color: onTap != null
                      ? AppColors.accent
                      : AppColors.textPrimaryOf(context),
                ),
              ),
            ],
          ),
          if (onTap != null) ...[
            const Spacer(),
            Icon(Icons.chevron_right_rounded,
                size: 16, color: AppColors.textMutedOf(context)),
          ],
        ],
      ),
    );
  }
}
