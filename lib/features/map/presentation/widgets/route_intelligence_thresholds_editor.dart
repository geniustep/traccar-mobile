import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/widgets/elmo_card.dart';
import '../../../../shared/providers/core_providers.dart';
import '../../data/route_intel_local_prefs_writer.dart';
import '../providers/route_intelligence_thresholds_provider.dart';
import '../utils/route_intel_local_threshold_form_parse.dart';

void _invalidateRouteIntelAfterLocalPrefsMutation(WidgetRef ref) {
  ref.invalidate(sharedPreferencesProvider);
  ref.invalidate(routeIntelligenceGlobalThresholdsProvider);
  ref.invalidate(routeIntelligenceGlobalThresholdsResolutionProvider);
  ref.invalidate(routeIntelligenceThresholdsForVehicleProvider);
  ref.invalidate(routeIntelligenceThresholdsResolutionForVehicleProvider);
}

/// Edits **global local-only** Route Intelligence prefs (SharedPreferences).
///
/// Does not sync to the central ELMOGPS configuration. User / group / device layers still win when set.
class RouteIntelligenceLocalThresholdsEditor extends ConsumerWidget {
  const RouteIntelligenceLocalThresholdsEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefsAsync = ref.watch(sharedPreferencesProvider);

    return prefsAsync.when(
      loading: () => ElmoCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                context.l10n.routeIntelPreviewLoadingLayers,
                style: AppTextStyles.labelSmall.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
      error: (e, _) => ElmoCard(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          e.toString(),
          style: AppTextStyles.bodySmall.copyWith(
            color: Theme.of(context).colorScheme.error,
          ),
        ),
      ),
      data: (prefs) => _RouteIntelLocalEditorLoaded(
        key: ValueKey(routeIntelLocalPrefsFingerprint(prefs)),
        prefs: prefs,
      ),
    );
  }
}

class _RouteIntelLocalEditorLoaded extends ConsumerStatefulWidget {
  const _RouteIntelLocalEditorLoaded({
    super.key,
    required this.prefs,
  });

  final SharedPreferences prefs;

  @override
  ConsumerState<_RouteIntelLocalEditorLoaded> createState() =>
      _RouteIntelLocalEditorLoadedState();
}

class _RouteIntelLocalEditorLoadedState
    extends ConsumerState<_RouteIntelLocalEditorLoaded> {
  late final TextEditingController _enterCtl;
  late final TextEditingController _exitCtl;
  late final TextEditingController _minStopCtl;
  late final TextEditingController _overCtl;
  bool _detectStops = true;
  bool _detectOverspeed = true;
  bool _detectIgnition = true;

  @override
  void initState() {
    super.initState();
    final t = routeIntelThresholdsFromLocalPrefsLayerOnly(widget.prefs);
    _enterCtl = TextEditingController(
      text: _formatNum(t.stopSpeedEnterKmh),
    );
    _exitCtl = TextEditingController(
      text: _formatNum(t.stopSpeedExitKmh),
    );
    _minStopCtl = TextEditingController(
      text: '${t.minStopDuration.inMinutes}',
    );
    _overCtl = TextEditingController(
      text: _formatNum(t.overspeedThresholdKmh),
    );
    _detectStops = t.detectStops;
    _detectOverspeed = t.detectOverspeed;
    _detectIgnition = t.detectIgnition;
  }

  String _formatNum(double v) {
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

  Future<void> _onSave(BuildContext context, AppLocalizations l10n) async {
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
    await writeRouteIntelLocalThresholdsToSharedPreferences(
      widget.prefs,
      parsed.thresholds!,
    );
    if (!context.mounted) return;
    _invalidateRouteIntelAfterLocalPrefsMutation(ref);
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(l10n.routeIntelSavedSnack)),
    );
  }

  Future<void> _onReset(BuildContext context, AppLocalizations l10n) async {
    await clearRouteIntelLocalPreferences(widget.prefs);
    if (!context.mounted) return;
    _invalidateRouteIntelAfterLocalPrefsMutation(ref);
    ScaffoldMessenger.maybeOf(context)?.showSnackBar(
      SnackBar(content: Text(l10n.routeIntelResetSnack)),
    );
  }

  InputDecoration _fieldDeco(String label, {String? helper}) {
    return InputDecoration(
      labelText: label,
      helperText: helper,
      isDense: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final cs = Theme.of(context).colorScheme;

    return ElmoCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.routeIntelLocalEditorTitle,
            style: AppTextStyles.headlineSmall,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.routeIntelLocalOnlyCentralWarning,
            style: AppTextStyles.labelSmall.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.routeIntelLocalParamsHeading,
            style:
                AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _enterCtl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _fieldDeco(l10n.routeIntelStopEnter),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _exitCtl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _fieldDeco(l10n.routeIntelStopExit),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _minStopCtl,
            keyboardType: TextInputType.number,
            decoration: _fieldDeco(l10n.routeIntelMinStopDuration),
          ),
          const SizedBox(height: AppSpacing.sm),
          TextField(
            controller: _overCtl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: _fieldDeco(l10n.routeIntelOverspeedThreshold),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.routeIntelDetectStops, style: AppTextStyles.bodyMedium),
            value: _detectStops,
            onChanged: (v) => setState(() => _detectStops = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.routeIntelDetectOverspeed, style: AppTextStyles.bodyMedium),
            value: _detectOverspeed,
            onChanged: (v) => setState(() => _detectOverspeed = v),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(l10n.routeIntelDetectIgnition, style: AppTextStyles.bodyMedium),
            value: _detectIgnition,
            onChanged: (v) => setState(() => _detectIgnition = v),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () => _onSave(context, l10n),
                  child: Text(l10n.routeIntelSave),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _onReset(context, l10n),
                  child: Text(
                    l10n.routeIntelResetLocalPrefsSettings,
                    textAlign: TextAlign.center,
                    maxLines: 3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
