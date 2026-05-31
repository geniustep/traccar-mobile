import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../shared/providers/traccar_providers.dart';
import '../../../commands/presentation/providers/commands_provider.dart';
import '../../../map/core/map_camera_focus.dart';
import '../../../map/core/vehicle_live_merger.dart';
import '../../../map/presentation/providers/map_provider.dart';
import '../../../map/presentation/widgets/route_intelligence_thresholds_preview.dart';
import '../../../map/presentation/widgets/route_intelligence_vehicle_central_threshold_editor.dart';
import '../../../trips/presentation/providers/trips_provider.dart';
import '../../../alerts/presentation/providers/alerts_provider.dart';
import '../../../fleet/presentation/fleet_vehicle_brief_provider.dart';
import '../../../reports/presentation/providers/reports_providers.dart';
import '../../domain/entities/vehicle.dart';
import '../providers/vehicle_today_dashboard_provider.dart';
import '../providers/vehicles_provider.dart';
import '../widgets/vehicle_detail_cards.dart';
import '../widgets/report_entry_sheet.dart';
import '../widgets/replay_entry_sheet.dart';

class VehicleDetailScreen extends ConsumerStatefulWidget {
  const VehicleDetailScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  ConsumerState<VehicleDetailScreen> createState() =>
      _VehicleDetailScreenState();
}

class _VehicleDetailScreenState extends ConsumerState<VehicleDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      AppLogger.navigation(
        'Vehicle details opened: vehicleId=${widget.vehicleId} '
        'source=vehicle_detail_screen',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final vehicleAsync = ref.watch(vehicleDetailProvider(widget.vehicleId));

    ref.listen(vehicleDetailProvider(widget.vehicleId), (prev, next) {
      if (prev?.isLoading == true && next.hasValue) {
        AppLogger.navigation(
          'Vehicle details loaded: vehicleId=${widget.vehicleId}',
        );
      }
      if (next.hasError && prev?.hasError != true) {
        AppLogger.navigation(
          'Vehicle details load failed: vehicleId=${widget.vehicleId}',
        );
      }
    });

    return Scaffold(
      body: vehicleAsync.when(
        data: (vehicle) => _VehicleDetailBody(
          vehicleId: widget.vehicleId,
          vehicle: vehicle,
        ),
        loading: () => LoadingView(message: l10n.loadingVehicle),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () =>
              ref.invalidate(vehicleDetailProvider(widget.vehicleId)),
        ),
      ),
    );
  }
}

void _openVehicleAlerts(
  WidgetRef ref,
  BuildContext context,
  VehicleEntity vehicle,
) {
  AppLogger.alerts(
    'Vehicle alerts opened: vehicleId=${vehicle.id} source=vehicle_detail',
  );
  ref.read(alertsProvider.notifier).setVehicleFilter(
        vehicle.id,
        vehicleName: vehicle.name,
      );
  context.go('/alerts');
}

void _openViewOnFleetMap(WidgetRef ref, BuildContext context, String vehicleId) {
  AppLogger.navigation(
    'View on map: vehicleId=$vehicleId source=vehicle_detail',
  );
  ref.read(pendingMapCameraFocusProvider.notifier).state =
      MapCameraFocusRequest.single(vehicleId);
  context.go('/map');
}

class _VehicleDetailBody extends ConsumerWidget {
  const _VehicleDetailBody({
    required this.vehicleId,
    required this.vehicle,
  });

  final String vehicleId;
  final VehicleEntity vehicle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final livePositions = ref.watch(livePositionsProvider);
    final liveDevices = ref.watch(liveDevicesProvider);
    final fleetBriefMap = ref.watch(fleetVehicleBriefMapProvider);
    final tripsAsync = ref.watch(
      vehicleTripsProvider(VehicleTripsQuery(vehicleId: vehicleId)),
    );
    final alertsAsync = ref.watch(vehicleAlertsProvider(vehicleId));
    final todayDashboardAsync =
        ref.watch(vehicleTodayDashboardProvider(vehicleId));
    final isAdmin = ref.watch(currentUserRoleProvider).isAdmin;

    final deviceId = int.tryParse(vehicle.id);
    final brief = fleetBriefMap[vehicleId];
    final displayVehicle = VehicleLiveMerger.mergeIfPresent(vehicle, livePositions);
    final livePos = deviceId != null ? livePositions[deviceId] : null;
    final device = deviceId != null ? liveDevices[deviceId] : null;
    final status = StatusBadge.fromString(displayVehicle.status);

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // ── App bar ───────────────────────────────────────────────────────
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
                style: AppTextStyles.bodySmall
                    .copyWith(color: AppColors.textSecondaryOf(context)),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_remote_rounded,
                  color: AppColors.accent),
              tooltip: l10n.commandsTitle,
              onPressed: () {
                AppLogger.navigation(
                    'VehicleDetail: Commands tapped vehicleId=$vehicleId');
                context.push(
                  '/vehicles/$vehicleId/commands',
                  extra: {'name': vehicle.name},
                );
              },
            ),
            IconButton(
              key: const Key('vehicle_detail_track_btn'),
              icon: const Icon(Icons.gps_fixed_rounded,
                  color: AppColors.accent),
              tooltip: l10n.trackVehicle,
              onPressed: () {
                AppLogger.navigation(
                    'VehicleDetail: Track tapped vehicleId=$vehicleId');
                context.push('/vehicles/$vehicleId/track');
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1),
            child: Container(height: 1, color: AppColors.borderOf(context)),
          ),
        ),

        // ── Content ───────────────────────────────────────────────────────
        SliverToBoxAdapter(
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // A. Status + Speed + Last Update
                  VdStatusSpeedCard(
                    status: StatusBadge(status: status),
                    speedKmh: displayVehicle.speed,
                    lastUpdate: displayVehicle.lastUpdate,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // B. Live telemetry
                  VdTelemetryCard(
                    ignition: livePos?.ignitionOn ?? vehicle.ignition,
                    motion: livePos?.motion ?? vehicle.isMoving,
                    speedKmh: livePos?.speedKmh ?? vehicle.speed,
                    fuelLiters: livePos?.fuelLevel ?? vehicle.fuelLevel,
                    voltage:
                        livePos?.vehicleVoltage ?? vehicle.batteryVoltage,
                    hardBrake: livePos?.hardBrake ?? false,
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // C. Location
                  VdLocationCard(
                    vehicle: vehicle,
                    onViewOnMap: () =>
                        _openViewOnFleetMap(ref, context, vehicleId),
                    onLiveTracking: () {
                      AppLogger.navigation(
                          'VehicleDetail: Live tracking vehicleId=$vehicleId');
                      context.push('/vehicles/$vehicleId/track');
                    },
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // D. Today Summary
                  todayDashboardAsync.when(
                    data: (dashboard) {
                      if (!dashboard.hasSummary) {
                        AppLogger.dashboard(
                            'VehicleDetail: Today summary returned null for vehicleId=$vehicleId');
                      } else {
                        AppLogger.dashboard(
                            'Vehicle daily summary loaded: vehicleId=$vehicleId '
                            'stops=${dashboard.stopsCount} '
                            'alertsToday=${dashboard.alertsTodayCount}',
                        );
                      }
                      return VdTodaySummaryCard(dashboard: dashboard);
                    },
                    loading: () => const VdTodaySummaryCard(),
                    error: (e, _) {
                      AppLogger.error('VehicleDetail',
                          'Today summary failed for vehicleId=$vehicleId', e);
                      AppLogger.dashboard(
                          'Vehicle daily summary failed: vehicleId=$vehicleId');
                      return const VdTodaySummaryCard();
                    },
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // E. Fleet Info
                  VdFleetInfoCard(vehicle: vehicle, brief: brief),

                  const SizedBox(height: AppSpacing.sectionSpacing),

                  // G. Actions
                  VdActionsSection(
                    onGenerateReport: () async {
                      AppLogger.navigation(
                          'Report opened from vehicle details: '
                          'vehicleId=$vehicleId');
                      final params = await showReportEntrySheet(
                        context,
                        vehicleId: vehicleId,
                        vehicleName: vehicle.name,
                      );
                      if (params != null && context.mounted) {
                        AppLogger.navigation(
                            'VehicleDetail: navigating to /reports with '
                            'vehicleId=${params.vehicleId} tab=${params.tabIndex} '
                            'period=${params.period}');
                        context.push('/reports', extra: params);
                      }
                    },
                    onReplayRoute: () async {
                      AppLogger.navigation(
                          'Replay opened from vehicle details: '
                          'vehicleId=$vehicleId');
                      final result = await showReplayEntrySheet(
                        context,
                        vehicleId: vehicleId,
                        vehicleName: vehicle.name,
                      );
                      if (result != null && context.mounted) {
                        AppLogger.navigation(
                            'VehicleDetail: navigating to /reports/replay '
                            'vehicleId=${result.vehicleId} '
                            'from=${result.from} to=${result.to}');
                        context.push(
                          '/reports/replay',
                          extra: {
                            'params': ReportFilterParams(
                              vehicleId: result.vehicleId,
                              from: result.from.toUtc(),
                              to: result.to.toUtc(),
                            ),
                            'vehicleName': result.vehicleName,
                          },
                        );
                      }
                    },
                    onViewOnMap: () =>
                        _openViewOnFleetMap(ref, context, vehicleId),
                    onLiveTracking: () {
                      AppLogger.navigation(
                          'VehicleDetail: Live tracking tapped vehicleId=$vehicleId');
                      context.push('/vehicles/$vehicleId/track');
                    },
                    onViewTrips: () {
                      AppLogger.navigation(
                          'VehicleDetail: View Trips tapped vehicleId=$vehicleId');
                      context.push('/vehicles/$vehicleId/trips');
                    },
                    onCommands: () {
                      AppLogger.navigation(
                          'VehicleDetail: Commands tapped vehicleId=$vehicleId');
                      context.push(
                        '/vehicles/$vehicleId/commands',
                        extra: {'name': vehicle.name},
                      );
                    },
                  ),

                  const SizedBox(height: AppSpacing.sectionSpacing),

                  // F. Recent Trips
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
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: Center(
                            child: Text(l10n.noTripsToday,
                                style: AppTextStyles.bodySmall),
                          ),
                        );
                      }
                      return Column(
                        children: trips.take(3).map((trip) {
                          return Padding(
                            padding:
                                const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: VdTripTile(trip: trip),
                          );
                        }).toList(),
                      );
                    },
                    loading: () => const InlineLoader(),
                    error: (_, __) => Padding(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.error_outline_rounded,
                                size: 16,
                                color: AppColors.textMutedOf(context)),
                            const SizedBox(width: 8),
                            Text(l10n.tripsLoadError,
                                style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.textMutedOf(context))),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.sectionSpacing),

                  // F. Recent Alerts
                  SectionHeader(
                    title: l10n.recentAlerts,
                    actionLabel: l10n.allAlerts,
                    onAction: () => context.go('/alerts'),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  VdRecentAlertsSection(
                    alertsAsync: alertsAsync,
                    onViewAll: () => _openVehicleAlerts(ref, context, vehicle),
                  ),

                  const SizedBox(height: AppSpacing.sectionSpacing),

                  if (isAdmin) ...[
                    RouteIntelligenceVehicleThresholdPreview(
                      vehicleId: vehicleId,
                      vehicleName: vehicle.name,
                      groupId: vehicle.groupId,
                    ),
                    RouteIntelligenceVehicleCentralThresholdSection(
                      vehicleId: vehicleId,
                    ),
                  ],

                  const SizedBox(height: AppSpacing.md),

                  // H. Technical Info (collapsible)
                  VdTechnicalInfoSection(
                    device: device,
                    livePos: livePos,
                  ),

                  SizedBox(
                      height: MediaQuery.paddingOf(context).bottom + 12),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
