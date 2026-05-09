import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../fleet_domain/fleet_condition_logic.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/presentation/providers/vehicles_provider.dart';
import '../../domain/entities/maintenance_record.dart';
import '../providers/maintenance_providers.dart';
import '../widgets/maintenance_card.dart';
import '../widgets/maintenance_empty_state.dart';

class MaintenanceScreen extends ConsumerStatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  ConsumerState<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends ConsumerState<MaintenanceScreen> {
  final _search = TextEditingController();
  /// قيمة `all` تجمع كل المركبات.
  String _filterVehicleKey = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _vehicleLabel(List<VehicleEntity> vv, MaintenanceRecordEntity r) {
    for (final v in vv) {
      if (v.id == '${r.deviceId}') return v.name;
    }
    return '';
  }

  List<MaintenanceRecordEntity> _applyLocalFilter(
    List<MaintenanceRecordEntity> rows,
  ) {
    var out = rows;
    if (_filterVehicleKey != 'all') {
      final id = int.tryParse(_filterVehicleKey);
      if (id != null) {
        out = out.where((r) => r.deviceId == id).toList();
      }
    }
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return out;
    return out
        .where((r) =>
            r.name.toLowerCase().contains(q))
        .toList(growable: false);
  }

  Future<void> _confirmDelete(
    AppLocalizations l10n,
    MaintenanceRecordEntity row,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.maintenanceDeleteConfirmTitle),
        content: Text(l10n.maintenanceDeleteConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(l10n.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.maintenanceDelete),
          ),
        ],
      ),
    );

    if (!mounted || ok != true) return;
    try {
      await ref.read(maintenanceRepositoryProvider).deleteRecord(row.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.maintenanceDelete)));
      await ref.read(maintenanceListProvider.notifier).refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  ElmoMaintenanceSeverity _status(
      MaintenanceRecordEntity r, List<VehicleEntity> vehicles,) {
    double? odom;
    for (final v in vehicles) {
      if (v.id == '${r.deviceId}') {
        odom = v.latestOdometerKm;
        break;
      }
    }
    return r.resolveSeverity(
      reference: DateTime.now(),
      currentOdometerKm: odom,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final async = ref.watch(maintenanceListProvider);
    final vehiclesAsync = ref.watch(vehiclesListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.maintenanceTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/maintenance/new/edit'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.sm,
              AppSpacing.screenPadding,
              0,
            ),
            child: Column(
              children: [
                TextField(
                  controller: _search,
                  decoration: InputDecoration(
                    hintText: l10n.maintenanceSearchHint,
                    prefixIcon:
                        const Icon(Icons.search_rounded, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: AppSpacing.sm),
                vehiclesAsync.when(
                  data: (vv) => DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      labelText: l10n.maintenanceFilterVehicle,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                      isDense: true,
                    ),
                    value: _filterVehicleKey,
                    items: [
                      DropdownMenuItem(
                        value: 'all',
                        child: Text(l10n.maintenanceFilterAll),
                      ),
                      ...vv.map(
                        (v) => DropdownMenuItem<String>(
                          value: v.id,
                          child:
                              Text(v.name, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                    ],
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => _filterVehicleKey = v);
                    },
                  ),
                  loading: () => const SizedBox.shrink(),
                  error: (_, __) => const SizedBox.shrink(),
                ),
              ],
            ),
          ),
          Expanded(
            child: vehiclesAsync.maybeWhen(
              data: (vehicles) => async.when(
                data: (rows) {
                  final filtered = _applyLocalFilter(rows);
                  if (filtered.isEmpty) {
                    return MaintenanceEmptyState(l10n: l10n);
                  }
                  return RefreshIndicator(
                    onRefresh: () =>
                        ref.read(maintenanceListProvider.notifier).refresh(),
                    child: ListView.separated(
                      padding:
                          const EdgeInsets.all(AppSpacing.screenPadding),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: AppSpacing.sm),
                      itemBuilder: (_, i) {
                        final r = filtered[i];
                        final st = _status(r, vehicles);
                        return MaintenanceCard(
                          record: r,
                          status: st,
                          l10n: l10n,
                          vehicleName: _vehicleLabel(vehicles, r),
                          onEdit:
                              () => context.push('/maintenance/${r.id}/edit'),
                          onDelete: () => _confirmDelete(l10n, r),
                        );
                      },
                    ),
                  );
                },
                loading: () => LoadingView(message: l10n.loading),
                error: (e, _) => ErrorView(
                  message: l10n.maintenanceLoadError,
                  onRetry: () =>
                      ref.invalidate(maintenanceListProvider),
                ),
              ),
              orElse: () => LoadingView(message: l10n.loading),
            ),
          ),
        ],
      ),
    );
  }
}
