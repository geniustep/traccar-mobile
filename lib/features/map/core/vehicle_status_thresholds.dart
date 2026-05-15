/// Central tunables for vehicle status, freshness, and map zoom bands.
///
/// Adjust here instead of scattering magic numbers across screens.
class VehicleStatusThresholds {
  VehicleStatusThresholds._();

  /// Speed above this (km/h) counts as [moving] when device is online.
  static const double movingSpeedKmh = 2.0;

  /// If a live socket fix is older than this, treat as [offline] for merge/display.
  static const Duration maxPositionAgeForLive = Duration(minutes: 20);

  /// Optional future: stricter “stale but not offline” window.
  static const Duration warnPositionAge = Duration(minutes: 10);
}

/// Zoom band constants (Google Maps zoom level).
/// Aligned with [MapConfig.defaultZoom] ≈ 11 and [MapConfig.clusterZoomThreshold] ≈ 14.
class MapZoomThresholds {
  MapZoomThresholds._();

  static const double overviewMax = 8;
  static const double cityBandMax = 12;
  static const double districtBandMax = 14;
  static const double vehicleBandMax = 16;

  /// Fleet: non-selected vehicles switch from pin → top-down SVG at/above this zoom.
  static const double fleetTopDownNonSelectedMin = 15;

  /// Alert pins drawn only at or above this zoom (reduces clutter when zoomed out).
  static const double alertPinsMinZoom = 9;

  /// Today route overlay: hide polyline when zoomed out below this (if layer enabled).
  static const double todayRouteMinZoom = 10;

  /// Tracking / report: hide hourly waypoint markers below this zoom.
  static const double routeHourlyMarkersMinZoom = 13;

  /// Geofence **editor** (GeofenceMapPicker): vertex / circle handle markers.
  static const double geofenceEditorHandlesMinZoom = 12;

  /// Optional title marker on the map (editor read-only preview).
  static const double geofenceEditorTitleMinZoom = 14.5;

  /// Route report map: stop / parking markers from [RouteEventAnalyzer].
  static const double routeStopMarkersReportMinZoom = 13;

  /// Vehicle tracking: same markers (lighter on map).
  static const double routeStopMarkersTrackingMinZoom = 14;

  static const double routeOverspeedMarkersReportMinZoom = 13.5;
  static const double routeOverspeedMarkersTrackingMinZoom = 14.5;

  static const double routeIgnitionMarkersReportMinZoom = 14;
  static const double routeIgnitionMarkersTrackingMinZoom = 15;

  /// Geofences: cap how many shapes we send to the GPU when zoomed out.
  static int geofenceCap(double zoom) {
    if (zoom < overviewMax) return 24;
    if (zoom < cityBandMax) return 40;
    if (zoom < districtBandMax) return 60;
    return 80;
  }
}
