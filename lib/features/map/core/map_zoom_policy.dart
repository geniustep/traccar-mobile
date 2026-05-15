import 'vehicle_marker_style.dart';
import 'vehicle_status_thresholds.dart';

/// Decides what to draw / how heavy processing should be for a given map zoom.
///
/// Used by live fleet, single-vehicle tracking, report maps, and replay (where applicable).
class MapZoomPolicy {
  const MapZoomPolicy._(this.zoom, {this.visibleVehicleCount = 0});

  final double zoom;

  /// Fleet only: number of vehicles currently drawn (after filters). Used to avoid
  /// allocating dozens of SVG markers when zoom is “high” but fleet is large.
  final int visibleVehicleCount;

  factory MapZoomPolicy.at(double zoom, {int visibleVehicleCount = 0}) =>
      MapZoomPolicy._(zoom, visibleVehicleCount: visibleVehicleCount);

  bool get isOverview => zoom < MapZoomThresholds.overviewMax;
  bool get isCityBand =>
      zoom >= MapZoomThresholds.overviewMax &&
      zoom < MapZoomThresholds.cityBandMax;
  bool get isDistrictBand =>
      zoom >= MapZoomThresholds.cityBandMax &&
      zoom < MapZoomThresholds.districtBandMax;

  /// Clustering still handled by grid in [buildLiveMapClusterBuckets]; zoom ≥ threshold ⇒ no clusters.
  bool shouldCluster(int vehicleCount) {
    if (zoom >= MapZoomThresholds.districtBandMax) return false;
    if (vehicleCount <= 1) return false;
    return true;
  }

  /// Alias for readability in callers (`VehicleMarkerFactory` + zoom gates).
  bool useTopDownVehicleIcon({required bool selected}) =>
      useTopDownForFleetVehicle(selected: selected);

  bool usePinMarker({required bool selected}) =>
      usePinForFleetVehicle(selected: selected);

  /// Fleet: show top-down SVG for a **non-selected** vehicle (selected always allowed separately).
  bool useTopDownForFleetVehicle({required bool selected}) {
    if (selected) return true;
    if (zoom < MapZoomThresholds.fleetTopDownNonSelectedMin) return false;
    if (visibleVehicleCount > 48) return false;
    return true;
  }

  bool usePinForFleetVehicle({required bool selected}) =>
      !useTopDownForFleetVehicle(selected: selected);

  /// Single-vehicle tracking: prefer SVG car whenever zoom allows sensible detail.
  bool useTopDownForTracking() =>
      zoom >= MapZoomThresholds.cityBandMax - 1; // ≈ 11 — whole page is about one vehicle

  /// Always use top-down for dedicated tracking UI (caller can still respect zoom).
  static bool useTopDownForTrackingScreenDefault() => true;

  bool useTopDownForReplay() => zoom >= MapZoomThresholds.cityBandMax - 1;

  /// Placeholder for future vehicle title chips beside markers.
  bool showVehicleLabels() => zoom >= MapZoomThresholds.vehicleBandMax + 0.5;

  bool showAlertPins({required bool layerEnabled}) {
    if (!layerEnabled) return false;
    return zoom >= MapZoomThresholds.alertPinsMinZoom;
  }

  bool showTodayRouteOverlay({required bool layerEnabled}) {
    if (!layerEnabled) return false;
    return zoom >= MapZoomThresholds.todayRouteMinZoom;
  }

  bool showRouteHourlyMarkers() =>
      zoom >= MapZoomThresholds.routeHourlyMarkersMinZoom;

  bool showRouteMaxSpeedMarker() => zoom >= MapZoomThresholds.routeHourlyMarkersMinZoom - 0.5;

  /// Historical / analysis maps: show full detail marker set.
  bool showRouteReportFullMarkers() => zoom >= MapZoomThresholds.routeHourlyMarkersMinZoom;

  double markerScale({VehicleMarkerStyle style = VehicleMarkerStyle.fleet}) {
    if (style == VehicleMarkerStyle.selected ||
        style == VehicleMarkerStyle.tracking) {
      if (zoom < 12) return 0.85;
      if (zoom < 15) return 1.0;
      return 1.1;
    }
    if (zoom < 11) return 0.9;
    if (zoom < 14) return 1.0;
    return 1.05;
  }

  int maxVisibleRoutePointsForDecimation() {
    if (zoom < MapZoomThresholds.overviewMax) return 120;
    if (zoom < MapZoomThresholds.cityBandMax) return 280;
    if (zoom < MapZoomThresholds.districtBandMax) return 500;
    return 900;
  }

  // ── Geofence editor (GeofenceMapPicker) ───────────────────────────────────

  bool showGeofenceEditorVertexHandles() =>
      zoom >= MapZoomThresholds.geofenceEditorHandlesMinZoom;

  bool showGeofenceEditorCircleCenterPin() =>
      zoom >= MapZoomThresholds.geofenceEditorHandlesMinZoom;

  bool showGeofenceEditorMapTitle() =>
      zoom >= MapZoomThresholds.geofenceEditorTitleMinZoom;

  /// Stroke width in logical px for editor circle/polygon outlines.
  int geofenceEditorStrokeWidthPx() {
    if (zoom < MapZoomThresholds.overviewMax) return 1;
    if (zoom < MapZoomThresholds.districtBandMax) return 2;
    return 3;
  }

  // ── Route intelligence markers (stops / overspeed / ignition) ───────────

  /// [reportStyle] true = route report map (slightly more detail at same zoom).
  bool showRouteStopMarkers({required bool reportStyle}) =>
      zoom >=
          (reportStyle
              ? MapZoomThresholds.routeStopMarkersReportMinZoom
              : MapZoomThresholds.routeStopMarkersTrackingMinZoom);

  bool showRouteOverspeedMarkers({required bool reportStyle}) =>
      zoom >=
          (reportStyle
              ? MapZoomThresholds.routeOverspeedMarkersReportMinZoom
              : MapZoomThresholds.routeOverspeedMarkersTrackingMinZoom);

  bool showRouteIgnitionMarkers({required bool reportStyle}) =>
      zoom >=
          (reportStyle
              ? MapZoomThresholds.routeIgnitionMarkersReportMinZoom
              : MapZoomThresholds.routeIgnitionMarkersTrackingMinZoom);

  int routeEventStopMarkerBudget({required bool reportStyle}) {
    if (!showRouteStopMarkers(reportStyle: reportStyle)) return 0;
    if (zoom < 13.5) return reportStyle ? 4 : 2;
    if (zoom < 15) return reportStyle ? 10 : 5;
    return reportStyle ? 22 : 12;
  }

  int routeEventOverspeedMarkerBudget({required bool reportStyle}) {
    if (!showRouteOverspeedMarkers(reportStyle: reportStyle)) return 0;
    if (zoom < 14) return reportStyle ? 3 : 2;
    if (zoom < 15.5) return reportStyle ? 8 : 5;
    return reportStyle ? 18 : 10;
  }

  int routeEventIgnitionMarkerBudget({required bool reportStyle}) {
    if (!showRouteIgnitionMarkers(reportStyle: reportStyle)) return 0;
    return reportStyle ? 16 : 10;
  }
}
