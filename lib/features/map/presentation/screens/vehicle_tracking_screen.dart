import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

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
import '../../../../core/utils/vehicle_category_utils.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/l10n/app_localizations.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../../data/datasources/route_datasource.dart';
import '../providers/tracking_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────

class VehicleTrackingScreen extends ConsumerStatefulWidget {
  const VehicleTrackingScreen({super.key, required this.vehicleId});

  final String vehicleId;

  @override
  ConsumerState<VehicleTrackingScreen> createState() =>
      _VehicleTrackingScreenState();
}

class _VehicleTrackingScreenState
    extends ConsumerState<VehicleTrackingScreen> {
  GoogleMapController? _controller;
  Timer? _liveTimer;

  bool _followMode = true;
  bool _showInfoPanel = true;

  /// Route time range (local datetimes). Default: today 00:00 → now.
  late DateTime _from;
  late DateTime _to;

  /// Prevents the first programmatic camera move from disabling follow mode.
  int _ignoreCameraMoveStartedEvents = 0;

  /// Set when the range changes so the camera fits the new route on load.
  bool _pendingRouteFit = false;

  // Vehicle marker cache
  final _markerCache = <String, BitmapDescriptor>{};
  final _pendingKeys  = <String>{};

  static const _refreshInterval = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _from = DateTime(now.year, now.month, now.day); // today midnight
    _to   = now;
    _liveTimer = Timer.periodic(_refreshInterval, (_) {
      ref.invalidate(liveVehicleProvider(widget.vehicleId));
    });
  }

  @override
  void dispose() {
    _liveTimer?.cancel();
    _controller?.dispose();
    super.dispose();
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  RouteQuery get _routeQuery =>
      RouteQuery(vehicleId: widget.vehicleId, from: _from, to: _to);

  bool get _isToday => _routeQuery.isToday;

  // ── Camera ─────────────────────────────────────────────────────────────────

  void _beginProgrammaticCameraMove() => _ignoreCameraMoveStartedEvents++;

  void _moveTo(LatLng target) {
    _beginProgrammaticCameraMove();
    _controller?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: 16, tilt: 30),
      ),
    );
  }

  void _fitRoute(List<LatLng> points, LatLng? current) {
    final all = [...points, if (current != null) current];
    final update = MapHelper.fitPoints(all, padding: 80);
    if (update != null) {
      _beginProgrammaticCameraMove();
      _controller?.animateCamera(update);
    }
  }

  void _fitRoutePoints(List<RoutePoint> pts, LatLng? current) =>
      _fitRoute(pts.map((p) => p.position).toList(), current);

  // ── Vehicle marker ─────────────────────────────────────────────────────────

  static int _iconCodePoint(String? type) =>
      vehicleCategoryIcon(type).codePoint;

  static Color _markerColor(String status) => switch (status) {
        'moving'  => AppColors.statusMoving,
        'idle'    => AppColors.statusIdle,
        'stopped' => AppColors.statusStopped,
        _         => AppColors.statusOffline,
      };

  static BitmapDescriptor _fallbackIcon(String status) => switch (status) {
        'moving'  => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        'idle'    => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        'stopped' => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        _         => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      };

  static Future<BitmapDescriptor> _paintVehicleMarker(VehicleEntity v) async {
    const double w = 56, circleR = 22, totalH = 68;
    const double cx = w / 2, cy = circleR + 2;
    final color = _markerColor(v.status);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, totalH));

    canvas.drawCircle(Offset(cx, cy + 3), circleR,
        Paint()
          ..color = Colors.black.withOpacity(0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6));

    canvas.drawPath(
      Path()
        ..moveTo(cx - 8, cy + circleR - 5)
        ..lineTo(cx, totalH)
        ..lineTo(cx + 8, cy + circleR - 5)
        ..close(),
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawCircle(Offset(cx, cy), circleR, Paint()..color = color);

    canvas.drawPath(
      Path()
        ..moveTo(cx - 8, cy + circleR - 5)
        ..lineTo(cx, totalH - 2)
        ..lineTo(cx + 8, cy + circleR - 5)
        ..close(),
      Paint()..color = color,
    );

    canvas.drawCircle(Offset(cx, cy), circleR - 0.5,
        Paint()
          ..color = Colors.white.withOpacity(0.28)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5);

    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(_iconCodePoint(v.type)),
        style: const TextStyle(
          fontSize: 22, color: Colors.white, fontFamily: 'MaterialIcons'),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    iconPainter.paint(canvas,
        Offset(cx - iconPainter.width / 2, cy - iconPainter.height / 2));

    final picture = recorder.endRecording();
    final image   = await picture.toImage(w.toInt(), totalH.toInt());
    final bytes   = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  BitmapDescriptor _iconForVehicle(VehicleEntity v) {
    final key = '${v.status}_${v.type}';
    if (_markerCache.containsKey(key)) return _markerCache[key]!;
    if (!_pendingKeys.contains(key)) {
      _pendingKeys.add(key);
      _paintVehicleMarker(v).then((icon) {
        if (mounted) setState(() {
          _markerCache[key] = icon;
          _pendingKeys.remove(key);
        });
      });
    }
    return _fallbackIcon(v.status);
  }

  Marker _buildVehicleMarker(VehicleEntity v) => Marker(
        markerId: const MarkerId('vehicle'),
        position: LatLng(v.latitude, v.longitude),
        icon: _iconForVehicle(v),
        anchor: const Offset(0.5, 1.0),
        infoWindow: InfoWindow(
          title: v.name,
          snippet: FormatUtils.speed(v.speed),
        ),
        zIndexInt: 3,
      );

  // ── Route markers ──────────────────────────────────────────────────────────

  static String _fmtTime(DateTime dt) =>
      DateFormat('HH:mm').format(dt.toLocal());

  Set<Marker> _buildRouteMarkers(List<RoutePoint> pts, AppLocalizations l10n) {
    if (pts.isEmpty) return {};

    final markers = <Marker>{};

    // Start
    final start = pts.first;
    markers.add(Marker(
      markerId: const MarkerId('route_start'),
      position: start.position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      anchor: const Offset(0.5, 1.0),
      zIndexInt: 2,
      infoWindow: InfoWindow(
        title: l10n.routeDeparture,
        snippet:
            '${_fmtTime(start.fixTime)} · ${FormatUtils.speed(start.speed)}'
            ' · ${start.ignition ? l10n.ignitionOnLabel : l10n.ignitionOffLabel}',
      ),
    ));

    // End (only if different from start)
    if (pts.length > 1) {
      final end = pts.last;
      markers.add(Marker(
        markerId: const MarkerId('route_end'),
        position: end.position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        anchor: const Offset(0.5, 1.0),
        zIndexInt: 2,
        infoWindow: InfoWindow(
          title: l10n.routeArrival,
          snippet:
              '${_fmtTime(end.fixTime)} · ${FormatUtils.speed(end.speed)}'
              ' · ${end.ignition ? l10n.ignitionOnLabel : l10n.ignitionOffLabel}',
        ),
      ));
    }

    // Max speed point
    if (pts.length > 1) {
      final maxPt = pts.reduce((a, b) => a.speed > b.speed ? a : b);
      if (maxPt.speed > 5) {
        markers.add(Marker(
          markerId: const MarkerId('route_maxspeed'),
          position: maxPt.position,
          icon: BitmapDescriptor.defaultMarkerWithHue(
              BitmapDescriptor.hueOrange),
          anchor: const Offset(0.5, 1.0),
          zIndexInt: 1,
          infoWindow: InfoWindow(
            title: l10n.routeMaxSpeedPoint,
            snippet:
                '${FormatUtils.speed(maxPt.speed)} · ${_fmtTime(maxPt.fixTime)}',
          ),
        ));
      }
    }

    return markers;
  }

  // ── Hourly time waypoint markers ───────────────────────────────────────────

  /// Adds a small cyan marker at each full hour along the route so the user
  /// can read "at what time was the vehicle here" by tapping the dot.
  Set<Marker> _buildTimeWaypoints(List<RoutePoint> pts) {
    if (pts.length < 2) return {};
    final startLocal = pts.first.fixTime.toLocal();
    final endLocal   = pts.last.fixTime.toLocal();
    if (endLocal.difference(startLocal).inMinutes < 30) return {};

    final markers = <Marker>{};
    int count = 0;

    // Walk through every full hour inside the route window.
    var target = DateTime(
      startLocal.year, startLocal.month, startLocal.day,
      startLocal.hour + 1,
    );

    while (target.isBefore(endLocal) && count < 24) {
      // Find the route point closest to this hour mark.
      RoutePoint? closest;
      var minDiff = const Duration(minutes: 40); // tolerance
      for (final pt in pts) {
        final diff = pt.fixTime.toLocal().difference(target).abs();
        if (diff < minDiff) { minDiff = diff; closest = pt; }
      }

      if (closest != null) {
        final label = DateFormat('HH:mm').format(target);
        final dayLabel = DateFormat('dd MMM').format(target);
        markers.add(Marker(
          markerId: MarkerId('twp_${target.toIso8601String()}'),
          position: closest.position,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueCyan),
          anchor: const Offset(0.5, 0.5),
          zIndexInt: 1,
          alpha: 0.9,
          infoWindow: InfoWindow(
            title: '$label · $dayLabel',
            snippet: FormatUtils.speed(closest.speed),
          ),
        ));
        count++;
      }
      target = target.add(const Duration(hours: 1));
    }

    return markers;
  }

  // ── Speed-coloured polylines ───────────────────────────────────────────────

  static List<Polyline> _buildSpeedPolylines(
      String vehicleId, List<RoutePoint> pts) {
    if (pts.length < 2) return const [];
    return List.generate(pts.length - 1, (i) {
      final avg = (pts[i].speed + pts[i + 1].speed) / 2;
      return Polyline(
        polylineId: PolylineId('route_${vehicleId}_$i'),
        points: [pts[i].position, pts[i + 1].position],
        color: MapHelper.routeColorForSpeed(avg),
        width: 5,
        geodesic: true,
        startCap: Cap.roundCap,
        endCap: Cap.roundCap,
        jointType: JointType.round,
      );
    });
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
      // Ensure to is never before from.
      if (_to.isBefore(_from)) _to = _from.add(const Duration(hours: 1));
      _pendingRouteFit = true;
    });
    ref.invalidate(routeDetailProvider(_routeQuery));
  }

  Future<void> _pickTo() async {
    final picked = await _pickDateTime(_to);
    if (picked == null) return;
    setState(() {
      _to = picked;
      // Ensure from is never after to.
      if (_from.isAfter(_to)) _from = _to.subtract(const Duration(hours: 1));
      _pendingRouteFit = true;
    });
    ref.invalidate(routeDetailProvider(_routeQuery));
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n       = context.l10n;
    final liveAsync  = ref.watch(liveVehicleProvider(widget.vehicleId));
    final routeAsync = ref.watch(routeDetailProvider(_routeQuery));

    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final mapStyle = isDark ? MapConfig.darkStyle : MapConfig.lightStyle;

    final vehicle     = liveAsync.valueOrNull;
    final routePoints = routeAsync.valueOrNull ?? [];
    final navBottom   = MediaQuery.paddingOf(context).bottom;

    // Follow mode: animate to vehicle position on each update
    ref.listen(liveVehicleProvider(widget.vehicleId), (_, next) {
      if (!_followMode) return;
      next.whenOrNull(data: (v) {
        if (v.latitude != 0 || v.longitude != 0) {
          _moveTo(LatLng(v.latitude, v.longitude));
        }
      });
    });

    // Fit route when a new date is picked and data arrives
    ref.listen(routeDetailProvider(_routeQuery), (_, next) {
      if (!_pendingRouteFit) return;
      next.whenOrNull(data: (pts) {
        if (pts.isNotEmpty) {
          _pendingRouteFit = false;
          final cur = vehicle != null && vehicle.latitude != 0
              ? LatLng(vehicle.latitude, vehicle.longitude)
              : null;
          WidgetsBinding.instance.addPostFrameCallback(
              (_) => _fitRoutePoints(pts, cur));
        }
      });
    });

    // Decimated points for rendering
    final drawPts = RoutePointDecimator.decimateForMap(routePoints);

    // Build map layers
    final Set<Marker> markers = {
      if (vehicle != null && (vehicle.latitude != 0 || vehicle.longitude != 0))
        _buildVehicleMarker(vehicle),
      ..._buildRouteMarkers(drawPts, l10n),
      ..._buildTimeWaypoints(drawPts),
    };

    final polylines = <Polyline>{
      ..._buildSpeedPolylines(widget.vehicleId, drawPts),
    };

    return Scaffold(
      body: Stack(
        children: [
          // ── Map ──────────────────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: MapConfig.defaultCameraPosition,
            markers: markers,
            polylines: polylines,
            onMapCreated: (c) {
              _controller = c;
              if (vehicle != null && vehicle.latitude != 0) {
                _moveTo(LatLng(vehicle.latitude, vehicle.longitude));
              }
            },
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            mapToolbarEnabled: false,
            compassEnabled: true,
            buildingsEnabled: false,
            style: mapStyle,
            onCameraMoveStarted: () {
              if (_ignoreCameraMoveStartedEvents > 0) {
                _ignoreCameraMoveStartedEvents--;
                return;
              }
              if (_followMode) setState(() => _followMode = false);
            },
          ),

          // Loading overlay (first load only)
          if (liveAsync.isLoading && vehicle == null)
            ColoredBox(
              color: AppColors.backgroundOf(context),
              child: LoadingView(message: l10n.loadingVehicleLocation),
            ),

          // ── Top header ────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: _TopBar(
                vehicle: vehicle,
                isLoading: liveAsync.isLoading,
                onBack: () => context.pop(),
              ),
            ),
          ),

          // ── Right-side controls ───────────────────────────────────────────
          Positioned(
            right: AppSpacing.screenPadding,
            bottom: (_showInfoPanel ? 280 : 120) + navBottom,
            child: Column(
              children: [
                _ControlBtn(
                  icon: _followMode
                      ? Icons.gps_fixed_rounded
                      : Icons.gps_not_fixed_rounded,
                  label: _followMode ? l10n.followLabel : l10n.freeLabel,
                  isActive: _followMode,
                  onTap: () {
                    setState(() => _followMode = !_followMode);
                    if (_followMode && vehicle != null) {
                      _moveTo(LatLng(vehicle.latitude, vehicle.longitude));
                    }
                  },
                ),
                const SizedBox(height: 6),
                _ControlBtn(
                  icon: Icons.fit_screen_rounded,
                  label: l10n.recentreRouteLabel,
                  onTap: () {
                    final cur = vehicle != null && vehicle.latitude != 0
                        ? LatLng(vehicle.latitude, vehicle.longitude)
                        : null;
                    _fitRoutePoints(routePoints, cur);
                    setState(() => _followMode = false);
                  },
                ),
                const SizedBox(height: 6),
                _ControlBtn(
                  icon: Icons.add_rounded,
                  onTap: () {
                    _beginProgrammaticCameraMove();
                    _controller?.animateCamera(CameraUpdate.zoomIn());
                  },
                ),
                const SizedBox(height: 4),
                _ControlBtn(
                  icon: Icons.remove_rounded,
                  onTap: () {
                    _beginProgrammaticCameraMove();
                    _controller?.animateCamera(CameraUpdate.zoomOut());
                  },
                ),
                const SizedBox(height: 6),
                _ControlBtn(
                  icon: Icons.refresh_rounded,
                  onTap: () {
                    ref.invalidate(liveVehicleProvider(widget.vehicleId));
                    ref.invalidate(routeDetailProvider(_routeQuery));
                  },
                ),
              ],
            ),
          ),

          // ── Info panel toggle ─────────────────────────────────────────────
          Positioned(
            left: AppSpacing.screenPadding,
            bottom: (_showInfoPanel ? 280 : 120) + navBottom,
            child: _ControlBtn(
              icon: _showInfoPanel
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_up_rounded,
              onTap: () => setState(() => _showInfoPanel = !_showInfoPanel),
            ),
          ),

          // ── Speed legend ──────────────────────────────────────────────────
          if (routePoints.isNotEmpty)
            Positioned(
              left: AppSpacing.screenPadding,
              bottom: (_showInfoPanel ? 280 : 120) + navBottom + 54,
              child: const _SpeedLegend(),
            ),

          // ── Bottom info panel ─────────────────────────────────────────────
          if (_showInfoPanel)
            Positioned(
              left: 0, right: 0, bottom: 0,
              child: _InfoPanel(
                vehicle: vehicle,
                routeAsync: routeAsync,
                from: _from,
                to: _to,
                isToday: _isToday,
                onPickFrom: _pickFrom,
                onPickTo: _pickTo,
                onViewDetails: () =>
                    context.push('/vehicles/${widget.vehicleId}'),
                onViewTrips: () =>
                    context.push('/vehicles/${widget.vehicleId}/trips'),
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
// Bottom info panel
// ─────────────────────────────────────────────────────────────────────────────

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.vehicle,
    required this.routeAsync,
    required this.from,
    required this.to,
    required this.isToday,
    required this.onPickFrom,
    required this.onPickTo,
    required this.onViewDetails,
    required this.onViewTrips,
  });

  final VehicleEntity?                  vehicle;
  final AsyncValue<List<RoutePoint>>    routeAsync;
  final DateTime                        from;
  final DateTime                        to;
  final bool                            isToday;
  final VoidCallback                    onPickFrom;
  final VoidCallback                    onPickTo;
  final VoidCallback                    onViewDetails;
  final VoidCallback                    onViewTrips;

  @override
  Widget build(BuildContext context) {
    final l10n      = context.l10n;
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
              AppSpacing.cardPadding, 10,
              AppSpacing.cardPadding,
              AppSpacing.cardPadding + navBottom,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
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
                _RouteStatsSection(routeAsync: routeAsync),

                const SizedBox(height: 14),

                // ── Live vehicle stats ───────────────────────────────────────
                if (vehicle != null) _VehicleStatsRow(vehicle: vehicle!),

                const SizedBox(height: 12),

                // ── Action buttons ───────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onViewDetails,
                        icon: const Icon(Icons.info_outline_rounded, size: 16),
                        label: Text(l10n.vehicleDetails),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                          side: BorderSide(
                              color: AppColors.borderOf(context)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: onViewTrips,
                        icon: const Icon(Icons.history_rounded, size: 16),
                        label: Text(l10n.tripHistory),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.accent,
                          padding:
                              const EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
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
            Icon(Icons.access_time_rounded, size: 12, color: AppColors.accent),
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
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.accent)),
              ],
            ),
            const SizedBox(width: 4),
            Icon(Icons.expand_more_rounded, size: 14, color: AppColors.accent),
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
  const _RouteStatsSection({required this.routeAsync});

  final AsyncValue<List<RoutePoint>> routeAsync;

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

        return Row(
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
            color: AppColors.textSecondaryOf(context),
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
