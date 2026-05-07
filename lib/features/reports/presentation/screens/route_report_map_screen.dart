import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../../core/l10n/app_localizations.dart';
import '../../../../core/maps/map_config.dart';
import '../../../../core/maps/map_helper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/route_decimator.dart';
import '../../../../core/widgets/loading_view.dart';
import '../../../map/data/datasources/route_datasource.dart';
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
  });

  final ReportFilterParams params;
  final String vehicleName;

  @override
  ConsumerState<RouteReportMapScreen> createState() =>
      _RouteReportMapScreenState();
}

class _RouteReportMapScreenState
    extends ConsumerState<RouteReportMapScreen> {
  GoogleMapController? _mapController;
  bool _hasFitted = false;

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  void _fitRoute(List<RoutePoint> pts) {
    if (pts.isEmpty || _mapController == null) return;
    final update =
        MapHelper.fitPoints(pts.map((p) => p.position).toList(), padding: 80);
    if (update != null) {
      _mapController!.animateCamera(update);
    }
    _hasFitted = true;
  }

  Set<Marker> _buildMarkers(List<RoutePoint> pts, BuildContext context) {
    if (pts.isEmpty) return {};
    final l10n = AppLocalizations.of(context);
    final markers = <Marker>{};

    markers.add(Marker(
      markerId: const MarkerId('route_start'),
      position: pts.first.position,
      icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      anchor: const Offset(0.5, 1.0),
      zIndexInt: 2,
      infoWindow: InfoWindow(
        title: l10n.routeDeparture,
        snippet:
            '${DateFormat('HH:mm').format(pts.first.fixTime)} · '
            '${FormatUtils.speed(pts.first.speed)}',
      ),
    ));

    if (pts.length > 1) {
      markers.add(Marker(
        markerId: const MarkerId('route_end'),
        position: pts.last.position,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        anchor: const Offset(0.5, 1.0),
        zIndexInt: 2,
        infoWindow: InfoWindow(
          title: l10n.routeArrival,
          snippet:
              '${DateFormat('HH:mm').format(pts.last.fixTime)} · '
              '${FormatUtils.speed(pts.last.speed)}',
        ),
      ));

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
            title: l10n.routeMaxSpeedShort,
            snippet:
                '${FormatUtils.speed(maxPt.speed)} · '
                '${DateFormat('HH:mm').format(maxPt.fixTime)}',
          ),
        ));
      }
    }

    return markers;
  }

  Set<Polyline> _buildPolylines(List<RoutePoint> pts) {
    if (pts.length < 2) return {};
    return {
      for (var i = 0; i < pts.length - 1; i++)
        Polyline(
          polylineId: PolylineId('seg_$i'),
          points: [pts[i].position, pts[i + 1].position],
          color: MapHelper.routeColorForSpeed(
              (pts[i].speed + pts[i + 1].speed) / 2),
          width: 5,
          geodesic: true,
          startCap: Cap.roundCap,
          endCap: Cap.roundCap,
          jointType: JointType.round,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);

    final routeAsync = ref.watch(reportRouteProvider(widget.params));
    final rawPoints = routeAsync.valueOrNull ?? [];
    final drawPts = RoutePointDecimator.decimateForMap(rawPoints);

    // Auto-fit once when route data arrives
    if (!_hasFitted && drawPts.isNotEmpty && _mapController != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _fitRoute(drawPts));
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
            data: (_) => GoogleMap(
              initialCameraPosition: MapConfig.defaultCameraPosition,
              markers: _buildMarkers(drawPts, context),
              polylines: _buildPolylines(drawPts),
              style: isDark ? MapConfig.darkStyle : MapConfig.lightStyle,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              compassEnabled: true,
              buildingsEnabled: false,
              onMapCreated: (c) {
                _mapController = c;
                if (drawPts.isNotEmpty) {
                  WidgetsBinding.instance
                      .addPostFrameCallback((_) => _fitRoute(drawPts));
                }
              },
            ),
          ),

          // ── Top bar ──────────────────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.screenPadding),
              child: _TopBar(
                vehicleName: widget.vehicleName,
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
                  onTap: () => _fitRoute(drawPts),
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
    required this.from,
    required this.to,
    required this.onBack,
  });

  final String vehicleName;
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
  });

  final List<RoutePoint> points;
  final List<RoutePoint> drawPoints;
  final double navBottom;

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
    if (points.isEmpty) return const SizedBox.shrink();

    final km = _calcTotalKm(points);
    final dur = points.last.fixTime.difference(points.first.fixTime).abs();
    final h = dur.inHours;
    final m = dur.inMinutes.remainder(60);
    final durStr = h > 0 ? '${h}h ${m}min' : '${m}min';
    final maxSpd = points.map((p) => p.speed).reduce((a, b) => a > b ? a : b);
    final avgSpd =
        points.map((p) => p.speed).reduce((a, b) => a + b) / points.length;

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
