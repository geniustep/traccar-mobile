import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/maps/map_config.dart';
import '../../../../core/maps/map_helper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/route_decimator.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/socket/socket_provider.dart';
import '../../../../core/socket/socket_state.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../../vehicles/presentation/widgets/report_entry_sheet.dart';
import '../../../vehicles/presentation/widgets/replay_entry_sheet.dart';
import '../../../reports/presentation/providers/reports_providers.dart';
import '../../core/map_camera_follow_controller.dart';
import '../../core/map_zoom_policy.dart';
import '../../core/route_event_analyzer.dart';
import '../../core/route_event_models.dart';
import '../../core/route_event_timeline_models.dart';
import '../../core/route_event_ui.dart';
import '../../core/route_intelligence_thresholds.dart';
import '../../core/route_polyline_builder.dart';
import '../../core/vehicle_marker_factory.dart';
import '../../core/vehicle_marker_style.dart';
import '../../core/route_stop_address_enrichment.dart';
import '../../core/trip_segment_models.dart';
import '../../core/trip_segment_summary.dart';
import '../../core/trip_segmenter.dart';
import '../../core/daily_behavior_score_calculator.dart';
import '../../core/daily_behavior_score_models.dart';
import '../../core/driver_behavior_score_models.dart';
import '../../core/driver_behavior_score_calculator.dart';
import '../../data/datasources/route_datasource.dart';
import '../providers/route_intelligence_thresholds_provider.dart';
import '../providers/route_stop_address_providers.dart';
import '../providers/tracking_provider.dart';
import '../utils/trip_formatters.dart';
import '../widgets/daily_behavior_score_details_sheet.dart';
import '../widgets/daily_vehicle_behavior_score_card.dart';
import '../widgets/route_event_details_sheet.dart';
import '../widgets/route_event_timeline.dart';
import '../widgets/trips_list.dart';

// ─────────────────────────────────────────────────────────────────────────────

class VehicleTrackingScreen extends ConsumerStatefulWidget {
  const VehicleTrackingScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  ConsumerState<VehicleTrackingScreen> createState() =>
      _VehicleTrackingScreenState();
}

class _VehicleTrackingScreenState
    extends ConsumerState<VehicleTrackingScreen>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  GoogleMapController? _controller;
  Timer? _liveTimer;

  double _cameraZoom = MapConfig.defaultZoom;

  final _followCamera = MapCameraFollowController(
    MapCameraFollowMode.singleVehicle,
  );

  final _sheetController = DraggableScrollableController();

  /// Route time range (local datetimes). Default: today 00:00 → now.
  late DateTime _from;
  late DateTime _to;

  /// Set when the range changes so the camera fits the new route on load.
  bool _pendingRouteFit = false;

  // Vehicle marker cache
  final _markerCache = <String, BitmapDescriptor>{};
  final _pendingKeys  = <String>{};

  /// Memo key for [RouteEventAnalyzer] on full route points.
  String _routeIntelKey = '';
  RouteEventAnalysisResult? _routeIntel;

  /// Phase 7C: shared highlight for timeline row + intelligence marker ([RouteEventTimelineItem.selectionKey]).
  String? _selectedRouteEventKey;

  /// Phase 7E: timeline filter (display only).
  RouteEventTimelineFilter _routeTimelineFilter = RouteEventTimelineFilter.all;

  /// Phase 8: memoized trip segmentation for the tracking window.
  String _tripsMemoKey = '';
  List<TripSegment> _tripSegments = const [];
  /// Phase 9B: memoized beside [_tripSegments] (same memo key).
  Map<String, DriverBehaviorScore> _tripBehaviorScores = const {};
  DailyVehicleBehaviorScore _dailyVehicleBehaviorScore =
      DailyVehicleBehaviorScoreCalculator.calculateDailyVehicleBehaviorScore(
    trips: const [],
  );
  static const _refreshInterval = Duration(seconds: 10);

  bool _didLogFirstPosition = false;

  // ── M4: connection-aware tracking status ──────────────────────────────────
  _TrackingLiveStatus? _lastLoggedStatus;

  // ── M2: map type toggle ───────────────────────────────────────────────────
  static const _mapTypes = [MapType.normal, MapType.satellite, MapType.terrain];
  MapType _mapType = MapType.normal;

  // ── M2: smooth marker interpolation ────────────────────────────────────────
  AnimationController? _markerMotion;
  LatLng _smoothPos = const LatLng(0, 0);
  double _smoothCourse = 0;
  LatLng? _animStartPos;
  LatLng? _animEndPos;
  double _courseAnimStart = 0;
  double _courseAnimEnd = 0;
  static const _maxInstantJumpMeters = 50000.0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    AppLogger.map('VehicleTrackingScreen opened: vehicleId=${widget.vehicleId}');
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, now.day); // today midnight
    _to   = now;
    _startLiveTimer();
    _followCamera.followEnabled = true;
    _markerMotion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    )..addListener(_onMarkerMotionTick);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _liveTimer?.cancel();
    _markerMotion?.dispose();
    _controller?.dispose();
    _sheetController.dispose();
    super.dispose();
  }

  // ── Lifecycle ─────────────────────────────────────────────────────────────

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      _liveTimer?.cancel();
      _liveTimer = null;
      AppLogger.map(
        'VehicleTracking: lifecycle paused, timer stopped '
        'for vehicleId=${widget.vehicleId}',
      );
    } else if (state == AppLifecycleState.resumed) {
      _startLiveTimer();
      ref.invalidate(liveVehicleProvider(widget.vehicleId));
      ref.invalidate(routeDetailProvider(_routeQuery));
      AppLogger.map(
        'VehicleTracking: lifecycle resumed, timer restarted '
        'for vehicleId=${widget.vehicleId}',
      );
    }
  }

  void _startLiveTimer() {
    _liveTimer?.cancel();
    _liveTimer = Timer.periodic(_refreshInterval, (_) {
      ref.invalidate(liveVehicleProvider(widget.vehicleId));
    });
  }

  // ── M2: smooth marker interpolation tick ──────────────────────────────────

  void _onMarkerMotionTick() {
    final a = _animStartPos;
    final b = _animEndPos;
    if (a == null || b == null || !mounted) return;
    final t = Curves.easeOut.transform(_markerMotion!.value);
    setState(() {
      _smoothPos = LatLng(
        a.latitude + (b.latitude - a.latitude) * t,
        a.longitude + (b.longitude - a.longitude) * t,
      );
      var dc = _courseAnimEnd - _courseAnimStart;
      if (dc.abs() > 180) dc -= 360 * dc.sign;
      _smoothCourse = _courseAnimStart + dc * t;
    });
  }

  void _applyLivePosition(VehicleEntity v) {
    final target = LatLng(v.latitude, v.longitude);
    final course = v.course ?? 0;

    if (_animEndPos == null) {
      _smoothPos = target;
      _smoothCourse = course;
      _animStartPos = target;
      _animEndPos = target;
      return;
    }

    final dist = MapHelper.distanceMeters(_smoothPos, target);
    if (dist > _maxInstantJumpMeters) {
      AppLogger.map(
        'Marker jump too large (${(dist / 1000).toStringAsFixed(1)} km) '
        'for vehicleId=${widget.vehicleId}, skipping animation',
      );
      _smoothPos = target;
      _smoothCourse = course;
      _animStartPos = target;
      _animEndPos = target;
      setState(() {});
      return;
    }

    _animStartPos = _smoothPos;
    _animEndPos = target;
    _courseAnimStart = _smoothCourse;
    _courseAnimEnd = course;
    _markerMotion?.forward(from: 0);
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  RouteQuery get _routeQuery =>
      RouteQuery(vehicleId: widget.vehicleId, from: _from, to: _to);

  bool get _isToday => _routeQuery.isToday;

  // ── Camera ─────────────────────────────────────────────────────────────────

  void _moveTo(LatLng target) {
    _followCamera.beginProgrammaticMove();
    _controller
        ?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 16, tilt: 30),
      ),
    )
        .then((_) => _followCamera.endProgrammaticMoveSoon());
  }

  void _fitRoute(List<LatLng> points, LatLng? current) {
    final all = [...points, if (current != null) current];
    final update = MapHelper.fitPoints(all, padding: 80);
    if (update != null) {
      _followCamera.beginProgrammaticMove();
      _controller
          ?.animateCamera(update)
          .then((_) => _followCamera.endProgrammaticMoveSoon());
    }
  }

  void _fitRoutePoints(List<RoutePoint> pts, LatLng? current) =>
      _fitRoute(pts.map((p) => p.position).toList(), current);

  void _animateCameraToRouteEvent(RouteEventTimelineItem item) {
    final c = _controller;
    if (c == null || !routeEventTimelineValidPosition(item.position)) return;
    _followCamera.followEnabled = false;
    _followCamera.beginProgrammaticMove();
    c.animateCamera(
      CameraUpdate.newLatLngZoom(
        item.position,
        RouteEventTimeline.focusZoomHint,
      ),
    ).then((_) {
      if (mounted) _followCamera.endProgrammaticMoveSoon();
    });
    setState(() {});
  }

  void _focusRouteTimelineEvent(RouteEventTimelineItem item) {
    if (!routeEventTimelineValidPosition(item.position)) return;
    setState(() => _selectedRouteEventKey = item.selectionKey);
    _animateCameraToRouteEvent(item);
    if (!mounted) return;
    RouteEventDetailsSheet.show(
      context,
      item: item,
      onRecenter: () => _animateCameraToRouteEvent(item),
      resolver: ref.read(routeStopAddressResolverProvider),
      onStopAddressCommitted: _applyResolvedStopAddress,
    );
  }

  /// Map pin tap (Route Intelligence) — details only; does not toggle follow mode.
  void _onRouteIntelMarkerTap(RouteEventTimelineItem item) {
    if (!mounted) return;
    setState(() => _selectedRouteEventKey = item.selectionKey);
    RouteEventDetailsSheet.show(
      context,
      item: item,
      onRecenter: () => _animateCameraToRouteEvent(item),
      resolver: ref.read(routeStopAddressResolverProvider),
      onStopAddressCommitted: _applyResolvedStopAddress,
    );
  }

  void _syncRouteIntel(List<RoutePoint> pts, RouteIntelligenceThresholds th) {
    final key = pts.length < 2
        ? '0'
        : '${pts.length}_${pts.first.fixTime.millisecondsSinceEpoch}_${pts.last.fixTime.millisecondsSinceEpoch}_${th.cacheKey}';
    if (key == _routeIntelKey) return;
    _selectedRouteEventKey = null;
    _routeTimelineFilter = RouteEventTimelineFilter.all;
    _routeIntelKey = key;
    final raw = pts.length < 2
        ? null
        : RouteEventAnalyzer.analyze(pts, thresholds: th);
    _routeIntel = raw == null
        ? null
        : enrichRouteIntelStopsFromRoutePoints(raw, pts);
    if (_routeIntel != null && pts.length >= 2) {
      _scheduleStopAddressPrefetch();
    }
  }

  void _syncTripSegments(List<RoutePoint> pts, RouteIntelligenceThresholds th) {
    const cfg = TripSegmentationConfig.defaults;
    final key = pts.isEmpty
        ? '0'
        : 't_${pts.length}_${pts.first.fixTime.millisecondsSinceEpoch}_${pts.last.fixTime.millisecondsSinceEpoch}_${th.cacheKey}_${cfg.cacheKey}';
    if (key == _tripsMemoKey) return;
    _tripsMemoKey = key;
    _tripSegments = TripSegmenter.build(
      vehicleId: widget.vehicleId,
      points: pts,
      thresholds: th,
      config: cfg,
    );
    _tripBehaviorScores = {
      for (final t in _tripSegments)
        t.selectionKey: DriverBehaviorScoreCalculator.calculateTripScore(t),
    };
    _dailyVehicleBehaviorScore =
        DailyVehicleBehaviorScoreCalculator.calculateDailyVehicleBehaviorScore(
      trips: _tripSegments,
    );
  }

  void _openTripDetailMap(TripSegment t) {
    final snap = ref.read(liveVehicleProvider(widget.vehicleId));
    final name = snap.valueOrNull?.name ?? '';
    final params = reportFilterParamsForTrip(
      vehicleId: widget.vehicleId,
      startTime: t.startTime,
      endTime: t.endTime,
    );
    final subtitle = TripUiFormatters.tripTitle(context.l10n, t.index);
    if (!mounted) return;
    context.push(
      '/vehicles/${widget.vehicleId}/trip-map',
      extra: <String, dynamic>{
        'params': params,
        'vehicleName': name,
        'tripSubtitle': subtitle,
      },
    );
  }

  void _openTripReplay(TripSegment t) {
    final snap = ref.read(liveVehicleProvider(widget.vehicleId));
    final name = snap.valueOrNull?.name ?? '';
    final params = reportFilterParamsForTrip(
      vehicleId: widget.vehicleId,
      startTime: t.startTime,
      endTime: t.endTime,
    );
    if (!mounted) return;
    context.push(
      '/reports/replay',
      extra: <String, dynamic>{
        'params': params,
        'vehicleName': name,
      },
    );
  }

  /// Phase **9F** — period behavior score breakdown (does not mutate Core calculators).
  void _openDailyBehaviorScoreDetails() {
    if (!mounted) return;
    DailyBehaviorScoreDetailsSheet.show(
      context,
      dailyScore: _dailyVehicleBehaviorScore,
    );
  }
  void _scheduleStopAddressPrefetch() {
    final k = _routeIntelKey;
    final cur = _routeIntel;
    if (cur == null || cur.stops.isEmpty) return;
    final resolver = ref.read(routeStopAddressResolverProvider);
    prefetchStopAddressesSequential(
      resolver: resolver,
      intel: cur,
      isStale: () => !mounted || _routeIntelKey != k,
      apply: (u) {
        if (!mounted || _routeIntelKey != k) return;
        setState(() => _routeIntel = u);
      },
    );
  }

  void _applyResolvedStopAddress(String selectionKey, String address) {
    final intel = _routeIntel;
    if (intel == null) return;
    RouteStopEvent? target;
    for (final s in intel.stops) {
      if (routeStopSelectionKey(s) == selectionKey) {
        target = s;
        break;
      }
    }
    if (target == null) return;
    final existing = target.address?.trim();
    if (existing != null && existing.isNotEmpty) return;
    setState(() {
      _routeIntel = intel.withStops(
        replaceStopAddressOnList(intel.stops, target!, address),
      );
    });
  }

  // ── Vehicle marker ─────────────────────────────────────────────────────────

  BitmapDescriptor _iconForVehicle(VehicleEntity v) {
    final body = VehicleMarkerFactory.pinBodyColor(
      v: v,
      alertVehicleIds: const <String>{},
      style: VehicleMarkerStyle.tracking,
    );
    final policy = MapZoomPolicy.at(_cameraZoom);
    final scale = policy.markerScale(style: VehicleMarkerStyle.tracking);
    final sizePx = (76 * scale).round();
    final key = VehicleMarkerFactory.northUpCarCacheKey(body, sizePx);
    if (_markerCache.containsKey(key)) return _markerCache[key]!;
    if (!_pendingKeys.contains(key)) {
      _pendingKeys.add(key);
      VehicleMarkerFactory.topDownCarNorthUp(
        bodyColor: body,
        size: sizePx.toDouble(),
      ).then((icon) {
        if (mounted) {
          setState(() {
            _markerCache[key] = icon;
            _pendingKeys.remove(key);
          });
        }
      });
    }
    return VehicleMarkerFactory.fallbackPinHue(v.status);
  }

  Marker _buildVehicleMarker(VehicleEntity v) {
    final useSmooth = _animEndPos != null &&
        (_smoothPos.latitude != 0 || _smoothPos.longitude != 0);
    final pos = useSmooth ? _smoothPos : LatLng(v.latitude, v.longitude);
    final course = useSmooth ? _smoothCourse : (v.course ?? 0);

    return Marker(
      markerId: const MarkerId('vehicle'),
      position: pos,
      icon: _iconForVehicle(v),
      anchor: const Offset(0.5, 0.5),
      flat: true,
      rotation: course,
      infoWindow: InfoWindow(
        title: v.name,
        snippet: FormatUtils.speed(v.speed),
      ),
      zIndexInt: 3,
    );
  }

  // ── Date picker ────────────────────────────────────────────────────────────

  /// Picks a date then a time, returns the combined DateTime or null.
  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
    );
    if (time == null) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickFrom() async {
    final picked = await _pickDateTime(_from);
    if (picked == null) return;
    setState(() {
      _from = picked;
      if (_to.isBefore(_from)) _to = _from.add(const Duration(hours: 1));
      _pendingRouteFit = true;
    });
    AppLogger.map(
      'Date range changed for vehicleId=${widget.vehicleId}: '
      'from=$_from to=$_to',
    );
    ref.invalidate(routeDetailProvider(_routeQuery));
  }

  Future<void> _pickTo() async {
    final picked = await _pickDateTime(_to);
    if (picked == null) return;
    setState(() {
      _to = picked;
      if (_from.isAfter(_to)) _from = _to.subtract(const Duration(hours: 1));
      _pendingRouteFit = true;
    });
    AppLogger.map(
      'Date range changed for vehicleId=${widget.vehicleId}: '
      'from=$_from to=$_to',
    );
    ref.invalidate(routeDetailProvider(_routeQuery));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n       = context.l10n;
    final liveAsync  = ref.watch(liveVehicleProvider(widget.vehicleId));
    final routeAsync = ref.watch(routeDetailProvider(_routeQuery));
    final socketAsync = ref.watch(socketStateProvider);

    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final mapStyle = isDark ? MapConfig.darkStyle : MapConfig.lightStyle;

    final vehicle     = liveAsync.valueOrNull;
    final routePoints = routeAsync.valueOrNull ?? [];
    final navBottom   = MediaQuery.paddingOf(context).bottom;
    final riThresholds =
        ref.watch(routeIntelligenceThresholdsForVehicleProvider(widget.vehicleId));

    _syncRouteIntel(routePoints, riThresholds);
    _syncTripSegments(routePoints, riThresholds);

    // Follow mode: smooth-interpolate vehicle marker + camera follow
    ref.listen(liveVehicleProvider(widget.vehicleId), (prev, next) {
      next.whenOrNull(
        data: (v) {
          final hasPos = v.latitude != 0 || v.longitude != 0;
          if (!_didLogFirstPosition && hasPos) {
            _didLogFirstPosition = true;
            AppLogger.map(
              'First live position for vehicleId=${widget.vehicleId}: '
              '${v.latitude.toStringAsFixed(5)},${v.longitude.toStringAsFixed(5)} '
              'speed=${v.speed}',
            );
          }
          if (!hasPos && prev?.valueOrNull != null) {
            AppLogger.map('No valid position for vehicleId=${widget.vehicleId}');
          }
          if (hasPos) _applyLivePosition(v);
          if (!_followCamera.canApplyLiveCamera || !hasPos) return;
          _moveTo(LatLng(v.latitude, v.longitude));
        },
        error: (e, _) {
          AppLogger.error(
            'VehicleTracking',
            'Live data failed for vehicleId=${widget.vehicleId}',
            e,
          );
        },
      );
    });

    // Fit route when a new date is picked and data arrives
    ref.listen(routeDetailProvider(_routeQuery), (_, next) {
      next.whenOrNull(
        data: (pts) {
          AppLogger.map(
            'Route loaded for vehicleId=${widget.vehicleId}: '
            '${pts.length} points',
          );
          if (_pendingRouteFit && pts.isNotEmpty) {
            _pendingRouteFit = false;
            final cur = vehicle != null && vehicle.latitude != 0
                ? LatLng(vehicle.latitude, vehicle.longitude)
                : null;
            WidgetsBinding.instance.addPostFrameCallback(
                (_) => _fitRoutePoints(pts, cur));
          }
        },
        error: (e, _) {
          AppLogger.error(
            'VehicleTracking',
            'Route load failed for vehicleId=${widget.vehicleId}',
            e,
          );
        },
      );
    });

    final screenH = MediaQuery.sizeOf(context).height;
    final controlsBottom = screenH * 0.32 + navBottom;

    final zoomPolicy = MapZoomPolicy.at(_cameraZoom);

    // Decimated points for rendering
    final drawPts = RoutePointDecimator.decimateForMap(
      routePoints,
      maxPoints: zoomPolicy.maxVisibleRoutePointsForDecimation(),
    );

    // Build map layers
    final Set<Marker> markers = {
      if (vehicle != null && (vehicle.latitude != 0 || vehicle.longitude != 0))
        _buildVehicleMarker(vehicle),
      ...RoutePolylineBuilder.buildRouteMarkers(
        drawPts,
        l10n,
        includeMaxSpeedMarker: zoomPolicy.showRouteMaxSpeedMarker(),
        omitRouteEndMarker:
            _isToday && vehicle != null && (vehicle.latitude != 0 || vehicle.longitude != 0),
        livePositionForRouteEndDedup: !_isToday &&
                vehicle != null &&
                (vehicle.latitude != 0 || vehicle.longitude != 0)
            ? LatLng(vehicle.latitude, vehicle.longitude)
            : null,
      ),
      ...RoutePolylineBuilder.buildHourlyWaypoints(
        drawPts,
        enabled: zoomPolicy.showRouteHourlyMarkers(),
      ),
      ...RoutePolylineBuilder.buildRouteIntelligenceMarkers(
        analysis: _routeIntel,
        l10n: l10n,
        policy: zoomPolicy,
        reportStyle: false,
        vehicleId: widget.vehicleId,
        onMarkerTap: _onRouteIntelMarkerTap,
        selectedEventKey: _selectedRouteEventKey,
      ),
    };

    final polylines = <Polyline>{
      ...RoutePolylineBuilder.buildSpeedColoredPolylines(
        vehicleId: widget.vehicleId,
        pts: drawPts,
      ),
    };

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: MapConfig.defaultCameraPosition,
            mapType: _mapType,
            markers: markers,
            polylines: polylines,
            onMapCreated: (c) {
              _controller = c;
              c.getZoomLevel().then((z) {
                if (mounted) setState(() => _cameraZoom = z);
              });
              if (vehicle != null && vehicle.latitude != 0) {
                _moveTo(LatLng(vehicle.latitude, vehicle.longitude));
              }
            },
            onCameraIdle: () {
              _controller?.getZoomLevel().then((z) {
                if (!mounted) return;
                if ((z - _cameraZoom).abs() > 0.02) {
                  setState(() => _cameraZoom = z);
                }
              });
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            buildingsEnabled: false,
            style: mapStyle,
            onCameraMoveStarted: () {
              if (_followCamera.handleUserCameraMoveStarted()) setState(() {});
            },
          ),

          // Loading overlay (first load only)
          if (liveAsync.isLoading && vehicle == null)
            ColoredBox(
              color: AppColors.backgroundOf(context),
              child: LoadingView(message: l10n.loadingVehicleLocation),
            ),

          // No live position banner (vehicle loaded but invalid coordinates)
          if (vehicle != null &&
              vehicle.latitude == 0 &&
              vehicle.longitude == 0 &&
              !liveAsync.isLoading)
            Positioned(
              top: 100,
              left: AppSpacing.screenPadding,
              right: AppSpacing.screenPadding,
              child: _NoPositionBanner(message: l10n.noLivePosition),
            ),

          // ── Top header ────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _TopBar(
                    vehicle: vehicle,
                    isLoading: liveAsync.isLoading,
                    onBack: () => context.pop(),
                  ),
                  const SizedBox(height: 6),
                  _LiveTrackingChip(
                    lastUpdate: vehicle?.lastUpdate,
                    hasValidPosition: vehicle != null &&
                        (vehicle.latitude != 0 || vehicle.longitude != 0),
                    socketState: socketAsync.valueOrNull,
                    onStatusChanged: (status) {
                      if (status != _lastLoggedStatus) {
                        _lastLoggedStatus = status;
                        AppLogger.map(
                          'Live status changed to ${status.name} '
                          'for vehicleId=${widget.vehicleId}',
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),

          // ── Right-side controls ───────────────────────────────────────────
          Positioned(
            right: AppSpacing.screenPadding,
            bottom: controlsBottom,
            child: Column(
              children: [
                _ControlBtn(
                  icon: _followCamera.followEnabled
                      ? Icons.gps_fixed_rounded
                      : Icons.gps_not_fixed_rounded,
                  label: _followCamera.followEnabled
                      ? l10n.followLabel
                      : l10n.freeLabel,
                  isActive: _followCamera.followEnabled,
                  onTap: () {
                    final newState = !_followCamera.followEnabled;
                    setState(() {
                      _followCamera.followEnabled = newState;
                    });
                    AppLogger.map(
                      'Follow mode ${newState ? "enabled" : "disabled"} '
                      'for vehicleId=${widget.vehicleId}',
                    );
                    if (newState && vehicle != null) {
                      _moveTo(LatLng(vehicle.latitude, vehicle.longitude));
                    }
                  },
                ),
                const SizedBox(height: 6),
                _ControlBtn(
                  icon: Icons.fit_screen_rounded,
                  label: l10n.recentreRouteLabel,
                  onTap: () {
                    AppLogger.map('Fit route tapped for vehicleId=${widget.vehicleId}');
                    final cur = vehicle != null && vehicle.latitude != 0
                        ? LatLng(vehicle.latitude, vehicle.longitude)
                        : null;
                    _fitRoutePoints(routePoints, cur);
                    setState(() {
                      _followCamera.followEnabled = false;
                    });
                  },
                ),
                const SizedBox(height: 6),
                _ControlBtn(
                  icon: Icons.add_rounded,
                  onTap: () {
                    _followCamera.beginProgrammaticMove();
                    _controller
                        ?.animateCamera(CameraUpdate.zoomIn())
                        .then((_) => _followCamera.endProgrammaticMoveSoon());
                  },
                ),
                const SizedBox(height: 4),
                _ControlBtn(
                  icon: Icons.remove_rounded,
                  onTap: () {
                    _followCamera.beginProgrammaticMove();
                    _controller
                        ?.animateCamera(CameraUpdate.zoomOut())
                        .then((_) => _followCamera.endProgrammaticMoveSoon());
                  },
                ),
                const SizedBox(height: 6),
                _ControlBtn(
                  icon: Icons.refresh_rounded,
                  onTap: () {
                    AppLogger.map('Refresh tapped for vehicleId=${widget.vehicleId}');
                    ref.invalidate(liveVehicleProvider(widget.vehicleId));
                    ref.invalidate(routeDetailProvider(_routeQuery));
                  },
                ),
                const SizedBox(height: 6),
                _ControlBtn(
                  icon: _mapType == MapType.satellite
                      ? Icons.satellite_alt_rounded
                      : _mapType == MapType.terrain
                          ? Icons.terrain_rounded
                          : Icons.map_rounded,
                  onTap: () {
                    final idx = (_mapTypes.indexOf(_mapType) + 1) %
                        _mapTypes.length;
                    setState(() => _mapType = _mapTypes[idx]);
                    final name = _mapType.name;
                    AppLogger.map(
                      'Map type changed to $name '
                      'for vehicleId=${widget.vehicleId}',
                    );
                  },
                ),
              ],
            ),
          ),

          // ── Collapse sheet button ─────────────────────────────────────────
          Positioned(
            left: AppSpacing.screenPadding,
            bottom: controlsBottom,
            child: _ControlBtn(
              icon: Icons.keyboard_arrow_down_rounded,
              onTap: () => _sheetController.animateTo(
                0.13,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
              ),
            ),
          ),

          // ── Speed legend ──────────────────────────────────────────────────
          if (routePoints.isNotEmpty)
            Positioned(
              left: AppSpacing.screenPadding,
              bottom: controlsBottom + 54,
              child: const _SpeedLegend(),
            ),

          // ── Bottom draggable sheet ────────────────────────────────────────
          DraggableScrollableSheet(
            controller: _sheetController,
            initialChildSize: 0.30,
            minChildSize: 0.13,
            maxChildSize: 0.65,
            snap: true,
            snapSizes: const [0.13, 0.30, 0.65],
            builder: (_, scrollController) => _InfoPanel(
              scrollController: scrollController,
              vehicle: vehicle,
              routeAsync: routeAsync,
              from: _from,
              to: _to,
              isToday: _isToday,
              onPickFrom: _pickFrom,
              onPickTo: _pickTo,
              onViewDetails: () {
                AppLogger.map(
                  'Details tapped for vehicleId=${widget.vehicleId}',
                );
                context.push('/vehicles/${widget.vehicleId}');
              },
              onViewTrips: () {
                AppLogger.map(
                  'Trip History tapped for vehicleId=${widget.vehicleId}',
                );
                context.push('/vehicles/${widget.vehicleId}/trips');
              },
              onGenerateReport: () async {
                AppLogger.map(
                  'Generate Report tapped for vehicleId=${widget.vehicleId}',
                );
                final name = vehicle?.name ?? '';
                final params = await showReportEntrySheet(
                  context,
                  vehicleId: widget.vehicleId,
                  vehicleName: name,
                );
                if (params != null && context.mounted) {
                  AppLogger.map(
                    'Navigating to /reports vehicleId=${params.vehicleId} '
                    'tab=${params.tabIndex} period=${params.period}',
                  );
                  context.push('/reports', extra: params);
                }
              },
              onReplayRoute: () async {
                AppLogger.map(
                  'Replay Route tapped for vehicleId=${widget.vehicleId}',
                );
                final name = vehicle?.name ?? '';
                final result = await showReplayEntrySheet(
                  context,
                  vehicleId: widget.vehicleId,
                  vehicleName: name,
                );
                if (result != null && context.mounted) {
                  AppLogger.map(
                    'Navigating to /reports/replay vehicleId=${result.vehicleId} '
                    'from=${result.from} to=${result.to}',
                  );
                  context.push(
                    '/reports/replay',
                    extra: <String, dynamic>{
                      'params': ReportFilterParams(
                        vehicleId: result.vehicleId,
                        from: result.from.toUtc(),
                        to: result.to.toUtc(),
                      ),
                      'vehicleName': result.vehicleName,
                    },
                  );
                }
              },
              onCommands: () {
                AppLogger.map(
                  'Commands tapped for vehicleId=${widget.vehicleId}',
                );
                context.push(
                  '/vehicles/${widget.vehicleId}/commands',
                  extra: {'name': vehicle?.name ?? ''},
                );
              },
              routeIntel: _routeIntel,
              routeIntelMemoKey: _routeIntelKey,
              selectedTimelineItemKey: _selectedRouteEventKey,
              timelineFilter: _routeTimelineFilter,
              onTimelineFilterChanged: (f) =>
                  setState(() => _routeTimelineFilter = f),
              onTimelineItemTap: _focusRouteTimelineEvent,
              tripSegments: _tripSegments,
              tripBehaviorScores: _tripBehaviorScores,
              dailyVehicleBehaviorScore: _dailyVehicleBehaviorScore,
              onTripOpenMap: _openTripDetailMap,
              onTripOpenReplay: _openTripReplay,
              onDailyScoreDetails: _openDailyBehaviorScoreDetails,
            ),
          ),

          // Error banner
          if (liveAsync.hasError)
            Positioned(
              top: 100,
              left: AppSpacing.screenPadding,
              right: AppSpacing.screenPadding,
              child: _ErrorBanner(
                message: l10n.updateLocationFailed,
                onRetry: () =>
                    ref.invalidate(liveVehicleProvider(widget.vehicleId)),
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Speed legend
// ─────────────────────────────────────────────────────────────────────────────

class _SpeedLegend extends StatelessWidget {
  const _SpeedLegend();

  @override
  Widget build(BuildContext context) {
    const items = [
      (Color(0xFF9E9E9E), '< 5'),
      (Color(0xFF4CAF50), '5–40'),
      (Color(0xFFFF9800), '40–80'),
      (Color(0xFFF44336), '80+'),
    ];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderOf(context), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: items.map((e) {
          final (color, label) = e;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10, height: 4,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 3),
                Text(label,
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondaryOf(context),
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.vehicle,
    required this.isLoading,
    required this.onBack,
  });

  final VehicleEntity? vehicle;
  final bool isLoading;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
            onPressed: onBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: AppColors.textSecondaryOf(context),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: vehicle == null
                ? Text(l10n.loading, style: AppTextStyles.labelLarge)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(vehicle!.name, style: AppTextStyles.labelLarge),
                      Text(
                        vehicle!.plateNumber,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondaryOf(context)),
                      ),
                    ],
                  ),
          ),
          if (vehicle != null)
            StatusBadge(status: StatusBadge.fromString(vehicle!.status)),
          if (isLoading) ...[
            const SizedBox(width: 8),
            const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.accent),
            ),
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Live tracking status chip (M4: connection-aware)
// ─────────────────────────────────────────────────────────────────────────────

enum _TrackingLiveStatus { live, stale, reconnecting, offline, noPosition }

class _LiveTrackingChip extends StatelessWidget {
  const _LiveTrackingChip({
    required this.lastUpdate,
    required this.hasValidPosition,
    this.socketState,
    this.onStatusChanged,
  });

  final DateTime? lastUpdate;
  final bool hasValidPosition;
  final SocketState? socketState;
  final ValueChanged<_TrackingLiveStatus>? onStatusChanged;

  static const _staleThreshold = Duration(minutes: 15);

  _TrackingLiveStatus _resolve() {
    // A) Socket reconnecting → show Reconnecting
    if (socketState is SocketReconnecting) return _TrackingLiveStatus.reconnecting;

    // B) Socket disconnected or error → show Offline
    if (socketState is SocketError || socketState is SocketDisconnected) {
      return _TrackingLiveStatus.offline;
    }

    // C) No valid GPS coordinates → No live position
    if (!hasValidPosition || lastUpdate == null) {
      return _TrackingLiveStatus.noPosition;
    }

    // D) Valid position but old → Stale data
    final age = DateTime.now().difference(lastUpdate!);
    if (age >= _staleThreshold) return _TrackingLiveStatus.stale;

    // E) Socket connected + valid recent position → Live
    //    Also show Live when socket is still initializing (null / connecting)
    //    because position data from REST is still fresh.
    return _TrackingLiveStatus.live;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final status = _resolve();

    if (onStatusChanged != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        onStatusChanged!(status);
      });
    }

    final String label;
    final Color color;
    final IconData icon;
    final bool showSpinner;

    switch (status) {
      case _TrackingLiveStatus.live:
        label = l10n.liveTrackingActive;
        color = AppColors.success;
        icon = Icons.sensors_rounded;
        showSpinner = false;
      case _TrackingLiveStatus.stale:
        label = l10n.trackingDataStale;
        color = AppColors.amber;
        icon = Icons.access_time_rounded;
        showSpinner = false;
      case _TrackingLiveStatus.reconnecting:
        label = l10n.trackingReconnecting;
        color = AppColors.amber;
        icon = Icons.sync_rounded;
        showSpinner = true;
      case _TrackingLiveStatus.offline:
        label = l10n.trackingOffline;
        color = AppColors.rose;
        icon = Icons.cloud_off_rounded;
        showSpinner = false;
      case _TrackingLiveStatus.noPosition:
        label = l10n.noLivePosition;
        color = AppColors.textMutedOf(context);
        icon = Icons.gps_off_rounded;
        showSpinner = false;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showSpinner)
            SizedBox(
              width: 10,
              height: 10,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
                color: color,
              ),
            )
          else
            Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom info panel
// ─────────────────────────────────────────────────────────────────────────────

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.scrollController,
    required this.vehicle,
    required this.routeAsync,
    required this.from,
    required this.to,
    required this.isToday,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onViewDetails,
    required this.onViewTrips,
    required this.onGenerateReport,
    required this.onReplayRoute,
    required this.onCommands,
    this.routeIntel,
    required this.routeIntelMemoKey,
    this.selectedTimelineItemKey,
    required this.timelineFilter,
    required this.onTimelineFilterChanged,
    required this.onTimelineItemTap,
    required this.tripSegments,
    required this.tripBehaviorScores,
    required this.dailyVehicleBehaviorScore,
    required this.onTripOpenMap,
    required this.onTripOpenReplay,
    required this.onDailyScoreDetails,
  });

  final ScrollController                 scrollController;
  final VehicleEntity?                  vehicle;
  final AsyncValue<List<RoutePoint>>    routeAsync;
  final DateTime                        from;
  final DateTime                        to;
  final bool                            isToday;
  final VoidCallback                    onPickFrom;
  final VoidCallback                    onPickTo;
  final VoidCallback                    onViewDetails;
  final VoidCallback                    onViewTrips;
  final VoidCallback                    onGenerateReport;
  final VoidCallback                    onReplayRoute;
  final VoidCallback                    onCommands;
  final RouteEventAnalysisResult?       routeIntel;
  final String                          routeIntelMemoKey;
  final String?                         selectedTimelineItemKey;
  final RouteEventTimelineFilter        timelineFilter;
  final ValueChanged<RouteEventTimelineFilter> onTimelineFilterChanged;
  final ValueChanged<RouteEventTimelineItem> onTimelineItemTap;
  final List<TripSegment>                tripSegments;
  final Map<String, DriverBehaviorScore> tripBehaviorScores;
  final DailyVehicleBehaviorScore        dailyVehicleBehaviorScore;
  final ValueChanged<TripSegment>        onTripOpenMap;
  final ValueChanged<TripSegment>        onTripOpenReplay;
  final VoidCallback                     onDailyScoreDetails;

  @override
  Widget build(BuildContext context) {
    final navBottom = MediaQuery.paddingOf(context).bottom;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20, offset: const Offset(0, -4)),
        ],
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderOf(context),
              borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(height: 2),

          Expanded(
            child: ListView(
              controller: scrollController,
              padding: EdgeInsets.fromLTRB(
                AppSpacing.cardPadding, 8,
                AppSpacing.cardPadding,
                AppSpacing.cardPadding + navBottom,
              ),
              children: [
                // ── From / To range picker ───────────────────────────────────
                _RangePickerBar(
                  from: from,
                  to: to,
                  isToday: isToday,
                  onPickFrom: onPickFrom,
                  onPickTo: onPickTo,
                ),

                const SizedBox(height: 10),

                // ── Route stats ──────────────────────────────────────────────
                _RouteStatsSection(
                  routeAsync: routeAsync,
                  routeIntel: routeIntel,
                  routeIntelMemoKey: routeIntelMemoKey,
                  selectedTimelineItemKey: selectedTimelineItemKey,
                  timelineFilter: timelineFilter,
                  onTimelineFilterChanged: onTimelineFilterChanged,
                  onTimelineItemTap: onTimelineItemTap,
                  tripSegments: tripSegments,
                  tripBehaviorScores: tripBehaviorScores,
                  dailyVehicleBehaviorScore: dailyVehicleBehaviorScore,
                  onTripOpenMap: onTripOpenMap,
                  onTripOpenReplay: onTripOpenReplay,
                  onDailyScoreDetails: onDailyScoreDetails,
                ),

                const SizedBox(height: 14),

                // ── Live vehicle stats ───────────────────────────────────────
                if (vehicle != null) _VehicleStatsRow(vehicle: vehicle!),

                const SizedBox(height: 8),

                // ── Address / position row ────────────────────────────────────
                if (vehicle != null) _VehicleAddressRow(vehicle: vehicle!),

                // ── Stale position warning ────────────────────────────────────
                if (vehicle != null)
                  _StalePositionWarning(lastUpdate: vehicle!.lastUpdate),

                const SizedBox(height: 12),

                // ── Quick Actions ─────────────────────────────────────────────
                _QuickActionsGrid(
                  onViewDetails: onViewDetails,
                  onGenerateReport: onGenerateReport,
                  onReplayRoute: onReplayRoute,
                  onViewTrips: onViewTrips,
                  onCommands: onCommands,
                ),

                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── From / To range picker bar ───────────────────────────────────────────────

class _RangePickerBar extends StatelessWidget {
  const _RangePickerBar({
    required this.from,
    required this.to,
    required this.isToday,
    required this.onPickFrom,
    required this.onPickTo,
  });

  final DateTime from;
  final DateTime to;
  final bool     isToday;
  final VoidCallback onPickFrom;
  final VoidCallback onPickTo;

  static String _fmt(DateTime dt, String langCode) {
    final now = DateTime.now();
    final isToday = dt.year == now.year && dt.month == now.month && dt.day == now.day;
    if (isToday) return DateFormat('HH:mm').format(dt);
    return DateFormat('dd MMM · HH:mm', langCode).format(dt);
  }

  Widget _chip({
    required BuildContext ctx,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: AppColors.accent.withValues(alpha: 0.3), width: 0.9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.access_time_rounded, size: 12, color: AppColors.accent),
            const SizedBox(width: 5),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: AppColors.accent.withValues(alpha: 0.7),
                        height: 1.1)),
                Text(value,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent)),
              ],
            ),
            const SizedBox(width: 4),
            const Icon(Icons.expand_more_rounded, size: 14, color: AppColors.accent),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final lang = Localizations.localeOf(context).languageCode;

    return Row(
      children: [
        _chip(
          ctx: context,
          label: l10n.fromLabel,
          value: _fmt(from, lang),
          onTap: onPickFrom,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Icon(Icons.arrow_forward_rounded,
              size: 14, color: AppColors.accent.withValues(alpha: 0.6)),
        ),
        _chip(
          ctx: context,
          label: l10n.toLabel,
          value: _fmt(to, lang),
          onTap: onPickTo,
        ),
        if (isToday) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(l10n.todayLabel,
                style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.green)),
          ),
        ],
      ],
    );
  }
}

// ── Route stats section ───────────────────────────────────────────────────────

class _RouteStatsSection extends StatelessWidget {
  const _RouteStatsSection({
    required this.routeAsync,
    this.routeIntel,
    required this.routeIntelMemoKey,
    this.selectedTimelineItemKey,
    required this.timelineFilter,
    required this.onTimelineFilterChanged,
    required this.onTimelineItemTap,
    required this.tripSegments,
    required this.tripBehaviorScores,
    required this.dailyVehicleBehaviorScore,
    required this.onTripOpenMap,
    required this.onTripOpenReplay,
    required this.onDailyScoreDetails,
  });

  final AsyncValue<List<RoutePoint>> routeAsync;
  final RouteEventAnalysisResult? routeIntel;
  final String routeIntelMemoKey;
  final String? selectedTimelineItemKey;
  final RouteEventTimelineFilter timelineFilter;
  final ValueChanged<RouteEventTimelineFilter> onTimelineFilterChanged;
  final ValueChanged<RouteEventTimelineItem> onTimelineItemTap;
  final List<TripSegment> tripSegments;
  final Map<String, DriverBehaviorScore> tripBehaviorScores;
  final DailyVehicleBehaviorScore dailyVehicleBehaviorScore;
  final ValueChanged<TripSegment> onTripOpenMap;
  final ValueChanged<TripSegment> onTripOpenReplay;
  final VoidCallback onDailyScoreDetails;

  static double _totalKm(List<RoutePoint> pts) {
    if (pts.length < 2) return 0;
    double d = 0;
    for (var i = 1; i < pts.length; i++) {
      d += MapHelper.distanceMeters(pts[i - 1].position, pts[i].position);
    }
    return d / 1000;
  }

  static Duration _duration(List<RoutePoint> pts) {
    if (pts.length < 2) return Duration.zero;
    return pts.last.fixTime.difference(pts.first.fixTime).abs();
  }

  static String _fmtDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60);
    if (h > 0) return '${h}h ${m.toString().padLeft(2, '0')}m';
    return '${m}m';
  }

  static double _maxSpeed(List<RoutePoint> pts) {
    if (pts.isEmpty) return 0;
    return pts.map((p) => p.speed).reduce(math.max);
  }

  static double _avgSpeed(List<RoutePoint> pts) {
    if (pts.isEmpty) return 0;
    return pts.map((p) => p.speed).reduce((a, b) => a + b) / pts.length;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return routeAsync.when(
      loading: () => const SizedBox(
        height: 48,
        child: Center(
          child: SizedBox.square(
            dimension: 18,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: AppColors.accent),
          ),
        ),
      ),
      error: (_, __) => _EmptyRouteCard(message: l10n.noRouteForDate),
      data: (pts) {
        if (pts.isEmpty) return _EmptyRouteCard(message: l10n.noRouteForDate);

        final km  = _totalKm(pts);
        final dur = _duration(pts);
        final max = _maxSpeed(pts);
        final avg = _avgSpeed(pts);
        final intelLine = formatRouteIntelSummaryLine(routeIntel, l10n);

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                _RouteStat(
                  icon: Icons.straighten_rounded,
                  value: '${km.toStringAsFixed(1)} km',
                  label: l10n.routeDistanceKm('').replaceAll(':', '').trim(),
                  color: AppColors.accent,
                ),
                _RouteStat(
                  icon: Icons.timer_outlined,
                  value: _fmtDuration(dur),
                  label: l10n.durationLabel,
                  color: AppColors.purple,
                ),
                _RouteStat(
                  icon: Icons.speed_rounded,
                  value: FormatUtils.speed(max),
                  label: l10n.maxSpeedLabel,
                  color: AppColors.error,
                ),
                _RouteStat(
                  icon: Icons.av_timer_rounded,
                  value: FormatUtils.speed(avg),
                  label: l10n.avgSpeedLabel,
                  color: AppColors.success,
                ),
                _RouteStat(
                  icon: Icons.location_on_outlined,
                  value: '${pts.length}',
                  label: 'pts',
                  color: AppColors.textSecondaryOf(context),
                ),
              ],
            ),
            if (intelLine != null) ...[
              const SizedBox(height: 6),
              Text(
                intelLine,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10,
                  height: 1.25,
                  color: AppColors.textSecondaryOf(context),
                ),
              ),
            ],
            if (pts.length >= 2) ...[
              const SizedBox(height: 10),
              RouteEventTimeline(
                analysisKey: routeIntelMemoKey,
                analysis: routeIntel,
                compact: true,
                reportStyle: false,
                showEmptyState: true,
                collapsedItemLimit: 8,
                selectedItemKey: selectedTimelineItemKey,
                filter: timelineFilter,
                onFilterChanged: onTimelineFilterChanged,
                onItemTap: onTimelineItemTap,
              ),
            ],
            if (pts.isNotEmpty) ...[
              const SizedBox(height: 12),
              DailyVehicleBehaviorScoreCard(
                dailyScore: dailyVehicleBehaviorScore,
                onTap: onDailyScoreDetails,
              ),
              const SizedBox(height: 12),
              TripsListSection(
                trips: tripSegments,
                scoresByTripKey: tripBehaviorScores,
                onOpenMap: onTripOpenMap,
                onOpenReplay: onTripOpenReplay,
              ),
            ],
          ],
        );
      },
    );
  }
}

class _RouteStat extends StatelessWidget {
  const _RouteStat({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String   value;
  final String   label;
  final Color    color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
            Text(
              label,
              style: TextStyle(
                  fontSize: 8,
                  color: AppColors.textMutedOf(context),
                  fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyRouteCard extends StatelessWidget {
  const _EmptyRouteCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.textMutedOf(context).withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: AppColors.borderOf(context).withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.route_rounded,
              size: 14, color: AppColors.textMutedOf(context)),
          const SizedBox(width: 8),
          Text(
            message,
            style: TextStyle(
                fontSize: 12,
                color: AppColors.textSecondaryOf(context),
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

// ── Live vehicle stats row ────────────────────────────────────────────────────

class _VehicleStatsRow extends StatelessWidget {
  const _VehicleStatsRow({required this.vehicle});
  final VehicleEntity vehicle;

  @override
  Widget build(BuildContext context) {
    final l10n      = context.l10n;
    final lastUpdate = vehicle.lastUpdate;
    final timeStr    = lastUpdate != null
        ? DateFormatter.toRelative(lastUpdate)
        : l10n.locationUnavailable;

    final Color lastUpdateColor;
    if (lastUpdate == null) {
      lastUpdateColor = AppColors.textMutedOf(context);
    } else {
      final age = DateTime.now().difference(lastUpdate);
      if (age >= const Duration(minutes: 60)) {
        lastUpdateColor = AppColors.error;
      } else if (age >= const Duration(minutes: 15)) {
        lastUpdateColor = AppColors.amber;
      } else {
        lastUpdateColor = AppColors.textSecondaryOf(context);
      }
    }

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.speed_rounded,
            value: FormatUtils.speed(vehicle.speed),
            label: l10n.speedLabel,
            color: vehicle.isMoving
                ? AppColors.success
                : AppColors.textSecondaryOf(context),
          ),
        ),
        Expanded(
          child: _StatTile(
            icon: vehicle.ignition
                ? Icons.power_rounded
                : Icons.power_off_rounded,
            value: vehicle.ignition
                ? l10n.ignitionOnLabel
                : l10n.ignitionOffLabel,
            label: l10n.engineLabel,
            color: vehicle.ignition ? AppColors.success : AppColors.error,
          ),
        ),
        Expanded(
          child: _StatTile(
            icon: Icons.update_rounded,
            value: timeStr,
            label: l10n.lastUpdateLabel,
            color: lastUpdateColor,
          ),
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String   value;
  final String   label;
  final Color    color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 3),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
                fontSize: 10,
                color: AppColors.textSecondaryOf(context)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Control button
// ─────────────────────────────────────────────────────────────────────────────

class _ControlBtn extends StatelessWidget {
  const _ControlBtn({
    required this.icon,
    required this.onTap,
    this.label,
    this.isActive = false,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String? label;
  final bool    isActive;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.accent.withValues(alpha: 0.15)
              : AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isActive ? AppColors.accent : AppColors.borderOf(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18,
                color: isActive
                    ? AppColors.accent
                    : AppColors.textSecondaryOf(context)),
            if (label != null) ...[
              const SizedBox(height: 2),
              Text(label!,
                  style: TextStyle(
                    fontSize: 8,
                    color: isActive
                        ? AppColors.accent
                        : AppColors.textSecondaryOf(context),
                  )),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Error banner
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String       message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border:
            Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded, size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(fontSize: 12, color: AppColors.error)),
          ),
          TextButton(
            onPressed: onRetry,
            child: Text(context.l10n.retry,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// No position banner
// ─────────────────────────────────────────────────────────────────────────────

class _NoPositionBanner extends StatelessWidget {
  const _NoPositionBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.amber.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.amber.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.gps_off_rounded,
              size: 16, color: AppColors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(fontSize: 12, color: AppColors.amber)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vehicle address row
// ─────────────────────────────────────────────────────────────────────────────

class _VehicleAddressRow extends StatelessWidget {
  const _VehicleAddressRow({required this.vehicle});
  final VehicleEntity vehicle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final address = vehicle.address?.trim();
    final hasAddress = address != null && address.isNotEmpty;
    final hasCoords = vehicle.latitude != 0 || vehicle.longitude != 0;

    final String displayText;
    final IconData icon;
    final Color iconColor;

    if (hasAddress) {
      displayText = address;
      icon = Icons.location_on_rounded;
      iconColor = AppColors.accent;
    } else if (hasCoords) {
      displayText =
          '${vehicle.latitude.toStringAsFixed(5)}, '
          '${vehicle.longitude.toStringAsFixed(5)}';
      icon = Icons.gps_fixed_rounded;
      iconColor = AppColors.textSecondaryOf(context);
    } else {
      displayText = l10n.locationUnavailable;
      icon = Icons.location_off_rounded;
      iconColor = AppColors.textMutedOf(context);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: iconColor),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              displayText,
              style: TextStyle(
                fontSize: 11,
                color: hasAddress
                    ? AppColors.textPrimaryOf(context)
                    : AppColors.textSecondaryOf(context),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Actions Grid
// ─────────────────────────────────────────────────────────────────────────────

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid({
    required this.onViewDetails,
    required this.onGenerateReport,
    required this.onReplayRoute,
    required this.onViewTrips,
    required this.onCommands,
  });

  final VoidCallback onViewDetails;
  final VoidCallback onGenerateReport;
  final VoidCallback onReplayRoute;
  final VoidCallback onViewTrips;
  final VoidCallback onCommands;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    final actions = <_QuickActionDef>[
      _QuickActionDef(
        icon: Icons.info_outline_rounded,
        label: l10n.vehicleDetails,
        color: AppColors.accent,
        onTap: onViewDetails,
      ),
      _QuickActionDef(
        icon: Icons.summarize_outlined,
        label: l10n.generateVehicleReport,
        color: AppColors.emerald,
        onTap: onGenerateReport,
      ),
      _QuickActionDef(
        icon: Icons.replay_rounded,
        label: l10n.replayRoute,
        color: AppColors.purple,
        onTap: onReplayRoute,
      ),
      _QuickActionDef(
        icon: Icons.history_rounded,
        label: l10n.tripHistory,
        color: AppColors.info,
        onTap: onViewTrips,
      ),
      _QuickActionDef(
        icon: Icons.settings_remote_rounded,
        label: l10n.commandsTitle,
        color: AppColors.amber,
        onTap: onCommands,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.quickActions,
          style: AppTextStyles.labelMedium.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 72,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: actions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (_, i) {
              final a = actions[i];
              return _QuickActionButton(
                icon: a.icon,
                label: a.label,
                color: a.color,
                onTap: a.onTap,
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuickActionDef {
  const _QuickActionDef({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 76,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: color.withValues(alpha: 0.2),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(height: 6),
              Text(
                label,
                style: AppTextStyles.bodySmall.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimaryOf(context),
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Stale position warning
// ─────────────────────────────────────────────────────────────────────────────

enum _StalenessLevel { fresh, stale, old, none }

class _StalePositionWarning extends StatelessWidget {
  const _StalePositionWarning({required this.lastUpdate});
  final DateTime? lastUpdate;

  static const _staleThreshold = Duration(minutes: 15);
  static const _oldThreshold = Duration(minutes: 60);

  _StalenessLevel get _level {
    if (lastUpdate == null) return _StalenessLevel.none;
    final age = DateTime.now().difference(lastUpdate!);
    if (age >= _oldThreshold) return _StalenessLevel.old;
    if (age >= _staleThreshold) return _StalenessLevel.stale;
    return _StalenessLevel.fresh;
  }

  @override
  Widget build(BuildContext context) {
    final level = _level;
    if (level == _StalenessLevel.fresh) return const SizedBox.shrink();

    final l10n = context.l10n;

    final String text;
    final Color color;
    final IconData icon;

    switch (level) {
      case _StalenessLevel.none:
        text = l10n.noLivePosition;
        color = AppColors.textMutedOf(context);
        icon = Icons.gps_off_rounded;
      case _StalenessLevel.stale:
        text = l10n.positionMayBeOutdated;
        color = AppColors.amber;
        icon = Icons.access_time_rounded;
      case _StalenessLevel.old:
        text = l10n.lastPositionIsOld;
        color = AppColors.error;
        icon = Icons.warning_amber_rounded;
      case _StalenessLevel.fresh:
        return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
