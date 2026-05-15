import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/vehicle_category_utils.dart';
import '../../vehicles/domain/entities/vehicle.dart';
import 'vehicle_marker_style.dart';

class _NavCarBodyTintMapper extends ColorMapper {
  const _NavCarBodyTintMapper(this.bodyColor);

  final Color bodyColor;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    if (id == 'nav-car-body' && attributeName == 'fill') {
      return bodyColor;
    }
    return color;
  }
}

/// Unified marker bitmaps for fleet + single-vehicle tracking screens.
///
/// Caches descriptors so SVG / canvas work is not repeated every frame.
class VehicleMarkerFactory {
  VehicleMarkerFactory._();

  static final Map<String, BitmapDescriptor> _cache = {};

  /// Body / pin colour: alert override, then semantic status colours.
  static Color pinBodyColor({
    required VehicleEntity v,
    required Set<String> alertVehicleIds,
    required VehicleMarkerStyle style,
  }) {
    final forceAlert = style == VehicleMarkerStyle.alert ||
        alertVehicleIds.contains(v.id);
    if (forceAlert) return AppColors.error;

    return switch (v.status) {
      'moving' => AppColors.statusMoving,
      'idle' => AppColors.statusIdle,
      'stopped' => AppColors.statusStopped,
      _ => AppColors.statusOffline,
    };
  }

  static BitmapDescriptor fallbackPinHue(String status) => switch (status) {
        'moving' => BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueGreen,
          ),
        'idle' => BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueAzure,
          ),
        'stopped' => BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueOrange,
          ),
        _ => BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      };

  static String pinDescriptorCacheKey(
    VehicleEntity v,
    Color body,
    VehicleMarkerStyle style,
  ) =>
      'pin_${style.name}_${v.id}_${v.status}_${Object.hash(v.type, body.r, body.g, body.b, body.a)}';

  /// Teardrop pin with Material category glyph — used for [fleet] & [tracking].
  static Future<BitmapDescriptor> buildTeardropPin(
    VehicleEntity v,
    Color bodyColor,
  ) async {
    const double w = 56;
    const double circleR = 22;
    const double totalH = 68;
    const double cx = w / 2;
    const double cy = circleR + 2;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, w, totalH));

    canvas.drawCircle(
      Offset(cx, cy + 3),
      circleR,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    canvas.drawPath(
      Path()
        ..moveTo(cx - 8, cy + circleR - 5)
        ..lineTo(cx, totalH)
        ..lineTo(cx + 8, cy + circleR - 5)
        ..close(),
      Paint()
        ..color = Colors.black.withValues(alpha: 0.2)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4),
    );

    canvas.drawCircle(Offset(cx, cy), circleR, Paint()..color = bodyColor);

    canvas.drawPath(
      Path()
        ..moveTo(cx - 8, cy + circleR - 5)
        ..lineTo(cx, totalH - 2)
        ..lineTo(cx + 8, cy + circleR - 5)
        ..close(),
      Paint()..color = bodyColor,
    );

    canvas.drawCircle(
      Offset(cx, cy),
      circleR - 0.5,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.28)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final iconPainter = TextPainter(
      text: TextSpan(
        text: String.fromCharCode(vehicleCategoryIcon(v.type).codePoint),
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
      Offset(cx - iconPainter.width / 2, cy - iconPainter.height / 2),
    );

    final picture = recorder.endRecording();
    final image = await picture.toImage(w.toInt(), totalH.toInt());
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    return BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
  }

  static Color clusterColorForMembers(
    List<VehicleEntity> members,
    Set<String> alertVehicleIds,
  ) {
    if (members.any((v) => alertVehicleIds.contains(v.id))) {
      return AppColors.error;
    }
    var moving = 0, idle = 0, stopped = 0, offline = 0;
    for (final v in members) {
      switch (v.status) {
        case 'moving':
          moving++;
          break;
        case 'idle':
          idle++;
          break;
        case 'stopped':
          stopped++;
          break;
        default:
          offline++;
      }
    }
    final best = [
      (moving, AppColors.statusMoving),
      (idle, AppColors.statusIdle),
      (stopped, AppColors.statusStopped),
      (offline, AppColors.statusOffline),
    ]..sort((a, b) => b.$1.compareTo(a.$1));
    if (best.first.$1 > 0) return best.first.$2;
    return AppColors.accent;
  }

  static Color clusterBorderColor(
    List<VehicleEntity> members,
    Set<String> alertVehicleIds,
  ) {
    if (members.any((v) => alertVehicleIds.contains(v.id))) {
      return Colors.white;
    }
    if (members.any((v) => v.isOffline)) {
      return AppColors.warning;
    }
    return Colors.white;
  }

  static Color replayBodyColorForSpeed(double speedKmh) {
    if (speedKmh < 5) return const Color(0xFF9E9E9E);
    if (speedKmh < 40) return AppColors.statusMoving;
    if (speedKmh < 80) return AppColors.statusStopped;
    return AppColors.error;
  }

  static String northUpCarCacheKey(Color body, int sizePx) =>
      'car_north_${Object.hash(body.r, body.g, body.b, body.a, sizePx)}';

  /// Bitmap aligned north; apply [Marker.rotation] with [Marker.flat] = true.
  static Future<BitmapDescriptor> topDownCarNorthUp({
    required Color bodyColor,
    double size = 80,
  }) async {
    final key = northUpCarCacheKey(bodyColor, size.round());
    final hit = _cache[key];
    if (hit != null) return hit;

    const svgLogical = 80.0;

    final PictureInfo pictureInfo = await vg.loadPicture(
      SvgAssetLoader(
        'assets/map/nav_car_top.svg',
        colorMapper: _NavCarBodyTintMapper(bodyColor),
      ),
      null,
      clipViewbox: false,
    );

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));

    final cx = size * 0.5;
    final cy = size * 0.5;
    final scale = size / svgLogical;

    canvas.save();
    canvas.translate(cx, cy);
    canvas.scale(scale);
    canvas.translate(-svgLogical / 2, -svgLogical / 2);
    canvas.drawPicture(pictureInfo.picture);
    canvas.restore();

    pictureInfo.picture.dispose();

    final pic = recorder.endRecording();
    final img = await pic.toImage(size.toInt(), size.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final d = BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
    _cache[key] = d;
    return d;
  }

  /// Course is **not** baked — use [Marker.rotation] for heading.
  static Future<BitmapDescriptor> topDownCar({
    required Color bodyColor,
    double courseDeg = 0,
    double size = 80,
  }) =>
      topDownCarNorthUp(bodyColor: bodyColor, size: size);

  static Future<BitmapDescriptor> topDownCarNorthUpForReplaySpeed(
    double speedKmh, {
    double size = 72,
  }) =>
      topDownCarNorthUp(
        bodyColor: replayBodyColorForSpeed(speedKmh),
        size: size,
      );

  /// Selected fleet vehicle: cache by id + body tint + rendered size only (heading via [Marker.rotation]).
  static String selectedCarCacheKey(
    VehicleEntity v,
    Color body,
    int sizePx,
  ) =>
      '${v.id}_${northUpCarCacheKey(body, sizePx)}';

  static Future<BitmapDescriptor> clusterDisc({
    required int count,
    required Color fill,
    required Color border,
  }) async {
    final key =
        'cl_${count}_h${Object.hash(fill.r, fill.g, fill.b, fill.a, border.r, border.g, border.b)}';
    final hit = _cache[key];
    if (hit != null) return hit;

    const size = 112.0;
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, size, size));
    final cx = size / 2;
    final cy = size / 2;
    const r = 38.0;

    canvas.drawCircle(
      Offset(cx, cy + 4),
      r + 2,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.22)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    canvas.drawCircle(
      Offset(cx, cy),
      r + 2,
      Paint()
        ..color = border.withValues(alpha: 0.95)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4,
    );
    canvas.drawCircle(Offset(cx, cy), r, Paint()..color = fill);

    final label = count > 999 ? '999+' : '$count';
    final tp = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 26,
          fontWeight: FontWeight.w800,
        ),
      ),
      textDirection: ui.TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(cx - tp.width / 2, cy - tp.height / 2));

    final pic = recorder.endRecording();
    final img = await pic.toImage(size.toInt(), size.toInt());
    final bytes = await img.toByteData(format: ui.ImageByteFormat.png);
    final d = BitmapDescriptor.bytes(bytes!.buffer.asUint8List());
    _cache[key] = d;
    return d;
  }
}
