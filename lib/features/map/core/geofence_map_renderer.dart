import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/utils/geofence_area_codec.dart';
import '../../geofences/domain/entities/geofence.dart';
import '../../../../core/maps/map_helper.dart';
import 'vehicle_status_thresholds.dart';

/// Renders geofence circles/polygons for map layers (fleet map, etc.).
class GeofenceMapRenderer {
  GeofenceMapRenderer._();

  static (Set<Circle>, Set<Polygon>) buildShapes(
    List<GeofenceEntity> geos, {
    required double mapZoom,
  }) {
    final maxN = MapZoomThresholds.geofenceCap(mapZoom);
    final cap = geos.length > maxN ? geos.sublist(0, maxN) : geos;

    final circles = <Circle>{};
    final polygons = <Polygon>{};
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

  /// Circle/polygon geometry for [GeofenceMapPicker] (shared stroke/fill wiring with fleet preview).
  static (Set<Circle> circles, Set<Polygon> polygons) buildEditorGeometry({
    required bool isCircle,
    LatLng? center,
    required double radiusMeters,
    required List<LatLng> polygonPoints,
    required Color strokeColor,
    required Color fillColor,
    required int strokeWidthPx,
    String circleId = 'editor_circle',
    String polygonId = 'editor_poly',
  }) {
    final circles = <Circle>{};
    final polygons = <Polygon>{};
    if (isCircle && center != null) {
      circles.add(
        MapHelper.buildGeofenceCircle(
          id: circleId,
          center: center,
          radiusMeters: radiusMeters,
          strokeColor: strokeColor,
          fillColor: fillColor,
          strokeWidth: strokeWidthPx,
        ),
      );
    } else if (!isCircle && polygonPoints.length >= 2) {
      polygons.add(
        MapHelper.buildGeofencePolygon(
          id: polygonId,
          points: List<LatLng>.from(polygonPoints),
          strokeColor: strokeColor,
          fillColor: fillColor,
          strokeWidth: strokeWidthPx,
        ),
      );
    }
    return (circles, polygons);
  }
}
