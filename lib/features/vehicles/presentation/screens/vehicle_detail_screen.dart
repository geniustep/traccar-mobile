import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/elmo_card.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/models/traccar_position.dart';
import '../../../../core/models/traccar_device.dart';
import '../../../../shared/providers/traccar_providers.dart';
import '../../../trips/presentation/providers/trips_provider.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../alerts/presentation/providers/alerts_provider.dart';
import '../../../alerts/domain/entities/alert.dart';
import '../../domain/entities/vehicle.dart';
import '../providers/vehicles_provider.dart';

class VehicleDetailScreen extends ConsumerWidget {
  const VehicleDetailScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final vehicleAsync = ref.watch(vehicleDetailProvider(vehicleId));
    final tripsAsync = ref.watch(vehicleTripsProvider(vehicleId));
    final alertsAsync = ref.watch(vehicleAlertsProvider(vehicleId));
    final livePositions = ref.watch(livePositionsProvider);
    final liveDevices = ref.watch(liveDevicesProvider);

    return Scaffold(
      body: vehicleAsync.when(
        data: (vehicle) {
          final deviceId = int.tryParse(vehicle.id);
          final livePos = deviceId != null ? livePositions[deviceId] : null;
          final device = deviceId != null ? liveDevices[deviceId] : null;
          final status = StatusBadge.fromString(vehicle.status);
          final voltage = livePos?.vehicleVoltage ?? vehicle.batteryVoltage;

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App bar ─────────────────────────────────────────────────────
              SliverAppBar(
                pinned: true,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
                  onPressed: () => context.pop(),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.name, style: AppTextStyles.headlineMedium),
                    Text(
                      vehicle.plateNumber,
                      style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textSecondaryOf(context)),
                    ),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.settings_remote_rounded,
                        color: AppColors.accent),
                    tooltip: l10n.commandsTitle,
                    onPressed: () => context.push(
                      '/vehicles/$vehicleId/commands',
                      extra: {'name': vehicle.name},
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.gps_fixed_rounded,
                        color: AppColors.accent),
                    tooltip: l10n.trackVehicle,
                    onPressed: () =>
                        context.push('/vehicles/$vehicleId/track'),
                  ),
                ],
                bottom: PreferredSize(
                  preferredSize: const Size.fromHeight(1),
                  child: Container(
                      height: 1, color: AppColors.borderOf(context)),
                ),
              ),

              // ── Content ─────────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 1. Status + Speed
                        ElmoCard(
                          child: Row(
                            children: [
                              Expanded(
                                child: _StatusItem(
                                  label: l10n.statusLabel,
                                  value: StatusBadge(status: status),
                                ),
                              ),
                              Container(
                                  width: 0.5,
                                  height: 40,
                                  color: AppColors.borderOf(context)),
                              Expanded(
                                child: _StatusItem(
                                  label: l10n.speedLabel,
                                  value: Text(
                                    FormatUtils.speed(
                                        livePos?.speedKmh ?? vehicle.speed),
                                    style: AppTextStyles.headlineSmall,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // 2. Real-time telemetry
                        ElmoCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    width: 7,
                                    height: 7,
                                    decoration: const BoxDecoration(
                                      color: AppColors.statusMoving,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    l10n.telemetryRealTime,
                                    style: AppTextStyles.labelSmall.copyWith(
                                        color: AppColors.textMutedOf(context)),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              _TelemetryGrid(
                                ignition:
                                    livePos?.ignitionOn ?? vehicle.ignition,
                                motion: livePos?.motion ?? vehicle.isMoving,
                                speedKmh:
                                    livePos?.speedKmh ?? vehicle.speed,
                                fuelLiters:
                                    livePos?.fuelLevel ?? vehicle.fuelLevel,
                                voltage: livePos?.vehicleVoltage ??
                                    vehicle.batteryVoltage,
                                hardBrake: livePos?.hardBrake ?? false,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // 3. Current location (if address available)
                        if (vehicle.address != null) ...[
                          ElmoCard(
                            child: Row(
                              children: [
                                const Icon(Icons.location_on_rounded,
                                    color: AppColors.accent, size: 20),
                                const SizedBox(width: AppSpacing.sm),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(l10n.currentLocation,
                                          style: AppTextStyles.labelSmall),
                                      Text(vehicle.address!,
                                          style: AppTextStyles.bodyMedium),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                        ],

                        // 4. Track vehicle button
                        GestureDetector(
                          onTap: () =>
                              context.push('/vehicles/$vehicleId/track'),
                          child: Container(
                            height: 52,
                            decoration: BoxDecoration(
                              color: AppColors.accent.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(
                                  AppSpacing.cardRadius),
                              border: Border.all(
                                  color: AppColors.accent
                                      .withValues(alpha: 0.35),
                                  width: 1),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.gps_fixed_rounded,
                                    color: AppColors.accent, size: 20),
                                const SizedBox(width: 10),
                                Text(
                                  l10n.trackVehicle,
                                  style: const TextStyle(
                                    color: AppColors.accent,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Icon(Icons.arrow_forward_ios_rounded,
                                    color: AppColors.accent, size: 13),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: AppSpacing.md),

                        // 5. Info grid
                        _buildInfoGrid(
                            context, vehicle, livePos, voltage, l10n),

                        // 6. Device info (if live device data available)
                        if (device != null) ...[
                          const SizedBox(height: AppSpacing.md),
                          _buildDeviceCard(context, device, l10n),
                        ],

                        // 7. Position details (altitude, course, accuracy, odometer)
                        if (livePos != null &&
                            _hasPositionDetails(livePos)) ...[
                          const SizedBox(height: AppSpacing.md),
                          _buildPositionCard(context, livePos, l10n),
                        ],

                        const SizedBox(height: AppSpacing.sectionSpacing),

                        // 8. Recent Trips
                        SectionHeader(
                          title: l10n.recentTrips,
                          actionLabel: l10n.allTrips,
                          onAction: () =>
                              context.push('/vehicles/$vehicleId/trips'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        tripsAsync.when(
                          data: (trips) {
                            if (trips.isEmpty) {
                              return Padding(
                                padding:
                                    const EdgeInsets.all(AppSpacing.lg),
                                child: Center(
                                  child: Text(l10n.noTripsToday,
                                      style: AppTextStyles.bodySmall),
                                ),
                              );
                            }
                            return Column(
                              children: trips.take(3).map((trip) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm),
                                  child: _TripTile(trip: trip),
                                );
                              }).toList(),
                            );
                          },
                          loading: () => const InlineLoader(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),

                        const SizedBox(height: AppSpacing.sectionSpacing),

                        // 9. Recent Alerts
                        SectionHeader(
                          title: l10n.recentAlerts,
                          actionLabel: l10n.allAlerts,
                          onAction: () => context.go('/alerts'),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        alertsAsync.when(
                          data: (alerts) {
                            if (alerts.isEmpty) {
                              return Padding(
                                padding:
                                    const EdgeInsets.all(AppSpacing.lg),
                                child: Center(
                                  child: Text(l10n.noAlertsVehicle,
                                      style: AppTextStyles.bodySmall),
                                ),
                              );
                            }
                            return Column(
                              children: alerts.take(3).map((alert) {
                                return Padding(
                                  padding: const EdgeInsets.only(
                                      bottom: AppSpacing.sm),
                                  child: _AlertTile(alert: alert),
                                );
                              }).toList(),
                            );
                          },
                          loading: () => const InlineLoader(),
                          error: (_, __) => const SizedBox.shrink(),
                        ),

                        SizedBox(
                            height:
                                MediaQuery.paddingOf(context).bottom + 12),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => LoadingView(message: l10n.loadingVehicle),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(vehicleDetailProvider(vehicleId)),
        ),
      ),
    );
  }

  Widget _buildInfoGrid(
    BuildContext context,
    VehicleEntity vehicle,
    TraccarPosition? livePos,
    double? voltage,
    AppLocalizations l10n,
  ) {
    final tiles = <Widget>[];
    if (vehicle.driverName != null) {
      tiles.add(_InfoGridTile(
        icon: Icons.person_rounded,
        label: l10n.driverLabel,
        value: vehicle.driverName!,
      ));
    }
    if (voltage != null) {
      tiles.add(_InfoGridTile(
        icon: Icons.battery_charging_full_rounded,
        label: l10n.batteryVoltageLabel,
        value: FormatUtils.voltage(voltage),
        color: voltage < 11.8 ? AppColors.warning : null,
      ));
    }
    tiles.add(_InfoGridTile(
      icon: Icons.gps_fixed_rounded,
      label: l10n.coordinatesLabel,
      value:
          '${vehicle.latitude.toStringAsFixed(4)}, ${vehicle.longitude.toStringAsFixed(4)}',
    ));
    if (vehicle.lastUpdate != null) {
      tiles.add(_InfoGridTile(
        icon: Icons.access_time_rounded,
        label: l10n.lastUpdateLabel,
        value: DateFormatter.toRelative(vehicle.lastUpdate!),
      ));
    }
    if (tiles.isEmpty) return const SizedBox.shrink();
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 2.8,
      ),
      children: tiles,
    );
  }

  Widget _buildDeviceCard(
    BuildContext context,
    TraccarDevice device,
    AppLocalizations l10n,
  ) {
    return ElmoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.deviceInfo,
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.textMutedOf(context)),
          ),
          const SizedBox(height: AppSpacing.sm),
          if (device.model != null && device.model!.isNotEmpty) ...[
            _DeviceInfoRow(
              icon: Icons.phone_android_rounded,
              label: l10n.deviceModelLabel,
              value: device.model!,
            ),
            Divider(
                height: 12,
                thickness: 0.5,
                color: AppColors.borderOf(context)),
          ],
          _DeviceInfoRow(
            icon: Icons.tag_rounded,
            label: l10n.deviceIdLabel,
            value: device.uniqueId,
          ),
          if (device.phone != null && device.phone!.isNotEmpty) ...[
            Divider(
                height: 12,
                thickness: 0.5,
                color: AppColors.borderOf(context)),
            _DeviceInfoRow(
              icon: Icons.sim_card_rounded,
              label: l10n.devicePhoneLabel,
              value: device.phone!,
            ),
          ],
        ],
      ),
    );
  }

  bool _hasPositionDetails(TraccarPosition pos) =>
      pos.altitude != 0 ||
      pos.course != 0 ||
      pos.accuracy > 0 ||
      (pos.odometer != null && pos.odometer! > 0);

  Widget _buildPositionCard(
    BuildContext context,
    TraccarPosition pos,
    AppLocalizations l10n,
  ) {
    return ElmoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.positionDetails,
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.textMutedOf(context)),
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              if (pos.altitude != 0)
                _PositionChip(
                    label: l10n.altitudeLabel,
                    value: '${pos.altitude.toStringAsFixed(0)} m'),
              if (pos.course != 0)
                _PositionChip(
                    label: l10n.courseLabel,
                    value: '${pos.course.toStringAsFixed(0)}°'),
              if (pos.accuracy > 0)
                _PositionChip(
                    label: l10n.accuracyLabel,
                    value: '${pos.accuracy.toStringAsFixed(0)} m'),
              if (pos.odometer != null && pos.odometer! > 0)
                _PositionChip(
                    label: l10n.odometerLabel,
                    value: FormatUtils.distance(pos.odometer!)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Telemetry ─────────────────────────────────────────────────────────────────

class _TelemetryGrid extends StatelessWidget {
  const _TelemetryGrid({
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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TelemetryCell(
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
            ),
            Expanded(
              child: _TelemetryCell(
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
            ),
            Expanded(
              child: _TelemetryCell(
                label: l10n.speedLabel,
                child: Text(
                  FormatUtils.speed(speedKmh),
                  style: AppTextStyles.labelLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          children: [
            Expanded(
              child: _TelemetryCell(
                label: l10n.fuelLabel,
                child: Text(
                  FormatUtils.fuelLevel(fuelLiters),
                  style: AppTextStyles.labelLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              child: _TelemetryCell(
                label: l10n.batteryVoltageLabel,
                child: Text(
                  FormatUtils.voltage(voltage),
                  style: AppTextStyles.labelLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              child: _TelemetryCell(
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
            ),
          ],
        ),
      ],
    );
  }
}

class _TelemetryCell extends StatelessWidget {
  const _TelemetryCell({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: 4),
        Text(label,
            style: AppTextStyles.labelSmall, textAlign: TextAlign.center),
      ],
    );
  }
}

// ── Status item ───────────────────────────────────────────────────────────────

class _StatusItem extends StatelessWidget {
  const _StatusItem({required this.label, required this.value});

  final String label;
  final Widget value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        value,
        const SizedBox(height: 4),
        Text(label, style: AppTextStyles.labelSmall),
      ],
    );
  }
}

// ── Info grid tile ────────────────────────────────────────────────────────────

class _InfoGridTile extends StatelessWidget {
  const _InfoGridTile({
    required this.icon,
    required this.label,
    required this.value,
    this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.cardBackgroundOf(context),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderOf(context), width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color ?? AppColors.textMutedOf(context)),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(label, style: AppTextStyles.labelSmall),
                Text(
                  value,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: color ?? AppColors.textPrimaryOf(context),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Device info row ───────────────────────────────────────────────────────────

class _DeviceInfoRow extends StatelessWidget {
  const _DeviceInfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textMutedOf(context)),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.bodySmall
              .copyWith(color: AppColors.textMutedOf(context)),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimaryOf(context),
              fontWeight: FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

// ── Position chip ─────────────────────────────────────────────────────────────

class _PositionChip extends StatelessWidget {
  const _PositionChip({required this.label, required this.value});

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
          Text(
            label,
            style: AppTextStyles.labelSmall.copyWith(
              color: AppColors.textMutedOf(context),
              fontSize: 9,
            ),
          ),
          Text(
            value,
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textPrimaryOf(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Trip tile ─────────────────────────────────────────────────────────────────

class _TripTile extends StatelessWidget {
  const _TripTile({required this.trip});

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
                Text(
                  DateFormatter.toDateTime(trip.startTime),
                  style: AppTextStyles.labelLarge.copyWith(fontSize: 12),
                ),
                Text(
                  '${FormatUtils.distance(trip.distanceMeters)} · '
                  '${DateFormatter.duration(trip.durationSeconds)}',
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            FormatUtils.speed(trip.maxSpeedKmh),
            style: AppTextStyles.labelSmall
                .copyWith(color: AppColors.textSecondaryOf(context)),
          ),
        ],
      ),
    );
  }
}

// ── Alert tile ────────────────────────────────────────────────────────────────

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
                Text(
                  alert.title,
                  style: AppTextStyles.labelLarge.copyWith(fontSize: 12),
                ),
                Text(
                  DateFormatter.toRelative(alert.createdAt),
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
