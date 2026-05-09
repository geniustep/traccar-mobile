import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/maps/map_config.dart';
import '../../../../core/maps/map_helper.dart';
import '../../../../core/theme/theme_provider.dart';

enum GeofenceDrawKind { circle, polygon }

class GeofenceMapPicker extends ConsumerWidget {
  const GeofenceMapPicker({
    super.key,
    required this.kind,
    required this.center,
    required this.radiusMeters,
    required this.polygonPoints,
    required this.onMapTap,
    required this.strokeColor,
    required this.fillColor,
  });

  final GeofenceDrawKind kind;
  final LatLng? center;
  final double radiusMeters;
  final List<LatLng> polygonPoints;
  final void Function(LatLng position) onMapTap;
  final Color strokeColor;
  final Color fillColor;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    final mapStyle = isDark ? MapConfig.darkStyle : MapConfig.lightStyle;

    final circles = <Circle>{};
    final polygons = <Polygon>{};
    final markers = <Marker>{};

    if (kind == GeofenceDrawKind.circle && center != null) {
      circles.add(
        MapHelper.buildGeofenceCircle(
          id: 'editor_circle',
          center: center!,
          radiusMeters: radiusMeters,
          strokeColor: strokeColor,
          fillColor: fillColor,
        ),
      );
      markers.add(
        Marker(
          markerId: const MarkerId('center'),
          position: center!,
          consumeTapEvents: true,
        ),
      );
    } else if (kind == GeofenceDrawKind.polygon && polygonPoints.length >= 2) {
      polygons.add(
        MapHelper.buildGeofencePolygon(
          id: 'editor_poly',
          points: List<LatLng>.from(polygonPoints),
          strokeColor: strokeColor,
          fillColor: fillColor,
        ),
      );
      for (var i = 0; i < polygonPoints.length; i++) {
        markers.add(
          Marker(
            markerId: MarkerId('pt_$i'),
            position: polygonPoints[i],
            icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
            consumeTapEvents: true,
          ),
        );
      }
    }

    final initial = center ??
        (polygonPoints.isNotEmpty ? polygonPoints.first : null) ??
        MapConfig.defaultCameraPosition.target;

    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        height: 260,
        child: GoogleMap(
          initialCameraPosition: MapHelper.cameraOn(initial, zoom: 14),
          circles: circles,
          polygons: polygons,
          markers: markers,
          onTap: onMapTap,
          zoomControlsEnabled: false,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: false,
          compassEnabled: false,
          style: mapStyle,
        ),
      ),
    );
  }
}
