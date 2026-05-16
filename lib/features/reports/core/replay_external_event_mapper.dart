import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart' hide TextDirection;

import '../../../core/l10n/app_localizations.dart';
import '../../../core/utils/format_utils.dart';
import '../../alerts/domain/entities/alert.dart';
import '../../map/core/route_event_timeline_models.dart';
import '../../map/data/datasources/route_datasource.dart';
import '../domain/entities/event_report.dart';
import 'replay_external_event.dart';

/// Timeline rows + lookup for replay external events (Phase R4).
class ReplayExternalTimelineBundle {
  const ReplayExternalTimelineBundle({
    required this.items,
    required this.bySelectionKey,
    required this.mapEligibleEvents,
  });

  final List<RouteEventTimelineItem> items;
  final Map<String, ReplayExternalEvent> bySelectionKey;

  /// Events with GPS coordinates (map markers only).
  final List<ReplayExternalEvent> mapEligibleEvents;
}

/// Maps report / alert rows into [ReplayExternalEvent] and timeline items.
abstract final class ReplayExternalEventMapper {
  ReplayExternalEventMapper._();

  static const int maxReportEvents = 250;
  static const int maxBackendAlerts = 150;

  static List<ReplayExternalEvent> fromEventReports(List<EventReport> reports) {
    if (reports.length > maxReportEvents) {
      reports = reports.sublist(0, maxReportEvents);
    }
    return reports
        .map(
          (e) => ReplayExternalEvent(
            id: 're_${e.id}',
            source: ReplayExternalEventSource.reportEvents,
            category: _categoryFromRawType(e.type),
            rawType: e.type,
            title: e.type,
            description: _descriptionForReportEvent(e),
            eventTime: e.eventTime,
            latitude: _latFromAttributes(e.attributes),
            longitude: _lngFromAttributes(e.attributes),
            speedKmh: e.speedKmh,
            severity: e.severity,
          ),
        )
        .toList();
  }

  static List<ReplayExternalEvent> fromAlerts(List<AlertEntity> alerts) {
    if (alerts.length > maxBackendAlerts) {
      alerts = alerts.sublist(0, maxBackendAlerts);
    }
    return alerts
        .map(
          (a) => ReplayExternalEvent(
            id: 'al_${a.id}',
            source: ReplayExternalEventSource.backendAlerts,
            category: _categoryFromRawType(a.type),
            rawType: a.type,
            title: a.title.trim().isNotEmpty ? a.title.trim() : a.type,
            description: a.description.trim(),
            eventTime: a.createdAt,
            latitude: a.latitude,
            longitude: a.longitude,
            speedKmh: _speedFromAlertAttributes(a.attributes),
            severity: a.severity,
          ),
        )
        .toList();
  }

  static List<ReplayExternalEvent> mergeSources({
    required List<EventReport> reportEvents,
    required List<AlertEntity> alerts,
  }) {
    final all = <ReplayExternalEvent>[
      ...fromEventReports(reportEvents),
      ...fromAlerts(alerts),
    ]..sort((a, b) => a.eventTime.compareTo(b.eventTime));
    return all;
  }

  static ReplayExternalTimelineBundle toTimelineBundle(
    List<ReplayExternalEvent> events,
    List<RoutePoint> routePoints,
    AppLocalizations l10n,
  ) {
    final sortedRoute = List<RoutePoint>.from(routePoints)
      ..sort((a, b) => a.fixTime.compareTo(b.fixTime));
    final items = <RouteEventTimelineItem>[];
    final byKey = <String, ReplayExternalEvent>{};
    final mapEligible = <ReplayExternalEvent>[];

    final hm = DateFormat.Hm();

    for (final e in events) {
      final pos = _resolvePosition(e, sortedRoute);
      final kind = _timelineKindForEvent(e);
      final item = RouteEventTimelineItem(
        selectionKey: routeEventTimelineSelectionKey(
          kindCode: 'x${e.category.name[0]}',
          anchorUtc: e.eventTime,
          lat: pos.latitude,
          lng: pos.longitude,
        ),
        kind: kind,
        sortTime: e.eventTime,
        position: pos,
        title: _displayTitle(e, l10n),
        primaryTimeLabel: hm.format(e.eventTime.toLocal()),
        detailLine: _detailLine(e, l10n),
        overspeedMaxSpeedKmh:
            e.speedKmh != null && kind == RouteTimelineEntryKind.overspeed
                ? e.speedKmh
                : null,
      );
      items.add(item);
      byKey[item.selectionKey] = e;
      if (e.hasCoordinates) mapEligible.add(e);
    }

    return ReplayExternalTimelineBundle(
      items: items,
      bySelectionKey: byKey,
      mapEligibleEvents: mapEligible,
    );
  }

  static LatLng _resolvePosition(
    ReplayExternalEvent e,
    List<RoutePoint> sortedRoute,
  ) {
    if (e.hasCoordinates) {
      return LatLng(e.latitude!, e.longitude!);
    }
    final nearest = _nearestRoutePoint(sortedRoute, e.eventTime);
    if (nearest != null) return nearest.position;
    return const LatLng(0, 0);
  }

  static RoutePoint? _nearestRoutePoint(
    List<RoutePoint> sorted,
    DateTime time,
  ) {
    if (sorted.isEmpty) return null;
    RoutePoint? best;
    var bestMs = 1 << 62;
    for (final p in sorted) {
      final d = (p.fixTime.difference(time)).inMilliseconds.abs();
      if (d < bestMs) {
        bestMs = d;
        best = p;
      }
    }
    return best;
  }

  static RouteTimelineEntryKind _timelineKindForEvent(ReplayExternalEvent e) {
    if (e.category == ReplayExternalEventCategory.ignition) {
      final t = e.rawType.toLowerCase();
      if (t.contains('on')) return RouteTimelineEntryKind.ignitionOn;
      if (t.contains('off')) return RouteTimelineEntryKind.ignitionOff;
    }
    return switch (e.category) {
      ReplayExternalEventCategory.overspeed =>
        RouteTimelineEntryKind.overspeed,
      ReplayExternalEventCategory.stop => RouteTimelineEntryKind.stop,
      ReplayExternalEventCategory.ignition =>
        RouteTimelineEntryKind.externalEvent,
      ReplayExternalEventCategory.geofence ||
      ReplayExternalEventCategory.maintenance ||
      ReplayExternalEventCategory.alert ||
      ReplayExternalEventCategory.unknown =>
        RouteTimelineEntryKind.externalEvent,
    };
  }

  static String _displayTitle(ReplayExternalEvent e, AppLocalizations l10n) {
    if (e.title.trim().isNotEmpty && e.title != e.rawType) {
      return e.title.trim();
    }
    return switch (e.category) {
      ReplayExternalEventCategory.overspeed => l10n.overspeedEvents,
      ReplayExternalEventCategory.ignition => l10n.replaySnapshotIgnition,
      ReplayExternalEventCategory.stop => l10n.reportsStops,
      ReplayExternalEventCategory.geofence => l10n.geofenceZoneEntry,
      ReplayExternalEventCategory.maintenance =>
        l10n.replayExternalMaintenance,
      ReplayExternalEventCategory.alert => l10n.replayExternalAlert,
      ReplayExternalEventCategory.unknown => l10n.replayExternalEvent,
    };
  }

  static String _detailLine(ReplayExternalEvent e, AppLocalizations l10n) {
    final parts = <String>[];
    if (e.description.isNotEmpty) parts.add(e.description);
    if (e.speedKmh != null) {
      parts.add('${l10n.maxSpeedLabel}: ${FormatUtils.speed(e.speedKmh!)}');
    }
    if (parts.isEmpty) return l10n.replayExternalEvent;
    return parts.join(' · ');
  }

  static ReplayExternalEventCategory _categoryFromRawType(String type) {
    final t = type.toLowerCase();
    if (t.contains('overspeed') || t == 'deviceoverspeed') {
      return ReplayExternalEventCategory.overspeed;
    }
    if (t.startsWith('ignition')) {
      return ReplayExternalEventCategory.ignition;
    }
    if (t.contains('stop') || t == 'devicestopped') {
      return ReplayExternalEventCategory.stop;
    }
    if (t.contains('geofence')) {
      return ReplayExternalEventCategory.geofence;
    }
    if (t.contains('maintenance')) {
      return ReplayExternalEventCategory.maintenance;
    }
    if (t == 'alarm' || t.contains('sos')) {
      return ReplayExternalEventCategory.alert;
    }
    return ReplayExternalEventCategory.unknown;
  }

  static String _descriptionForReportEvent(EventReport e) {
    if (e.speedKmh != null) {
      return FormatUtils.speed(e.speedKmh!);
    }
    return e.type;
  }

  static double? _latFromAttributes(Map<String, dynamic> attrs) {
    final v = attrs['latitude'] ?? attrs['lat'];
    return (v as num?)?.toDouble();
  }

  static double? _lngFromAttributes(Map<String, dynamic> attrs) {
    final v = attrs['longitude'] ?? attrs['lng'];
    return (v as num?)?.toDouble();
  }

  static double? _speedFromAlertAttributes(Map<String, dynamic> attrs) {
    final knots = (attrs['speed'] as num?)?.toDouble();
    if (knots == null) return null;
    return knots * 1.852;
  }
}
