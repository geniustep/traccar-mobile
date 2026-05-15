import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../core/route_intelligence_threshold_resolution.dart';
import '../../core/route_intelligence_thresholds.dart';
import '../providers/route_intelligence_thresholds_provider.dart';
import '../utils/route_intel_local_threshold_form_parse.dart';
import '../utils/route_intel_vehicle_central_edit_permission.dart';
import '../utils/route_intel_vehicle_central_write_actions.dart';

/// Phase 6K — vehicle-only central Route Intelligence editing (below preview).
class RouteIntelligenceVehicleCentralThresholdSection extends ConsumerWidget {
  const RouteIntelligenceVehicleCentralThresholdSection({
    super.key,
    required this.vehicleId,
  });

  final String vehicleId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;
    final user = ref.watch(currentUserProvider);
    final resolution = ref.watch(
      routeIntelligenceThresholdsResolutionForVehicleProvider(vehicleId),
    );
    final canEdit = routeIntelCanEditVehicleCentralThresholds(user);
    final hasDevice = routeIntelResolutionHasDeviceOverride(resolution);

    if (!canEdit) {
      return Padding(
        padding: const EdgeInsets.only(top: AppSpacing.sm),
        child: Text(
          l10n.routeIntelVehicleNoPermissionHint,
          style: AppTextStyles.labelSmall.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              FilledButton.icon(
                onPressed: () => _openEditSheet(
                  context,
                  ref,
                  vehicleId,
                  resolution,
                ),
                icon: const Icon(Icons.tune_rounded, size: 18),
                label: Text(l10n.routeIntelVehicleEditButton),
              ),
              if (hasDevice)
                OutlinedButton.icon(
                  onPressed: () => _confirmAndClear(
                    context,
                    ref,
                    vehicleId,
                  ),
                  icon: const Icon(Icons.layers_clear_rounded, size: 18),
                  label: Text(l10n.routeIntelVehicleReset),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.routeIntelVehicleOnlyHint,
            style: AppTextStyles.labelSmall.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _openEditSheet(
  BuildContext context,
  WidgetRef ref,
  String vehicleId,
  RouteIntelligenceThresholdResolution resolution,
) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.viewInsetsOf(ctx).bottom,
      ),
      child: _VehicleCentralThresholdEditPanel(
        vehicleId: vehicleId,
        initial: resolution.thresholds.normalized(),
      ),
    ),
  );
}

Future<void> _confirmAndClear(
  BuildContext context,
  WidgetRef ref,
  String vehicleId,
) async {
  final l10n = context.l10n;
  final ok = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(l10n.routeIntelVehicleReset),
      content: Text(l10n.routeIntelVehicleResetConfirmMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: Text(MaterialLocalizations.of(ctx).cancelButtonLabel),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(l10n.routeIntelVehicleReset),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted) return;
  try {
    await clearVehicleRouteIntelCentral(ref, vehicleId: vehicleId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.routeIntelVehicleResetDone)),
    );
  } catch (e, st) {
    logVehicleRouteIntelCentralError(e, st);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.routeIntelVehicleResetError)),
    );
  }
}

class _VehicleCentralThresholdEditPanel extends ConsumerStatefulWidget {
  const _VehicleCentralThresholdEditPanel({
    required this.vehicleId,
    required this.initial,
  });

  final String vehicleId;
  final RouteIntelligenceThresholds initial;

  @override
  ConsumerState<_VehicleCentralThresholdEditPanel> createState() =>
      _VehicleCentralThresholdEditPanelState();
}

class _VehicleCentralThresholdEditPanelState
    extends ConsumerState<_VehicleCentralThresholdEditPanel> {
  late final TextEditingController _enterCtl;
  late final TextEditingController _exitCtl;
  late final TextEditingController _minStopCtl;
  late final TextEditingController _overCtl;
  late bool _detectStops;
  late bool _detectOverspeed;
  late bool _detectIgnition;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final t = widget.initial;
    _enterCtl = TextEditingController(text: _fmtNum(t.stopSpeedEnterKmh));
    _exitCtl = TextEditingController(text: _fmtNum(t.stopSpeedExitKmh));
    _minStopCtl = TextEditingController(
      text: '${t.minStopDuration.inMinutes}',
    );
    _overCtl = TextEditingController(text: _fmtNum(t.overspeedThresholdKmh));
    _detectStops = t.detectStops;
    _detectOverspeed = t.detectOverspeed;
    _detectIgnition = t.detectIgnition;
  }

  String _fmtNum(double v) {
    if (!v.isFinite) return '';
    final r = v.roundToDouble();
    if ((v - r).abs() < 1e-9) return r.toInt().toString();
    return v.toStringAsFixed(1);
  }

  @override
  void dispose() {
    _enterCtl.dispose();
    _exitCtl.dispose();
    _minStopCtl.dispose();
    _overCtl.dispose();
    super.dispose();
  }

  Future<void> _submit(AppLocalizations l10n) async {
    final parsed = parseRouteIntelLocalFormInputs(
      stopSpeedEnterRaw: _enterCtl.text,
      stopSpeedExitRaw: _exitCtl.text,
      minStopMinutesRaw: _minStopCtl.text,
      overspeedRaw: _overCtl.text,
      detectStops: _detectStops,
      detectOverspeed: _detectOverspeed,
      detectIgnition: _detectIgnition,
    );
    if (parsed.invalidNumeric || parsed.thresholds == null) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(l10n.routeIntelInvalidValue)),
      );
      return;
    }
    final messenger = ScaffoldMessenger.of(context);
    setState(() => _busy = true);
    try {
      await saveVehicleRouteIntelCentral(
        ref,
        vehicleId: widget.vehicleId,
        thresholds: parsed.thresholds!,
      );
      if (!mounted) return;
      Navigator.of(context).pop();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.routeIntelVehicleSaved)),
      );
    } catch (e, st) {
      logVehicleRouteIntelCentralError(e, st);
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.routeIntelVehicleSaveError)),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(labelText: label, isDense: true);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.lg + bottomInset,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            l10n.routeIntelVehicleEditTitle,
            style: AppTextStyles.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.routeIntelVehicleEditSubtitle,
            style: AppTextStyles.bodySmall.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.routeIntelVehicleOnlyHint,
            style: AppTextStyles.labelSmall.copyWith(
              color: cs.outline,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextField(
            controller: _enterCtl,
            enabled: !_busy,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _decoration(l10n.routeIntelStopEnter),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _exitCtl,
            enabled: !_busy,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _decoration(l10n.routeIntelStopExit),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _minStopCtl,
            enabled: !_busy,
            keyboardType: TextInputType.number,
            decoration: _decoration(l10n.routeIntelMinStopDuration),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _overCtl,
            enabled: !_busy,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _decoration(l10n.routeIntelOverspeedThreshold),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.routeIntelDetectStops),
            value: _detectStops,
            onChanged: _busy ? null : (v) => setState(() => _detectStops = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.routeIntelDetectOverspeed),
            value: _detectOverspeed,
            onChanged: _busy
                ? null
                : (v) => setState(() => _detectOverspeed = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.routeIntelDetectIgnition),
            value: _detectIgnition,
            onChanged: _busy
                ? null
                : (v) => setState(() => _detectIgnition = v),
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton(
            onPressed: _busy ? null : () => _submit(l10n),
            child: _busy
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(l10n.routeIntelVehicleSave),
          ),
        ],
      ),
    );
  }
}
