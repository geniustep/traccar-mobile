import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../models/traccar_device.dart';
import '../models/traccar_position.dart';
import '../theme/app_colors.dart';

/// Builds custom Google Maps markers for fleet vehicles.
class MarkerBuilder {
  MarkerBuilder._();

  // ── Status hues (using default marker with tint) ───────────────────────────

  static BitmapDescriptor movingMarker() =>
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);

  static BitmapDescriptor stoppedMarker() =>
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange);

  static BitmapDescriptor idleMarker() =>
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure);

  static BitmapDescriptor offlineMarker() =>
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet);

  static BitmapDescriptor selectedMarker() =>
      BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueYellow);

  /// Pick marker colour based on Traccar device status + position speed.
  static BitmapDescriptor forDevice(
    TraccarDevice device,
    TraccarPosition? position, {
    bool isSelected = false,
  }) {
    if (isSelected) return selectedMarker();
    if (device.isOffline) return offlineMarker();
    if (position == null) return offlineMarker();
    if (position.isMoving) return movingMarker();
    if (position.ignitionOn) return idleMarker();
    return stoppedMarker();
  }

  // ── Custom painted markers ─────────────────────────────────────────────────

  /// Creates a circular icon with the device initial and status colour.
  /// Async because it uses [ui.Picture] → [BitmapDescriptor].
  static Future<BitmapDescriptor> customCircleMarker({
    required String label,
    required Color backgroundColor,
    Color textColor = Colors.white,
    double size = 48,
  }) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()..color = backgroundColor;
    final center = Offset(size / 2, size / 2);
    final radius = size / 2;

    // Shadow
    canvas.drawCircle(
      center.translate(0, 2),
      radius,
      Paint()
        ..color = const Color(0x40000000)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    // Background circle
    canvas.drawCircle(center, radius, paint);

    // Border
    canvas.drawCircle(
      center,
      radius - 1,
      Paint()
        ..color = const Color(0x66FFFFFF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Label
    final textPainter = TextPainter(
      text: TextSpan(
        text: label.length > 2 ? label.substring(0, 2) : label,
        style: TextStyle(
          color: textColor,
          fontSize: size * 0.38,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy - textPainter.height / 2,
      ),
    );

    final image = await recorder
        .endRecording()
        .toImage(size.toInt(), size.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  // ── Colour helpers ────────────────────────────────────────────────────────

  static Color colorForStatus(String status) => switch (status.toLowerCase()) {
        'online' || 'moving' => AppColors.success,
        'idle' => AppColors.warning,
        'stopped' => const Color(0xFFFF8C00),
        _ => AppColors.textSecondary,
      };

  /// Build a [Marker] from a [TraccarDevice] and its latest [TraccarPosition].
  static Marker buildMarker({
    required TraccarDevice device,
    required TraccarPosition? position,
    bool isSelected = false,
    VoidCallback? onTap,
    String? snippetText,
  }) {
    final lat = position?.latitude ?? 0;
    final lng = position?.longitude ?? 0;
    final speedText = position != null
        ? '${position.speedKmh.toStringAsFixed(0)} km/h'
        : 'No position';

    return Marker(
      markerId: MarkerId('device_${device.id}'),
      position: LatLng(lat, lng),
      icon: forDevice(device, position, isSelected: isSelected),
      anchor: const Offset(0.5, 1.0),
      infoWindow: InfoWindow(
        title: device.name,
        snippet: snippetText ?? speedText,
      ),
      zIndexInt: isSelected ? 2 : 1,
      onTap: onTap,
    );
  }
}
