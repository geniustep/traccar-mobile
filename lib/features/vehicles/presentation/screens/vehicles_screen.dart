import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/empty_view.dart';
import '../../../../core/widgets/status_badge.dart';
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
    final filter = ref.watch(vehicleFilterProvider);
    final allAsync = ref.watch(vehiclesListProvider);
    final filteredAsync = ref.watch(filteredVehiclesProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ── App bar ─────────────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            floating: true,
            backgroundColor: AppColors.surface,
            surfaceTintColor: Colors.transparent,
            elevation: 0,
            title: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _searchActive
                  ? _SearchField(
                      key: const ValueKey('search'),
                      controller: _searchController,
                      onChanged: (q) =>
                          ref.read(vehicleFilterProvider.notifier).setQuery(q),
                      onClose: () {
                        setState(() => _searchActive = false);
                        _searchController.clear();
                        ref.read(vehicleFilterProvider.notifier).setQuery('');
                      },
                    )
                  : const Align(
                      key: ValueKey('title'),
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'لائحة المركبات',
                        style: TextStyle(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                        ),
                      ),
                    ),
            ),
            actions: [
              if (!_searchActive)
                IconButton(
                  icon: const Icon(Icons.search_rounded,
                      color: AppColors.textSecondary),
                  tooltip: 'بحث',
                  onPressed: () => setState(() => _searchActive = true),
                ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded,
                    color: AppColors.textSecondary),
                tooltip: 'تحديث',
                onPressed: () => ref.invalidate(vehiclesListProvider),
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(height: 1, color: AppColors.border),
            ),
          ),

          // ── Fleet stats summary ──────────────────────────────────────────────
          SliverToBoxAdapter(
            child: allAsync.whenOrNull(
                  data: (vehicles) => _FleetStatsBar(vehicles: vehicles),
                ) ??
                const SizedBox.shrink(),
          ),

          // ── Sticky filter chips ──────────────────────────────────────────────
          SliverPersistentHeader(
            pinned: true,
            delegate: _FilterDelegate(
              filter: filter,
              allAsync: allAsync,
              onStatusChanged: (s) =>
                  ref.read(vehicleFilterProvider.notifier).setStatus(s),
            ),
          ),

          // ── Vehicle list ─────────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
            sliver: filteredAsync.when(
              data: (vehicles) {
                if (vehicles.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 48),
                      child: EmptyView(
                        icon: Icons.directions_car_outlined,
                        title: 'لا توجد مركبات',
                        message: filter.query.isNotEmpty ||
                                filter.statusFilter != null
                            ? 'جرّب تغيير معايير البحث أو الفلتر.'
                            : 'لا توجد مركبات مسجلة.',
                      ),
                    ),
                  );
                }
                return SliverList.separated(
                  itemCount: vehicles.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, i) => VehicleCard(
                    vehicle: vehicles[i],
                    onTap: () => context.push('/vehicles/${vehicles[i].id}'),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.only(top: 64),
                  child: LoadingView(message: 'جار تحميل الأسطول…'),
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
    required this.onChanged,
    required this.onClose,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      autofocus: true,
      onChanged: onChanged,
      style: const TextStyle(color: AppColors.textPrimary, fontSize: 15),
      decoration: InputDecoration(
        hintText: 'البحث بالاسم أو رقم اللوحة…',
        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
        border: InputBorder.none,
        isDense: true,
        contentPadding: EdgeInsets.zero,
        suffixIcon: IconButton(
          icon: const Icon(Icons.close_rounded,
              size: 20, color: AppColors.textSecondary),
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
    final moving = vehicles.where((v) => v.isMoving).length;
    final stopped = vehicles.where((v) => v.isStopped).length;
    final idle = vehicles.where((v) => v.isIdle).length;
    final offline = vehicles.where((v) => v.isOffline).length;

    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.directions_car_filled_rounded,
                  size: 13, color: AppColors.textMuted),
              const SizedBox(width: 5),
              Text(
                'إجمالي الأسطول: ${vehicles.length} مركبة',
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.3,
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
                  label: 'متحركة',
                  icon: Icons.play_circle_filled_rounded,
                  color: AppColors.statusMoving,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  count: stopped,
                  label: 'متوقفة',
                  icon: Icons.stop_circle_rounded,
                  color: AppColors.statusStopped,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  count: idle,
                  label: 'خاملة',
                  icon: Icons.pause_circle_filled_rounded,
                  color: AppColors.statusIdle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  count: offline,
                  label: 'مقطوعة',
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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.18), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 13),
              const Spacer(),
              Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: TextStyle(
              color: color.withValues(alpha: 0.75),
              fontSize: 10,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sticky filter delegate ────────────────────────────────────────────────────

class _FilterDelegate extends SliverPersistentHeaderDelegate {
  _FilterDelegate({
    required this.filter,
    required this.allAsync,
    required this.onStatusChanged,
  });

  final VehicleFilterState filter;
  final AsyncValue<List<VehicleEntity>> allAsync;
  final ValueChanged<String?> onStatusChanged;

  static const _items = [
    (label: 'الكل', status: null as String?),
    (label: 'متحرك', status: 'moving'),
    (label: 'متوقف', status: 'stopped'),
    (label: 'خامل', status: 'idle'),
    (label: 'مقطوع', status: 'offline'),
  ];

  int _count(String? status) {
    final vehicles = allAsync.valueOrNull;
    if (vehicles == null) return 0;
    if (status == null) return vehicles.length;
    return vehicles.where((v) => v.status == status).length;
  }

  Color _chipColor(String? status) => switch (status) {
        'moving' => AppColors.statusMoving,
        'stopped' => AppColors.statusStopped,
        'idle' => AppColors.statusIdle,
        'offline' => AppColors.statusOffline,
        _ => AppColors.accent,
      };

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: AppColors.background,
      child: Column(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, i) {
                final item = _items[i];
                final isSelected = item.status == null
                    ? filter.statusFilter == null
                    : filter.statusFilter == item.status;
                final color = _chipColor(item.status);
                final count = _count(item.status);

                return GestureDetector(
                  onTap: () => onStatusChanged(item.status),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 0),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? color.withValues(alpha: 0.14)
                          : AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? color.withValues(alpha: 0.55)
                            : AppColors.border,
                        width: isSelected ? 1.2 : 0.8,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (item.status != null) ...[
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
                          item.label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: isSelected
                                ? color
                                : AppColors.textSecondary,
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
                                : AppColors.border,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '$count',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? color : AppColors.textMuted,
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
          Container(height: 1, color: AppColors.border),
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
      old.filter != filter || old.allAsync != allAsync;
}
