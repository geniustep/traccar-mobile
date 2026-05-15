import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../alerts/domain/entities/alert.dart';
import '../../dashboard/data/services/dashboard_alert_filter.dart';

/// Alert pins on fleet map — separated from [LiveMapScreen] to keep UI lean.
class AlertMarkerBuilder {
  AlertMarkerBuilder._();

  static Set<Marker> buildImportantUnread({
    required List<AlertEntity> alerts,
  }) {
    final markers = <Marker>{};
    var i = 0;
    for (final a in alerts) {
      if (a.isRead || !DashboardAlertFilter.isImportantAlert(a)) continue;
      if (!a.hasLocation) continue;
      final lat = a.latitude!;
      final lng = a.longitude!;
      markers.add(
        Marker(
          markerId: MarkerId('al_${a.id}_$i'),
          position: LatLng(lat, lng),
          anchor: const Offset(0.5, 0.9),
          zIndexInt: 0,
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
          infoWindow: InfoWindow(title: a.title),
        ),
      );
      i++;
    }
    return markers;
  }
}
