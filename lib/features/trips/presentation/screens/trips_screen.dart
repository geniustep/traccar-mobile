import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/elmo_card.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/format_utils.dart';
import '../providers/trips_provider.dart';
import '../../domain/entities/trip.dart';

class TripsScreen extends ConsumerWidget {
  const TripsScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tripsAsync = ref.watch(vehicleTripsProvider(vehicleId));

    return Scaffold(      appBar: AppBar(        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: const Text('Trip History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_rounded, size: 18),
            onPressed: () {}, // TODO: date range picker
            tooltip: 'Filter by date',
          ),
        ],
      ),
      body: tripsAsync.when(
        data: (trips) {
          if (trips.isEmpty) {
            return const EmptyView(
              icon: Icons.route_outlined,
              title: 'No trips recorded',
              message: 'Trip history will appear here.',
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.screenPadding),
            itemCount: trips.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, i) {
              final trip = trips[i];
              return TripCard(
                trip: trip,
                onTap: () => context.push('/trips/${trip.id}'),
              );
            },
          );
        },
        loading: () => const LoadingView(message: 'Loading trips…'),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(vehicleTripsProvider(vehicleId)),
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
                  color: AppColors.accent.withOpacity(0.1),
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
                      '${trip.endTime != null ? DateFormatter.toTime(trip.endTime!) : "Ongoing"}',
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
                    color: AppColors.statusMoving.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Ongoing',
                    style: TextStyle(
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
                label: 'Distance',
                value: FormatUtils.distance(trip.distanceMeters),
              ),
              _TripStat(
                icon: Icons.timer_rounded,
                label: 'Duration',
                value: DateFormatter.duration(trip.durationSeconds),
              ),
              _TripStat(
                icon: Icons.speed_rounded,
                label: 'Max speed',
                value: FormatUtils.speed(trip.maxSpeedKmh),
              ),
            ],
          ),
          if (trip.startAddress != null || trip.endAddress != null) ...[
            const SizedBox(height: AppSpacing.md),
            _RouteRow(
              start: trip.startAddress ?? 'Unknown',
              end: trip.endAddress ?? 'Unknown',
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
        Text(value, style: AppTextStyles.labelLarge.copyWith(fontSize: 13)),
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
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          _Location(icon: Icons.radio_button_checked, label: start,
              color: AppColors.statusMoving),
          Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Container(
              width: 1.5,
              height: 12,
              color: AppColors.border,
            ),
          ),
          _Location(icon: Icons.location_on_rounded, label: end,
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
