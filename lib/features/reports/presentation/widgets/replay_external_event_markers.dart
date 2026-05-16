import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/l10n/app_localizations.dart';
import '../../../map/core/route_event_timeline_models.dart';
import '../../core/replay_external_event_mapper.dart';

/// Map markers for replay external events with GPS (Phase R4).
abstract final class ReplayExternalEventMarkers {
  ReplayExternalEventMarkers._();

  static const int maxMarkers = 20;

  static Set<Marker> build({
    required ReplayExternalTimelineBundle bundle,
    required AppLocalizations l10n,
    required String vehicleId,
    ValueChanged<RouteEventTimelineItem>? onMarkerTap,
    String? selectedEventKey,
  }) {
    if (bundle.mapEligibleEvents.isEmpty) return const {};

    final itemByKey = {
      for (final i in bundle.items) i.selectionKey: i,
    };

    final markers = <Marker>{};
    final consumeTap = onMarkerTap != null;
    var added = 0;

    for (final entry in bundle.bySelectionKey.entries) {
      if (added >= maxMarkers) break;
      final event = entry.value;
      if (!event.hasCoordinates) continue;

      final item = itemByKey[entry.key];
      if (item == null) continue;

      final selected =
          selectedEventKey != null && item.selectionKey == selectedEventKey;
      markers.add(
        Marker(
          markerId: MarkerId('${vehicleId}_replay_ext_${event.id}'),
          position: LatLng(event.latitude!, event.longitude!),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            selected ? BitmapDescriptor.hueOrange : BitmapDescriptor.hueRose,
          ),
          anchor: const Offset(0.5, 0.5),
          consumeTapEvents: consumeTap,
          zIndexInt: selected ? 5 : 4,
          onTap: onMarkerTap == null ? null : () => onMarkerTap(item),
          infoWindow: InfoWindow(
            title: item.title,
            snippet: item.primaryTimeLabel,
          ),
        ),
      );
      added++;
    }

    return markers;
  }
}
