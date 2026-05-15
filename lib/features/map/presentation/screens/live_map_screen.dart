import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/maps/map_config.dart';
import '../../../../core/maps/map_helper.dart';
import '../../../../core/socket/socket_provider.dart';
import '../../../../core/socket/socket_state.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/geofence_area_codec.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/vehicle_category_utils.dart';
import '../../core/map_camera_follow_controller.dart';
import '../../core/map_zoom_policy.dart';
import '../../core/route_polyline_builder.dart';
import '../../core/vehicle_marker_factory.dart';
import '../../core/vehicle_marker_style.dart';
import '../../../alerts/domain/entities/alert.dart';
import '../../../alerts/presentation/providers/alerts_provider.dart';
import '../../../dashboard/data/services/dashboard_alert_filter.dart';
import '../../../geofences/domain/entities/geofence.dart';
import '../../../geofences/presentation/providers/geofences_providers.dart';
import '../../../reports/presentation/providers/reports_providers.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/presentation/widgets/replay_entry_sheet.dart';
import '../../../vehicles/presentation/widgets/report_entry_sheet.dart';
import '../../core/map_camera_focus.dart';
import '../../core/vehicle_status_colors.dart';
import '../providers/map_live_overlay_providers.dart';
import '../providers/map_provider.dart';
import '../providers/map_vehicle_filter.dart';
import '../widgets/vehicle_map_filter_sheet.dart';
import '../providers/tracking_provider.dart';
import '../utils/live_map_clustering.dart';
import '../utils/live_map_marker_bitmaps.dart';

/// Fleet tracking screen — clustered markers, live follow, compact chrome.
class LiveMapScreen extends ConsumerStatefulWidget {
  const LiveMapScreen({super.key});

  @override
  ConsumerState<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends ConsumerState<LiveMapScreen>
    with TickerProviderStateMixin {
  GoogleMapController? _mapController;
  Timer? _refreshTimer;

  /// Zoom tracked between camera-idle updates — clustering recomputes on idle only.
  double _cameraZoom = MapConfig.defaultZoom;

  String _selectedFilter = 'all';

  bool _didFitBounds = false;

  int? _lastLoggedMarkerCount;
  String? _lastRoutePointsLogKey;

  final _followCamera = MapCameraFollowController(
    MapCameraFollowMode.fleetSelectedVehicle,
    followThrottle: const Duration(milliseconds: 420),
  );

  final Map<String, BitmapDescriptor> _pinCache = {};
  final Set<String> _pinInflight = {};
  final Map<String, BitmapDescriptor> _clusterDiscCache = {};
  final Map<String, BitmapDescriptor> _carTopCache = {};

  AnimationController? _selMotionController;

  LatLng _smoothSel = const LatLng(0, 0);
  double _smoothCourse = 0;
  LatLng? _selAnimStart;
  LatLng? _selAnimEnd;
  double _courseAnimStart = 0;
  double _courseAnimEnd = 0;

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => ref.invalidate(mapVehiclesProvider),
    );
    _selMotionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    )..addListener(_onSelMotionTick);

    ref.listenManual(pendingMapCameraFocusProvider, (prev, next) {
      if (next == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tryConsumePendingMapFocus();
      });
    });

    ref.listenManual(mapVehiclesProvider, (prev, next) {
      if (!next.hasValue) return;
      if (ref.read(pendingMapCameraFocusProvider) == null) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _tryConsumePendingMapFocus();
      });
    });
  }

  void _onSelMotionTick() {
    final t = Curves.easeOut.transform(_selMotionController!.value);
    final a = _selAnimStart;
    final b = _selAnimEnd;
    if (a != null && b != null && mounted) {
      setState(() {
        _smoothSel = LatLng(
          a.latitude + (b.latitude - a.latitude) * t,
          a.longitude + (b.longitude - a.longitude) * t,
        );
        final dc = _courseAnimEnd - _courseAnimStart;
        var step = dc;
        if (step.abs() > 180) step -= 360 * step.sign;
        _smoothCourse = _courseAnimStart + step * t;
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _selMotionController?.dispose();
    _mapController?.dispose();
    super.dispose();
  }

  BitmapDescriptor _descriptorForPin(VehicleEntity v, Set<String> alerts) {
    final color = VehicleMarkerFactory.pinBodyColor(
      v: v,
      alertVehicleIds: alerts,
      style: VehicleMarkerStyle.fleet,
    );
    final key = VehicleMarkerFactory.pinDescriptorCacheKey(
      v,
      color,
      VehicleMarkerStyle.fleet,
    );
    if (_pinCache.containsKey(key)) return _pinCache[key]!;
    if (!_pinInflight.contains(key)) {
      _pinInflight.add(key);
      VehicleMarkerFactory.buildTeardropPin(v, color).then((bmp) {
        _pinInflight.remove(key);
        if (mounted) {
          setState(() => _pinCache[key] = bmp);
        }
      });
    }
    return VehicleMarkerFactory.fallbackPinHue(v.status);
  }

  void _syncSmoothSelection(VehicleEntity v) {
    final rawCourse = v.course ?? 0;
    final target = LatLng(v.latitude, v.longitude);
    if (ref.read(selectedMapVehicleProvider) != v.id) return;
    if (_selAnimEnd == null) {
      _smoothSel = target;
      _smoothCourse = rawCourse;
      _selAnimStart = target;
      _selAnimEnd = target;
      return;
    }

    _selAnimStart = _smoothSel;
    _selAnimEnd = target;
    _courseAnimStart = _smoothCourse;
    _courseAnimEnd = rawCourse;
    _selMotionController?.forward(from: 0);
  }

  void _maybeCameraFollow(VehicleEntity v) {
    if (!_followCamera.canApplyLiveCamera || _mapController == null) return;
    if (_followCamera.consumeFollowThrottle()) return;
    _followCamera.beginProgrammaticMove();
    _mapController!.animateCamera(CameraUpdate.newLatLng(_smoothSel)).then((_) {
      _followCamera.endProgrammaticMoveSoon();
    });
  }

  List<VehicleEntity> _applyStatusFilter(
    List<VehicleEntity> list,
    Set<String> alertIds,
  ) {
    switch (_selectedFilter) {
      case 'moving':
        return list.where((v) => v.isMoving).toList();
      case 'stopped':
        return list.where((v) => v.isStopped).toList();
      case 'idle':
        return list.where((v) => v.isIdle).toList();
      case 'offline':
        return list.where((v) => v.isOffline).toList();
      case 'alert':
        return list.where((v) => alertIds.contains(v.id)).toList();
      default:
        return list;
    }
  }

  Map<String, int> _aggregateCounts(
    List<VehicleEntity> all,
    Set<String> alertIds,
  ) {
    return {
      'all': all.length,
      'moving': all.where((v) => v.isMoving).length,
      'stopped': all.where((v) => v.isStopped).length,
      'idle': all.where((v) => v.isIdle).length,
      'offline': all.where((v) => v.isOffline).length,
      'alert': all.where((v) => alertIds.contains(v.id)).length,
    };
  }

  Set<Marker> _composeMarkers({
    required List<VehicleEntity> filtered,
    required Set<String> alertVehicleIds,
    required String? selectedId,
    required BitmapDescriptor Function(VehicleEntity) pinDescriptor,
  }) {
    final zoomPolicy = MapZoomPolicy.at(
      _cameraZoom,
      visibleVehicleCount: filtered.length,
    );
    final buckets = buildLiveMapClusterBuckets(
      vehicles: filtered,
      zoomLevel: _cameraZoom,
      selectedVehicleId: selectedId,
    );

    final markers = <Marker>{};
    for (var i = 0; i < buckets.length; i++) {
      final bucket = buckets[i];
      if (bucket.isCluster) {
        // Cluster tap zooms in — avoids spawning hundreds of markers until zoom is sufficient.
        final cid =
            'cl_${Object.hash(bucket.center.latitude, bucket.center.longitude, bucket.members.length, bucket.members.map((m) => m.id).join(','))}';
        final fill = LiveMapMarkerBitmaps.clusterColorForMembers(
          bucket.members,
          alertVehicleIds,
        );
        final border = VehicleMarkerFactory.clusterBorderColor(
          bucket.members,
          alertVehicleIds,
        );
        final n = bucket.members.length;
        if (!_clusterDiscCache.containsKey(cid)) {
          LiveMapMarkerBitmaps.clusterDisc(
            count: n,
            fill: fill,
            border: border,
          ).then((d) {
            if (!mounted) return;
            setState(() => _clusterDiscCache[cid] = d);
          });
        }
        markers.add(
          Marker(
            markerId: MarkerId(cid),
            position: bucket.center,
            icon: _clusterDiscCache[cid] ??
                BitmapDescriptor.defaultMarkerWithHue(
                  fill == AppColors.error
                      ? BitmapDescriptor.hueRed
                      : BitmapDescriptor.hueAzure,
                ),
            anchor: const Offset(0.5, 0.5),
            zIndexInt: 1,
            infoWindow: const InfoWindow(),
            onTap: () {
              final pts = bucket.members
                  .where((m) => m.latitude != 0 || m.longitude != 0)
                  .map((m) => LatLng(m.latitude, m.longitude))
                  .toList();
              final fit = MapHelper.fitPoints(pts, padding: 88);
              _followCamera.beginProgrammaticMove();
              if (fit != null) {
                _mapController?.animateCamera(fit).then((_) {
                  _followCamera.endProgrammaticMoveSoon(
                    const Duration(milliseconds: 120),
                  );
                });
              } else {
                final double targetZoom = math.min(
                  22.0,
                  math.max(_cameraZoom + 2.2, MapConfig.clusterZoomThreshold),
                );
                _mapController
                    ?.animateCamera(
                  CameraUpdate.newLatLngZoom(bucket.center, targetZoom),
                )
                    .then((_) {
                  _followCamera.endProgrammaticMoveSoon(
                    const Duration(milliseconds: 120),
                  );
                });
              }
            },
          ),
        );
      } else {
        final v = bucket.members.single;
        final isSel = v.id == selectedId;
        final pos = isSel ? _smoothSel : LatLng(v.latitude, v.longitude);
        final courseForCar =
            isSel ? _smoothCourse : (v.course ?? 0);

        if (isSel) {
          final body = VehicleMarkerFactory.pinBodyColor(
            v: v,
            alertVehicleIds: alertVehicleIds,
            style: VehicleMarkerStyle.selected,
          );
          final selScale =
              zoomPolicy.markerScale(style: VehicleMarkerStyle.selected);
          final selSize = (80 * selScale).round();
          final carKey = VehicleMarkerFactory.selectedCarCacheKey(
            v,
            body,
            selSize,
          );
          if (!_carTopCache.containsKey(carKey)) {
            VehicleMarkerFactory.topDownCarNorthUp(
              bodyColor: body,
              size: selSize.toDouble(),
            ).then((d) {
              if (!mounted) return;
              setState(() => _carTopCache[carKey] = d);
            });
          }
          markers.add(
            Marker(
              markerId: MarkerId('sel_${v.id}'),
              position: pos,
              rotation: courseForCar,
              flat: true,
              anchor: const Offset(0.5, 0.5),
              zIndexInt: 4,
              icon: _carTopCache[carKey] ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueYellow,
                  ),
              consumeTapEvents: true,
              infoWindow: const InfoWindow(),
              onTap: () =>
                  ref.read(selectedMapVehicleProvider.notifier).state = v.id,
            ),
          );
        } else if (zoomPolicy.useTopDownVehicleIcon(selected: false)) {
          final body = VehicleMarkerFactory.pinBodyColor(
            v: v,
            alertVehicleIds: alertVehicleIds,
            style: VehicleMarkerStyle.fleet,
          );
          final flScale = zoomPolicy.markerScale(style: VehicleMarkerStyle.fleet);
          final sizePx = (72 * flScale).round();
          final carKey =
              'flt_${v.id}_${VehicleMarkerFactory.northUpCarCacheKey(body, sizePx)}';
          if (!_carTopCache.containsKey(carKey)) {
            VehicleMarkerFactory.topDownCarNorthUp(
              bodyColor: body,
              size: sizePx.toDouble(),
            ).then((d) {
              if (!mounted) return;
              setState(() => _carTopCache[carKey] = d);
            });
          }
          markers.add(
            Marker(
              markerId: MarkerId(v.id),
              position: pos,
              icon: _carTopCache[carKey] ?? pinDescriptor(v),
              rotation: v.course ?? 0,
              flat: true,
              anchor: const Offset(0.5, 0.5),
              zIndexInt: v.isOffline ? 1 : 2,
              consumeTapEvents: true,
              infoWindow: const InfoWindow(),
              onTap: () => _onVehicleMarkerTap(v),
            ),
          );
        } else {
          markers.add(
            Marker(
              markerId: MarkerId(v.id),
              position: pos,
              icon: pinDescriptor(v),
              anchor: const Offset(0.5, 1.0),
              zIndexInt: v.isOffline ? 1 : 2,
              consumeTapEvents: true,
              infoWindow: const InfoWindow(),
              onTap: () => _onVehicleMarkerTap(v),
            ),
          );
        }
      }
    }
    return markers;
  }

  void _onVehicleMarkerTap(VehicleEntity v) {
    AppLogger.map(
      'Vehicle selected on map: vehicleId=${v.id} source=map_marker',
    );
    ref.read(selectedMapVehicleProvider.notifier).state = v.id;
    _smoothSel = LatLng(v.latitude, v.longitude);
    _smoothCourse = v.course ?? 0;
    _followCamera.clearFollow();

    _followCamera.beginProgrammaticMove();
    _mapController?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(
          target: LatLng(v.latitude, v.longitude),
          zoom: math.max(_cameraZoom, 16.4).toDouble(),
        ),
      ),
    ).then((_) {
      _followCamera.endProgrammaticMoveSoon(const Duration(milliseconds: 200));
    });
    setState(() {});
  }

  void _clearSelectionIfHidden(
    List<VehicleEntity> visible,
    String? selectedId,
  ) {
    if (selectedId == null) return;
    if (visible.any((v) => v.id == selectedId)) return;
    AppLogger.map(
      'Hidden selected vehicle cleared: vehicleId=$selectedId source=map_filter',
    );
    ref.read(selectedMapVehicleProvider.notifier).state = null;
    if (mounted) {
      setState(() => _followCamera.clearFollow());
    }
  }

  void _clearPendingCameraFocus() {
    ref.read(pendingMapCameraFocusProvider.notifier).state = null;
  }

  void _focusSingleVehicle(VehicleEntity v, {double zoom = 16.2}) {
    if (v.latitude == 0 && v.longitude == 0) return;
    AppLogger.map('Camera focused on vehicle: id=${v.id}');
    ref.read(selectedMapVehicleProvider.notifier).state = v.id;
    _smoothSel = LatLng(v.latitude, v.longitude);
    _smoothCourse = v.course ?? 0;
    _followCamera.beginProgrammaticMove();
    final upd = cameraUpdateForVehicle(v, zoom: zoom);
    if (upd != null) {
      _mapController?.animateCamera(upd).then((_) {
        _followCamera.endProgrammaticMoveSoon(
          const Duration(milliseconds: 200),
        );
      });
    }
  }

  void _fitVehiclesOnMap(
    List<VehicleEntity> vehicles, {
    double padding = 120,
    VoidCallback? onComplete,
  }) {
    if (vehicles.isEmpty || _mapController == null) return;
    if (vehicles.length == 1) {
      _focusSingleVehicle(vehicles.first);
      onComplete?.call();
      return;
    }
    AppLogger.map('Camera fitted to vehicles: count=${vehicles.length}');
    final upd = cameraUpdateFitVehicles(vehicles, padding: padding);
    if (upd == null) {
      AppLogger.map('Camera focus skipped: no valid coordinates');
      onComplete?.call();
      return;
    }
    _followCamera.beginProgrammaticMove();
    _mapController!.animateCamera(upd).then((_) {
      _followCamera.endProgrammaticMoveSoon(const Duration(milliseconds: 280));
      onComplete?.call();
    });
  }

  /// Returns true when focus was applied or the pending request was dropped.
  bool _tryConsumePendingMapFocus() {
    final legacyId = ref.read(pendingMapVehicleFocusProvider);
    if (legacyId != null) {
      ref.read(pendingMapVehicleFocusProvider.notifier).state = null;
      if (ref.read(pendingMapCameraFocusProvider) == null) {
        ref.read(pendingMapCameraFocusProvider.notifier).state =
            MapCameraFocusRequest.single(legacyId);
      }
    }

    final req = ref.read(pendingMapCameraFocusProvider);
    if (req == null) return false;

    if (_mapController == null) {
      AppLogger.map('Camera focus pending: controller not ready');
      return false;
    }

    final all = ref.read(mapVehiclesProvider).valueOrNull ?? const [];

    switch (req.mode) {
      case MapCameraFocusMode.singleVehicle:
        final id = req.vehicleId;
        if (id == null) {
          _clearPendingCameraFocus();
          return true;
        }
        final vehicle = all.where((v) => v.id == id).firstOrNull;
        if (vehicle == null) {
          _clearPendingCameraFocus();
          return true;
        }
        if (vehicle.latitude == 0 && vehicle.longitude == 0) {
          AppLogger.map('Camera focus skipped: no valid coordinates');
          _clearPendingCameraFocus();
          return true;
        }
        ref.read(selectedMapVehicleProvider.notifier).state = id;
        _smoothSel = LatLng(vehicle.latitude, vehicle.longitude);
        _smoothCourse = vehicle.course ?? 0;
        _followCamera.beginProgrammaticMove();
        final upd = cameraUpdateForVehicle(vehicle, zoom: 16.2);
        if (upd == null) {
          AppLogger.map('Camera focus skipped: no valid coordinates');
          _clearPendingCameraFocus();
          return true;
        }
        _mapController!.animateCamera(upd).then((_) {
          _followCamera.endProgrammaticMoveSoon(
            const Duration(milliseconds: 200),
          );
          if (mounted) {
            AppLogger.map('Camera focused on vehicle: id=$id');
            _clearPendingCameraFocus();
          }
        });
        return true;

      case MapCameraFocusMode.fitVehicles:
        final ids = req.vehicleIds;
        if (ids.isEmpty) {
          _clearPendingCameraFocus();
          return true;
        }
        ref.read(selectedMapVehicleProvider.notifier).state = null;
        _followCamera.clearFollow();
        final withPos = all
            .where(
              (v) =>
                  ids.contains(v.id) &&
                  (v.latitude != 0 || v.longitude != 0),
            )
            .toList();
        if (withPos.isEmpty) {
          AppLogger.map('Camera focus skipped: no valid coordinates');
          _clearPendingCameraFocus();
          return true;
        }
        if (withPos.length == 1) {
          ref.read(pendingMapCameraFocusProvider.notifier).state =
              MapCameraFocusRequest.single(withPos.first.id);
          return _tryConsumePendingMapFocus();
        }
        _fitVehiclesOnMap(
          withPos,
          onComplete: () {
            if (mounted) _clearPendingCameraFocus();
          },
        );
        return true;
    }
  }

  void _runInitialFitAllIfNeeded(List<VehicleEntity> allRaw) {
    if (allRaw.isEmpty) return;
    if (ref.read(pendingMapCameraFocusProvider) != null) {
      AppLogger.map('Initial fitAll skipped: pending focus exists');
      _tryConsumePendingMapFocus();
      return;
    }
    _fitAll(allRaw);
  }

  Future<void> _openReportFromMapCard(VehicleEntity v) async {
    AppLogger.map(
      'Report action from map card: vehicleId=${v.id} source=map_bottom_card',
    );
    final params = await showReportEntrySheet(
      context,
      vehicleId: v.id,
      vehicleName: v.name,
    );
    if (params != null && mounted) {
      context.push('/reports', extra: params);
    }
  }

  Future<void> _openReplayFromMapCard(VehicleEntity v) async {
    AppLogger.map(
      'Replay action from map card: vehicleId=${v.id} source=map_bottom_card',
    );
    final result = await showReplayEntrySheet(
      context,
      vehicleId: v.id,
      vehicleName: v.name,
    );
    if (result != null && mounted) {
      context.push(
        '/reports/replay',
        extra: {
          'params': ReportFilterParams(
            vehicleId: result.vehicleId,
            from: result.from.toUtc(),
            to: result.to.toUtc(),
          ),
          'vehicleName': result.vehicleName,
        },
      );
    }
  }

  void _fitAll(List<VehicleEntity> vehicles) {
    if (_mapController == null) return;
    final pts = vehicles
        .where((v) => v.latitude != 0 || v.longitude != 0)
        .map((v) => LatLng(v.latitude, v.longitude))
        .toList();
    final upd = MapHelper.fitPoints(pts, padding: 88);
    if (upd != null) {
      _followCamera.beginProgrammaticMove();
      _mapController!.animateCamera(upd).then((_) {
        _followCamera.endProgrammaticMoveSoon(const Duration(milliseconds: 200));
      });
    }
  }

  void _maybeShowGeofenceDialog(
    BuildContext context,
    WidgetRef ref,
    LatLng tap,
    List<GeofenceEntity> geos,
    AppLocalizations l10n,
  ) {
    final entries = geos.take(80).map((g) => MapEntry('${g.id}', g.area));
    final idStr = GeofenceAreaCodec.hitTestGeofence(tap, entries);
    if (idStr == null) return;
    final id = int.tryParse(idStr);
    if (id == null) return;
    final name = ref.read(geofenceNameMapProvider)[id] ?? l10n.geofencesTitle;
    GeofenceEntity? g;
    for (final e in geos) {
      if (e.id == id) {
        g = e;
        break;
      }
    }
    if (g == null) return;
    final typeLabel =
        g.isCircle ? l10n.geofenceTypeCircle : l10n.geofenceTypePolygon;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(name),
        content: Text(typeLabel),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.confirm),
          ),
        ],
      ),
    );
  }

  (Set<Circle>, Set<Polygon>) _geofenceShapes(List<GeofenceEntity> geos) {
    final circles = <Circle>{};
    final polygons = <Polygon>{};
    final cap = geos.length > 80 ? geos.sublist(0, 80) : geos;
    for (final g in cap) {
      final sid = 'gf_${g.id}';
      final stroke = Color.fromARGB(
        255,
        g.fillColor.red,
        g.fillColor.green,
        g.fillColor.blue,
      );
      if (g.isCircle) {
        final c = GeofenceAreaCodec.decodeCircle(g.area);
        if (c != null) {
          circles.add(
            MapHelper.buildGeofenceCircle(
              id: sid,
              center: LatLng(c.latitude, c.longitude),
              radiusMeters: c.radiusMeters,
              strokeColor: stroke,
              fillColor: g.fillColor,
            ),
          );
        }
      } else if (g.isPolygon) {
        final pts = GeofenceAreaCodec.decodePolygon(g.area);
        if (pts.length >= 3) {
          polygons.add(
            MapHelper.buildGeofencePolygon(
              id: sid,
              points: pts,
              strokeColor: stroke,
              fillColor: g.fillColor,
            ),
          );
        }
      }
    }
    return (circles, polygons);
  }

  Set<Marker> _alertMarkers(
    List<AlertEntity> alerts,
    Set<String> alertVehicleIds,
  ) {
    final markers = <Marker>{};
    var i = 0;
    for (final a in alerts) {
      if (a.isRead || !DashboardAlertFilter.isImportantAlert(a)) continue;
      if (!a.hasLocation) continue;
      final lat = a.latitude!;
      final lng = a.longitude!;
      markers.add(
        Marker(
          markerId: MarkerId('al_${a.id}_$i'),
          position: LatLng(lat, lng),
          anchor: const Offset(0.5, 0.9),
          zIndexInt: 0,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: a.title),
        ),
      );
      i++;
    }
    return markers;
  }

  Future<void> _openLayersSheet(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) {
        final pad = MediaQuery.paddingOf(ctx).bottom;
        return Padding(
          padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + pad),
          child: Consumer(
            builder: (context, ref, _) {
              final showGf = ref.watch(showGeofencesOnMapProvider);
              final showAl = ref.watch(liveMapShowAlertPinsProvider);
              final showRt = ref.watch(liveMapShowTodayRouteOverlayProvider);
              final mapType = ref.watch(liveMapMapTypeProvider);
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    l10n.mapLayersTitle,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.textPrimaryOf(context),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile.adaptive(
                    title: Text(l10n.geofenceShowOnMap),
                    value: showGf,
                    onChanged: (v) =>
                        ref.read(showGeofencesOnMapProvider.notifier).state = v,
                  ),
                  SwitchListTile.adaptive(
                    title: Text(l10n.mapLayerAlerts),
                    value: showAl,
                    onChanged: (v) => ref
                        .read(liveMapShowAlertPinsProvider.notifier)
                        .state = v,
                  ),
                  SwitchListTile.adaptive(
                    title: Text(l10n.mapLayerRoutesToday),
                    value: showRt,
                    onChanged: (v) => ref
                        .read(liveMapShowTodayRouteOverlayProvider.notifier)
                        .state = v,
                  ),
                  const Divider(),
                  RadioListTile<MapType>(
                    title: Text(l10n.mapTypeNormal),
                    value: MapType.normal,
                    groupValue: mapType,
                    onChanged: (v) {
                      if (v == null) return;
                      ref.read(liveMapMapTypeProvider.notifier).state = v;
                      Navigator.pop(ctx);
                    },
                  ),
                  RadioListTile<MapType>(
                    title: Text(l10n.mapTypeSatellite),
                    value: MapType.satellite,
                    groupValue: mapType,
                    onChanged: (v) {
                      if (v == null) return;
                      ref.read(liveMapMapTypeProvider.notifier).state = v;
                      Navigator.pop(ctx);
                    },
                  ),
                  RadioListTile<MapType>(
                    title: Text(l10n.mapTypeTerrain),
                    value: MapType.terrain,
                    groupValue: mapType,
                    onChanged: (v) {
                      if (v == null) return;
                      ref.read(liveMapMapTypeProvider.notifier).state = v;
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  void _openVehiclePickerFromBottomSummary() {
    AppLogger.map('Vehicle picker opened source=bottom_summary');
    showVehicleMapFilterSheet(context, ref);
  }

  void _openVehiclePickerFromVehicleCard() {
    AppLogger.map('Vehicle picker opened source=vehicle_card');
    showVehicleMapFilterSheet(context, ref);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final vehiclesAsync = ref.watch(mapVehiclesProvider);
    final mapFilter = ref.watch(vehicleMapFilterProvider);
    final selectedId = ref.watch(selectedMapVehicleProvider);
    final showGf = ref.watch(showGeofencesOnMapProvider);
    final geofencesAsync = ref.watch(geofencesListProvider);
    final alertVehicleIds = ref.watch(mapUnreadImportantAlertVehicleIdsProvider);
    final mapType = ref.watch(liveMapMapTypeProvider);
    final showAlertPins = ref.watch(liveMapShowAlertPinsProvider);
    final showRouteOverlay = ref.watch(liveMapShowTodayRouteOverlayProvider);

    final alertsAsync = ref.watch(alertsProvider).alertsAsync;

    final socketAsync = ref.watch(socketStateProvider);

    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final mapStyle = isDark ? MapConfig.darkStyle : MapConfig.lightStyle;

    final navBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: Stack(
        children: [
          vehiclesAsync.when(
            data: (allRaw) {
              final visibilityFiltered =
                  applyVehicleMapFilter(allRaw, mapFilter);
              final filtered =
                  _applyStatusFilter(visibilityFiltered, alertVehicleIds);

              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _clearSelectionIfHidden(visibilityFiltered, selectedId);
                if (ref.read(pendingMapCameraFocusProvider) != null) {
                  _tryConsumePendingMapFocus();
                }
              });

              VehicleEntity? selectedVehicle;
              if (selectedId != null) {
                for (final v in visibilityFiltered) {
                  if (v.id == selectedId) {
                    selectedVehicle = v;
                    break;
                  }
                }
              }

              if (selectedVehicle != null) {
                final sv = selectedVehicle;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _syncSmoothSelection(sv);
                  _maybeCameraFollow(sv);
                });
              }

              if (!_didFitBounds && allRaw.isNotEmpty) {
                _didFitBounds = true;
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!mounted) return;
                  _runInitialFitAllIfNeeded(allRaw);
                });
              }

              final markers = _composeMarkers(
                filtered: filtered,
                alertVehicleIds: alertVehicleIds,
                selectedId: selectedId,
                pinDescriptor: (v) => _descriptorForPin(v, alertVehicleIds),
              );

              if (showAlertPins) {
                alertsAsync.whenOrNull(
                  data: (list) => markers.addAll(_alertMarkers(list, alertVehicleIds)),
                );
              }

              if (kDebugMode) {
                if (_lastLoggedMarkerCount != markers.length) {
                  _lastLoggedMarkerCount = markers.length;
                  AppLogger.map('Markers updated: count=${markers.length}');
                }
              }

              final geos = geofencesAsync.valueOrNull ?? const <GeofenceEntity>[];
              final gfShapes = _geofenceShapes(geos);

              final bottomInset =
                  selectedId != null ? 210.0 + navBottom * 0.25 : 120.0;

              String? emptyMsg;
              if (allRaw.isEmpty) {
                emptyMsg = l10n.mapNoVehiclesEmpty;
              } else if (visibilityFiltered.isEmpty && mapFilter.isActive) {
                emptyMsg = l10n.mapFilterZeroVisible;
              } else if (filtered.isEmpty) {
                emptyMsg = l10n.mapEmptyFilteredState;
              }

              return Stack(
                children: [
                  Consumer(
                    builder: (context, ref, _) {
                      final polylines = <Polyline>{};
                      final routeSid = selectedId;
                      if (showRouteOverlay &&
                          routeSid != null &&
                          selectedVehicle != null) {
                        ref
                            .watch(
                              routeDetailProvider(
                                RouteQuery.today(routeSid),
                              ),
                            )
                            .whenOrNull(
                              data: (pts) {
                                if (kDebugMode) {
                                  final key = '${routeSid}_${pts.length}';
                                  if (_lastRoutePointsLogKey != key) {
                                    _lastRoutePointsLogKey = key;
                                    AppLogger.map(
                                      'Route points loaded: count=${pts.length}',
                                    );
                                  }
                                }
                                polylines.addAll(
                                  RoutePolylineBuilder.buildTodayPreview(
                                    vehicleId: routeSid,
                                    pts: pts,
                                    color: AppColors.accent
                                        .withValues(alpha: 0.85),
                                  ),
                                );
                              },
                            );
                      }
                      return GoogleMap(
                        initialCameraPosition:
                            MapConfig.defaultCameraPosition,
                        mapType: mapType,
                        markers: markers,
                        polylines: polylines,
                        circles: showGf ? gfShapes.$1 : const {},
                        polygons: showGf ? gfShapes.$2 : const {},
                        padding:
                            EdgeInsets.fromLTRB(12, 52, 52, bottomInset),
                        onMapCreated: (c) {
                          _mapController = c;
                          if (allRaw.isNotEmpty) {
                            _runInitialFitAllIfNeeded(allRaw);
                          } else {
                            _tryConsumePendingMapFocus();
                          }
                        },
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: false,
                        mapToolbarEnabled: false,
                        compassEnabled: false,
                        buildingsEnabled: false,
                        style: mapStyle,
                        onCameraMove: (pos) => _cameraZoom = pos.zoom,
                        onCameraIdle: () => setState(() {}),
                        onCameraMoveStarted: () {
                          if (_followCamera.handleUserCameraMoveStarted()) {
                            setState(() {});
                          }
                        },
                        onTap: (pos) {
                          if (showGf && geos.isNotEmpty) {
                            _maybeShowGeofenceDialog(
                              context,
                              ref,
                              pos,
                              geos,
                              l10n,
                            );
                          }
                          ref.read(selectedMapVehicleProvider.notifier).state =
                              null;
                          setState(() {
                            _followCamera.clearFollow();
                          });
                        },
                      );
                    },
                  ),
                  if (emptyMsg != null)
                    Positioned(
                      top: 165,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 300),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 14),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceOf(context)
                                .withValues(alpha: 0.96),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.borderOf(context)
                                  .withValues(alpha: 0.4),
                              width: 0.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.14),
                                blurRadius: 14,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color:
                                      AppColors.accent.withValues(alpha: 0.08),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.directions_car_outlined,
                                  size: 16,
                                  color:
                                      AppColors.accent.withValues(alpha: 0.7),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Flexible(
                                child: Text(
                                  emptyMsg,
                                  textAlign: TextAlign.start,
                                  style: TextStyle(
                                    color:
                                        AppColors.textSecondaryOf(context),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
            loading: () => _MapLoadingState(),
            error: (_, __) => _MapErrorState(
              onRetry: () => ref.invalidate(mapVehiclesProvider),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenPadding,
                AppSpacing.sm,
                AppSpacing.screenPadding,
                0,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _FilterStrip(
                    selected: _selectedFilter,
                    counts: vehiclesAsync.whenOrNull(data: (all) {
                          return _aggregateCounts(
                            all,
                            alertVehicleIds,
                          );
                        }) ??
                        {},
                    alertVehicleIds: alertVehicleIds,
                    l10n: l10n,
                    onSelect: (k) => setState(() => _selectedFilter = k),
                  ),
                  if (mapFilter.isActive) ...[
                    const SizedBox(height: 6),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: AppColors.accent.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          vehiclesAsync.when(
                            data: (all) => l10n.vehiclesShownCount(
                              applyVehicleMapFilter(all, mapFilter).length,
                            ),
                            loading: () => l10n.mapFilterActiveLabel,
                            error: (_, __) => l10n.mapFilterActiveLabel,
                          ),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.accent,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          PositionedDirectional(
            end: AppSpacing.screenPadding,
            bottom: 220 + navBottom,
            child: Column(
              children: [
                _CtrlBtn(
                  icon: Icons.layers_rounded,
                  onTap: () => _openLayersSheet(context, ref, l10n),
                  tooltip: l10n.mapLayersButton,
                ),
                const SizedBox(height: 8),
                _CtrlBtn(
                  icon: Icons.add_rounded,
                  onTap: () {
                    _followCamera.beginProgrammaticMove();
                    _mapController?.animateCamera(CameraUpdate.zoomIn()).then((_) {
                      _followCamera.endProgrammaticMoveSoon(
                        const Duration(milliseconds: 120),
                      );
                    });
                  },
                  tooltip: l10n.zoomIn,
                ),
                const SizedBox(height: 2),
                _CtrlBtn(
                  icon: Icons.remove_rounded,
                  onTap: () {
                    _followCamera.beginProgrammaticMove();
                    _mapController?.animateCamera(CameraUpdate.zoomOut()).then((_) {
                      _followCamera.endProgrammaticMoveSoon(
                        const Duration(milliseconds: 120),
                      );
                    });
                  },
                  tooltip: l10n.zoomOut,
                ),
                const SizedBox(height: 8),
                _CtrlBtn(
                  icon: Icons.fit_screen_rounded,
                  onTap: () => vehiclesAsync.whenOrNull(data: _fitAll),
                  tooltip: l10n.centerFleetTooltip,
                ),
                const SizedBox(height: 2),
                _CtrlBtn(
                  icon: Icons.refresh_rounded,
                  onTap: () => ref.invalidate(mapVehiclesProvider),
                  tooltip: l10n.refreshTooltip,
                ),
              ],
            ),
          ),

          if (_followCamera.followEnabled &&
              _followCamera.gesturePaused &&
              selectedId != null)
            Positioned(
              bottom: 260 + navBottom,
              left: 0,
              right: 0,
              child: Center(
                child: Material(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(20),
                  elevation: 4,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _followCamera.resumeFleetGesturePause();
                      });
                      final v = vehiclesAsync.whenOrNull(
                        data: (list) => list
                            .where((e) => e.id == selectedId)
                            .firstOrNull,
                      );
                      if (v != null) {
                        _followCamera.beginProgrammaticMove();
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            LatLng(v.latitude, v.longitude),
                            math.max(_cameraZoom, 15.0).toDouble(),
                          ),
                        ).then((_) {
                          _followCamera.endProgrammaticMoveSoon(
                            const Duration(milliseconds: 200),
                          );
                        });
                      }
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      child: Text(
                        l10n.resumeVehicleFollow,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: selectedId != null
                ? vehiclesAsync.whenOrNull(
                      data: (all) {
                        final visible =
                            applyVehicleMapFilter(all, mapFilter);
                        final v =
                            visible.where((x) => x.id == selectedId).firstOrNull;
                        if (v == null) return const SizedBox.shrink();
                        return _VehicleBottomSheetCard(
                          vehicle: v,
                          navBottom: navBottom,
                          isLiveFollowing: _followCamera.followEnabled,
                          onClose: () {
                            ref.read(selectedMapVehicleProvider.notifier).state =
                                null;
                            setState(() {
                              _followCamera.clearFollow();
                            });
                          },
                          onToggleLiveFollow: () {
                            setState(() {
                              _followCamera.followEnabled =
                                  !_followCamera.followEnabled;
                              _followCamera.resumeFleetGesturePause();
                            });
                          },
                          onDetails: () {
                            AppLogger.navigation(
                              'Vehicle details opened: vehicleId=${v.id} '
                              'source=map_bottom_card',
                            );
                            context.push('/vehicles/${v.id}');
                          },
                          onGenerateReport: () => _openReportFromMapCard(v),
                          onReplayRoute: () => _openReplayFromMapCard(v),
                          onMiniCenter: () {
                            _followCamera.beginProgrammaticMove();
                            _mapController?.animateCamera(
                              CameraUpdate.newLatLngZoom(
                                LatLng(v.latitude, v.longitude),
                                math.max(_cameraZoom, 16.2).toDouble(),
                              ),
                            ).then((_) {
                              _followCamera.endProgrammaticMoveSoon(
                                const Duration(milliseconds: 200),
                              );
                            });
                          },
                          filterActive: mapFilter.isActive,
                          selectedCount: mapFilter.selectedCount,
                          onChooseVehicles: _openVehiclePickerFromVehicleCard,
                          l10n: l10n,
                        );
                      },
                    ) ??
                    const SizedBox.shrink()
                : vehiclesAsync.whenOrNull(
                      data: (all) => Padding(
                        padding: EdgeInsets.fromLTRB(
                          AppSpacing.screenPadding,
                          AppSpacing.screenPadding,
                          AppSpacing.screenPadding,
                          AppSpacing.screenPadding + navBottom,
                        ),
                        child: _FleetSummaryBar(
                          vehicles: all,
                          l10n: l10n,
                          socketState: socketAsync.valueOrNull,
                          filterActive: mapFilter.isActive,
                          selectedCount: mapFilter.selectedCount,
                          onChooseVehicles: _openVehiclePickerFromBottomSummary,
                        ),
                      ),
                    ) ??
                    const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

// ── Filters ──────────────────────────────────────────────────────────────────

class _FilterStrip extends StatelessWidget {
  const _FilterStrip({
    required this.selected,
    required this.counts,
    required this.alertVehicleIds,
    required this.l10n,
    required this.onSelect,
  });

  final String selected;
  final Map<String, int> counts;
  final Set<String> alertVehicleIds;
  final AppLocalizations l10n;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    final filters = <(
      String key,
      String label,
      Color? tint,
      IconData icon,
    )>[
      ('all', l10n.filterAll, null, Icons.grid_view_rounded),
      ('moving', l10n.filterMoving, AppColors.statusMoving, Icons.navigation_rounded),
      ('stopped', l10n.filterStopped, AppColors.statusIdle, Icons.stop_circle_outlined),
      ('idle', l10n.filterIdle, AppColors.statusStopped, Icons.timelapse_rounded),
      ('offline', l10n.filterOffline, AppColors.statusOffline, Icons.signal_wifi_off_rounded),
      ('alert', l10n.filterAlertsMap, AppColors.error, Icons.notifications_active_rounded),
    ];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        physics: const BouncingScrollPhysics(),
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final (key, label, tint, icon) = filters[i];
          final n = counts[key] ?? 0;
          final active = tint ?? AppColors.accent;
          final sel = selected == key;
          return FilterChip(
            label: Text(
              '$label $n',
              softWrap: false,
              overflow: TextOverflow.visible,
              style: TextStyle(
                fontSize: 11,
                fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                color: sel ? active : AppColors.textSecondaryOf(context),
              ),
            ),
            avatar: Icon(icon, size: 14, color: sel ? active : AppColors.textMutedOf(context)),
            selected: sel,
            showCheckmark: false,
            selectedColor: active.withValues(alpha: 0.16),
            backgroundColor:
                AppColors.surfaceOf(context).withValues(alpha: 0.92),
            side: BorderSide(
              color: sel ? active : AppColors.borderOf(context),
              width: sel ? 1.2 : 0.7,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
            onSelected: (_) => onSelect(key),
          );
        },
      ),
    );
  }
}

// ── Fleet summary pill ─────────────────────────────────────────────────────────

class _FleetSummaryBar extends StatelessWidget {
  const _FleetSummaryBar({
    required this.vehicles,
    required this.l10n,
    required this.socketState,
    required this.filterActive,
    required this.selectedCount,
    required this.onChooseVehicles,
  });

  final List<VehicleEntity> vehicles;
  final AppLocalizations l10n;
  final SocketState? socketState;
  final bool filterActive;
  final int selectedCount;
  final VoidCallback onChooseVehicles;

  @override
  Widget build(BuildContext context) {
    final online = vehicles.where((v) => v.isOnline).length;
    final moving = vehicles.where((v) => v.isMoving).length;
    final idle = vehicles.where((v) => v.isIdle).length;
    final total = vehicles.length;
    final connected = socketState is SocketConnected;
    final dotColor =
        connected ? AppColors.statusMoving : AppColors.statusStopped;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context).withValues(alpha: 0.97),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.borderOf(context).withValues(alpha: 0.5),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 8, 4, 8),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: dotColor.withValues(alpha: 0.45),
                    blurRadius: 5,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                l10n.fleetSummaryBar(online, total, moving, idle),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimaryOf(context),
                ),
                maxLines: 2,
              ),
            ),
            IconButton(
              onPressed: onChooseVehicles,
              tooltip: filterActive && selectedCount > 0
                  ? l10n.selectedVehiclesCount(selectedCount)
                  : l10n.chooseVehicles,
              style: IconButton.styleFrom(
                backgroundColor: filterActive
                    ? AppColors.accent.withValues(alpha: 0.12)
                    : AppColors.accent.withValues(alpha: 0.06),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              icon: Badge(
                isLabelVisible: filterActive && selectedCount > 0,
                label: Text(
                  '$selectedCount',
                  style: const TextStyle(fontSize: 10),
                ),
                child: const Icon(
                  Icons.checklist_rounded,
                  color: AppColors.accent,
                  size: 22,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Bottom sheet card ──────────────────────────────────────────────────────────

class _VehicleBottomSheetCard extends StatelessWidget {
  const _VehicleBottomSheetCard({
    required this.vehicle,
    required this.navBottom,
    required this.onClose,
    required this.onToggleLiveFollow,
    required this.isLiveFollowing,
    required this.onDetails,
    required this.onGenerateReport,
    required this.onReplayRoute,
    required this.onMiniCenter,
    required this.filterActive,
    required this.selectedCount,
    required this.onChooseVehicles,
    required this.l10n,
  });

  final VehicleEntity vehicle;
  final double navBottom;
  final VoidCallback onClose;
  final VoidCallback onToggleLiveFollow;
  final bool isLiveFollowing;
  final VoidCallback onDetails;
  final VoidCallback onGenerateReport;
  final VoidCallback onReplayRoute;
  final VoidCallback onMiniCenter;
  final bool filterActive;
  final int selectedCount;
  final VoidCallback onChooseVehicles;
  final AppLocalizations l10n;

  String _statusLabel(String s) => switch (s) {
        'moving' => l10n.filterMoving,
        'stopped' => l10n.filterStopped,
        'idle' => l10n.filterIdle,
        _ => l10n.filterOffline,
      };

  @override
  Widget build(BuildContext context) {
    final sc = vehicleStatusColor(vehicle.status);
    final subId =
        vehicle.uniqueId?.isNotEmpty == true ? vehicle.uniqueId! : vehicle.plateNumber;

    return Container(
      margin: EdgeInsets.fromLTRB(12, 0, 12, 10 + navBottom),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sc.withValues(alpha: 0.24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 28,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: sc.withValues(alpha: 0.08),
            blurRadius: 16,
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      AppColors.textMutedOf(context).withValues(alpha: 0.30),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
          // Status accent bar
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
            child: Row(
              children: [
                Container(
                  width: 4,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        sc,
                        sc.withValues(alpha: 0.3),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vehicle.name,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryOf(context),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 7, vertical: 2),
                            decoration: BoxDecoration(
                              color: sc.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(20),
                              border:
                                  Border.all(color: sc.withValues(alpha: 0.32)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: sc,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  _statusLabel(vehicle.status),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: sc,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              subId,
                              style: TextStyle(
                                fontSize: 11,
                                color: AppColors.textMutedOf(context),
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: sc.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.all(8),
                  child: Icon(vehicleCategoryIcon(vehicle.type),
                      color: sc, size: 24),
                ),
                const SizedBox(width: 4),
                IconButton(
                  onPressed: onChooseVehicles,
                  tooltip: filterActive && selectedCount > 0
                      ? l10n.selectedVehiclesCount(selectedCount)
                      : l10n.chooseVehicles,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  style: IconButton.styleFrom(
                    backgroundColor: filterActive
                        ? AppColors.accent.withValues(alpha: 0.12)
                        : AppColors.backgroundOf(context).withValues(alpha: 0.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  icon: Badge(
                    isLabelVisible: filterActive && selectedCount > 0,
                    label: Text(
                      '$selectedCount',
                      style: const TextStyle(fontSize: 9),
                    ),
                    child: const Icon(
                      Icons.checklist_rounded,
                      color: AppColors.accent,
                      size: 20,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: onClose,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.backgroundOf(context)
                          .withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.close_rounded,
                        color: AppColors.textSecondaryOf(context), size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Metrics row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.backgroundOf(context).withValues(alpha: 0.45),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.borderOf(context).withValues(alpha: 0.4),
                  width: 0.7,
                ),
              ),
              child: IntrinsicHeight(
                child: Row(
                  children: [
                    Expanded(
                      child: _MiniMetric(
                        label: l10n.speedLabel,
                        value: FormatUtils.speed(vehicle.speed),
                        icon: Icons.speed_rounded,
                        iconColor: sc,
                      ),
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 0.7,
                      color:
                          AppColors.borderOf(context).withValues(alpha: 0.5),
                    ),
                    Expanded(
                      child: _MiniMetric(
                        label: l10n.engineLabel,
                        value: vehicle.ignition
                            ? l10n.ignitionOnLabel
                            : l10n.ignitionOffLabel,
                        icon: vehicle.ignition
                            ? Icons.bolt_rounded
                            : Icons.power_off_rounded,
                        iconColor: vehicle.ignition
                            ? AppColors.statusMoving
                            : AppColors.textMutedOf(context),
                      ),
                    ),
                    VerticalDivider(
                      width: 1,
                      thickness: 0.7,
                      color:
                          AppColors.borderOf(context).withValues(alpha: 0.5),
                    ),
                    Expanded(
                      child: _MiniMetric(
                        label: l10n.lastUpdateLabel,
                        value: vehicle.lastUpdate != null
                            ? DateFormatter.toRelative(vehicle.lastUpdate!)
                            : '–',
                        icon: Icons.access_time_rounded,
                        iconColor: AppColors.accent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Optional extra info
          if (vehicle.address != null && vehicle.address!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(Icons.location_on_rounded,
                      size: 13,
                      color: AppColors.textMutedOf(context)
                          .withValues(alpha: 0.7)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      vehicle.address!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (vehicle.driverName != null &&
              vehicle.driverName!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                children: [
                  Icon(Icons.person_rounded,
                      size: 13,
                      color: AppColors.textMutedOf(context)
                          .withValues(alpha: 0.7)),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      '${l10n.driverLabel}: ${vehicle.driverName}',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondaryOf(context),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (vehicle.batteryVoltage != null ||
              (vehicle.latestOdometerKm != null &&
                  vehicle.latestOdometerKm! > 0)) ...[
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              child: Row(
                children: [
                  if (vehicle.batteryVoltage != null) ...[
                    Icon(Icons.battery_std_rounded,
                        size: 12,
                        color: AppColors.textMutedOf(context)
                            .withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text(
                      '${l10n.batteryVoltageLabel}: ${FormatUtils.voltage(vehicle.batteryVoltage)}',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMutedOf(context),
                      ),
                    ),
                  ],
                  if (vehicle.batteryVoltage != null &&
                      vehicle.latestOdometerKm != null &&
                      vehicle.latestOdometerKm! > 0)
                    const SizedBox(width: 12),
                  if (vehicle.latestOdometerKm != null &&
                      vehicle.latestOdometerKm! > 0) ...[
                    Icon(Icons.speed_rounded,
                        size: 12,
                        color: AppColors.textMutedOf(context)
                            .withValues(alpha: 0.6)),
                    const SizedBox(width: 4),
                    Text(
                      '${l10n.odometerLabel}: ${vehicle.latestOdometerKm!.toStringAsFixed(1)} km',
                      style: TextStyle(
                        fontSize: 10.5,
                        color: AppColors.textMutedOf(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
            child: Row(
              children: [
                Expanded(
                  child: _MapCardAction(
                    icon: Icons.info_outline_rounded,
                    label: l10n.detailsLabel,
                    onTap: onDetails,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _MapCardAction(
                    icon: Icons.assessment_outlined,
                    label: l10n.generateReport,
                    onTap: onGenerateReport,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _MapCardAction(
                    icon: Icons.replay_rounded,
                    label: l10n.replayRoute,
                    onTap: onReplayRoute,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor:
                      isLiveFollowing ? AppColors.emerald : AppColors.accent,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                ),
                onPressed: onToggleLiveFollow,
                icon: Icon(
                  isLiveFollowing
                      ? Icons.gps_fixed_rounded
                      : Icons.gps_not_fixed_rounded,
                  size: 15,
                ),
                label: Text(
                  isLiveFollowing
                      ? l10n.liveFollowRunningLabel
                      : l10n.liveTracking,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    this.icon,
    this.iconColor,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: iconColor ?? AppColors.accent),
          const SizedBox(height: 3),
        ],
        Text(
          value,
          style: TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryOf(context),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontSize: 9.5,
            color: AppColors.textMutedOf(context),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

// ── Controls ───────────────────────────────────────────────────────────────────

class _MapCardAction extends StatelessWidget {
  const _MapCardAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.backgroundOf(context).withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: AppColors.accent),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  const _CtrlBtn({
    required this.icon,
    required this.onTap,
    required this.tooltip,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.surfaceOf(context).withValues(alpha: 0.97),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.borderOf(context).withValues(alpha: 0.7),
              width: 0.8,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 9,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: AppColors.accent),
        ),
      ),
    );
  }
}

// ── Loading / Error ────────────────────────────────────────────────────────────

class _MapLoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ColoredBox(
      color: AppColors.backgroundOf(context),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.08),
                shape: BoxShape.circle,
                border: Border.all(
                  color: AppColors.accent.withValues(alpha: 0.22),
                  width: 1.2,
                ),
              ),
              child: const Icon(
                Icons.map_rounded,
                color: AppColors.accent,
                size: 30,
              ),
            ),
            const SizedBox(height: 18),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                color: AppColors.accent,
                strokeWidth: 2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              l10n.mapLoadingFleet,
              style: TextStyle(
                color: AppColors.textSecondaryOf(context),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MapErrorState extends StatelessWidget {
  const _MapErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return ColoredBox(
      color: AppColors.backgroundOf(context),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.error,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              l10n.mapLoadError,
              style: TextStyle(
                color: AppColors.textSecondaryOf(context),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                  border:
                      Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.refresh_rounded,
                        color: AppColors.accent, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      l10n.retry,
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
