import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../data/datasources/geofences_remote_datasource.dart';
import '../../domain/entities/geofence.dart';
import '../providers/geofences_providers.dart';
import '../widgets/geofence_card.dart';
import '../widgets/geofence_empty_state.dart';

class GeofencesScreen extends ConsumerStatefulWidget {
  const GeofencesScreen({super.key});

  @override
  ConsumerState<GeofencesScreen> createState() => _GeofencesScreenState();
}

class _GeofencesScreenState extends ConsumerState<GeofencesScreen> {
  final _search = TextEditingController();
  String _typeFilter = 'all';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<GeofenceEntity> _filter(List<GeofenceEntity> all) {
    final q = _search.text.trim().toLowerCase();
    return all.where((g) {
      final nameOk = q.isEmpty || g.name.toLowerCase().contains(q);
      final typeOk = _typeFilter == 'all' ||
          (_typeFilter == 'circle' && g.isCircle) ||
          (_typeFilter == 'polygon' && g.isPolygon);
      return nameOk && typeOk;
    }).toList();
  }

  bool _hasAlerts(GeofenceEntity g) {
    final p = GeofencesRemoteDataSource.parseStoredNotificationIds(g.attributes);
    return p.$1 != null || p.$2 != null;
  }

  Future<void> _confirmDelete(GeofenceEntity g, AppLocalizations l10n) async {
    final linked = g.linkedDeviceIds.isNotEmpty;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.geofenceDeleteTitle),
        content: Text(
          linked
              ? l10n.geofenceDeleteWarningWithVehicles(g.linkedDeviceIds.length)
              : l10n.geofenceDeleteMessage,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(l10n.geofenceDelete),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(geofencesRepositoryProvider).deleteGeofence(g.id);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(l10n.geofenceDeleted)));
        await ref.read(geofencesListProvider.notifier).refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.geofenceLoadError}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final async = ref.watch(geofencesListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.geofencesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/geofences/new/edit'),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenPadding,
              AppSpacing.sm,
              AppSpacing.screenPadding,
              0,
            ),
            child: TextField(
              controller: _search,
              decoration: InputDecoration(
                hintText: l10n.geofenceSearchHint,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.screenPadding),
              children: [
                _FilterChip(
                  label: l10n.geofenceFilterAllTypes,
                  selected: _typeFilter == 'all',
                  onTap: () => setState(() => _typeFilter = 'all'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l10n.geofenceTypeCircle,
                  selected: _typeFilter == 'circle',
                  onTap: () => setState(() => _typeFilter = 'circle'),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: l10n.geofenceTypePolygon,
                  selected: _typeFilter == 'polygon',
                  onTap: () => setState(() => _typeFilter = 'polygon'),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: async.when(
              data: (list) {
                final filtered = _filter(list);
                if (filtered.isEmpty) {
                  return GeofenceEmptyState(l10n: l10n);
                }
                return RefreshIndicator(
                  onRefresh: () => ref.read(geofencesListProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) {
                      final g = filtered[i];
                      return GeofenceCard(
                        geofence: g,
                        l10n: l10n,
                        hasAlerts: _hasAlerts(g),
                        onTap: () => context.push('/geofences/${g.id}'),
                        onEdit: () => context.push('/geofences/${g.id}/edit'),
                        onDelete: () => _confirmDelete(g, l10n),
                      );
                    },
                  ),
                );
              },
              loading: () => LoadingView(message: l10n.loading),
              error: (e, _) => ErrorView(
                message: l10n.geofenceLoadError,
                onRetry: () => ref.read(geofencesListProvider.notifier).refresh(),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/geofences/new/edit'),
        icon: const Icon(Icons.add_rounded),
        label: Text(l10n.geofencesAdd),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.accent.withValues(alpha: 0.14)
              : AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppColors.accent : AppColors.borderOf(context),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppColors.accent : AppColors.textSecondaryOf(context),
          ),
        ),
      ),
    );
  }
}
