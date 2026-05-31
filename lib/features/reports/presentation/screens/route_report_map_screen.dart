import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/maps/map_config.dart';
import '../../../../core/maps/map_helper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../map/core/map_zoom_policy.dart';
import '../../../map/core/route_event_analyzer.dart';
import '../../../map/core/route_event_models.dart';
import '../../../map/core/route_event_timeline_models.dart';
import '../../../map/core/route_event_ui.dart';
import '../../../map/core/route_intelligence_thresholds.dart';
import '../../../map/core/route_polyline_builder.dart';
import '../../../map/core/route_stop_address_enrichment.dart';
import '../../../map/data/datasources/route_datasource.dart';
import '../../../map/presentation/widgets/route_event_details_sheet.dart';
import '../../../map/presentation/widgets/route_event_timeline.dart';
import '../../../map/presentation/providers/route_intelligence_thresholds_provider.dart';
import '../../../map/presentation/providers/route_stop_address_providers.dart';
import '../../../map/core/map_audit_logger.dart';
import '../providers/reports_providers.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RouteReportMapScreen
// Displays the GPS route for a report on a full-screen map with:
// - Speed-coloured polylines
// - Start / End / Max-speed markers
// - Bottom info panel
// ─────────────────────────────────────────────────────────────────────────────

class RouteReportMapScreen extends ConsumerStatefulWidget {
  const RouteReportMapScreen({
    super.key,
    required this.params,
    required this.vehicleName,
    this.contextualSubtitle,
    this.onOpenReplayShortcut,
  });

  final ReportFilterParams params;
  final String vehicleName;

  /// Optional second line below the vehicle name (e.g. phased trip heading).
  final String? contextualSubtitle;

  /// When set (e.g. trip detail surface), exposes a Replay affordance beside the timeline.
  final VoidCallback? onOpenReplayShortcut;

  @override
  ConsumerState<RouteReportMapScreen> createState() =>
      _RouteReportMapScreenState();
}

class _RouteReportMapScreenState
    extends ConsumerState<RouteReportMapScreen> {
  GoogleMapController? _mapController;
  bool _hasFitted = false;
  double _cameraZoom = MapConfig.defaultZoom;

  String _reportIntelKey = '';
  RouteEventAnalysisResult? _reportIntel;

  /// Phase 7C: shared highlight for timeline row + intelligence marker.
  String? _selectedRouteEventKey;

  /// Phase 7E: timeline filter (display only).
  RouteEventTimelineFilter _reportTimelineFilter = RouteEventTimelineFilter.all;

  void _syncReportIntel(List<RoutePoint> pts, RouteIntelligenceThresholds th) {
    final key = pts.length < 2
        ? '0'
        : '${pts.length}_${pts.first.fixTime.millisecondsSinceEpoch}_${pts.last.fixTime.millisecondsSinceEpoch}_${th.cacheKey}';
    if (key == _reportIntelKey) return;
    _selectedRouteEventKey = null;
    _reportTimelineFilter = RouteEventTimelineFilter.all;
    _reportIntelKey = key;
    final raw = pts.length < 2
        ? null
        : RouteEventAnalyzer.analyze(pts, thresholds: th);
    _reportIntel = raw == null
        ? null
        : enrichRouteIntelStopsFromRoutePoints(raw, pts);
    if (_reportIntel != null && pts.length >= 2) {
      _scheduleReportStopAddressPrefetch();
    }
  }

  void _scheduleReportStopAddressPrefetch() {
    final k = _reportIntelKey;
    final cur = _reportIntel;
    if (cur == null || cur.stops.isEmpty) return;
    final resolver = ref.read(routeStopAddressResolverProvider);
    prefetchStopAddressesSequential(
      resolver: resolver,
      intel: cur,
      isStale: () => !mounted || _reportIntelKey != k,
      apply: (u) {
        if (!mounted || _reportIntelKey != k) return;
        setState(() => _reportIntel = u);
      },
    );
  }

  void _applyReportResolvedStopAddress(String selectionKey, String address) {
    final intel = _reportIntel;
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
      _reportIntel = intel.withStops(
        replaceStopAddressOnList(intel.stops, target!, address),
      );
    });
  }

  @override
  void initState() {
    super.initState();
    MapAuditLogger.screenOpened(
      'RouteReportMap',
      extra: 'vehicleId=${widget.params.vehicleId}',
    );
  }

  @override
  void dispose() {
    MapAuditLogger.screenDisposed('RouteReportMap', timers: 'none');
    _mapController?.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant RouteReportMapScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.params != widget.params) {
      _hasFitted = false;
      _reportIntelKey = '';
      _reportIntel = null;
      _selectedRouteEventKey = null;
      _reportTimelineFilter = RouteEventTimelineFilter.all;
    }
  }

  /// Fit camera to full route extent (uses raw points so bounds stay accurate when decimated for drawing).
  void _fitRoute(List<RoutePoint> boundsPoints) {
    if (boundsPoints.isEmpty || _mapController == null) return;
    final pts = boundsPoints
        .map((p) => p.position)
        .where(
          (ll) =>
              ll.latitude.abs() > 1e-6 || ll.longitude.abs() > 1e-6,
        )
        .toList();
    if (pts.isEmpty) return;

    if (pts.length == 1) {
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(pts.first, 15),
      );
    } else {
      final update = MapHelper.fitPoints(pts, padding: 96);
      if (update != null) {
        _mapController!.animateCamera(update);
      }
    }
    _hasFitted = true;
  }

  void _focusRouteTimelineEvent(RouteEventTimelineItem item) {
    final c = _mapController;
    if (c == null || !routeEventTimelineValidPosition(item.position)) return;
    setState(() => _selectedRouteEventKey = item.selectionKey);
    c.animateCamera(
      CameraUpdate.newLatLngZoom(
        item.position,
        RouteEventTimeline.focusZoomHint,
      ),
    );
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
      onStopAddressCommitted: _applyReportResolvedStopAddress,
    );
  }

  void _onRouteIntelMarkerTap(RouteEventTimelineItem item) {
    if (!mounted) return;
    setState(() => _selectedRouteEventKey = item.selectionKey);
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
      onStopAddressCommitted: _applyReportResolvedStopAddress,
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    final routeAsync = ref.watch(reportRouteProvider(widget.params));
    final rawPoints = routeAsync.valueOrNull ?? [];
    final riThresholds = ref.watch(
      routeIntelligenceThresholdsForVehicleProvider(widget.params.vehicleId),
    );
    _syncReportIntel(rawPoints, riThresholds);
    final zoomPolicy = MapZoomPolicy.at(_cameraZoom);
    final drawPts = RoutePolylineBuilder.decimateForMapWithMax(
      rawPoints,
      maxPoints: zoomPolicy.maxVisibleRoutePointsForDecimation(),
    );
    final l10n = AppLocalizations.of(context);

    final markers = <Marker>{
      ...RoutePolylineBuilder.buildRouteMarkers(
        drawPts,
        l10n,
        includeMaxSpeedMarker: zoomPolicy.showRouteMaxSpeedMarker(),
        compactMaxSpeedTitle: true,
      ),
      ...RoutePolylineBuilder.buildHourlyWaypoints(
        drawPts,
        enabled: zoomPolicy.showRouteHourlyMarkers(),
      ),
      ...RoutePolylineBuilder.buildRouteIntelligenceMarkers(
        analysis: _reportIntel,
        l10n: l10n,
        policy: zoomPolicy,
        reportStyle: true,
        vehicleId: widget.params.vehicleId,
        onMarkerTap: _onRouteIntelMarkerTap,
        selectedEventKey: _selectedRouteEventKey,
      ),
    };
    final polylines =
        RoutePolylineBuilder.buildSpeedColoredPolylines(
      vehicleId: widget.params.vehicleId,
      pts: drawPts,
    ).toSet();

    // Auto-fit once when route data arrives (full extent from raw points).
    if (!_hasFitted && rawPoints.isNotEmpty && _mapController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitRoute(rawPoints));
    }

    final navBottom = MediaQuery.paddingOf(context).bottom;

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          routeAsync.when(
            loading: () => Center(
              child: LoadingView(message: context.l10n.loadingRoute),
            ),
            error: (_, __) => Center(
              child: Text(context.l10n.errorLoadingRoute),
            ),
            data: (_) => Stack(
              fit: StackFit.expand,
              children: [
                GoogleMap(
                  initialCameraPosition: MapConfig.defaultCameraPosition,
                  markers: markers,
                  polylines: polylines,
                  style: isDark ? MapConfig.darkStyle : MapConfig.lightStyle,
                  myLocationButtonEnabled: false,
                  zoomControlsEnabled: false,
                  mapToolbarEnabled: false,
                  compassEnabled: true,
                  buildingsEnabled: false,
                  onMapCreated: (c) {
                    _mapController = c;
                    c.getZoomLevel().then((z) {
                      if (mounted) setState(() => _cameraZoom = z);
                    });
                    if (rawPoints.isNotEmpty) {
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _fitRoute(rawPoints),
                      );
                    }
                  },
                  onCameraIdle: () {
                    _mapController?.getZoomLevel().then((z) {
                      if (!mounted) return;
                      if ((z - _cameraZoom).abs() > 0.02) {
                        setState(() => _cameraZoom = z);
                      }
                    });
                  },
                ),
                if (rawPoints.isEmpty)
                  Material(
                    color: Colors.black.withValues(alpha: 0.08),
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 32),
                        child: Text(
                          context.l10n.noRouteReport,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.bodyMedium.copyWith(
                            color: AppColors.textSecondaryOf(context),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // ── Top bar ──────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: _TopBar(
                vehicleName: widget.vehicleName,
                contextualSubtitle: widget.contextualSubtitle,
                from: widget.params.from.toLocal(),
                to: widget.params.to.toLocal(),
                onBack: () => context.pop(),
              ),
            ),
          ),

          // ── Speed legend ─────────────────────────────────────────────────
          if (drawPts.isNotEmpty)
            Positioned(
              left: AppSpacing.screenPadding,
              bottom: 170 + navBottom,
              child: const _SpeedLegend(),
            ),

          // ── Control buttons ───────────────────────────────────────────────
          Positioned(
            right: AppSpacing.screenPadding,
            bottom: 160 + navBottom,
            child: Column(
              children: [
                _MapBtn(
                  icon: Icons.fit_screen_rounded,
                  onTap: () => _fitRoute(rawPoints),
                ),
                const SizedBox(height: 6),
                _MapBtn(
                  icon: Icons.add_rounded,
                  onTap: () => _mapController?.animateCamera(
                    CameraUpdate.zoomIn(),
                  ),
                ),
                const SizedBox(height: 4),
                _MapBtn(
                  icon: Icons.remove_rounded,
                  onTap: () => _mapController?.animateCamera(
                    CameraUpdate.zoomOut(),
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom info panel ─────────────────────────────────────────────
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: _BottomPanel(
              points: rawPoints,
              drawPoints: drawPts,
              navBottom: navBottom,
              routeIntel: _reportIntel,
              routeIntelMemoKey: _reportIntelKey,
              selectedTimelineItemKey: _selectedRouteEventKey,
              timelineFilter: _reportTimelineFilter,
              onTimelineFilterChanged: (f) =>
                  setState(() => _reportTimelineFilter = f),
              onTimelineItemTap: _focusRouteTimelineEvent,
              onOpenReplayShortcut: widget.onOpenReplayShortcut,
              l10n: l10n,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Top bar
// ─────────────────────────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.vehicleName,
    this.contextualSubtitle,
    required this.from,
    required this.to,
    required this.onBack,
  });

  final String vehicleName;
  final String? contextualSubtitle;
  final DateTime from;
  final DateTime to;
  final VoidCallback onBack;

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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(vehicleName, style: AppTextStyles.labelLarge),
                if (contextualSubtitle != null &&
                    contextualSubtitle!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      contextualSubtitle!,
                      style: AppTextStyles.bodySmall.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.accent,
                      ),
                    ),
                  ),
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
              color: AppColors.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.map_rounded, size: 12, color: AppColors.accent),
                const SizedBox(width: 4),
                Text(context.l10n.gpsTraceLabel,
                    style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.accent,
                        fontWeight: FontWeight.w600)),
              ],
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

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({
    required this.points,
    required this.drawPoints,
    required this.navBottom,
    this.routeIntel,
    required this.routeIntelMemoKey,
    this.selectedTimelineItemKey,
    required this.timelineFilter,
    required this.onTimelineFilterChanged,
    required this.onTimelineItemTap,
    this.onOpenReplayShortcut,
    required this.l10n,
  });

  final List<RoutePoint> points;
  final List<RoutePoint> drawPoints;
  final double navBottom;
  final RouteEventAnalysisResult? routeIntel;
  final String routeIntelMemoKey;
  final String? selectedTimelineItemKey;
  final RouteEventTimelineFilter timelineFilter;
  final ValueChanged<RouteEventTimelineFilter> onTimelineFilterChanged;
  final ValueChanged<RouteEventTimelineItem> onTimelineItemTap;
  final VoidCallback? onOpenReplayShortcut;
  final AppLocalizations l10n;

  static double _calcTotalKm(List<RoutePoint> pts) {
    if (pts.length < 2) return 0;
    double d = 0;
    for (var i = 1; i < pts.length; i++) {
      d += MapHelper.distanceMeters(pts[i - 1].position, pts[i].position);
    }
    return d / 1000;
  }

  @override
  Widget build(BuildContext context) {
    if (points.isEmpty) {
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
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            AppSpacing.cardPadding,
            AppSpacing.cardPadding,
            AppSpacing.cardPadding,
            AppSpacing.cardPadding + navBottom,
          ),
          child: Row(
            children: [
              Icon(
                Icons.route_rounded,
                size: 22,
                color: AppColors.textMutedOf(context),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  context.l10n.noRouteReport,
                  style: AppTextStyles.bodySmall.copyWith(
                    color: AppColors.textSecondaryOf(context),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final km = _calcTotalKm(points);
    final dur = points.last.fixTime.difference(points.first.fixTime).abs();
    final h = dur.inHours;
    final m = dur.inMinutes.remainder(60);
    final durStr = h > 0 ? '${h}h ${m}min' : '${m}min';
    final maxSpd = points.map((p) => p.speed).reduce((a, b) => a > b ? a : b);
    final avgSpd =
        points.map((p) => p.speed).reduce((a, b) => a + b) / points.length;
    final intelLine = formatRouteIntelSummaryLine(routeIntel, context.l10n);

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
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36, height: 4,
            decoration: BoxDecoration(
              color: AppColors.borderOf(context),
              borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.cardPadding,
              10,
              AppSpacing.cardPadding,
              AppSpacing.cardPadding + navBottom,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.route_rounded,
                        label: context.l10n.distanceLabel,
                        value: '${km.toStringAsFixed(1)} km',
                        color: AppColors.accent,
                      ),
                    ),
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.timer_rounded,
                        label: context.l10n.durationLabel,
                        value: durStr,
                        color: AppColors.purple,
                      ),
                    ),
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.speed_rounded,
                        label: context.l10n.routeMaxSpeedShort,
                        value: FormatUtils.speed(maxSpd),
                        color: AppColors.error,
                      ),
                    ),
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.av_timer_rounded,
                        label: context.l10n.routeAvgSpeedShort,
                        value: FormatUtils.speed(avgSpd),
                        color: AppColors.success,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.gps_fixed_rounded,
                        size: 11, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      context.l10n.routeGpsPointsInfo(
                          points.length, drawPoints.length),
                      style: const TextStyle(
                          fontSize: 10, color: AppColors.textSecondary),
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
                    style: const TextStyle(
                      fontSize: 10,
                      height: 1.25,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (points.length >= 2) ...[
                  const SizedBox(height: 10),
                  RouteEventTimeline(
                    analysisKey: routeIntelMemoKey,
                    analysis: routeIntel,
                    compact: false,
                    reportStyle: true,
                    showEmptyState: true,
                    collapsedItemLimit: 12,
                    selectedItemKey: selectedTimelineItemKey,
                    filter: timelineFilter,
                    onFilterChanged: onTimelineFilterChanged,
                    onItemTap: onTimelineItemTap,
                  ),
                ],
                if (points.length >= 2 && onOpenReplayShortcut != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      icon: Icon(
                        Icons.play_circle_outline_rounded,
                        color: AppColors.accent.withValues(alpha: 0.95),
                        size: 18,
                      ),
                      label: Text(l10n.tripReplay),
                      onPressed: onOpenReplayShortcut,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
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
      margin: const EdgeInsets.symmetric(horizontal: 2),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
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
              fontSize: 11, fontWeight: FontWeight.w800, color: color),
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
                      fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map control button
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
        width: 44, height: 44,
        decoration: BoxDecoration(
          color: AppColors.surfaceOf(context),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.borderOf(context)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Icon(icon, size: 18,
            color: AppColors.textSecondaryOf(context)),
      ),
    );
  }
}
