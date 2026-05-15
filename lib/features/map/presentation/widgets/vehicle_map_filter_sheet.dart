import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/presentation/comparison/vehicle_comparison_route_args.dart';
import '../../../vehicles/presentation/replay_multi/multi_vehicle_replay_formatters.dart';
import '../../../vehicles/presentation/replay_multi/multi_vehicle_replay_screen.dart';
import '../../core/map_camera_focus.dart';
import '../../core/vehicle_status_colors.dart';
import '../providers/map_provider.dart';
import '../providers/map_vehicle_filter.dart';

/// Opens the vehicle picker bottom sheet (search + multi-select).
Future<void> showVehicleMapFilterSheet(
  BuildContext context,
  WidgetRef ref, {
  bool autofocusSearch = false,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceOf(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (ctx) {
      final height = MediaQuery.sizeOf(ctx).height * 0.78;
      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(ctx).bottom,
        ),
        child: SizedBox(
          height: height,
          child: _VehicleMapFilterSheetBody(autofocusSearch: autofocusSearch),
        ),
      );
    },
  );
}

class _VehicleMapFilterSheetBody extends ConsumerStatefulWidget {
  const _VehicleMapFilterSheetBody({this.autofocusSearch = false});

  final bool autofocusSearch;

  @override
  ConsumerState<_VehicleMapFilterSheetBody> createState() =>
      _VehicleMapFilterSheetBodyState();
}

class _VehicleMapFilterSheetBodyState
    extends ConsumerState<_VehicleMapFilterSheetBody> {
  late final TextEditingController _searchCtrl;
  late final FocusNode _searchFocus;
  late Set<String> _selectedIds;
  late bool _onlineOnly;
  late bool _movingOnly;
  String _lastLoggedSearch = '';

  @override
  void initState() {
    super.initState();
    final f = ref.read(vehicleMapFilterProvider);
    _searchCtrl = TextEditingController(text: f.searchQuery);
    _searchFocus = FocusNode();
    _selectedIds = Set<String>.from(f.selectedVehicleIds);
    _onlineOnly = f.onlineOnly;
    _movingOnly = f.movingOnly;
    if (widget.autofocusSearch) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _searchFocus.requestFocus();
      });
    }
  }

  void _onSearchChanged(String value) {
    final q = value.trim();
    if (q != _lastLoggedSearch && q.length >= 2) {
      _lastLoggedSearch = q;
      AppLogger.map('Map filter search: queryLength=${q.length}');
    }
    if (q.isEmpty) _lastLoggedSearch = '';
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  void _toggleSelection(VehicleEntity v, bool? checked) {
    setState(() {
      if (checked == true) {
        _selectedIds.add(v.id);
      } else {
        _selectedIds.remove(v.id);
      }
    });
  }

  String _primaryActionLabel(AppLocalizations l10n) {
    final n = _selectedIds.length;
    if (n == 0) return l10n.showAllVehiclesOnMap;
    if (n == 1) return l10n.showVehicleOnMap;
    return l10n.showSelectedVehiclesOnMap(n);
  }

  void _scheduleCameraAfterApply(
    List<VehicleEntity> visibleOnMap,
    VehicleMapFilterState next,
  ) {
    if (_selectedIds.length == 1) {
      final id = _selectedIds.first;
      ref.read(selectedMapVehicleProvider.notifier).state = id;
      ref.read(pendingMapCameraFocusProvider.notifier).state =
          MapCameraFocusRequest.single(id);
      return;
    }

    ref.read(selectedMapVehicleProvider.notifier).state = null;

    if (_selectedIds.length >= 2) {
      ref.read(pendingMapCameraFocusProvider.notifier).state =
          MapCameraFocusRequest.fitVehicles(Set<String>.from(_selectedIds));
      return;
    }

    if (visibleOnMap.isNotEmpty && next.isActive) {
      ref.read(pendingMapCameraFocusProvider.notifier).state =
          MapCameraFocusRequest.fitVehicles(
        visibleOnMap.map((v) => v.id).toSet(),
      );
    } else {
      ref.read(pendingMapCameraFocusProvider.notifier).state = null;
    }
  }

  void _openComparison() {
    final ids = _selectedIds.toList();
    Navigator.pop(context);
    context.push(
      '/vehicles/compare',
      extra: VehicleComparisonRouteArgs(vehicleIds: ids),
    );
  }

  void _openMultiReplay() {
    final ids = _selectedIds.toList();
    final l10n = context.l10n;
    if (ids.length > 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.multiReplayLimitMessage)),
      );
      return;
    }
    if (!MultiVehicleReplayFormatters.canReplay(ids.length)) return;
    Navigator.pop(context);
    openMultiVehicleReplay(context, vehicleIds: ids);
  }

  void _applySelection() {
    final next = VehicleMapFilterState(
      selectedVehicleIds: Set<String>.from(_selectedIds),
      onlineOnly: _onlineOnly,
      movingOnly: _movingOnly,
      searchQuery: _searchCtrl.text,
    );
    ref.read(vehicleMapFilterProvider.notifier).state = next;

    final all = ref.read(mapVehiclesProvider).valueOrNull ?? const [];
    final visible = applyVehicleMapFilter(all, next);

    AppLogger.map(
      'Vehicle selection applied: count=${_selectedIds.length} '
      'visibleCount=${visible.length}',
    );

    _scheduleCameraAfterApply(visible, next);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final vehiclesAsync = ref.watch(mapVehiclesProvider);

    return vehiclesAsync.when(
      loading: () => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: LoadingView(message: l10n.mapLoadingFleet),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          l10n.mapLoadError,
          style: AppTextStyles.bodySmall,
          textAlign: TextAlign.center,
        ),
      ),
      data: (all) {
        final matching = vehiclesForFilterSheetList(
          all,
          searchQuery: _searchCtrl.text,
          onlineOnly: _onlineOnly,
          movingOnly: _movingOnly,
        );

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.textMutedOf(context)
                            .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    l10n.chooseVehicles,
                    style: AppTextStyles.headlineSmall,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.chooseVehiclesHint,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppColors.accent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      l10n.selectedVehiclesCount(_selectedIds.length),
                      style: AppTextStyles.labelLarge.copyWith(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    l10n.matchingVehiclesCount(matching.length),
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.textMutedOf(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchCtrl,
                    focusNode: _searchFocus,
                    autofocus: false,
                    decoration: InputDecoration(
                      hintText: l10n.mapFilterSearchHint,
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onChanged: _onSearchChanged,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      FilterChip(
                        label: Text(l10n.onlineOnlyFilter),
                        selected: _onlineOnly,
                        onSelected: (v) => setState(() => _onlineOnly = v),
                      ),
                      FilterChip(
                        label: Text(l10n.movingOnlyFilter),
                        selected: _movingOnly,
                        onSelected: (v) => setState(() => _movingOnly = v),
                      ),
                    ],
                  ),
                  if (_selectedIds.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: _selectedIds.map((id) {
                          final v =
                              all.where((e) => e.id == id).firstOrNull;
                          final label = v?.name ?? id;
                          return Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InputChip(
                              label: Text(
                                label,
                                style: const TextStyle(fontSize: 11),
                              ),
                              onDeleted: () {
                                setState(() => _selectedIds.remove(id));
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Expanded(
              child: matching.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 40,
                              color: AppColors.textMutedOf(context),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _searchCtrl.text.trim().isNotEmpty
                                  ? l10n.noMatchingVehicles
                                  : l10n.noVehiclesMatchFilter,
                              style: AppTextStyles.bodySmall.copyWith(
                                color: AppColors.textMutedOf(context),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: matching.length,
                      itemBuilder: (context, i) {
                        final v = matching[i];
                        final selected = _selectedIds.contains(v.id);
                        final sc = vehicleStatusColor(v.status);
                        return _FilterVehicleRow(
                          vehicle: v,
                          selected: selected,
                          statusColor: sc,
                          statusBadge: StatusBadge(
                            status: StatusBadge.fromString(v.status),
                          ),
                          onChanged: (c) => _toggleSelection(v, c),
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_selectedIds.isNotEmpty)
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() => _selectedIds = {});
                          AppLogger.map('Map filter selection cleared');
                        },
                        icon: const Icon(Icons.deselect_rounded, size: 18),
                        label: Text(l10n.clearSelection),
                      ),
                    if (_selectedIds.length > 5) ...[
                      const SizedBox(height: 8),
                      Text(
                        l10n.multiReplayLimitMessage,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMutedOf(context),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (_selectedIds.length >= 2 &&
                        _selectedIds.length <= 5) ...[
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _openComparison,
                          icon: const Icon(Icons.compare_arrows_rounded, size: 18),
                          label: Text(
                            _selectedIds.length == 2
                                ? l10n.compareVehicles
                                : l10n.compareVehiclesCount(_selectedIds.length),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _openMultiReplay,
                          icon: const Icon(Icons.play_circle_outline_rounded, size: 18),
                          label: Text(
                            _selectedIds.length == 2
                                ? l10n.replayMultiVehicles
                                : l10n.replayVehiclesCount(_selectedIds.length),
                            maxLines: 2,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                    if (_selectedIds.isNotEmpty) const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(l10n.cancel),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            onPressed: _applySelection,
                            child: Text(
                              _primaryActionLabel(l10n),
                              maxLines: 2,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _FilterVehicleRow extends StatelessWidget {
  const _FilterVehicleRow({
    required this.vehicle,
    required this.selected,
    required this.statusColor,
    required this.statusBadge,
    required this.onChanged,
  });

  final VehicleEntity vehicle;
  final bool selected;
  final Color statusColor;
  final Widget statusBadge;
  final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final sub = vehicle.plateNumber.isNotEmpty
        ? vehicle.plateNumber
        : (vehicle.uniqueId ?? '');

    return Material(
      color: selected
          ? AppColors.accent.withValues(alpha: 0.08)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(12),
      child: CheckboxListTile(
        value: selected,
        onChanged: onChanged,
        controlAffinity: ListTileControlAffinity.leading,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                vehicle.name,
                style: AppTextStyles.labelLarge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            statusBadge,
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(left: 16, top: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (sub.isNotEmpty)
                Text(sub, style: AppTextStyles.bodySmall),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    FormatUtils.speed(vehicle.speed),
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.textSecondaryOf(context),
                    ),
                  ),
                  if (vehicle.lastUpdate != null) ...[
                    Text(
                      ' · ',
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textMutedOf(context),
                      ),
                    ),
                    Flexible(
                      child: Text(
                        DateFormatter.toRelative(vehicle.lastUpdate!),
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textMutedOf(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
