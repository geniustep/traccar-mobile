import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/maps/map_config.dart';
import '../../../../core/maps/map_helper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../map/data/datasources/route_datasource.dart';
import '../../../map/core/map_zoom_policy.dart';
import '../../../map/core/route_event_analyzer.dart';
import '../../../map/core/route_event_models.dart';
import '../../../map/core/route_event_timeline_models.dart';
import '../../../map/core/route_event_ui.dart';
import '../../../map/core/route_intelligence_thresholds.dart';
import '../../../map/core/route_polyline_builder.dart';
import '../../core/replay_route_gap.dart';
import '../widgets/replay_gaps_sheet.dart';
import '../../../map/core/route_stop_address_enrichment.dart';
import '../../../map/presentation/widgets/route_event_details_sheet.dart';
import '../../../map/presentation/widgets/route_event_timeline.dart';
import '../../../map/core/vehicle_marker_factory.dart';
import '../../../map/presentation/providers/route_intelligence_thresholds_provider.dart';
import '../../../map/presentation/providers/route_stop_address_providers.dart';
import '../providers/replay_controller.dart';
import '../providers/reports_providers.dart';
import '../widgets/speed_chart.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ReplayReportScreen
// ─────────────────────────────────────────────────────────────────────────────

class ReplayReportScreen extends ConsumerStatefulWidget {
  const ReplayReportScreen({
    super.key,
    required this.params,
    required this.vehicleName,
  });

  final ReportFilterParams params;
  final String vehicleName;

  @override
  ConsumerState<ReplayReportScreen> createState() =>
      _ReplayReportScreenState();
}

class _ReplayReportScreenState extends ConsumerState<ReplayReportScreen> {
  GoogleMapController? _mapController;
  bool _hasFitted = false;
  bool _mapReady = false;

  double _cameraZoom = MapConfig.defaultZoom;

  // UI state — managed locally, no provider needed.
  bool _followVehicle = true;
  bool _showMiniChart = false;

  // Fixed markers (start / end) — computed once.
  Set<Marker> _baseMarkers = {};

  /// Route intelligence (stops / overspeed / ignition) — rebuilt on zoom only;
  /// analysis memo: length + first/last fix + [RouteIntelligenceThresholds.cacheKey].
  String _replayIntelKey = '';
  RouteEventAnalysisResult? _replayIntel;
  Set<Marker> _intelMarkers = {};

  /// Phase 7C: shared highlight for timeline row + intelligence marker.
  String? _selectedRouteEventKey;

  /// Phase 7E: timeline filter (display only).
  RouteEventTimelineFilter _replayTimelineFilter = RouteEventTimelineFilter.all;

  // Vehicle marker — cheaply updated on each tick.
  Marker? _vehicleMarker;

  // Polylines — decimated, computed once.
  Set<Polyline> _polylines = {};

  /// Phase R1 — gaps on full route (not replay subsample).
  List<ReplayRouteGap> _replayGaps = [];
  List<RouteEventTimelineItem> _replayGapTimelineItems = [];
  Set<Marker> _gapMarkers = {};

  // All raw route points — kept for chart stats + start/end markers.
  List<RoutePoint> _allPoints = [];

  // Custom car icons — built asynchronously, cached by speed band.
  BitmapDescriptor? _iconSlow;   // < 5 km/h  grey
  BitmapDescriptor? _iconUrban;  // 5–40      green
  BitmapDescriptor? _iconRoad;   // 40–80     orange
  BitmapDescriptor? _iconFast;   // 80+       red
  bool _iconsReady = false;

  // Guards against duplicate initialisation when build() fires many times.
  bool _initStarted = false;

  // ── Lifecycle ────────────────────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadIcons();
    // If route data is already cached, initialise on the first frame.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final snap = ref.read(reportRouteProvider(widget.params));
      snap.whenData((pts) {
        if (pts.isNotEmpty) _initRoute(pts);
      });
    });
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant ReplayReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params != widget.params) {
      ref.read(replayControllerProvider.notifier).pause();
      _initStarted = false;
      _hasFitted = false;
      _replayIntelKey = '';
      _replayIntel = null;
      _intelMarkers = {};
      _baseMarkers = {};
      _polylines = {};
      _replayGaps = [];
      _replayGapTimelineItems = [];
      _gapMarkers = {};
      _vehicleMarker = null;
      _allPoints = [];
      _cameraZoom = MapConfig.defaultZoom;
      _selectedRouteEventKey = null;
      _replayTimelineFilter = RouteEventTimelineFilter.all;
    }
  }

  /// Memoized route intelligence — full [RoutePoint] list from report (not replay subsample).
  /// Returns true if analysis result changed (need intel marker rebuild outside full init).
  bool _syncReplayIntel(List<RoutePoint> pts, RouteIntelligenceThresholds th) {
    final key = pts.length < 2
        ? '0'
        : '${pts.length}_${pts.first.fixTime.millisecondsSinceEpoch}_${pts.last.fixTime.millisecondsSinceEpoch}_${th.cacheKey}';
    if (key == _replayIntelKey) return false;
    _selectedRouteEventKey = null;
    _replayTimelineFilter = RouteEventTimelineFilter.all;
    _replayIntelKey = key;
    final raw = pts.length < 2
        ? null
        : RouteEventAnalyzer.analyze(pts, thresholds: th);
    _replayIntel =
        raw == null ? null : enrichRouteIntelStopsFromRoutePoints(raw, pts);
    return true;
  }

  void _rebuildReplayIntelMarkers() {
    final intel = _replayIntel;
    if (intel == null) {
      _intelMarkers = {};
      return;
    }
    final l10n = AppLocalizations.of(context);
    _intelMarkers = RoutePolylineBuilder.buildRouteIntelligenceMarkers(
      analysis: intel,
      l10n: l10n,
      policy: MapZoomPolicy.at(_cameraZoom),
      reportStyle: true,
      vehicleId: widget.params.vehicleId,
      onMarkerTap: _onReplayRouteIntelMarkerTap,
      selectedEventKey: _selectedRouteEventKey,
    );
  }

  void _scheduleReplayStopAddressPrefetch() {
    final k = _replayIntelKey;
    final cur = _replayIntel;
    if (cur == null || cur.stops.isEmpty) return;
    final resolver = ref.read(routeStopAddressResolverProvider);
    prefetchStopAddressesSequential(
      resolver: resolver,
      intel: cur,
      isStale: () => !mounted || _replayIntelKey != k,
      apply: (u) {
        if (!mounted || _replayIntelKey != k) return;
        setState(() {
          _replayIntel = u;
          _rebuildReplayIntelMarkers();
        });
      },
    );
  }

  void _applyReplayResolvedStopAddress(String selectionKey, String address) {
    final intel = _replayIntel;
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
      _replayIntel = intel.withStops(
        replaceStopAddressOnList(intel.stops, target!, address),
      );
      _rebuildReplayIntelMarkers();
    });
  }

  /// Rebuild intelligence markers only (same analysis; zoom / policy changed).
  void _onResolvedMapZoom(double z) {
    if (!mounted) return;
    final prev = _cameraZoom;
    _cameraZoom = z;
    if (_replayIntel == null) return;
    if ((z - prev).abs() <= 0.02) return;

    setState(() {
      _rebuildReplayIntelMarkers();
    });
  }

  // ── Route init (runs exactly once) ──────────────────────────────────────────

  /// Entry point called whenever route data arrives (cache or network).
  /// The `_initStarted` flag ensures it is executed at most once per session.
  void _initRoute(List<RoutePoint> pts) {
    if (_initStarted || pts.isEmpty || !mounted) return;
    _initStarted = true;

    ref.read(replayControllerProvider.notifier).loadPoints(pts);
    final replayPts = ref.read(replayControllerProvider).points;
    final th = ref.read(
      routeIntelligenceThresholdsForVehicleProvider(widget.params.vehicleId),
    );
    _initMapData(pts, replayPts, th);
  }

  // ── Custom marker icons ──────────────────────────────────────────────────────

  Future<void> _loadIcons() async {
    final results = await Future.wait([
      VehicleMarkerFactory.topDownCarNorthUpForReplaySpeed(2, size: 56),
      VehicleMarkerFactory.topDownCarNorthUpForReplaySpeed(25, size: 56),
      VehicleMarkerFactory.topDownCarNorthUpForReplaySpeed(55, size: 56),
      VehicleMarkerFactory.topDownCarNorthUpForReplaySpeed(95, size: 56),
    ]);
    if (!mounted) return;
    setState(() {
      _iconSlow = results[0];
      _iconUrban = results[1];
      _iconRoad = results[2];
      _iconFast = results[3];
      _iconsReady = true;
      // Refresh the vehicle marker with the proper icon now that it is ready.
      final idx = ref.read(replayControllerProvider).currentIndex;
      _refreshVehicleMarker(idx);
    });
  }

  BitmapDescriptor _iconForSpeed(double speedKmh) {
    if (!_iconsReady) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);
    }
    if (speedKmh < 5)  return _iconSlow!;
    if (speedKmh < 40) return _iconUrban!;
    if (speedKmh < 80) return _iconRoad!;
    return _iconFast!;
  }

  // ── Map helpers ──────────────────────────────────────────────────────────────

  void _fitRoute(List<RoutePoint> pts) {
    if (pts.isEmpty || _mapController == null) return;
    final update =
        MapHelper.fitPoints(pts.map((p) => p.position).toList(), padding: 80);
    if (update != null) {
      _mapController!.animateCamera(update);
      _hasFitted = true;
    }
  }

  Marker _makeVehicleMarker(RoutePoint pt) => Marker(
        markerId: const MarkerId('replay_vehicle'),
        position: pt.position,
        icon: _iconForSpeed(pt.speed),
        anchor: const Offset(0.5, 0.5),
        flat: true,
        rotation: pt.course,
        zIndexInt: 10,
        infoWindow: InfoWindow(
          title: FormatUtils.speed(pt.speed),
          snippet: DateFormat('HH:mm:ss').format(pt.fixTime),
        ),
      );

  Set<Marker> _buildBaseMarkers(List<RoutePoint> pts) {
    if (pts.isEmpty) return {};
    final m = <Marker>{};
    m.add(Marker(
      markerId: const MarkerId('replay_start'),
      position: pts.first.position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      anchor: const Offset(0.5, 1.0),
      zIndexInt: 3,
      infoWindow: InfoWindow(
        title: context.l10n.routeDeparture,
        snippet: DateFormat('HH:mm').format(pts.first.fixTime),
      ),
    ));
    if (pts.length > 1) {
      m.add(Marker(
        markerId: const MarkerId('replay_end'),
        position: pts.last.position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        anchor: const Offset(0.5, 1.0),
        zIndexInt: 3,
        infoWindow: InfoWindow(
          title: context.l10n.routeArrival,
          snippet: DateFormat('HH:mm').format(pts.last.fixTime),
        ),
      ));
    }
    return m;
  }

  void _rebuildReplayGapMarkers() {
    if (_replayGaps.isEmpty) {
      _gapMarkers = {};
      return;
    }
    final l10n = AppLocalizations.of(context);
    _gapMarkers = RoutePolylineBuilder.buildReplayGapMarkers(
      gaps: _replayGaps,
      l10n: l10n,
      vehicleId: widget.params.vehicleId,
      onMarkerTap: _onReplayTimelineTap,
      selectedEventKey: _selectedRouteEventKey,
    );
  }

  void _initMapData(
    List<RoutePoint> allPts,
    List<RoutePoint> replayPts,
    RouteIntelligenceThresholds th,
  ) {
    if (!mounted) return;
    _syncReplayIntel(allPts, th);

    final gaps = ReplayRouteGapDetector.detectGaps(allPts);
    final maxGap = ReplayRouteGapDetector.maxGapDuration(gaps);
    AppLogger.replay(
      'replay_route_loaded points=${allPts.length} gaps=${gaps.length} '
      'maxGapMin=${maxGap.inMinutes} thresholdMin=${replayGapThreshold.inMinutes}',
    );

    final l10n = AppLocalizations.of(context);
    final gapTimeline = buildReplayGapTimelineItems(gaps, l10n);

    final base = _buildBaseMarkers(allPts);
    final polys = RoutePolylineBuilder.buildReplaySpeedColoredPolylinesRespectingGaps(
      allPoints: allPts,
      gaps: gaps,
    );
    final vm = replayPts.isNotEmpty ? _makeVehicleMarker(replayPts.first) : null;

    setState(() {
      _allPoints = allPts;
      _replayGaps = gaps;
      _replayGapTimelineItems = gapTimeline;
      _baseMarkers = base;
      _polylines = polys;
      _vehicleMarker = vm;
      _rebuildReplayIntelMarkers();
      _rebuildReplayGapMarkers();
    });

    _scheduleReplayStopAddressPrefetch();

    if (!_hasFitted && _mapReady) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) => _fitRoute(allPts));
    }
  }

  /// BUG FIX: only updates the vehicle marker object (cheap setState).
  /// Parent does NOT watch currentPoint, so only this method triggers rebuild.
  void _refreshVehicleMarker(int index) {
    final pts = ref.read(replayControllerProvider).points;
    if (pts.isEmpty || index >= pts.length) return;
    final pt = pts[index];
    setState(() {
      _vehicleMarker = _makeVehicleMarker(pt);
    });
    // Instant camera move avoids animation lag at x4/x8.
    if (_followVehicle && ref.read(replayControllerProvider).isPlaying) {
      _mapController?.moveCamera(CameraUpdate.newLatLng(pt.position));
    }
  }

  /// Zoom + seek replay to timeline event; disables vehicle follow until re-enabled.
  void _onReplayTimelineTap(RouteEventTimelineItem item) {
    if (!routeEventTimelineValidPosition(item.position)) return;
    setState(() {
      _followVehicle = false;
      _selectedRouteEventKey = item.selectionKey;
      _rebuildReplayIntelMarkers();
      _rebuildReplayGapMarkers();
    });

    final pts = ref.read(replayControllerProvider).points;
    if (pts.isNotEmpty) {
      final seekTime = item.kind == RouteTimelineEntryKind.dataGap &&
              item.stopEndTime != null
          ? item.stopEndTime!
          : item.sortTime;
      var bestI = 0;
      var bestDelta =
          (pts[0].fixTime.difference(seekTime)).inMilliseconds.abs();
      for (var i = 1; i < pts.length; i++) {
        final d = (pts[i].fixTime.difference(seekTime)).inMilliseconds.abs();
        if (d < bestDelta) {
          bestDelta = d;
          bestI = i;
        }
      }
      ref.read(replayControllerProvider.notifier).seekTo(bestI);
    }

    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(item.position, RouteEventTimeline.focusZoomHint),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      RouteEventDetailsSheet.show(
        context,
        item: item,
        onRecenter: () {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
              item.position,
              RouteEventTimeline.focusZoomHint,
            ),
          );
        },
        resolver: ref.read(routeStopAddressResolverProvider),
        onStopAddressCommitted: _applyReplayResolvedStopAddress,
      );
    });
  }

  /// Route Intelligence marker on map: show details only; does not seek or pause replay.
  void _onReplayRouteIntelMarkerTap(RouteEventTimelineItem item) {
    if (!mounted) return;
    setState(() => _selectedRouteEventKey = item.selectionKey);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      RouteEventDetailsSheet.show(
        context,
        item: item,
        onRecenter: () {
          setState(() => _followVehicle = false);
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
              item.position,
              RouteEventTimeline.focusZoomHint,
            ),
          );
        },
        resolver: ref.read(routeStopAddressResolverProvider),
        onStopAddressCommitted: _applyReplayResolvedStopAddress,
      );
    });
  }

  void _showReplayGapsSheet() {
    if (_replayGaps.isEmpty) return;
    ReplayGapsSheet.show(
      context,
      gaps: _replayGaps,
      timelineItems: _replayGapTimelineItems,
      onGapTap: _onReplayTimelineTap,
    );
  }

  Set<Marker> get _allMarkers => {
        ..._baseMarkers,
        ..._intelMarkers,
        ..._gapMarkers,
        if (_vehicleMarker != null) _vehicleMarker!,
      };

  // ── Build ────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    final routeAsync = ref.watch(reportRouteProvider(widget.params));

    // BUG FIX: use ref.listen instead of routeAsync.whenData inside build().
    // This fires at most once when the data transitions to loaded, not on every
    // rebuild triggered by setState.
    ref.listen<AsyncValue<List<RoutePoint>>>(
      reportRouteProvider(widget.params),
      (_, next) {
        next.whenData((pts) {
          if (pts.isEmpty) {
            AppLogger.navigation(
                'ReplayScreen: route data empty for '
                'vehicleId=${widget.params.vehicleId}');
          } else if (!_initStarted) {
            AppLogger.navigation(
                'ReplayScreen: route loaded ${pts.length} points for '
                'vehicleId=${widget.params.vehicleId}');
            WidgetsBinding.instance
                .addPostFrameCallback((_) => _initRoute(pts));
          }
        });
        next.whenOrNull(
          error: (e, _) => AppLogger.error(
              'ReplayScreen',
              'route load failed for vehicleId=${widget.params.vehicleId}',
              e),
        );
      },
    );

    // BUG FIX: listen to index changes without rebuilding the full widget tree.
    // The parent does NOT watch currentPoint — only _ReplayControls does.
    ref.listen<int>(
      replayControllerProvider.select((s) => s.currentIndex),
      (_, idx) => _refreshVehicleMarker(idx),
    );

    ref.listen<RouteIntelligenceThresholds>(
      routeIntelligenceThresholdsForVehicleProvider(widget.params.vehicleId),
      (prev, next) {
        if (!_initStarted || _allPoints.length < 2) return;
        if (prev == next) return;
        if (!_syncReplayIntel(_allPoints, next)) return;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _rebuildReplayIntelMarkers();
          });
          _scheduleReplayStopAddressPrefetch();
        });
      },
    );

    final navBottom = MediaQuery.paddingOf(context).bottom;
    final routeIntelSummary =
        formatRouteIntelSummaryLine(_replayIntel, context.l10n);

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ─────────────────────────────────────────────────────────────
          routeAsync.when(
            loading: () => Center(
              child: LoadingView(message: context.l10n.loadingReplay),
            ),
            error: (_, __) => Center(
              child: _ErrorBody(
                message: context.l10n.errorLoadingReplay,
                onRetry: () =>
                    ref.invalidate(reportRouteProvider(widget.params)),
                onBack: () => context.pop(),
              ),
            ),
            data: (_) => GoogleMap(
              initialCameraPosition: MapConfig.defaultCameraPosition,
              markers: _allMarkers,
              polylines: _polylines,
              style: isDark ? MapConfig.darkStyle : MapConfig.lightStyle,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              buildingsEnabled: false,
              onMapCreated: (c) {
                _mapController = c;
                _mapReady = true;
                c.getZoomLevel().then((z) {
                  if (!mounted) return;
                  _onResolvedMapZoom(z);
                });
                if (_allPoints.isNotEmpty && !_hasFitted) {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _fitRoute(_allPoints));
                }
              },
              onCameraIdle: () {
                _mapController?.getZoomLevel().then((z) {
                  if (!mounted) return;
                  _onResolvedMapZoom(z);
                });
              },
            ),
          ),

          // ── Top bar ──────────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: _TopBar(
                vehicleName: widget.vehicleName,
                from: widget.params.from.toLocal(),
                to: widget.params.to.toLocal(),
                onBack: () {
                  ref.read(replayControllerProvider.notifier).pause();
                  context.pop();
                },
                onFit: () => _fitRoute(_allPoints),
              ),
            ),
          ),

          // ── Empty state overlay ────────────────────────────────────────────
          if (routeAsync.hasValue && routeAsync.value!.isEmpty)
            Center(
              child: _EmptyRouteBody(
                message: context.l10n.noReplayDataForPeriod,
                onBack: () => context.pop(),
              ),
            ),

          // ── Speed legend ─────────────────────────────────────────────────────
          if (_polylines.isNotEmpty)
            Positioned(
              left: AppSpacing.screenPadding,
              bottom: _basePanelHeight +
                  navBottom +
                  (_showMiniChart ? _chartPanelHeight : 0) +
                  16,
              child: const _SpeedLegend(),
            ),

          // ── Zoom controls ────────────────────────────────────────────────────
          Positioned(
            right: AppSpacing.screenPadding,
            bottom: _basePanelHeight +
                navBottom +
                (_showMiniChart ? _chartPanelHeight : 0) +
                16,
            child: Column(
              children: [
                _MapBtn(
                  icon: Icons.add_rounded,
                  onTap: () =>
                      _mapController?.animateCamera(CameraUpdate.zoomIn()),
                ),
                const SizedBox(height: 4),
                _MapBtn(
                  icon: Icons.remove_rounded,
                  onTap: () =>
                      _mapController?.animateCamera(CameraUpdate.zoomOut()),
                ),
              ],
            ),
          ),

          // ── Controls panel ────────────────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _ReplayControls(
              navBottom: navBottom,
              followVehicle: _followVehicle,
              showMiniChart: _showMiniChart,
              allPoints: _allPoints,
              replayGapCount: _replayGaps.length,
              onReplayGapsTap: _showReplayGapsSheet,
              routeIntelSummary: routeIntelSummary,
              routeIntelKey: _replayIntelKey,
              routeIntel: _replayIntel,
              replayGapTimelineItems: _replayGapTimelineItems,
              selectedTimelineItemKey: _selectedRouteEventKey,
              timelineFilter: _replayTimelineFilter,
              onTimelineFilterChanged: (f) =>
                  setState(() => _replayTimelineFilter = f),
              onTimelineItemTap: _onReplayTimelineTap,
              onFollowToggle: () =>
                  setState(() => _followVehicle = !_followVehicle),
              onChartToggle: () =>
                  setState(() => _showMiniChart = !_showMiniChart),
            ),
          ),
        ],
      ),
    );
  }
}

// Heights used to position overlay elements above the bottom panel.
const double _basePanelHeight = 336;
const double _chartPanelHeight  = 180;

// ─────────────────────────────────────────────────────────────────────────────
// _ReplayControls — separate ConsumerWidget so only it rebuilds on tick,
// NOT the parent (which would rebuild the GoogleMap unnecessarily).
// ─────────────────────────────────────────────────────────────────────────────

class _ReplayControls extends ConsumerWidget {
  const _ReplayControls({
    required this.navBottom,
    required this.followVehicle,
    required this.showMiniChart,
    required this.allPoints,
    required this.replayGapCount,
    required this.onReplayGapsTap,
    this.routeIntelSummary,
    required this.routeIntelKey,
    this.routeIntel,
    this.replayGapTimelineItems = const [],
    this.selectedTimelineItemKey,
    required this.timelineFilter,
    required this.onTimelineFilterChanged,
    required this.onTimelineItemTap,
    required this.onFollowToggle,
    required this.onChartToggle,
  });

  final double navBottom;
  final bool followVehicle;
  final bool showMiniChart;
  final List<RoutePoint> allPoints;
  final int replayGapCount;
  final VoidCallback onReplayGapsTap;
  final String? routeIntelSummary;
  final String routeIntelKey;
  final RouteEventAnalysisResult? routeIntel;
  final List<RouteEventTimelineItem> replayGapTimelineItems;
  final String? selectedTimelineItemKey;
  final RouteEventTimelineFilter timelineFilter;
  final ValueChanged<RouteEventTimelineFilter> onTimelineFilterChanged;
  final ValueChanged<RouteEventTimelineItem> onTimelineItemTap;
  final VoidCallback onFollowToggle;
  final VoidCallback onChartToggle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(replayControllerProvider);
    final l10n  = context.l10n;

    if (!state.hasData) return const SizedBox.shrink();

    final pt       = state.currentPoint;
    final timeStr  = pt != null ? DateFormat('HH:mm:ss').format(pt.fixTime) : '--:--:--';
    final speedStr = pt != null ? FormatUtils.speed(pt.speed) : '-- km/h';
    final progress = (state.progress * 100).toStringAsFixed(0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderOf(context),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Mini speed chart (expandable) ────────────────────────────────
          // BUG FIX: currentPoint is read from local `state`, not from parent.
          AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            height: showMiniChart && allPoints.length >= 2
                ? _chartPanelHeight
                : 0.0,
            child: showMiniChart && allPoints.length >= 2
                ? ClipRect(
                    child: SpeedChartWidget(
                      points: allPoints,
                      highlightTime: state.currentPoint?.fixTime,
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(16, 8, 16, 8 + navBottom),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Info row ─────────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _InfoChip(
                      icon: Icons.schedule_rounded,
                      label: l10n.replayCurrentTime,
                      value: timeStr,
                      color: AppColors.accent,
                    ),
                    _InfoChip(
                      icon: Icons.speed_rounded,
                      label: l10n.replayCurrentSpeed,
                      value: speedStr,
                      color: AppColors.emerald,
                    ),
                    _InfoChip(
                      icon: Icons.linear_scale_rounded,
                      label: l10n.replayProgress,
                      value: '$progress%',
                      color: AppColors.purple,
                    ),
                  ],
                ),
                const SizedBox(height: 6),

                if (routeIntelSummary != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      routeIntelSummary!,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontSize: 10,
                        color: AppColors.textSecondaryOf(context),
                      ),
                    ),
                  ),

                if (replayGapCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Align(
                      child: Material(
                        color: AppColors.surfaceElevatedOf(context),
                        borderRadius: BorderRadius.circular(8),
                        child: InkWell(
                          onTap: onReplayGapsTap,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.signal_cellular_connected_no_internet_0_bar_rounded,
                                  size: 14,
                                  color: AppColors.textSecondaryOf(context),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  l10n.replayGapsDetected(replayGapCount),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.textSecondaryOf(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                if (allPoints.length >= 2) ...[
                  const SizedBox(height: 6),
                  RepaintBoundary(
                    child: RouteEventTimeline(
                      analysisKey: routeIntelKey,
                      analysis: routeIntel,
                      supplementalTimelineItems: replayGapTimelineItems,
                      compact: true,
                      reportStyle: true,
                      showEmptyState: true,
                      collapsedItemLimit: 4,
                      listHeightOverride: 120,
                      selectedItemKey: selectedTimelineItemKey,
                      filter: timelineFilter,
                      onFilterChanged: onTimelineFilterChanged,
                      onItemTap: onTimelineItemTap,
                    ),
                  ),
                ],

                // ── Completion banner ────────────────────────────────────────
                if (state.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    margin: const EdgeInsets.only(bottom: 4),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: AppColors.success.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded,
                            size: 14, color: AppColors.success),
                        const SizedBox(width: 6),
                        Text(l10n.routeCompleted,
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.success,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),

                // ── Slider ───────────────────────────────────────────────────
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(
                    trackHeight: 3,
                    activeTrackColor: AppColors.accent,
                    inactiveTrackColor:
                        AppColors.accent.withValues(alpha: 0.2),
                    thumbColor: AppColors.accent,
                    overlayColor: AppColors.accent.withValues(alpha: 0.15),
                  ),
                  child: Slider(
                    value: state.currentIndex.toDouble(),
                    min: 0,
                    max: (state.points.length - 1).toDouble(),
                    onChanged: (v) => ref
                        .read(replayControllerProvider.notifier)
                        .seekTo(v.round()),
                  ),
                ),

                // ── Buttons row ──────────────────────────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Restart
                    _ControlBtn(
                      icon: Icons.replay_rounded,
                      tooltip: l10n.replayRestart,
                      onTap: () => ref
                          .read(replayControllerProvider.notifier)
                          .restart(),
                    ),
                    const SizedBox(width: 6),

                    // Play / Pause
                    GestureDetector(
                      onTap: () {
                        final n =
                            ref.read(replayControllerProvider.notifier);
                        state.isPlaying ? n.pause() : n.play();
                      },
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: AppColors.accent,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color:
                                  AppColors.accent.withValues(alpha: 0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          state.isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),

                    // Follow toggle
                    _ControlBtn(
                      icon: followVehicle
                          ? Icons.gps_fixed_rounded
                          : Icons.gps_not_fixed_rounded,
                      tooltip: followVehicle
                          ? l10n.followLabel
                          : l10n.freeLabel,
                      active: followVehicle,
                      onTap: onFollowToggle,
                    ),
                    const SizedBox(width: 6),

                    // Chart toggle
                    _ControlBtn(
                      icon: Icons.show_chart_rounded,
                      tooltip: l10n.speedChartTitle,
                      active: showMiniChart,
                      onTap: onChartToggle,
                    ),
                    const SizedBox(width: 8),

                    // Playback speed selector
                    _SpeedSelector(current: state.playbackSpeed),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SpeedSelector
// ─────────────────────────────────────────────────────────────────────────────

class _SpeedSelector extends ConsumerWidget {
  const _SpeedSelector({required this.current});
  final PlaybackSpeed current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: PlaybackSpeed.values.map((s) {
        final active = s == current;
        return GestureDetector(
          onTap: () => ref
              .read(replayControllerProvider.notifier)
              .setPlaybackSpeed(s),
          child: Container(
            margin: const EdgeInsets.only(left: 4),
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: active
                  ? AppColors.accent
                  : AppColors.surfaceElevatedOf(context),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: active
                    ? AppColors.accent
                    : AppColors.borderOf(context),
              ),
            ),
            child: Text(
              s.label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: active
                    ? Colors.white
                    : AppColors.textSecondaryOf(context),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _InfoChip
// ─────────────────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800, color: color),
          ),
          Text(
            label,
            style: TextStyle(
                fontSize: 9, color: AppColors.textMutedOf(context)),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ControlBtn
// ─────────────────────────────────────────────────────────────────────────────

class _ControlBtn extends StatelessWidget {
  const _ControlBtn({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.active = false,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final bool active;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: active
                ? AppColors.accent.withValues(alpha: 0.15)
                : AppColors.surfaceElevatedOf(context),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: active
                  ? AppColors.accent.withValues(alpha: 0.5)
                  : AppColors.borderOf(context),
            ),
          ),
          child: Icon(
            icon,
            size: 19,
            color: active
                ? AppColors.accent
                : AppColors.textSecondaryOf(context),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TopBar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.vehicleName,
    required this.from,
    required this.to,
    required this.onBack,
    required this.onFit,
  });

  final String vehicleName;
  final DateTime from;
  final DateTime to;
  final VoidCallback onBack;
  final VoidCallback onFit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceOf(context).withValues(alpha: 0.95),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderOf(context)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(vehicleName, style: AppTextStyles.labelLarge),
                Text(
                  '${DateFormatter.toDate(from)} → ${DateFormatter.toDate(to)}',
                  style: AppTextStyles.bodySmall.copyWith(fontSize: 10),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.play_circle_outline_rounded,
                    size: 12, color: AppColors.purple),
                const SizedBox(width: 4),
                Text(context.l10n.replayRoute,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.purple,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            icon: const Icon(Icons.fit_screen_rounded, size: 18),
            onPressed: onFit,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            color: AppColors.textSecondaryOf(context),
            tooltip: context.l10n.recentreRouteLabel,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MapBtn
// ─────────────────────────────────────────────────────────────────────────────

class _MapBtn extends StatelessWidget {
  const _MapBtn({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderOf(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon,
            size: 18, color: AppColors.textSecondaryOf(context)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SpeedLegend
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
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
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
                  width: 10,
                  height: 4,
                  decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 3),
                Text(label,
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.textSecondaryOf(context),
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyRouteBody
// ─────────────────────────────────────────────────────────────────────────────

class _EmptyRouteBody extends StatelessWidget {
  const _EmptyRouteBody({
    required this.message,
    required this.onBack,
  });

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surfaceOf(context).withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderOf(context)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.route_outlined,
                    size: 44, color: AppColors.purple),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
                const SizedBox(height: 16),
                OutlinedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: Text(context.l10n.cancel),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ErrorBody
// ─────────────────────────────────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.onRetry,
    required this.onBack,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.error),
            const SizedBox(height: 12),
            Text(message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodyMedium),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded, size: 16),
                  label: Text(context.l10n.cancel),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: Text(context.l10n.retry),
                  style: FilledButton.styleFrom(
                      backgroundColor: AppColors.accent),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
