import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/maps/map_config.dart';
import '../../../../core/maps/map_helper.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/format_utils.dart';
import '../../../vehicles/domain/entities/vehicle.dart';
import '../providers/map_provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Screen
// ─────────────────────────────────────────────────────────────────────────────

class LiveMapScreen extends ConsumerStatefulWidget {
  const LiveMapScreen({super.key});

  @override
  ConsumerState<LiveMapScreen> createState() => _LiveMapScreenState();
}

class _LiveMapScreenState extends ConsumerState<LiveMapScreen> {
  GoogleMapController? _mapController;
  Timer? _refreshTimer;
  String _selectedFilter = 'all';
  bool _didFitBounds = false;

  // Cache: key = '${vehicleId}_${status}_${isSelected}'
  final _markerCache = <String, BitmapDescriptor>{};
  final _pendingKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 20),
      (_) => ref.invalidate(mapVehiclesProvider),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  // ── Custom marker icons ─────────────────────────────────────────────────────

  BitmapDescriptor _iconForVehicle(VehicleEntity v, {bool isSelected = false}) {
    final key = '${v.id}_${v.status}_$isSelected';
    if (_markerCache.containsKey(key)) return _markerCache[key]!;

    if (!_pendingKeys.contains(key)) {
      _pendingKeys.add(key);
      _buildVehicleMarker(v, isSelected: isSelected).then((icon) {
        if (mounted) {
          setState(() {
            _markerCache[key] = icon;
            _pendingKeys.remove(key);
          });
        }
      });
    }
    return _fallbackIcon(v.status, isSelected);
  }

  static BitmapDescriptor _fallbackIcon(String status, bool isSelected) {
    if (isSelected) {
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);
    }
    return switch (status) {
      'moving' => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
      'idle'   => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      'stopped'=> BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
      _        => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
    };
  }

  static Color _markerColor(String status, bool isSelected) {
    if (isSelected) return const Color(0xFFFFC107);
    return switch (status) {
      'moving'  => AppColors.statusMoving,
      'idle'    => AppColors.statusIdle,
      'stopped' => AppColors.statusStopped,
      _         => AppColors.statusOffline,
    };
  }

  static int _iconCodePoint(String type) => switch (type.toLowerCase()) {
    'truck'                  => 0xe558, // local_shipping
    'bus'                    => 0xe530, // directions_bus
    'motorcycle' || 'moto'   => 0xf8b6, // two_wheeler
    'van'                    => 0xe068, // airport_shuttle
    'pickup'                 => 0xe558, // local_shipping (small)
    _                        => 0xe1b0, // directions_car
  };

  static Future<BitmapDescriptor> _buildVehicleMarker(
    VehicleEntity v, {
    bool isSelected = false,
  }) async {
    const double w = 56;
    const double circleR = 22;
    const double totalH = 68; // circle(44) + pointer(24)
    const double cx = w / 2;
    const double cy = circleR + 2;

    final color = _markerColor(v.status, isSelected);

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, totalH));

    // 1. Drop shadow beneath circle
    canvas.drawCircle(
      Offset(cx, cy + 3),
      circleR,
      Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // 2. Teardrop pointer shadow
    final pointerShadow = Path()
      ..moveTo(cx - 8, cy + circleR - 5)
      ..lineTo(cx, totalH)
      ..lineTo(cx + 8, cy + circleR - 5)
      ..close();
    canvas.drawPath(
      pointerShadow,
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // 3. Circle body
    canvas.drawCircle(Offset(cx, cy), circleR, Paint()..color = color);

    // 4. Teardrop pointer
    final pointer = Path()
      ..moveTo(cx - 8, cy + circleR - 5)
      ..lineTo(cx, totalH - 2)
      ..lineTo(cx + 8, cy + circleR - 5)
      ..close();
    canvas.drawPath(pointer, Paint()..color = color);

    // 5. White border ring
    canvas.drawCircle(
      Offset(cx, cy),
      circleR - 0.5,
      Paint()
        ..color = Colors.white.withOpacity(isSelected ? 0.95 : 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = isSelected ? 2.5 : 1.5,
    );

    // 6. Vehicle icon (Material Icons font)
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

    // 7. Selected: outer glow ring
    if (isSelected) {
      canvas.drawCircle(
        Offset(cx, cy),
        circleR + 4,
        Paint()
          ..color = color.withOpacity(0.35)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3,
      );
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(w.toInt(), totalH.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  // ── Marker set ──────────────────────────────────────────────────────────────

  Set<Marker> _buildMarkers(List<VehicleEntity> vehicles, String? selectedId) {
    return vehicles.map((v) {
      final isSelected = v.id == selectedId;
      return Marker(
        markerId: MarkerId(v.id),
        position: LatLng(v.latitude, v.longitude),
        icon: _iconForVehicle(v, isSelected: isSelected),
        anchor: const Offset(0.5, 1.0),
        zIndexInt: isSelected ? 2 : (v.isOffline ? 0 : 1),
        infoWindow: InfoWindow(
          title: v.name,
          snippet: '${v.plateNumber} · ${FormatUtils.speed(v.speed)}',
        ),
        onTap: () =>
            ref.read(selectedMapVehicleProvider.notifier).state = v.id,
      );
    }).toSet();
  }

  // ── Filter / camera ─────────────────────────────────────────────────────────

  List<VehicleEntity> _filterVehicles(List<VehicleEntity> all) {
    if (_selectedFilter == 'all') return all;
    return all.where((v) => v.status == _selectedFilter).toList();
  }

  void _fitAll(List<VehicleEntity> vehicles) {
    if (_mapController == null) return;
    final pts = vehicles
        .where((v) => v.latitude != 0 || v.longitude != 0)
        .map((v) => LatLng(v.latitude, v.longitude))
        .toList();
    final upd = MapHelper.fitPoints(pts, padding: 80);
    if (upd != null) _mapController!.animateCamera(upd);
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final vehiclesAsync = ref.watch(mapVehiclesProvider);
    final selectedId   = ref.watch(selectedMapVehicleProvider);

    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final mapStyle = isDark ? MapConfig.darkStyle : MapConfig.lightStyle;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // ── Full-screen map ────────────────────────────────────────────────
          vehiclesAsync.when(
            data: (all) {
              final filtered = _filterVehicles(all);
              final markers  = _buildMarkers(filtered, selectedId);

              if (!_didFitBounds && all.isNotEmpty) {
                _didFitBounds = true;
                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _fitAll(all));
              }

              return GoogleMap(
                initialCameraPosition: MapConfig.defaultCameraPosition,
                markers: markers,
                onMapCreated: (c) {
                  _mapController = c;
                  if (all.isNotEmpty) _fitAll(all);
                },
                myLocationButtonEnabled: false,
                zoomControlsEnabled:     false,
                mapToolbarEnabled:       false,
                compassEnabled:          false,
                buildingsEnabled:        false,
                style: mapStyle,
                onTap: (_) =>
                    ref.read(selectedMapVehicleProvider.notifier).state = null,
              );
            },
            loading: () => _MapLoadingState(),
            error:   (_, __) => _MapErrorState(
              onRetry: () => ref.invalidate(mapVehiclesProvider),
            ),
          ),

          // ── Top overlay (header + filter) ──────────────────────────────────
          SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenPadding, AppSpacing.md,
                    AppSpacing.screenPadding, 0,
                  ),
                  child: _MapHeader(vehiclesAsync: vehiclesAsync),
                ),
                const SizedBox(height: AppSpacing.sm),
                _FilterBar(
                  selected: _selectedFilter,
                  vehiclesAsync: vehiclesAsync,
                  onSelect: (f) => setState(() => _selectedFilter = f),
                ),
              ],
            ),
          ),

          // ── Right map controls ─────────────────────────────────────────────
          Positioned(
            right: AppSpacing.screenPadding,
            bottom: 220,
            child: _MapControlsColumn(
              onZoomIn:  () => _mapController?.animateCamera(CameraUpdate.zoomIn()),
              onZoomOut: () => _mapController?.animateCamera(CameraUpdate.zoomOut()),
              onFitAll:  () => vehiclesAsync.whenOrNull(data: _fitAll),
              onRefresh: () => ref.invalidate(mapVehiclesProvider),
            ),
          ),

          // ── Bottom area ────────────────────────────────────────────────────
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: selectedId != null
                ? (vehiclesAsync.whenOrNull(data: (all) {
                    final v = all.where((x) => x.id == selectedId).firstOrNull;
                    if (v == null) return null;
                    return _VehicleBottomCard(
                      vehicle: v,
                      onClose: () =>
                          ref.read(selectedMapVehicleProvider.notifier).state = null,
                      onTrack: () => context.push('/vehicles/${v.id}/track'),
                      onDetails: () => context.push('/vehicles/${v.id}'),
                      onCenter: () => _mapController?.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          LatLng(v.latitude, v.longitude), 16),
                      ),
                    );
                  }) ?? const SizedBox.shrink())
                : (vehiclesAsync.whenOrNull(data: (all) => Padding(
                    padding: const EdgeInsets.all(AppSpacing.screenPadding),
                    child: _FleetSummaryPill(vehicles: all),
                  )) ?? const SizedBox.shrink()),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map Header
// ─────────────────────────────────────────────────────────────────────────────

class _MapHeader extends StatelessWidget {
  const _MapHeader({required this.vehiclesAsync});
  final AsyncValue<List<VehicleEntity>> vehiclesAsync;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface.withOpacity(0.96),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border, width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Live dot
          Container(
            width: 8, height: 8,
            decoration: const BoxDecoration(
              color: AppColors.statusMoving,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Color(0x6010B981), blurRadius: 8)],
            ),
          ),
          const SizedBox(width: 9),
          const Text(
            'خريطة الأسطول',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const Spacer(),
          vehiclesAsync.whenOrNull(
            data: (v) => _HeaderStatusRow(vehicles: v),
          ) ?? const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _HeaderStatusRow extends StatelessWidget {
  const _HeaderStatusRow({required this.vehicles});
  final List<VehicleEntity> vehicles;

  @override
  Widget build(BuildContext context) {
    final moving  = vehicles.where((v) => v.isMoving).length;
    final stopped = vehicles.where((v) => v.isStopped).length;
    final idle    = vehicles.where((v) => v.isIdle).length;
    final offline = vehicles.where((v) => v.isOffline).length;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (moving  > 0) _MiniDot(color: AppColors.statusMoving,  count: moving),
        if (stopped > 0) _MiniDot(color: AppColors.statusStopped, count: stopped),
        if (idle    > 0) _MiniDot(color: AppColors.statusIdle,    count: idle),
        if (offline > 0) _MiniDot(color: AppColors.statusOffline, count: offline),
      ],
    );
  }
}

class _MiniDot extends StatelessWidget {
  const _MiniDot({required this.color, required this.count});
  final Color color;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 9),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7, height: 7,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.55), blurRadius: 5)],
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12, color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Filter Bar
// ─────────────────────────────────────────────────────────────────────────────

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.selected,
    required this.vehiclesAsync,
    required this.onSelect,
  });

  final String selected;
  final AsyncValue<List<VehicleEntity>> vehiclesAsync;
  final void Function(String) onSelect;

  @override
  Widget build(BuildContext context) {
    final counts = vehiclesAsync.whenOrNull(data: (v) => {
      'all':     v.length,
      'moving':  v.where((x) => x.isMoving).length,
      'stopped': v.where((x) => x.isStopped).length,
      'idle':    v.where((x) => x.isIdle).length,
      'offline': v.where((x) => x.isOffline).length,
    });

    const filters = [
      ('all',     'الكل',    null,                       Icons.grid_view_rounded),
      ('moving',  'متحرك',   AppColors.statusMoving,     Icons.navigation_rounded),
      ('stopped', 'متوقف',   AppColors.statusStopped,    Icons.stop_circle_outlined),
      ('idle',    'خامل',    AppColors.statusIdle,       Icons.timelapse_rounded),
      ('offline', 'مقطوع',   AppColors.statusOffline,    Icons.signal_wifi_off_rounded),
    ];

    return SizedBox(
      height: 36,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding),
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (_, i) {
          final (key, label, color, icon) = filters[i];
          final activeColor = color ?? AppColors.accent;
          final isSelected  = selected == key;
          final count       = counts?[key];
          return _FilterPill(
            icon: icon,
            label: count != null ? '$label · $count' : label,
            isSelected: isSelected,
            activeColor: activeColor,
            onTap: () => onSelect(key),
          );
        },
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.activeColor,
    required this.onTap,
  });

  final IconData   icon;
  final String     label;
  final bool       isSelected;
  final Color      activeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withOpacity(0.18)
              : AppColors.surface.withOpacity(0.94),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? activeColor : AppColors.border,
            width: isSelected ? 1.2 : 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12,
                color: isSelected ? activeColor : AppColors.textMuted),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: isSelected ? activeColor : AppColors.textSecondary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Map Controls Column
// ─────────────────────────────────────────────────────────────────────────────

class _MapControlsColumn extends StatelessWidget {
  const _MapControlsColumn({
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onFitAll,
    required this.onRefresh,
  });

  final VoidCallback onZoomIn;
  final VoidCallback onZoomOut;
  final VoidCallback onFitAll;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _CtrlBtn(icon: Icons.add_rounded,        onTap: onZoomIn,  tooltip: 'تكبير'),
        const SizedBox(height: 2),
        _CtrlBtn(icon: Icons.remove_rounded,      onTap: onZoomOut, tooltip: 'تصغير'),
        const SizedBox(height: 8),
        _CtrlBtn(icon: Icons.fit_screen_rounded,  onTap: onFitAll,  tooltip: 'ضبط العرض'),
        const SizedBox(height: 2),
        _CtrlBtn(icon: Icons.refresh_rounded,     onTap: onRefresh, tooltip: 'تحديث'),
      ],
    );
  }
}

class _CtrlBtn extends StatelessWidget {
  const _CtrlBtn({required this.icon, required this.onTap, this.tooltip = ''});
  final IconData     icon;
  final VoidCallback onTap;
  final String       tooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppColors.surface.withOpacity(0.96),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border, width: 0.8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.28),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(icon, size: 18, color: AppColors.accent),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fleet Summary Pill  (shown when no vehicle is selected)
// ─────────────────────────────────────────────────────────────────────────────

class _FleetSummaryPill extends StatelessWidget {
  const _FleetSummaryPill({required this.vehicles});
  final List<VehicleEntity> vehicles;

  @override
  Widget build(BuildContext context) {
    final online = vehicles.where((v) => v.isOnline).length;
    final moving = vehicles.where((v) => v.isMoving).length;
    final total  = vehicles.length;

    return Align(
      alignment: AlignmentDirectional.bottomStart,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface.withOpacity(0.96),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border, width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8, height: 8,
              decoration: const BoxDecoration(
                color: AppColors.statusMoving,
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0x5010B981), blurRadius: 6)],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$online/$total متصل  ·  $moving متحرك',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Vehicle Bottom Card
// ─────────────────────────────────────────────────────────────────────────────

class _VehicleBottomCard extends StatelessWidget {
  const _VehicleBottomCard({
    required this.vehicle,
    required this.onClose,
    required this.onTrack,
    required this.onDetails,
    required this.onCenter,
  });

  final VehicleEntity vehicle;
  final VoidCallback  onClose;
  final VoidCallback  onTrack;
  final VoidCallback  onDetails;
  final VoidCallback  onCenter;

  static Color _statusColor(String s) => switch (s) {
    'moving'  => AppColors.statusMoving,
    'stopped' => AppColors.statusStopped,
    'idle'    => AppColors.statusIdle,
    _         => AppColors.statusOffline,
  };

  static String _statusLabel(String s) => switch (s) {
    'moving'  => 'متحرك',
    'stopped' => 'متوقف',
    'idle'    => 'خامل',
    _         => 'مقطوع',
  };

  static IconData _vehicleIcon(String type) => switch (type.toLowerCase()) {
    'truck'                => Icons.local_shipping_rounded,
    'bus'                  => Icons.directions_bus_rounded,
    'motorcycle' || 'moto' => Icons.two_wheeler_rounded,
    'van'                  => Icons.airport_shuttle_rounded,
    _                      => Icons.directions_car_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final sc   = _statusColor(vehicle.status);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: sc.withOpacity(0.3), width: 1.0),
        boxShadow: [
          BoxShadow(
            color: sc.withOpacity(0.12),
            blurRadius: 28,
            offset: const Offset(0, -4),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.38),
            blurRadius: 20,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 32, height: 3,
            decoration: BoxDecoration(
              color: sc.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── Header row ────────────────────────────────────────────────
                Row(
                  children: [
                    // Vehicle type icon
                    Container(
                      width: 46, height: 46,
                      decoration: BoxDecoration(
                        color: sc.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: sc.withOpacity(0.3), width: 0.8),
                      ),
                      child: Icon(_vehicleIcon(vehicle.type), color: sc, size: 24),
                    ),
                    const SizedBox(width: 12),

                    // Name + plate
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.name,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.textPrimary
                                           : const Color(0xFF0D1B2A),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            vehicle.plateNumber,
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Status badge
                    _StatusPill(label: _statusLabel(vehicle.status), color: sc),
                    const SizedBox(width: 8),

                    // Close
                    GestureDetector(
                      onTap: onClose,
                      child: Container(
                        width: 28, height: 28,
                        decoration: BoxDecoration(
                          color: AppColors.textMuted.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // ── Info tiles ────────────────────────────────────────────────
                Row(
                  children: [
                    _InfoTile(
                      icon: Icons.speed_rounded,
                      color: sc,
                      value: FormatUtils.speed(vehicle.speed),
                      label: 'السرعة',
                    ),
                    const SizedBox(width: 8),
                    _InfoTile(
                      icon: vehicle.ignition
                          ? Icons.key_rounded
                          : Icons.key_off_rounded,
                      color: vehicle.ignition
                          ? AppColors.statusMoving
                          : AppColors.textMuted,
                      value: vehicle.ignition ? 'مشتعل' : 'مطفأ',
                      label: 'المحرك',
                    ),
                    const SizedBox(width: 8),
                    _InfoTile(
                      icon: Icons.access_time_rounded,
                      color: AppColors.accent,
                      value: vehicle.lastUpdate != null
                          ? DateFormatter.toRelative(vehicle.lastUpdate!)
                          : '–',
                      label: 'آخر تحديث',
                    ),
                  ],
                ),

                // ── Driver / address ──────────────────────────────────────────
                if (vehicle.driverName != null || vehicle.address != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.textMuted.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: AppColors.border.withOpacity(0.5)),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          vehicle.driverName != null
                              ? Icons.person_rounded
                              : Icons.location_on_rounded,
                          size: 13,
                          color: AppColors.textMuted,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            vehicle.driverName ?? vehicle.address ?? '',
                            style: const TextStyle(
                              fontSize: 11,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 12),

                // ── Action buttons ────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      flex: 5,
                      child: _ActionBtn(
                        icon: Icons.my_location_rounded,
                        label: 'تتبع مباشر',
                        color: AppColors.accent,
                        filled: true,
                        onTap: onTrack,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: _ActionBtn(
                        icon: Icons.center_focus_strong_rounded,
                        label: 'توسيط',
                        color: AppColors.emerald,
                        filled: false,
                        onTap: onCenter,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      flex: 3,
                      child: _ActionBtn(
                        icon: Icons.info_outline_rounded,
                        label: 'التفاصيل',
                        color: AppColors.purple,
                        filled: false,
                        onTap: onDetails,
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

// ─────────────────────────────────────────────────────────────────────────────
// Small reusable widgets
// ─────────────────────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.label, required this.color});
  final String label;
  final Color  color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6, height: 6,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: color.withOpacity(0.6), blurRadius: 4)],
            ),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11, color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
  });
  final IconData icon;
  final Color    color;
  final String   value;
  final String   label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.2), width: 0.8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 12, color: color),
            const SizedBox(height: 3),
            Text(
              value,
              style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700,
                color: color, height: 1.2,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              label,
              style: const TextStyle(
                fontSize: 9, color: AppColors.textMuted,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.filled,
    required this.onTap,
  });
  final IconData     icon;
  final String       label;
  final Color        color;
  final bool         filled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: filled ? color : color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
          border: filled
              ? null
              : Border.all(color: color.withOpacity(0.3), width: 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14,
                color: filled ? Colors.white : color),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w700,
                  color: filled ? Colors.white : color,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Loading / Error states
// ─────────────────────────────────────────────────────────────────────────────

class _MapLoadingState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 28, height: 28,
              child: CircularProgressIndicator(
                color: AppColors.accent, strokeWidth: 2),
            ),
            SizedBox(height: 16),
            Text(
              'جارٍ تحميل الخريطة…',
              style: TextStyle(
                color: AppColors.textSecondary, fontSize: 13),
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
    return ColoredBox(
      color: AppColors.background,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wifi_off_rounded,
                color: AppColors.error, size: 30),
            ),
            const SizedBox(height: 16),
            const Text(
              'تعذّر تحميل بيانات المركبات',
              style: TextStyle(
                color: AppColors.textSecondary, fontSize: 14),
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: onRetry,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.accent.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: AppColors.accent.withOpacity(0.4)),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.refresh_rounded,
                        color: AppColors.accent, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'إعادة المحاولة',
                      style: TextStyle(
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
