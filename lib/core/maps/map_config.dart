import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../api/api_config.dart';

/// Central configuration for Google Maps throughout the app.
class MapConfig {
  MapConfig._();

  // ── API ───────────────────────────────────────────────────────────────────

  static String get apiKey => ApiConfig.googleMapsKey;

  // ── Default camera ────────────────────────────────────────────────────────

  /// Default center: Riyadh, Saudi Arabia
  static const LatLng defaultCenter = LatLng(24.7136, 46.6753);
  static const double defaultZoom = 11.0;
  static const double streetZoom = 16.0;
  static const double countryZoom = 6.0;
  static const double cityZoom = 12.0;

  static const CameraPosition defaultCameraPosition = CameraPosition(
    target: defaultCenter,
    zoom: defaultZoom,
  );

  // ── Map UI defaults ───────────────────────────────────────────────────────

  static const bool showTraffic = false;
  static const bool showMyLocation = false;
  static const bool showMyLocationButton = false;
  static const bool showZoomControls = false;
  static const bool showMapToolbar = false;
  static const bool showCompass = false;
  static const bool showIndoorLevelPicker = false;
  static const bool showBuildingsLayer = false;
  static const MapType defaultMapType = MapType.normal;

  // ── Clustering ────────────────────────────────────────────────────────────

  static const double clusteringRadius = 60.0;
  static const double clusterZoomThreshold = 14.0;

  // ── Marker sizes ──────────────────────────────────────────────────────────

  static const double markerIconSize = 40.0;
  static const double selectedMarkerIconSize = 52.0;

  // ── Info window ───────────────────────────────────────────────────────────

  static const double infoWindowAnchorX = 0.5;
  static const double infoWindowAnchorY = 0.0;

  // ── Polyline (route / trip replay) ───────────────────────────────────────

  static const int routePolylineWidth = 4;
  static const int tripPolylineWidth = 3;

  // ── Padding ───────────────────────────────────────────────────────────────

  static const double mapPaddingTop = 120.0;
  static const double mapPaddingBottom = 200.0;
  static const double mapPaddingHorizontal = 32.0;

  // ── Dark map style (JSON) ─────────────────────────────────────────────────

  static const String darkStyle = '''
[
  {"elementType":"geometry","stylers":[{"color":"#0d1b2a"}]},
  {"elementType":"labels.text.fill","stylers":[{"color":"#8fa3b1"}]},
  {"elementType":"labels.text.stroke","stylers":[{"color":"#0d1b2a"}]},
  {"featureType":"administrative","elementType":"geometry","stylers":[{"color":"#1a2e44"}]},
  {"featureType":"road","elementType":"geometry","stylers":[{"color":"#162030"}]},
  {"featureType":"road.arterial","elementType":"geometry","stylers":[{"color":"#1a2e44"}]},
  {"featureType":"road.highway","elementType":"geometry","stylers":[{"color":"#00b4d8"}]},
  {"featureType":"water","elementType":"geometry","stylers":[{"color":"#060d14"}]},
  {"featureType":"poi","stylers":[{"visibility":"off"}]}
]
''';

  static const String lightStyle = '';
}
