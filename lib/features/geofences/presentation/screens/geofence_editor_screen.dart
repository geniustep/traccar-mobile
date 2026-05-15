import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/maps/map_config.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/geofence_area_codec.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../vehicles/presentation/providers/vehicles_provider.dart';
import '../../domain/entities/geofence.dart';
import '../providers/geofences_providers.dart';
import '../widgets/geofence_map_picker.dart';
import '../widgets/geofence_type_selector.dart';
import '../widgets/geofence_vehicle_selector.dart';

class GeofenceEditorScreen extends ConsumerStatefulWidget {
  const GeofenceEditorScreen({super.key, required this.geofenceId});

  final String geofenceId;
  bool get isCreate => geofenceId == 'new';

  @override
  ConsumerState<GeofenceEditorScreen> createState() =>
      _GeofenceEditorScreenState();
}

class _GeofenceEditorScreenState extends ConsumerState<GeofenceEditorScreen> {
  final _name = TextEditingController();
  GeofenceDrawKind _kind = GeofenceDrawKind.circle;
  LatLng? _center;
  double _radius = 250;
  final List<LatLng> _poly = [];
  final Set<int> _devices = {};
  Color _color = const Color(0xFF2196F3);
  bool _notifyEnter = false;
  bool _notifyExit = false;
  bool _busy = false;
  GeofenceEntity? _initial;
  int _mapFitSeq = 0;

  static const _presets = <Color>[
    Color(0xFF2196F3),
    Color(0xFF4CAF50),
    Color(0xFFFF9800),
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF00BCD4),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate());
  }

  Future<void> _hydrate() async {
    if (widget.isCreate) {
      _center = MapConfig.defaultCameraPosition.target;
      if (mounted) {
        setState(() {
          _mapFitSeq++;
        });
      }
      return;
    }
    final id = int.tryParse(widget.geofenceId);
    if (id == null) return;
    await ref.read(geofencesListProvider.notifier).refresh();
    final list = ref.read(geofencesListProvider).valueOrNull ?? const [];
    GeofenceEntity? g;
    for (final e in list) {
      if (e.id == id) {
        g = e;
        break;
      }
    }
    if (g == null || !mounted) return;
    _initial = g;
    _name.text = g.name;
    _devices
      ..clear()
      ..addAll(g.linkedDeviceIds);
    if (g.isCircle) {
      _kind = GeofenceDrawKind.circle;
      final c = GeofenceAreaCodec.decodeCircle(g.area);
      if (c != null) {
        _center = LatLng(c.latitude, c.longitude);
        _radius = c.radiusMeters;
      }
    } else if (g.isPolygon) {
      _kind = GeofenceDrawKind.polygon;
      _poly
        ..clear()
        ..addAll(GeofenceAreaCodec.decodePolygon(g.area));
    }
    _color = Color.fromARGB(255, g.fillColor.red, g.fillColor.green, g.fillColor.blue);
    setState(() {
      _mapFitSeq++;
    });
  }

  int _argb(Color c) =>
      0xFF000000 | (c.red << 16) | (c.green << 8) | c.blue;

  Future<void> _submit(AppLocalizations l10n) async {
    final name = _name.text.trim();
    if (name.isEmpty) return;

    late final String area;
    if (_kind == GeofenceDrawKind.circle) {
      if (_center == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.geofenceTapMapCenter)),
        );
        return;
      }
      area = GeofenceAreaCodec.encodeCircle(
        latitude: _center!.latitude,
        longitude: _center!.longitude,
        radiusMeters: _radius,
      );
    } else {
      if (_poly.length < 3) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.geofencePolygonMinPoints)),
        );
        return;
      }
      area = GeofenceAreaCodec.encodePolygon(_poly);
    }

    final user = ref.read(currentUserProvider);
    final uid = int.tryParse(user?.id ?? '') ?? 0;

    setState(() => _busy = true);
    try {
      final repo = ref.read(geofencesRepositoryProvider);
      late final GeofenceEntity saved;
      if (widget.isCreate) {
        saved = await repo.createGeofence(
          name: name,
          areaWkt: area,
          deviceIds: _devices.toList(),
          fillColorArgb: _argb(_color),
        );
        if ((_notifyEnter || _notifyExit) && uid > 0) {
          await repo.ensureSmartNotifications(
            userId: uid,
            geofence: saved,
            deviceIds: _devices.toList(),
            createEnter: _notifyEnter,
            createExit: _notifyExit,
          );
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.geofenceCreated)),
          );
        }
      } else {
        final cur = _initial;
        if (cur == null) return;
        saved = await repo.updateGeofence(
          current: cur,
          name: name,
          areaWkt: area,
          deviceIds: _devices.toList(),
          fillColorArgb: _argb(_color),
        );
        if ((_notifyEnter || _notifyExit) && uid > 0) {
          await repo.ensureSmartNotifications(
            userId: uid,
            geofence: saved,
            deviceIds: _devices.toList(),
            createEnter: _notifyEnter,
            createExit: _notifyExit,
          );
        }
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(l10n.geofenceUpdated)),
          );
        }
      }
      await ref.read(geofencesListProvider.notifier).refresh();
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${l10n.geofenceLoadError}: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final vehiclesAsync = ref.watch(vehiclesListProvider);
    final fill = _color.withValues(alpha: 0.35);
    final stroke = _color.withValues(alpha: 0.95);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: _busy ? null : () => context.pop(),
        ),
        title: Text(widget.isCreate ? l10n.geofencesAdd : l10n.geofenceEdit),
        actions: [
          if (_busy)
            const Padding(
              padding: EdgeInsets.all(12),
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            TextButton(
              onPressed: () => _submit(l10n),
              child: Text(l10n.confirm),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        children: [
          TextField(
            controller: _name,
            decoration: InputDecoration(
              labelText: l10n.geofenceNameLabel,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.geofenceTypeLabel,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          GeofenceTypeSelector(
            value: _kind,
            l10n: l10n,
            onChanged: (k) => setState(() {
              _kind = k;
              if (k == GeofenceDrawKind.circle && _center == null) {
                _center = MapConfig.defaultCameraPosition.target;
              }
              _mapFitSeq++;
            }),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.geofenceColorLabel,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            children: _presets
                .map(
                  (c) => GestureDetector(
                    onTap: () => setState(() => _color = c),
                    child: CircleAvatar(
                      backgroundColor: c,
                      radius: 16,
                      child: _color == c
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: AppSpacing.md),
          GeofenceMapPicker(
            kind: _kind,
            center: _center,
            radiusMeters: _radius,
            polygonPoints: _poly,
            strokeColor: stroke,
            fillColor: fill,
            fitNonce: _mapFitSeq,
            emptyHint: _kind == GeofenceDrawKind.polygon && _poly.isEmpty
                ? l10n.geofencePolygonTapHint
                : _kind == GeofenceDrawKind.circle && _center == null
                    ? l10n.geofenceTapMapCenterHint
                    : null,
            onMapTap: (pos) => setState(() {
              if (_kind == GeofenceDrawKind.circle) {
                _center = pos;
              } else {
                _poly.add(pos);
              }
            }),
          ),
          if (_kind == GeofenceDrawKind.circle) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.geofenceTapMapCenterHint,
              style: TextStyle(fontSize: 12, color: AppColors.textMutedOf(context)),
            ),
            Row(
              children: [
                Expanded(child: Text('${l10n.geofenceRadius} (${_radius.round()} m)')),
                Expanded(
                  child: Slider(
                    value: _radius.clamp(30, 5000),
                    min: 30,
                    max: 5000,
                    divisions: 40,
                    onChanged: (v) => setState(() => _radius = v),
                  ),
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.geofencePolygonTapHint,
              style: TextStyle(fontSize: 12, color: AppColors.textMutedOf(context)),
            ),
            Align(
              alignment: AlignmentDirectional.centerStart,
              child: TextButton.icon(
                onPressed:
                    _poly.isEmpty ? null : () => setState(() => _poly.removeLast()),
                icon: const Icon(Icons.undo_rounded, size: 18),
                label: Text(l10n.geofencePolygonUndoLast),
              ),
            ),
          ],
          const Divider(height: 32),
          vehiclesAsync.when(
            data: (vehicles) => GeofenceVehicleSelector(
              vehicles: vehicles,
              selectedIds: Set<int>.from(_devices),
              l10n: l10n,
              onChanged: (s) => setState(() {
                _devices
                  ..clear()
                  ..addAll(s);
              }),
            ),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => Text(l10n.errorLoadingData('vehicles')),
          ),
          const Divider(height: 32),
          Text(l10n.geofenceAlertSectionTitle,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          CheckboxListTile(
            value: _notifyEnter,
            onChanged: (v) => setState(() => _notifyEnter = v ?? false),
            title: Text(l10n.geofenceNotifyEnter),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            value: _notifyExit,
            onChanged: (v) => setState(() => _notifyExit = v ?? false),
            title: Text(l10n.geofenceNotifyExit),
            controlAffinity: ListTileControlAffinity.leading,
          ),
          CheckboxListTile(
            value: _notifyEnter && _notifyExit,
            onChanged: (v) {
              final on = v ?? false;
              setState(() {
                _notifyEnter = on;
                _notifyExit = on;
              });
            },
            title: Text(l10n.geofenceNotifyBoth),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }
}
