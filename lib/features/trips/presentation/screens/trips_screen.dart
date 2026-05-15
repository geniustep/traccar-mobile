import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/elmo_card.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../map/core/trip_segment_summary.dart';
import '../providers/trips_provider.dart';
import '../../domain/entities/trip.dart';

class TripsScreen extends ConsumerStatefulWidget {
  const TripsScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  ConsumerState<TripsScreen> createState() => _TripsScreenState();
}

class _TripsScreenState extends ConsumerState<TripsScreen> {
  DateTime? _from;
  DateTime? _to;

  VehicleTripsQuery get _query => VehicleTripsQuery(
        vehicleId: widget.vehicleId,
        from: _from,
        to: _to,
      );

  Future<void> _pickDateRange() async {
    final l10n = context.l10n;
    final now = DateTime.now();
    final initialRange = DateTimeRange(
      start: _from ?? now.subtract(const Duration(days: 7)),
      end: _to ?? now,
    );
    final range = await showDateRangePicker(
      context: context,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      initialDateRange: initialRange,
      helpText: l10n.tripDateFilter,
    );
    if (range == null || !mounted) return;

    setState(() {
      _from = DateTime(
        range.start.year,
        range.start.month,
        range.start.day,
      );
      _to = DateTime(
        range.end.year,
        range.end.month,
        range.end.day,
        23,
        59,
        59,
      );
    });

    AppLogger.navigation(
      'Trips date filter applied: vehicleId=${widget.vehicleId} '
      'from=$_from to=$_to',
    );
  }

  void _clearDateFilter() {
    if (_from == null && _to == null) return;
    setState(() {
      _from = null;
      _to = null;
    });
    AppLogger.navigation(
      'Trips date filter cleared: vehicleId=${widget.vehicleId}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final tripsAsync = ref.watch(vehicleTripsProvider(_query));
    final hasDateFilter = _from != null || _to != null;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.tripHistory),
        actions: [
          if (hasDateFilter)
            IconButton(
              icon: const Icon(Icons.filter_alt_off_rounded, size: 18),
              tooltip: l10n.clearDateFilter,
              onPressed: _clearDateFilter,
            ),
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            onPressed: _pickDateRange,
            tooltip: l10n.tripDateFilter,
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            if (hasDateFilter)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenPadding,
                  AppSpacing.sm,
                  AppSpacing.screenPadding,
                  0,
                ),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: AppColors.accent.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    '${l10n.tripDateFilter}: '
                    '${DateFormatter.toDate(_from!)} – ${DateFormatter.toDate(_to!)}',
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.accent,
                    ),
                  ),
                ),
              ),
            Expanded(
              child: tripsAsync.when(
                data: (trips) {
                  if (trips.isEmpty) {
                    return EmptyView(
                      icon: Icons.route_outlined,
                      title: l10n.noTrips,
                      message: l10n.noTripsMessage,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    itemCount: trips.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, i) {
                      final trip = trips[i];
                      return TripCard(
                        trip: trip,
                        onTap: () {
                          final end = trip.endTime ?? DateTime.now();
                          final params = reportFilterParamsForTrip(
                            vehicleId: trip.vehicleId,
                            startTime: trip.startTime,
                            endTime: end,
                          );
                          context.push(
                            '/vehicles/${trip.vehicleId}/trip-map',
                            extra: {
                              'params': params,
                              'vehicleName': trip.vehicleName,
                              'tripSubtitle':
                                  DateFormatter.toDateTime(trip.startTime),
                            },
                          );
                        },
                      );
                    },
                  );
                },
                loading: () => LoadingView(message: l10n.loadingTrips),
                error: (e, _) => ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(vehicleTripsProvider(_query)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TripCard extends StatelessWidget {
  const TripCard({super.key, required this.trip, this.onTap});

  final TripEntity trip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ElmoCard(
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.route_rounded,
                    color: AppColors.accent, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormatter.toDate(trip.startTime),
                      style: AppTextStyles.labelLarge,
                    ),
                    Text(
                      '${DateFormatter.toTime(trip.startTime)} – '
                      '${trip.endTime != null ? DateFormatter.toTime(trip.endTime!) : l10n.ongoingTrip}',
                      style: AppTextStyles.bodySmall,
                    ),
                  ],
                ),
              ),
              if (trip.isOngoing)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.statusMoving.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    l10n.ongoingTrip,
                    style: const TextStyle(
                      color: AppColors.statusMoving,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Divider(height: 0, thickness: 0.5),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _TripStat(
                icon: Icons.route_rounded,
                label: l10n.distanceLabel,
                value: FormatUtils.distance(trip.distanceMeters),
              ),
              _TripStat(
                icon: Icons.timer_rounded,
                label: l10n.durationLabel,
                value: DateFormatter.duration(trip.durationSeconds),
              ),
              _TripStat(
                icon: Icons.speed_rounded,
                label: l10n.maxSpeedLabel,
                value: FormatUtils.speed(trip.maxSpeedKmh),
              ),
            ],
          ),
          if (trip.startAddress != null || trip.endAddress != null) ...[
            const SizedBox(height: AppSpacing.md),
            _RouteRow(
              start: trip.startAddress ?? l10n.noData,
              end: trip.endAddress ?? l10n.noData,
            ),
          ],
        ],
      ),
    );
  }
}

class _TripStat extends StatelessWidget {
  const _TripStat({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 16, color: AppColors.accent),
        const SizedBox(height: 4),
        Text(value,
            style: AppTextStyles.labelLarge.copyWith(fontSize: 13)),
        Text(label, style: AppTextStyles.labelSmall),
      ],
    );
  }
}

class _RouteRow extends StatelessWidget {
  const _RouteRow({required this.start, required this.end});

  final String start;
  final String end;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevatedOf(context),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _Location(
              icon: Icons.radio_button_checked,
              label: start,
              color: AppColors.statusMoving),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Container(
              width: 1.5,
              height: 12,
              color: AppColors.borderOf(context),
            ),
          ),
          _Location(
              icon: Icons.location_on_rounded,
              label: end,
              color: AppColors.error),
        ],
      ),
    );
  }
}

class _Location extends StatelessWidget {
  const _Location({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySmall,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
