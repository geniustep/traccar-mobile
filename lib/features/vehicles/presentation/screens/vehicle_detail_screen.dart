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
import '../../../trips/presentation/providers/trips_provider.dart';
import '../../../trips/domain/entities/trip.dart';
import '../../../alerts/presentation/providers/alerts_provider.dart';
import '../../../alerts/domain/entities/alert.dart';
import '../../../../core/models/traccar_position.dart';
import '../../../../shared/providers/traccar_providers.dart';
import '../../domain/entities/vehicle.dart';
import '../providers/vehicles_provider.dart';

class VehicleDetailScreen extends ConsumerWidget {
  const VehicleDetailScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final vehicleAsync = ref.watch(vehicleDetailProvider(vehicleId));
    final tripsAsync = ref.watch(vehicleTripsProvider(vehicleId));
    final alertsAsync = ref.watch(vehicleAlertsProvider(vehicleId));
    final livePositions = ref.watch(livePositionsProvider);

    return Scaffold(      body: vehicleAsync.when(
        data: (vehicle) {
          final deviceId = int.tryParse(vehicle.id);
          final livePos =
              deviceId != null ? livePositions[deviceId] : null;
          final status = StatusBadge.fromString(vehicle.status);
          return CustomScrollView(
            slivers: [
              SliverAppBar(                pinned: true,
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      size: 18),
                  onPressed: () => context.pop(),
                ),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(vehicle.name, style: AppTextStyles.headlineMedium),
                    Text(vehicle.plateNumber, style: AppTextStyles.bodySmall),
                  ],
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.gps_fixed_rounded),
                    onPressed: () =>
                        context.push('/vehicles/$vehicleId/track'),
                    tooltip: 'تتبع السيارة',
                  ),
                ],
              ),

              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.screenPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status bar
                      ElmoCard(
                        child: Row(
                          children: [
                            Expanded(
                              child: _StatusItem(
                                label: 'Statut',
                                value: StatusBadge(status: status),
                              ),
                            ),
                            _divider(),
                            Expanded(
                              child: _StatusItem(
                                label: 'Vitesse',
                                value: Text(
                                  FormatUtils.speed(
                                    livePos?.speedKmh ?? vehicle.speed,
                                  ),
                                  style: AppTextStyles.headlineSmall,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: AppSpacing.md),

                      ElmoCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Télémétrie (temps réel)',
                              style: AppTextStyles.labelSmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            _TelemetryGrid(
                              ignition:
                                  livePos?.ignitionOn ?? vehicle.ignition,
                              motion: livePos?.motion ?? vehicle.isMoving,
                              speedKmh: livePos?.speedKmh ?? vehicle.speed,
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

                      // Location info
                      if (vehicle.address != null)
                        ElmoCard(
                          child: Row(
                            children: [
                              const Icon(Icons.location_on_rounded,
                                  color: AppColors.accent, size: 20),
                              const SizedBox(width: AppSpacing.sm),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Current location',
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

                      // Map placeholder
                      _buildMapSection(context, vehicle),

                      const SizedBox(height: AppSpacing.md),

                      // Info grid
                      _buildInfoGrid(vehicle, livePos),

                      const SizedBox(height: AppSpacing.sectionSpacing),

                      // Trips section
                      SectionHeader(
                        title: 'Recent Trips',
                        actionLabel: 'All trips',
                        onAction: () => context.push('/vehicles/$vehicleId/trips'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      tripsAsync.when(
                        data: (trips) {
                          if (trips.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(AppSpacing.lg),
                              child: Center(
                                child: Text('No trips recorded today.',
                                    style: AppTextStyles.bodySmall),
                              ),
                            );
                          }
                          return Column(
                            children: trips.take(3).map((trip) {
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: _TripTile(trip: trip),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const InlineLoader(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      const SizedBox(height: AppSpacing.sectionSpacing),

                      // Alerts section
                      SectionHeader(
                        title: 'Recent Alerts',
                        actionLabel: 'All alerts',
                        onAction: () => context.go('/alerts'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      alertsAsync.when(
                        data: (alerts) {
                          if (alerts.isEmpty) {
                            return const Padding(
                              padding: EdgeInsets.all(AppSpacing.lg),
                              child: Center(
                                child: Text('No alerts for this vehicle.',
                                    style: AppTextStyles.bodySmall),
                              ),
                            );
                          }
                          return Column(
                            children: alerts.take(3).map((alert) {
                              return Padding(
                                padding:
                                    const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: _AlertTile(alert: alert),
                              );
                            }).toList(),
                          );
                        },
                        loading: () => const InlineLoader(),
                        error: (_, __) => const SizedBox.shrink(),
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
        loading: () => const LoadingView(message: 'Loading vehicle…'),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(vehicleDetailProvider(vehicleId)),
        ),
      ),
    );
  }

  Widget _buildMapSection(BuildContext context, VehicleEntity vehicle) {
    return GestureDetector(
      onTap: () => context.push('/vehicles/$vehicleId/track'),
      child: Container(
        height: 160,
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated,
          borderRadius: BorderRadius.circular(AppSpacing.cardRadius),
          border: Border.all(color: AppColors.border, width: 0.5),
        ),
        child: Stack(
          children: [
            CustomPaint(
              painter: _MapGridPainter(),
              child: const SizedBox.expand(),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: AppColors.accent.withOpacity(0.5), width: 2),
                    ),
                    child: const Icon(Icons.gps_fixed_rounded,
                        color: AppColors.accent, size: 24),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'تتبع السيارة',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoGrid(VehicleEntity vehicle, TraccarPosition? livePos) {
    final voltage = livePos?.vehicleVoltage ?? vehicle.batteryVoltage;
    return GridView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: AppSpacing.sm,
        mainAxisSpacing: AppSpacing.sm,
        childAspectRatio: 2.8,
      ),
      children: [
        if (vehicle.driverName != null)
          _InfoGridTile(
            icon: Icons.person_rounded,
            label: 'Driver',
            value: vehicle.driverName!,
          ),
        if (voltage != null)
          _InfoGridTile(
            icon: Icons.battery_charging_full_rounded,
            label: 'Battery',
            value: FormatUtils.voltage(voltage),
            color: voltage < 11.8 ? AppColors.warning : null,
          ),
        _InfoGridTile(
          icon: Icons.gps_fixed_rounded,
          label: 'Coordinates',
          value:
              '${vehicle.latitude.toStringAsFixed(4)}, ${vehicle.longitude.toStringAsFixed(4)}',
        ),
        if (vehicle.lastUpdate != null)
          _InfoGridTile(
            icon: Icons.access_time_rounded,
            label: 'Last Update',
            value: DateFormatter.toRelative(vehicle.lastUpdate!),
          ),
      ],
    );
  }

  Widget _divider() {
    return Container(
      width: 0.5,
      height: 40,
      color: AppColors.border,
    );
  }
}

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
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _TelemetryCell(
                label: 'Allumage',
                child: Icon(
                  ignition
                      ? Icons.power_settings_new_rounded
                      : Icons.power_off_rounded,
                  color: ignition
                      ? AppColors.statusMoving
                      : AppColors.textMuted,
                  size: 22,
                ),
              ),
            ),
            Expanded(
              child: _TelemetryCell(
                label: 'Mouvement',
                child: Icon(
                  motion ? Icons.directions_run_rounded : Icons.pause_circle_outline,
                  color: motion ? AppColors.accent : AppColors.textMuted,
                  size: 22,
                ),
              ),
            ),
            Expanded(
              child: _TelemetryCell(
                label: 'Vitesse',
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
                label: 'Carburant',
                child: Text(
                  FormatUtils.fuelLevel(fuelLiters),
                  style: AppTextStyles.labelLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              child: _TelemetryCell(
                label: 'Batterie',
                child: Text(
                  FormatUtils.voltage(voltage),
                  style: AppTextStyles.labelLarge,
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            Expanded(
              child: _TelemetryCell(
                label: 'Freinage',
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      hardBrake
                          ? Icons.warning_amber_rounded
                          : Icons.check_circle_outline_rounded,
                      color: hardBrake ? AppColors.warning : AppColors.textMuted,
                      size: 20,
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        hardBrake ? 'Dur' : 'OK',
                        style: AppTextStyles.labelSmall.copyWith(
                          color: hardBrake
                              ? AppColors.warning
                              : AppColors.textMuted,
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
  const _TelemetryCell({
    required this.label,
    required this.child,
  });

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        child,
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTextStyles.labelSmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

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
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color ?? AppColors.textMuted),
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
                    color: color ?? AppColors.textPrimary,
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

class _TripTile extends StatelessWidget {
  const _TripTile({required this.trip});

  final TripEntity trip;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
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
                .copyWith(color: AppColors.textSecondary),
          ),
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
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border, width: 0.5),
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

class _MapGridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border.withOpacity(0.5)
      ..strokeWidth = 0.5;

    for (double x = 0; x < size.width; x += 30) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 30) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
