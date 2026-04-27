import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/maps/map_config.dart';
import '../../../../core/maps/map_helper.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../providers/tracking_provider.dart';

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

  /// [GoogleMap] calls [onCameraMoveStarted] for user pans **and** for
  /// [animateCamera]. Without this counter, the first follow move would set
  /// follow mode off and the map would stop tracking the vehicle.
  int _ignoreCameraMoveStartedEvents = 0;

  // Custom marker cache: key = '${status}_${type}'
  final _markerCache = <String, BitmapDescriptor>{};
  final _pendingKeys = <String>{};

  static const _refreshInterval = Duration(seconds: 10);

  @override
  void initState() {
    super.initState();
    // Refresh live position every 10 s
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

  // ── Camera ─────────────────────────────────────────────────────────────────

  void _beginProgrammaticCameraMove() {
    _ignoreCameraMoveStartedEvents++;
  }

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

  // ── Markers ────────────────────────────────────────────────────────────────

  static int _iconCodePoint(String type) => switch (type.toLowerCase()) {
    'truck'                => 0xe558,
    'bus'                  => 0xe530,
    'motorcycle' || 'moto' => 0xf8b6,
    'van'                  => 0xe068,
    'pickup'               => 0xe558,
    _                      => 0xe1b0, // directions_car
  };

  static Color _markerColor(String status) => switch (status) {
    'moving'  => AppColors.statusMoving,
    'idle'    => AppColors.statusIdle,
    'stopped' => AppColors.statusStopped,
    _         => AppColors.statusOffline,
  };

  static BitmapDescriptor _fallbackIcon(String status) =>
      switch (status) {
        'moving'  => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        'idle'    => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        'stopped' => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        _         => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      };

  static Future<BitmapDescriptor> _paintMarker(VehicleEntity v) async {
    const double w = 56;
    const double circleR = 22;
    const double totalH = 68;
    const double cx = w / 2;
    const double cy = circleR + 2;
    final color = _markerColor(v.status);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, totalH));

    // Shadow
    canvas.drawCircle(
      Offset(cx, cy + 3),
      circleR,
      Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Teardrop pointer shadow
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

    // Circle body
    canvas.drawCircle(Offset(cx, cy), circleR, Paint()..color = color);

    // Teardrop pointer
    canvas.drawPath(
      Path()
        ..moveTo(cx - 8, cy + circleR - 5)
        ..lineTo(cx, totalH - 2)
        ..lineTo(cx + 8, cy + circleR - 5)
        ..close(),
      Paint()..color = color,
    );

    // White border ring
    canvas.drawCircle(
      Offset(cx, cy),
      circleR - 0.5,
      Paint()
        ..color = Colors.white.withOpacity(0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // Vehicle icon
    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(_iconCodePoint(v.type)),
        style: const TextStyle(
          fontSize: 22,
          color: Colors.white,
          fontFamily: 'MaterialIcons',
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();

    iconPainter.paint(
      canvas,
      Offset(
        cx - iconPainter.width / 2,
        cy - iconPainter.height / 2,
      ),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(w.toInt(), totalH.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  BitmapDescriptor _iconForVehicle(VehicleEntity v) {
    final key = '${v.status}_${v.type}';
    if (_markerCache.containsKey(key)) return _markerCache[key]!;

    if (!_pendingKeys.contains(key)) {
      _pendingKeys.add(key);
      _paintMarker(v).then((icon) {
        if (mounted) {
          setState(() {
            _markerCache[key] = icon;
            _pendingKeys.remove(key);
          });
        }
      });
    }
    return _fallbackIcon(v.status);
  }

  Marker _buildVehicleMarker(VehicleEntity v) => Marker(
        markerId: const MarkerId('vehicle'),
        position: LatLng(v.latitude, v.longitude),
        icon: _iconForVehicle(v),
        anchor: const Offset(0.5, 1.0),
        rotation: 0,
        infoWindow: InfoWindow(
          title: v.name,
          snippet: FormatUtils.speed(v.speed),
        ),
        zIndexInt: 2,
      );

  // ── Polyline ───────────────────────────────────────────────────────────────

  Polyline _buildRoutePolyline(List<LatLng> points) =>
      MapHelper.buildRoutePolyline(
        id: 'route_${widget.vehicleId}',
        points: points,
        width: 4,
      );

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final liveAsync = ref.watch(liveVehicleProvider(widget.vehicleId));
    final routeAsync = ref.watch(todayRouteProvider(widget.vehicleId));

    // Theme-aware map style
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final mapStyle = isDark ? MapConfig.darkStyle : MapConfig.lightStyle;

    // Auto-follow camera when live data updates
    ref.listen(liveVehicleProvider(widget.vehicleId), (_, next) {
      if (!_followMode) return;
      next.whenOrNull(
        data: (v) {
          if (v.latitude != 0 || v.longitude != 0) {
            _moveTo(LatLng(v.latitude, v.longitude));
          }
        },
      );
    });

    final vehicle = liveAsync.valueOrNull;
    final routePoints = routeAsync.valueOrNull ?? [];

    final markers = <Marker>{
      if (vehicle != null && (vehicle.latitude != 0 || vehicle.longitude != 0))
        _buildVehicleMarker(vehicle),
    };

    final polylines = <Polyline>{
      if (routePoints.length >= 2) _buildRoutePolyline(routePoints),
    };

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Map ─────────────────────────────────────────────────────────
          GoogleMap(
            initialCameraPosition: MapConfig.defaultCameraPosition,
            markers: markers,
            polylines: polylines,
            onMapCreated: (c) {
              _controller = c;
              // Move to vehicle once the map is ready
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
            // Fires for user gestures *and* animateCamera; ignore the latter.
            onCameraMoveStarted: () {
              if (_ignoreCameraMoveStartedEvents > 0) {
                _ignoreCameraMoveStartedEvents--;
                return;
              }
              if (_followMode) {
                setState(() => _followMode = false);
              }
            },
          ),

          // Loading overlay on top of map
          if (liveAsync.isLoading && vehicle == null)
            const ColoredBox(
              color: AppColors.background,
              child: LoadingView(message: 'جارٍ تحميل موقع المركبة…'),
            ),

          // ── Top header ───────────────────────────────────────────────────
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

          // ── Right-side controls ──────────────────────────────────────────
          Positioned(
            right: AppSpacing.screenPadding,
            bottom: _showInfoPanel ? 260 : 120,
            child: Column(
              children: [
                // Follow toggle
                _ControlBtn(
                  icon: _followMode
                      ? Icons.gps_fixed_rounded
                      : Icons.gps_not_fixed_rounded,
                  label: _followMode ? 'متابعة' : 'حر',
                  isActive: _followMode,
                  onTap: () {
                    setState(() => _followMode = !_followMode);
                    if (_followMode && vehicle != null) {
                      _moveTo(LatLng(vehicle.latitude, vehicle.longitude));
                    }
                  },
                ),
                const SizedBox(height: 6),
                // Fit route
                _ControlBtn(
                  icon: Icons.route_rounded,
                  label: 'المسار',
                  onTap: () {
                    final cur = vehicle != null && vehicle.latitude != 0
                        ? LatLng(vehicle.latitude, vehicle.longitude)
                        : null;
                    _fitRoute(routePoints, cur);
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
                    ref.invalidate(todayRouteProvider(widget.vehicleId));
                  },
                ),
              ],
            ),
          ),

          // ── Info panel toggle button ────────────────────────────────────
          Positioned(
            left: AppSpacing.screenPadding,
            bottom: _showInfoPanel ? 260 : 120,
            child: _ControlBtn(
              icon: _showInfoPanel
                  ? Icons.keyboard_arrow_down_rounded
                  : Icons.keyboard_arrow_up_rounded,
              onTap: () => setState(() => _showInfoPanel = !_showInfoPanel),
            ),
          ),

          // ── Bottom info panel ────────────────────────────────────────────
          if (_showInfoPanel)
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _InfoPanel(
                vehicle: vehicle,
                routePoints: routePoints,
                isLoadingRoute: routeAsync.isLoading,
                onViewDetails: () => context.push('/vehicles/${widget.vehicleId}'),
                onViewTrips: () => context.push(
                    '/vehicles/${widget.vehicleId}/trips'),
              ),
            ),

          // Error banner
          if (liveAsync.hasError)
            Positioned(
              top: 100,
              left: AppSpacing.screenPadding,
              right: AppSpacing.screenPadding,
              child: _ErrorBanner(
                message: 'تعذّر تحديث الموقع',
                onRetry: () =>
                    ref.invalidate(liveVehicleProvider(widget.vehicleId)),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Top bar ────────────────────────────────────────────────────────────────────

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
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
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
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: vehicle == null
                ? const Text('جارٍ التحميل…',
                    style: AppTextStyles.labelLarge)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(vehicle!.name,
                          style: AppTextStyles.labelLarge),
                      Text(
                        vehicle!.plateNumber,
                        style: AppTextStyles.bodySmall.copyWith(
                            color: AppColors.textSecondary),
                      ),
                    ],
                  ),
          ),
          if (vehicle != null)
            StatusBadge(
                status: StatusBadge.fromString(vehicle!.status)),
          if (isLoading) ...[
            const SizedBox(width: 8),
            const SizedBox.square(
              dimension: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.accent,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Bottom info panel ──────────────────────────────────────────────────────────

class _InfoPanel extends StatelessWidget {
  const _InfoPanel({
    required this.vehicle,
    required this.routePoints,
    required this.isLoadingRoute,
    required this.onViewDetails,
    required this.onViewTrips,
  });

  final VehicleEntity? vehicle;
  final List<LatLng> routePoints;
  final bool isLoadingRoute;
  final VoidCallback onViewDetails;
  final VoidCallback onViewTrips;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: AppColors.border),
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
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.cardPadding, 12,
                AppSpacing.cardPadding, AppSpacing.cardPadding),
            child: vehicle == null
                ? const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('جارٍ جلب بيانات المركبة…',
                        style: AppTextStyles.bodySmall),
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Stats grid
                      _StatsGrid(
                        vehicle: vehicle!,
                        routePointCount: routePoints.length,
                        isLoadingRoute: isLoadingRoute,
                      ),
                      const SizedBox(height: 12),
                      // Route progress bar
                      if (routePoints.isNotEmpty)
                        _RouteBar(points: routePoints),
                      const SizedBox(height: 14),
                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: onViewDetails,
                              icon: const Icon(Icons.info_outline_rounded,
                                  size: 16),
                              label: const Text('تفاصيل المركبة'),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                side: const BorderSide(
                                    color: AppColors.border),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: FilledButton.icon(
                              onPressed: onViewTrips,
                              icon: const Icon(Icons.history_rounded,
                                  size: 16),
                              label: const Text('سجل الرحلات'),
                              style: FilledButton.styleFrom(
                                backgroundColor: AppColors.accent,
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
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

// ── Stats grid ─────────────────────────────────────────────────────────────────

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({
    required this.vehicle,
    required this.routePointCount,
    required this.isLoadingRoute,
  });

  final VehicleEntity vehicle;
  final int routePointCount;
  final bool isLoadingRoute;

  @override
  Widget build(BuildContext context) {
    final lastUpdate = vehicle.lastUpdate;
    final lastUpdateStr = lastUpdate != null
        ? _timeAgo(lastUpdate)
        : 'غير متاح';

    return Row(
      children: [
        Expanded(
          child: _StatTile(
            icon: Icons.speed_rounded,
            value: FormatUtils.speed(vehicle.speed),
            label: 'السرعة',
            color: vehicle.isMoving ? AppColors.success : AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: _StatTile(
            icon: vehicle.ignition
                ? Icons.power_rounded
                : Icons.power_off_rounded,
            value: vehicle.ignition ? 'تشتعل' : 'مطفأ',
            label: 'المحرك',
            color: vehicle.ignition ? AppColors.success : AppColors.error,
          ),
        ),
        Expanded(
          child: _StatTile(
            icon: Icons.update_rounded,
            value: lastUpdateStr,
            label: 'آخر تحديث',
            color: AppColors.textSecondary,
          ),
        ),
        Expanded(
          child: _StatTile(
            icon: Icons.route_rounded,
            value: isLoadingRoute
                ? '...'
                : '$routePointCount نقطة',
            label: 'مسار اليوم',
            color: AppColors.accent,
          ),
        ),
      ],
    );
  }

  static String _timeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'الآن';
    if (diff.inMinutes < 60) return 'منذ ${diff.inMinutes} د';
    if (diff.inHours < 24) return 'منذ ${diff.inHours} س';
    return 'منذ ${diff.inDays} ي';
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
  final String value;
  final String label;
  final Color color;

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
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
                fontSize: 10, color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ── Route progress bar ────────────────────────────────────────────────────────

class _RouteBar extends StatelessWidget {
  const _RouteBar({required this.points});

  final List<LatLng> points;

  static double _totalKm(List<LatLng> pts) {
    if (pts.length < 2) return 0;
    double d = 0;
    for (var i = 1; i < pts.length; i++) {
      d += MapHelper.distanceMeters(pts[i - 1], pts[i]);
    }
    return d / 1000;
  }

  @override
  Widget build(BuildContext context) {
    final km = _totalKm(points);
    return Row(
      children: [
        const Icon(Icons.route_rounded,
            size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'مسار اليوم: ${km.toStringAsFixed(1)} كم',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                  const Spacer(),
                  Text(
                    '${points.length} نقطة',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (km / 200).clamp(0.0, 1.0),
                  backgroundColor: AppColors.border,
                  valueColor: const AlwaysStoppedAnimation(AppColors.accent),
                  minHeight: 4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Control button ─────────────────────────────────────────────────────────────

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
  final bool isActive;

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
              : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isActive ? AppColors.accent : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 18,
                color: isActive ? AppColors.accent : AppColors.textSecondary),
            if (label != null) ...[
              const SizedBox(height: 2),
              Text(
                label!,
                style: TextStyle(
                  fontSize: 8,
                  color: isActive
                      ? AppColors.accent
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Error banner ───────────────────────────────────────────────────────────────

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 16, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.error)),
          ),
          TextButton(
            onPressed: onRetry,
            child: const Text('إعادة',
                style: TextStyle(fontSize: 12, color: AppColors.accent)),
          ),
        ],
      ),
    );
  }
}
