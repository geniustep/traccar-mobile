import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/empty_view.dart';
import '../providers/vehicles_provider.dart';
import '../widgets/vehicle_card.dart';

class VehiclesScreen extends ConsumerWidget {
  const VehiclesScreen({super.key});

  static const _statusFilters = ['All', 'moving', 'stopped', 'idle', 'offline'];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(vehicleFilterProvider);
    final vehiclesAsync = ref.watch(filteredVehiclesProvider);

    return Scaffold(      appBar: AppBar(        title: const Text('Fleet Vehicles'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(vehiclesListProvider),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(114),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding, 0,
              AppSpacing.screenPadding, AppSpacing.md,
            ),
            child: Column(
              children: [
                // Search
                TextField(
                  onChanged: (q) => ref.read(vehicleFilterProvider.notifier).setQuery(q),
                  style: AppTextStyles.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Search by name or plate…',
                    prefixIcon: const Icon(Icons.search_rounded, size: 20),
                    suffixIcon: filter.query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            onPressed: () =>
                                ref.read(vehicleFilterProvider.notifier).setQuery(''),
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                // Status filter chips
                SizedBox(
                  height: 32,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: _statusFilters.map((s) {
                      final isSelected = s == 'All'
                          ? filter.statusFilter == null
                          : filter.statusFilter == s;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(
                            s == 'All' ? 'All Vehicles' : _capitalize(s),
                            style: TextStyle(
                              fontSize: 12,
                              color: isSelected
                                  ? AppColors.accent
                                  : AppColors.textSecondary,
                            ),
                          ),
                          selected: isSelected,
                          onSelected: (_) {
                            ref.read(vehicleFilterProvider.notifier).setStatus(
                                  s == 'All' ? null : s,
                                );
                          },
                          backgroundColor: AppColors.surfaceElevated,
                          selectedColor: AppColors.accent.withOpacity(0.15),
                          side: BorderSide(
                            color: isSelected
                                ? AppColors.accent.withOpacity(0.5)
                                : AppColors.border,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          showCheckmark: false,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 0),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: vehiclesAsync.when(
        data: (vehicles) {
          if (vehicles.isEmpty) {
            return EmptyView(
              icon: Icons.directions_car_outlined,
              title: 'No vehicles found',
              message: filter.query.isNotEmpty || filter.statusFilter != null
                  ? 'Try adjusting your search or filter.'
                  : 'No vehicles are registered yet.',
            );
          }
          return RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: AppColors.surface,
            onRefresh: () async => ref.invalidate(vehiclesListProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              itemCount: vehicles.length,
              separatorBuilder: (_, __) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final vehicle = vehicles[i];
                return VehicleCard(
                  vehicle: vehicle,
                  onTap: () => context.push('/vehicles/${vehicle.id}'),
                );
              },
            ),
          );
        },
        loading: () => const LoadingView(message: 'Loading fleet…'),
        error: (e, _) => ErrorView(
          message: e.toString(),
          onRetry: () => ref.invalidate(vehiclesListProvider),
        ),
      ),
    );
  }

  String _capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1)}';
}
