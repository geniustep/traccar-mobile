import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'map_config.dart';

// ── Controller ────────────────────────────────────────────────────────────────

/// Stores the active [GoogleMapController] after the map is created.
final mapControllerProvider =
    StateProvider<GoogleMapController?>((ref) => null);

// ── Camera position ───────────────────────────────────────────────────────────

/// Current camera position, updated on every camera move.
final mapCameraProvider = StateProvider<CameraPosition>(
  (ref) => MapConfig.defaultCameraPosition,
);

// ── Map type ──────────────────────────────────────────────────────────────────

final mapTypeProvider = StateProvider<MapType>((ref) => MapConfig.defaultMapType);

// ── Selected entity ───────────────────────────────────────────────────────────

/// ID of the currently selected device marker (null = none selected).
final selectedDeviceIdProvider = StateProvider<int?>((ref) => null);

// ── Map style ─────────────────────────────────────────────────────────────────

enum MapStyleMode { dark, light }

final mapStyleModeProvider =
    StateProvider<MapStyleMode>((ref) => MapStyleMode.dark);

final mapStyleProvider = Provider<String>((ref) {
  final mode = ref.watch(mapStyleModeProvider);
  return switch (mode) {
    MapStyleMode.dark => MapConfig.darkStyle,
    MapStyleMode.light => MapConfig.lightStyle,
  };
});

// ── Map actions ───────────────────────────────────────────────────────────────

/// Helper extension for programmatic camera control via the provider.
extension MapControllerActions on StateController<GoogleMapController?> {
  void moveTo(LatLng target, {double zoom = MapConfig.cityZoom}) {
    state?.animateCamera(
      CameraUpdate.newCameraPosition(
        CameraPosition(target: target, zoom: zoom),
      ),
    );
  }

  void zoomIn() => state?.animateCamera(CameraUpdate.zoomIn());
  void zoomOut() => state?.animateCamera(CameraUpdate.zoomOut());

  void fitBounds(LatLngBounds bounds, {double padding = 60}) {
    state?.animateCamera(
      CameraUpdate.newLatLngBounds(bounds, padding),
    );
  }
}
