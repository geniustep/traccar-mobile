import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/error_view.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../domain/entities/driver.dart';
import '../providers/drivers_providers.dart';
import '../widgets/driver_card.dart';
import '../widgets/driver_empty_state.dart';

class DriversScreen extends ConsumerStatefulWidget {
  const DriversScreen({super.key});

  @override
  ConsumerState<DriversScreen> createState() => _DriversScreenState();
}

class _DriversScreenState extends ConsumerState<DriversScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<DriverEntity> _filter(List<DriverEntity> rows) {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return rows;
    return rows.where((d) {
      final code = d.uniqueId.toLowerCase();
      return d.name.toLowerCase().contains(q) || code.contains(q);
    }).toList();
  }

  Future<void> _confirmDelete(
    AppLocalizations l10n,
    DriverEntity driver,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.driversDeleteConfirmTitle),
        content: Text(l10n.driversDeleteConfirmBody),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancel)),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, true), child: Text(l10n.driversDelete)),
        ],
      ),
    );
    if (!mounted || ok != true) return;
    try {
      await ref.read(driversRepositoryProvider).deleteDriver(driver.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.driversDelete)));
      await ref.read(driversListProvider.notifier).refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final async = ref.watch(driversListProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => context.pop(),
        ),
        title: Text(l10n.driversTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded),
            onPressed: () => context.push('/drivers/new/edit'),
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
                hintText: l10n.driversSearchHint,
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          Expanded(
            child: async.when(
              data: (rows) {
                final filtered = _filter(rows);
                if (filtered.isEmpty) return DriverEmptyState(l10n: l10n);
                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(driversListProvider.notifier).refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (_, i) {
                      final d = filtered[i];
                      return DriverCard(
                        driver: d,
                        licenseStatus: d.licenseStatus(DateTime.now()),
                        l10n: l10n,
                        onDetails: () => context.push('/drivers/${d.id}'),
                        onEdit: () => context.push('/drivers/${d.id}/edit'),
                        onDelete: () => _confirmDelete(l10n, d),
                      );
                    },
                  ),
                );
              },
              loading: () => LoadingView(message: l10n.loading),
              error: (e, _) => ErrorView(
                message: l10n.driversLoadError,
                onRetry: () => ref.invalidate(driversListProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
