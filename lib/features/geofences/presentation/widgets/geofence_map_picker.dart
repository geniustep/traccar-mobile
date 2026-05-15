import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/maps/map_config.dart';
import '../../../../core/maps/map_helper.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../map/core/geofence_map_renderer.dart';
import '../../../map/core/map_zoom_policy.dart';

enum GeofenceDrawKind { circle, polygon }

/// Embedded map for drawing or previewing a single geofence.
///
/// Uses [GeofenceMapRenderer.buildEditorGeometry] + [MapZoomPolicy] for outline
/// weight and for showing vertex / center handles only when zoomed in enough.
class GeofenceMapPicker extends ConsumerStatefulWidget {
  const GeofenceMapPicker({
    super.key,
    required this.kind,
    required this.center,
    required this.radiusMeters,
    required this.polygonPoints,
    required this.onMapTap,
    required this.strokeColor,
    required this.fillColor,
    /// Increment when the editor loads geometry so the camera fits once.
    this.fitNonce = 0,
    /// Read-only preview title (e.g. geofence name) — shown as marker info when zoom ≥ threshold.
    this.mapTitle,
    /// Shown as a light overlay when [interactive] and geometry not ready (e.g. circle awaiting first tap).
    this.emptyHint,
    this.interactive = true,
  });

  final GeofenceDrawKind kind;
  final LatLng? center;
  final double radiusMeters;
  final List<LatLng> polygonPoints;
  final void Function(LatLng position) onMapTap;
  final Color strokeColor;
  final Color fillColor;
  final int fitNonce;
  final String? mapTitle;
  final String? emptyHint;
  final bool interactive;

  @override
  ConsumerState<GeofenceMapPicker> createState() => _GeofenceMapPickerState();
}

class _GeofenceMapPickerState extends ConsumerState<GeofenceMapPicker> {
  GoogleMapController? _controller;
  double _cameraZoom = 14;
  int? _lastAppliedFitNonce;

  LatLng get _fallbackTarget =>
      widget.center ??
      (widget.polygonPoints.isNotEmpty
          ? widget.polygonPoints.first
          : MapConfig.defaultCameraPosition.target);

  List<LatLng> _boundsPointsForFit() {
    if (widget.kind == GeofenceDrawKind.circle && widget.center != null) {
      final c = widget.center!;
      final r = widget.radiusMeters.clamp(30.0, 5000.0);
      final dLat = r / 111320.0;
      final dLng =
          r / (111320.0 * math.cos(c.latitude * math.pi / 180).clamp(0.2, 1.0));
      return [
        LatLng(c.latitude + dLat, c.longitude + dLng),
        LatLng(c.latitude - dLat, c.longitude - dLng),
      ];
    }
    if (widget.kind == GeofenceDrawKind.polygon &&
        widget.polygonPoints.length >= 2) {
      return List<LatLng>.from(widget.polygonPoints);
    }
    if (widget.center != null) return [widget.center!];
    if (widget.polygonPoints.isNotEmpty) return [widget.polygonPoints.first];
    return [];
  }

  Future<void> _fitBounds() async {
    final c = _controller;
    if (c == null) return;
    final pts = _boundsPointsForFit();
    if (pts.isEmpty) return;
    if (pts.length == 1) {
      await c.animateCamera(
        CameraUpdate.newLatLngZoom(pts.first, math.max(_cameraZoom, 15)),
      );
      return;
    }
    final upd = MapHelper.fitPoints(pts, padding: 52);
    if (upd != null) {
      await c.animateCamera(upd);
    }
  }

  void _maybeFitForNonce() {
    if (widget.fitNonce == 0) return;
    if (_lastAppliedFitNonce == widget.fitNonce) return;
    final pts = _boundsPointsForFit();
    if (pts.isEmpty) return;
    _lastAppliedFitNonce = widget.fitNonce;
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      await _fitBounds();
    });
  }

  @override
  void didUpdateWidget(covariant GeofenceMapPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fitNonce != oldWidget.fitNonce) {
      _lastAppliedFitNonce = null;
      _maybeFitForNonce();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final mapStyle = isDark ? MapConfig.darkStyle : MapConfig.lightStyle;

    final policy = MapZoomPolicy.at(_cameraZoom);
    final strokePx = policy.geofenceEditorStrokeWidthPx();

    final isCircle = widget.kind == GeofenceDrawKind.circle;
    final (circles, polygons) = GeofenceMapRenderer.buildEditorGeometry(
      isCircle: isCircle,
      center: widget.center,
      radiusMeters: widget.radiusMeters,
      polygonPoints: widget.polygonPoints,
      strokeColor: widget.strokeColor,
      fillColor: widget.fillColor,
      strokeWidthPx: strokePx,
    );

    final markers = <Marker>{};

    if (isCircle &&
        widget.center != null &&
        policy.showGeofenceEditorCircleCenterPin()) {
      markers.add(
        Marker(
          markerId: const MarkerId('gf_editor_center'),
          position: widget.center!,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
          anchor: const Offset(0.5, 0.5),
          consumeTapEvents: false,
          zIndexInt: 2,
          infoWindow: const InfoWindow(),
        ),
      );
    }

    if (!isCircle &&
        widget.polygonPoints.isNotEmpty &&
        policy.showGeofenceEditorVertexHandles()) {
      for (var i = 0; i < widget.polygonPoints.length; i++) {
        markers.add(
          Marker(
            markerId: MarkerId('gf_pt_$i'),
            position: widget.polygonPoints[i],
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            anchor: const Offset(0.5, 0.5),
            consumeTapEvents: false,
            zIndexInt: 2,
            infoWindow: InfoWindow(
              snippet: '${i + 1} / ${widget.polygonPoints.length}',
            ),
          ),
        );
      }
    }

    final title = widget.mapTitle?.trim();
    if (title != null &&
        title.isNotEmpty &&
        policy.showGeofenceEditorMapTitle()) {
      LatLng? labelPos = widget.center;
      labelPos ??=
          widget.polygonPoints.isNotEmpty ? widget.polygonPoints.first : null;
      if (labelPos != null) {
        markers.add(
          Marker(
            markerId: const MarkerId('gf_editor_title'),
            position: labelPos,
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
            anchor: const Offset(0.5, 0.5),
            consumeTapEvents: false,
            zIndexInt: 0,
            alpha: 0.85,
            infoWindow: InfoWindow(title: title),
          ),
        );
      }
    }

    final showEmptyOverlay = widget.interactive &&
        widget.emptyHint != null &&
        widget.emptyHint!.isNotEmpty &&
        ((isCircle && widget.center == null) ||
            (!isCircle && widget.polygonPoints.isEmpty));

    final mapChild = GoogleMap(
      initialCameraPosition: MapHelper.cameraOn(_fallbackTarget, zoom: 14),
      circles: circles,
      polygons: polygons,
      markers: markers,
      onTap: widget.interactive
          ? widget.onMapTap
          : (_) {},
      zoomControlsEnabled: false,
      myLocationButtonEnabled: false,
      mapToolbarEnabled: false,
      compassEnabled: false,
      style: mapStyle,
      onMapCreated: (c) {
        _controller = c;
        c.getZoomLevel().then((z) {
          if (mounted) setState(() => _cameraZoom = z);
        });
        _maybeFitForNonce();
      },
      onCameraIdle: () {
        _controller?.getZoomLevel().then((z) {
          if (!mounted) return;
          if ((z - _cameraZoom).abs() > 0.02) {
            setState(() => _cameraZoom = z);
          }
        });
      },
    );

    Widget content = mapChild;
    if (showEmptyOverlay) {
      content = Stack(
        fit: StackFit.expand,
        children: [
          mapChild,
          IgnorePointer(
            child: Container(
              alignment: Alignment.center,
              color: Colors.black.withValues(alpha: 0.06),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                widget.emptyHint!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.75),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 260,
        child: content,
      ),
    );
  }
}
