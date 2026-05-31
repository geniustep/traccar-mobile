import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../fleet/presentation/fleet_vehicle_brief_provider.dart';
import '../../domain/entities/vehicle.dart';
import '../providers/vehicles_provider.dart';
import '../widgets/vehicle_card.dart';

class VehiclesScreen extends ConsumerStatefulWidget {
  const VehiclesScreen({super.key});

  @override
  ConsumerState<VehiclesScreen> createState() => _VehiclesScreenState();
}

class _VehiclesScreenState extends ConsumerState<VehiclesScreen> {
  final _searchController = TextEditingController();
  bool _searchActive = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final filter = ref.watch(vehicleFilterProvider);
    final allAsync = ref.watch(vehiclesListProvider);
    final filteredAsync = ref.watch(filteredVehiclesProvider);
    final fleetBriefMap = ref.watch(fleetVehicleBriefMapProvider);
    final allVehicles = allAsync.valueOrNull ?? const <VehicleEntity>[];
    final statusCounts = fleetStatusFilterCounts(allVehicles);

    ref.listen(vehiclesListProvider, (previous, next) {
      next.whenData((list) {
        final status = ref.read(vehicleFilterProvider).statusFilter;
        if (status == null) return;
        final count = list.where((v) => v.status == status).length;
        if (count == 0) {
          ref.read(vehicleFilterProvider.notifier).setStatus(null);
        }
      });
    });

    return Scaffold(
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App bar ───────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            floating: true,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _searchActive
                  ? _SearchField(
                      key: const ValueKey('search'),
                      controller: _searchController,
                      hint: l10n.searchHint,
                      onChanged: (q) =>
                          ref.read(vehicleFilterProvider.notifier).setQuery(q),
                      onClose: () {
                        setState(() => _searchActive = false);
                        _searchController.clear();
                        ref.read(vehicleFilterProvider.notifier).setQuery('');
                      },
                    )
                  : Align(
                      key: const ValueKey('title'),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.vehicleList,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
            ),
            actions: [
              if (!_searchActive)
                IconButton(
                  icon: const Icon(Icons.search_rounded),
                  tooltip: l10n.searchTooltip,
                  onPressed: () => setState(() => _searchActive = true),
                ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: l10n.refreshTooltip,
                onPressed: () => ref.invalidate(vehiclesListProvider),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                  height: 1,
                  color: AppColors.borderOf(context)),
            ),
          ),

          // ── Fleet stats summary ──────────────────────────────────────────
          SliverToBoxAdapter(
            child: allAsync.whenOrNull(
                  data: (vehicles) => _FleetStatsBar(vehicles: vehicles),
                ) ??
                const SizedBox.shrink(),
          ),

          // ── Sticky filter chips ──────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterDelegate(
              filter: filter,
              vehicles: allVehicles,
              statusCounts: statusCounts,
              onStatusChanged: (s) =>
                  ref.read(vehicleFilterProvider.notifier).setStatus(s),
            ),
          ),

          // ── Vehicle list ─────────────────────────────────────────────────
          SliverPadding(
            padding: EdgeInsets.fromLTRB(
              16,
              4,
              16,
              16 + MediaQuery.paddingOf(context).bottom,
            ),
            sliver: filteredAsync.when(
              data: (vehicles) {
                if (vehicles.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: EmptyView(
                        icon: Icons.directions_car_outlined,
                        title: l10n.noVehicles,
                        message: filter.statusFilter != null
                            ? l10n.noVehiclesInFilter
                            : filter.query.isNotEmpty
                                ? l10n.tryChangingFilters
                                : l10n.noVehiclesRegistered,
                      ),
                    ),
                  );
                }
                return SliverList.separated(
                  itemCount: vehicles.length,
                  separatorBuilder: (_, __) =>
                      const SizedBox(height: 10),
                  itemBuilder: (context, i) => VehicleCard(
                    vehicle: vehicles[i],
                    fleetBrief: fleetBriefMap[vehicles[i].id],
                    onTap: () =>
                        context.push('/vehicles/${vehicles[i].id}'),
                  ),
                );
              },
              loading: () => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 64),
                  child: LoadingView(message: l10n.loadingFleet),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: ErrorView(
                  message: e.toString(),
                  onRetry: () => ref.invalidate(vehiclesListProvider),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search field ──────────────────────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({
    super.key,
    required this.controller,
    required this.hint,
    required this.onChanged,
    required this.onClose,
  });

  final TextEditingController controller;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      onChanged: onChanged,
      style: TextStyle(
          color: AppColors.textPrimaryOf(context), fontSize: 15),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            color: AppColors.textMutedOf(context), fontSize: 14),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
        suffixIcon: IconButton(
          icon: Icon(Icons.close_rounded,
              size: 20,
              color: AppColors.textSecondaryOf(context)),
          onPressed: onClose,
        ),
      ),
    );
  }
}

// ── Fleet stats bar ───────────────────────────────────────────────────────────

class _FleetStatsBar extends StatelessWidget {
  const _FleetStatsBar({required this.vehicles});

  final List<VehicleEntity> vehicles;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final moving = vehicles.where((v) => v.isMoving).length;
    final stopped = vehicles.where((v) => v.isStopped).length;
    final idle = vehicles.where((v) => v.isIdle).length;
    final offline = vehicles.where((v) => v.isOffline).length;

    return Container(
      color: AppColors.surfaceOf(context),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.directions_car_filled_rounded,
                  size: 13,
                  color: AppColors.textMutedOf(context)),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  l10n.totalFleetCount(vehicles.length),
                  style: TextStyle(
                    color: AppColors.textMutedOf(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
              Text(
                l10n.fleetStatsLastSyncNow,
                style: TextStyle(
                  color: AppColors.textMutedOf(context),
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  count: moving,
                  label: l10n.statusMovingPlural,
                  icon: Icons.play_circle_filled_rounded,
                  color: AppColors.statusMoving,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  count: stopped,
                  label: l10n.statusStoppedPlural,
                  icon: Icons.stop_circle_rounded,
                  color: AppColors.statusStopped,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  count: idle,
                  label: l10n.statusIdlePlural,
                  icon: Icons.pause_circle_filled_rounded,
                  color: AppColors.statusIdle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  count: offline,
                  label: l10n.statusOfflinePlural,
                  icon: Icons.wifi_off_rounded,
                  color: AppColors.statusOffline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.count,
    required this.label,
    required this.icon,
    required this.color,
  });

  final int count;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final isZero = count == 0;
    final tileColor = isZero
        ? AppColors.textMutedOf(context)
        : color;
    return Opacity(
      opacity: isZero ? 0.5 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: isZero
              ? AppColors.surfaceElevatedOf(context).withValues(alpha: 0.5)
              : color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isZero
                ? AppColors.borderOf(context).withValues(alpha: 0.35)
                : color.withValues(alpha: 0.18),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: tileColor, size: isZero ? 12 : 13),
                const Spacer(),
                Text(
                  '$count',
                  style: TextStyle(
                    color: tileColor,
                    fontSize: isZero ? 16 : 22,
                    fontWeight: isZero ? FontWeight.w600 : FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 5),
            Text(
              label,
              style: TextStyle(
                color: tileColor.withValues(alpha: isZero ? 0.7 : 0.75),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sticky filter delegate ────────────────────────────────────────────────────

class _FilterDelegate extends SliverPersistentHeaderDelegate {
  _FilterDelegate({
    required this.filter,
    required this.vehicles,
    required this.statusCounts,
    required this.onStatusChanged,
  });

  final VehicleFilterState filter;
  final List<VehicleEntity> vehicles;
  final Map<String?, int> statusCounts;
  final ValueChanged<String?> onStatusChanged;

  List<String?> get _visibleStatuses => visibleFleetStatusFilters(statusCounts);

  int _count(String? status) => statusCounts[status] ?? 0;

  Color _chipColor(String? status) => switch (status) {
        'moving' => AppColors.statusMoving,
        'stopped' => AppColors.statusStopped,
        'idle' => AppColors.statusIdle,
        'offline' => AppColors.statusOffline,
        _ => AppColors.accent,
      };

  String _chipLabel(String? status, AppLocalizations l10n) =>
      switch (status) {
        'moving' => l10n.filterMoving,
        'stopped' => l10n.filterStopped,
        'idle' => l10n.filterIdle,
        'offline' => l10n.filterOffline,
        _ => l10n.filterAll,
      };

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final l10n = context.l10n;
    final statuses = _visibleStatuses;
    return Container(
      color: AppColors.backgroundOf(context),
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: statuses.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final status = statuses[i];
                final isSelected = status == null
                    ? filter.statusFilter == null
                    : filter.statusFilter == status;
                final color = _chipColor(status);
                final count = _count(status);
                final label = _chipLabel(status, l10n);

                return GestureDetector(
                  onTap: () => onStatusChanged(status),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 0),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.14)
                          : AppColors.surfaceElevatedOf(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? color.withValues(alpha: 0.55)
                            : AppColors.borderOf(context),
                        width: isSelected ? 1.2 : 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (status != null) ...[
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            width: 7,
                            height: 7,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? color
                                  : color.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? color
                                : AppColors.textSecondaryOf(context),
                          ),
                        ),
                        const SizedBox(width: 7),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.22)
                                : AppColors.borderOf(context),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? color
                                  : AppColors.textMutedOf(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
              height: 1,
              color: AppColors.borderOf(context)),
        ],
      ),
    );
  }

  @override
  double get maxExtent => 53;

  @override
  double get minExtent => 53;

  @override
  bool shouldRebuild(_FilterDelegate old) =>
      old.filter != filter ||
      old.vehicles.length != vehicles.length ||
      old.statusCounts != statusCounts;
}
