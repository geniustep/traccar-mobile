import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/elmo_card.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/models/traccar_position.dart';
import '../../../../core/models/traccar_device.dart';
import '../../../alerts/domain/entities/alert.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../fleet/presentation/fleet_vehicle_brief_provider.dart';
import '../../domain/entities/vehicle_today_dashboard.dart';
import '../../domain/entities/vehicle.dart';

// ── Section dot header ────────────────────────────────────────────────────────

class VdSectionDot extends StatelessWidget {
  const VdSectionDot({super.key, required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: AppTextStyles.labelSmall
              .copyWith(color: AppColors.textMutedOf(context)),
        ),
      ],
    );
  }
}

// ── A. Status + Speed card ────────────────────────────────────────────────────

class VdStatusSpeedCard extends StatelessWidget {
  const VdStatusSpeedCard({
    super.key,
    required this.status,
    required this.speedKmh,
    required this.lastUpdate,
  });

  final Widget status;
  final double speedKmh;
  final DateTime? lastUpdate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ElmoCard(
      child: Row(
        children: [
          Expanded(
            child: Column(
              children: [
                status,
                const SizedBox(height: 4),
                Text(l10n.statusLabel, style: AppTextStyles.labelSmall),
              ],
            ),
          ),
          Container(
              width: 0.5, height: 40, color: AppColors.borderOf(context)),
          Expanded(
            child: Column(
              children: [
                Text(
                  FormatUtils.speed(speedKmh),
                  style: AppTextStyles.headlineSmall,
                ),
                const SizedBox(height: 4),
                Text(l10n.speedLabel, style: AppTextStyles.labelSmall),
              ],
            ),
          ),
          if (lastUpdate != null) ...[
            Container(
                width: 0.5, height: 40, color: AppColors.borderOf(context)),
            Expanded(
              child: Column(
                children: [
                  Text(
                    DateFormatter.toRelative(lastUpdate!),
                    style: AppTextStyles.labelLarge,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(l10n.lastUpdateLabel, style: AppTextStyles.labelSmall),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── B. Telemetry card ─────────────────────────────────────────────────────────

class VdTelemetryCard extends StatelessWidget {
  const VdTelemetryCard({
    super.key,
    required this.ignition,
    required this.motion,
    required this.speedKmh,
    required this.fuelLiters,
    required this.voltage,
    required this.hardBrake,
  });

  final bool ignition;
  final bool motion;
  final double speedKmh;
  final double? fuelLiters;
  final double? voltage;
  final bool hardBrake;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ElmoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VdSectionDot(
              color: AppColors.statusMoving, label: l10n.telemetryRealTime),
          const SizedBox(height: AppSpacing.sm),
          Column(
            children: [
              Row(
                children: [
                  _Cell(
                    label: l10n.ignitionLabel,
                    child: Icon(
                      ignition
                          ? Icons.power_settings_new_rounded
                          : Icons.power_off_rounded,
                      color: ignition
                          ? AppColors.statusMoving
                          : AppColors.textMutedOf(context),
                      size: 22,
                    ),
                  ),
                  _Cell(
                    label: l10n.motionLabel,
                    child: Icon(
                      motion
                          ? Icons.directions_run_rounded
                          : Icons.pause_circle_outline,
                      color: motion
                          ? AppColors.accent
                          : AppColors.textMutedOf(context),
                      size: 22,
                    ),
                  ),
                  _Cell(
                    label: l10n.speedLabel,
                    child: Text(FormatUtils.speed(speedKmh),
                        style: AppTextStyles.labelLarge,
                        textAlign: TextAlign.center),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: [
                  _Cell(
                    label: l10n.fuelLabel,
                    child: Text(FormatUtils.fuelLevel(fuelLiters),
                        style: AppTextStyles.labelLarge,
                        textAlign: TextAlign.center),
                  ),
                  _Cell(
                    label: l10n.batteryVoltageLabel,
                    child: Text(FormatUtils.voltage(voltage),
                        style: AppTextStyles.labelLarge,
                        textAlign: TextAlign.center),
                  ),
                  _Cell(
                    label: l10n.brakingLabel,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hardBrake
                              ? Icons.warning_amber_rounded
                              : Icons.check_circle_outline_rounded,
                          color: hardBrake
                              ? AppColors.warning
                              : AppColors.textMutedOf(context),
                          size: 20,
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            hardBrake ? l10n.hardBrakeLabel : l10n.normalLabel,
                            style: AppTextStyles.labelSmall.copyWith(
                              color: hardBrake
                                  ? AppColors.warning
                                  : AppColors.textMutedOf(context),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  const _Cell({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          const SizedBox(height: 4),
          Text(label,
              style: AppTextStyles.labelSmall, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

// ── C. Location card ──────────────────────────────────────────────────────────

class VdLocationCard extends StatelessWidget {
  const VdLocationCard({
    super.key,
    required this.vehicle,
    required this.onViewOnMap,
    this.onLiveTracking,
  });

  final VehicleEntity vehicle;
  final VoidCallback onViewOnMap;
  final VoidCallback? onLiveTracking;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final hasAddress = vehicle.address != null && vehicle.address!.isNotEmpty;
    final hasPosition = vehicle.latitude != 0 || vehicle.longitude != 0;

    if (!hasAddress && !hasPosition) return const SizedBox.shrink();

    return ElmoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VdSectionDot(
              color: AppColors.accent, label: l10n.currentLocation),
          const SizedBox(height: AppSpacing.sm),
          if (hasAddress) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_rounded,
                    color: AppColors.accent, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(vehicle.address!,
                      style: AppTextStyles.bodySmall.copyWith(height: 1.35)),
                ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          if (hasPosition)
            Row(
              children: [
                Icon(Icons.gps_fixed_rounded,
                    size: 14, color: AppColors.textMutedOf(context)),
                const SizedBox(width: 6),
                Text(
                  '${vehicle.latitude.toStringAsFixed(5)}, ${vehicle.longitude.toStringAsFixed(5)}',
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryOf(context),
                    fontFamily: 'monospace',
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          if (vehicle.lastUpdate != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time_rounded,
                    size: 14, color: AppColors.textMutedOf(context)),
                const SizedBox(width: 6),
                Text(
                  DateFormatter.toRelative(vehicle.lastUpdate!),
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMutedOf(context)),
                ),
              ],
            ),
          ],
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                    color: AppColors.accent.withValues(alpha: 0.4)),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
              onPressed: onViewOnMap,
              icon: const Icon(Icons.map_rounded,
                  size: 16, color: AppColors.accent),
              label: Text(l10n.viewOnMap,
                  style: const TextStyle(
                      color: AppColors.accent, fontSize: 13)),
            ),
          ),
          if (onLiveTracking != null) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: onLiveTracking,
                icon: Icon(Icons.gps_fixed_rounded,
                    size: 16, color: AppColors.textMutedOf(context)),
                label: Text(l10n.liveTracking,
                    style: TextStyle(
                        color: AppColors.textSecondaryOf(context),
                        fontSize: 12)),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── D. Today Summary card ─────────────────────────────────────────────────────

class VdTodaySummaryCard extends StatelessWidget {
  const VdTodaySummaryCard({super.key, this.dashboard});

  final VehicleTodayDashboard? dashboard;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final summary = dashboard?.summary;

    final d = dashboard;
    final hasExtras = d != null &&
        (d.stopsCount > 0 || d.totalStopSeconds > 0 || d.alertsTodayCount > 0);

    if (summary == null && !hasExtras) {
      return ElmoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            VdSectionDot(
                color: AppColors.amber, label: l10n.todaySummaryTitle),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  l10n.noSummaryData,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMutedOf(context)),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final s = summary;
    return ElmoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VdSectionDot(color: AppColors.amber, label: l10n.todaySummaryTitle),
          const SizedBox(height: AppSpacing.sm),
          if (s != null) ...[
            Row(
              children: [
                _SummaryKpi(
                  icon: Icons.route_rounded,
                  label: l10n.totalDistanceLabel,
                  value: FormatUtils.distance(s.totalDistanceMeters),
                ),
                _SummaryKpi(
                  icon: Icons.timer_outlined,
                  label: l10n.engineHoursLabel,
                  value: DateFormatter.duration(s.engineDuration.inSeconds),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                _SummaryKpi(
                  icon: Icons.speed_rounded,
                  label: l10n.maxSpeedLabel,
                  value: FormatUtils.speed(s.maxSpeedKmh),
                ),
                _SummaryKpi(
                  icon: Icons.trending_up_rounded,
                  label: l10n.avgSpeedLabel,
                  value: FormatUtils.speed(s.averageSpeedKmh),
                ),
              ],
            ),
          ],
          if (d != null &&
              (d.stopsCount > 0 ||
                  d.totalStopSeconds > 0 ||
                  d.alertsTodayCount > 0)) ...[
            if (s != null) const SizedBox(height: 6),
            Row(
              children: [
                if (d.totalStopSeconds > 0)
                  _SummaryKpi(
                    icon: Icons.pause_circle_outline_rounded,
                    label: l10n.stopDurationLabel,
                    value: DateFormatter.duration(d.totalStopSeconds),
                  ),
                if (d.stopsCount > 0)
                  _SummaryKpi(
                    icon: Icons.place_outlined,
                    label: l10n.stopsCountLabel,
                    value: '${d.stopsCount}',
                  ),
              ],
            ),
            if (d.alertsTodayCount > 0) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  _SummaryKpi(
                    icon: Icons.notifications_active_outlined,
                    label: l10n.alertsTodayLabel,
                    value: '${d.alertsTodayCount}',
                  ),
                  const Spacer(),
                ],
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _SummaryKpi extends StatelessWidget {
  const _SummaryKpi({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 16, color: AppColors.amber),
            const SizedBox(width: 6),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(value,
                      style: AppTextStyles.labelLarge
                          .copyWith(fontSize: 13)),
                  Text(label,
                      style: AppTextStyles.labelSmall.copyWith(
                        color: AppColors.textMutedOf(context),
                        fontSize: 10,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── E. Fleet Info card ────────────────────────────────────────────────────────

String vehicleDetailFleetDriverLine(
  AppLocalizations l10n,
  VehicleEntity vehicle,
  FleetVehicleBrief? brief,
) {
  if (brief != null) return brief.driverLine;
  final n = vehicle.driverName?.trim();
  if (n != null && n.isNotEmpty) return l10n.fleetCardDriverAssigned(n);
  return l10n.fleetCardNoDriver;
}

class VdFleetInfoCard extends StatelessWidget {
  const VdFleetInfoCard({
    super.key,
    required this.vehicle,
    required this.brief,
  });

  final VehicleEntity vehicle;
  final FleetVehicleBrief? brief;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ElmoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          VdSectionDot(color: AppColors.emerald, label: l10n.sectionFleet),
          const SizedBox(height: AppSpacing.sm),
          _FleetLine(
            icon: Icons.person_outline_rounded,
            text: vehicleDetailFleetDriverLine(l10n, vehicle, brief),
          ),
          const SizedBox(height: 6),
          _FleetLine(
            icon: Icons.build_circle_outlined,
            text: brief?.maintenanceLine ?? l10n.fleetCardNoMaintenance,
          ),
          if (brief?.hasMaintenanceOverdue == true) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_rounded,
                      color: AppColors.error, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.maintStatusOverdue,
                      style: const TextStyle(
                          color: AppColors.error, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (brief?.insuranceLine.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: _FleetLine(
                  icon: Icons.verified_user_outlined,
                  text: brief!.insuranceLine),
            ),
          if (brief?.techLine.isNotEmpty == true)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: _FleetLine(
                  icon: Icons.fact_check_outlined, text: brief!.techLine),
            ),
        ],
      ),
    );
  }
}

class _FleetLine extends StatelessWidget {
  const _FleetLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.accent.withValues(alpha: 0.85)),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(text,
              style: AppTextStyles.bodySmall.copyWith(height: 1.35)),
        ),
      ],
    );
  }
}

// ── F. Recent Alerts card ─────────────────────────────────────────────────────

class VdRecentAlertsSection extends StatelessWidget {
  const VdRecentAlertsSection({
    super.key,
    required this.alertsAsync,
    required this.onViewAll,
  });

  final AsyncValue<List<AlertEntity>> alertsAsync;
  final VoidCallback onViewAll;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return alertsAsync.when(
      data: (alerts) {
        if (alerts.isEmpty) {
          return _EmptyMiniSection(
            icon: Icons.notifications_none_rounded,
            message: l10n.noAlertsForVehicle,
          );
        }
        return Column(
          children: alerts.take(3).map((alert) {
            return Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: _AlertTile(alert: alert),
            );
          }).toList(),
        );
      },
      loading: () => const _InlineMiniLoader(),
      error: (_, __) => _EmptyMiniSection(
        icon: Icons.error_outline_rounded,
        message: l10n.alertsLoadError,
      ),
    );
  }
}

// ── G. Actions section ────────────────────────────────────────────────────────

class VdActionsSection extends StatelessWidget {
  const VdActionsSection({
    super.key,
    required this.onGenerateReport,
    required this.onReplayRoute,
    required this.onViewOnMap,
    required this.onLiveTracking,
    required this.onViewTrips,
    this.onCommands,
  });

  final VoidCallback onGenerateReport;
  final VoidCallback onReplayRoute;
  final VoidCallback onViewOnMap;
  final VoidCallback onLiveTracking;
  final VoidCallback onViewTrips;
  final VoidCallback? onCommands;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        VdSectionDot(
            color: AppColors.accent, label: l10n.vehicleActionsTitle),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _ActionChip(
              icon: Icons.assessment_rounded,
              label: l10n.generateReport,
              color: AppColors.purple,
              onTap: onGenerateReport,
            ),
            const SizedBox(width: AppSpacing.sm),
            _ActionChip(
              icon: Icons.replay_rounded,
              label: l10n.replayRoute,
              color: AppColors.accent,
              onTap: onReplayRoute,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _ActionChip(
              icon: Icons.map_rounded,
              label: l10n.viewOnMap,
              color: AppColors.emerald,
              onTap: onViewOnMap,
            ),
            const SizedBox(width: AppSpacing.sm),
            _ActionChip(
              icon: Icons.gps_fixed_rounded,
              label: l10n.liveTracking,
              color: AppColors.accent,
              onTap: onLiveTracking,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            _ActionChip(
              icon: Icons.route_rounded,
              label: l10n.tripHistory,
              color: AppColors.amber,
              onTap: onViewTrips,
            ),
            const Spacer(),
          ],
        ),
        if (onCommands != null) ...[
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              _ActionChip(
                icon: Icons.settings_remote_rounded,
                label: l10n.commandsTitle,
                color: AppColors.rose,
                onTap: onCommands!,
              ),
              const Spacer(),
            ],
          ),
        ],
      ],
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.07),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 11, color: color.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── H. Technical Info (collapsible) ───────────────────────────────────────────

class VdTechnicalInfoSection extends StatefulWidget {
  const VdTechnicalInfoSection({
    super.key,
    this.device,
    this.livePos,
  });

  final TraccarDevice? device;
  final TraccarPosition? livePos;

  @override
  State<VdTechnicalInfoSection> createState() => _VdTechnicalInfoSectionState();
}

class _VdTechnicalInfoSectionState extends State<VdTechnicalInfoSection> {
  bool _expanded = false;

  bool get _hasContent {
    if (widget.device != null) return true;
    final p = widget.livePos;
    if (p == null) return false;
    return p.altitude != 0 ||
        p.course != 0 ||
        p.accuracy > 0 ||
        (p.odometer != null && p.odometer! > 0);
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasContent) return const SizedBox.shrink();

    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => setState(() => _expanded = !_expanded),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                Icon(Icons.build_outlined,
                    size: 16, color: AppColors.textMutedOf(context)),
                const SizedBox(width: 6),
                Text(
                  l10n.technicalInfoTitle,
                  style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textMutedOf(context)),
                ),
                const Spacer(),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 200),
                  child: Icon(Icons.expand_more_rounded,
                      size: 20, color: AppColors.textMutedOf(context)),
                ),
              ],
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox(width: double.infinity),
          secondChild: _buildContent(context, l10n),
          crossFadeState:
              _expanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 250),
        ),
      ],
    );
  }

  Widget _buildContent(BuildContext context, AppLocalizations l10n) {
    return Column(
      children: [
        if (widget.device != null) _buildDeviceCard(context, widget.device!, l10n),
        if (widget.livePos != null && _hasPosDetails(widget.livePos!)) ...[
          const SizedBox(height: AppSpacing.sm),
          _buildPositionCard(context, widget.livePos!, l10n),
        ],
      ],
    );
  }

  bool _hasPosDetails(TraccarPosition pos) =>
      pos.altitude != 0 ||
      pos.course != 0 ||
      pos.accuracy > 0 ||
      (pos.odometer != null && pos.odometer! > 0);

  Widget _buildDeviceCard(
      BuildContext context, TraccarDevice device, AppLocalizations l10n) {
    return ElmoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.deviceInfo,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textMutedOf(context))),
          const SizedBox(height: AppSpacing.sm),
          if (device.model != null && device.model!.isNotEmpty) ...[
            _DeviceRow(
                icon: Icons.phone_android_rounded,
                label: l10n.deviceModelLabel,
                value: device.model!),
            Divider(
                height: 12,
                thickness: 0.5,
                color: AppColors.borderOf(context)),
          ],
          _DeviceRow(
              icon: Icons.tag_rounded,
              label: l10n.deviceIdLabel,
              value: device.uniqueId),
          if (device.phone != null && device.phone!.isNotEmpty) ...[
            Divider(
                height: 12,
                thickness: 0.5,
                color: AppColors.borderOf(context)),
            _DeviceRow(
                icon: Icons.sim_card_rounded,
                label: l10n.devicePhoneLabel,
                value: device.phone!),
          ],
        ],
      ),
    );
  }

  Widget _buildPositionCard(
      BuildContext context, TraccarPosition pos, AppLocalizations l10n) {
    return ElmoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.positionDetails,
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textMutedOf(context))),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (pos.altitude != 0)
                _PosChip(
                    label: l10n.altitudeLabel,
                    value: '${pos.altitude.toStringAsFixed(0)} m'),
              if (pos.course != 0)
                _PosChip(
                    label: l10n.courseLabel,
                    value: '${pos.course.toStringAsFixed(0)}°'),
              if (pos.accuracy > 0)
                _PosChip(
                    label: l10n.accuracyLabel,
                    value: '${pos.accuracy.toStringAsFixed(0)} m'),
              if (pos.odometer != null && pos.odometer! > 0)
                _PosChip(
                    label: l10n.odometerLabel,
                    value: FormatUtils.distance(pos.odometer!)),
            ],
          ),
        ],
      ),
    );
  }
}

class _DeviceRow extends StatelessWidget {
  const _DeviceRow(
      {required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMutedOf(context)),
        const SizedBox(width: 8),
        Text(label,
            style: AppTextStyles.bodySmall
                .copyWith(color: AppColors.textMutedOf(context))),
        const Spacer(),
        Flexible(
          child: Text(value,
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimaryOf(context),
                  fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.end),
        ),
      ],
    );
  }
}

class _PosChip extends StatelessWidget {
  const _PosChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedOf(context),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.borderOf(context), width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: AppTextStyles.labelSmall.copyWith(
                  color: AppColors.textMutedOf(context), fontSize: 9)),
          Text(value,
              style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.textPrimaryOf(context),
                  fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────

class VdTripTile extends StatelessWidget {
  const VdTripTile({super.key, required this.trip});

  final TripEntity trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundOf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderOf(context), width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.route_rounded, color: AppColors.accent, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormatter.toDateTime(trip.startTime),
                    style: AppTextStyles.labelLarge.copyWith(fontSize: 12)),
                Text(
                  '${FormatUtils.distance(trip.distanceMeters)} · '
                  '${DateFormatter.duration(trip.durationSeconds)}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Text(FormatUtils.speed(trip.maxSpeedKmh),
              style: AppTextStyles.labelSmall
                  .copyWith(color: AppColors.textSecondaryOf(context))),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});

  final AlertEntity alert;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundOf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderOf(context), width: 0.5),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded,
              color: AppColors.warning, size: 18),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.title,
                    style: AppTextStyles.labelLarge.copyWith(fontSize: 12)),
                Text(DateFormatter.toRelative(alert.createdAt),
                    style: AppTextStyles.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyMiniSection extends StatelessWidget {
  const _EmptyMiniSection({required this.icon, required this.message});

  final IconData icon;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: Center(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: AppColors.textMutedOf(context)),
            const SizedBox(width: 8),
            Flexible(
              child: Text(message,
                  style: AppTextStyles.bodySmall
                      .copyWith(color: AppColors.textMutedOf(context))),
            ),
          ],
        ),
      ),
    );
  }
}

class _InlineMiniLoader extends StatelessWidget {
  const _InlineMiniLoader();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 16),
      child: Center(child: SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      )),
    );
  }
}
