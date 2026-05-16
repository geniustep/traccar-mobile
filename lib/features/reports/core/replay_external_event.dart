import 'package:flutter/foundation.dart';

/// Source of a replay-period event (Phase R4).
enum ReplayExternalEventSource {
  reportEvents,
  backendAlerts,
}

/// Category used for timeline display and deduplication.
enum ReplayExternalEventCategory {
  alert,
  overspeed,
  ignition,
  stop,
  maintenance,
  geofence,
  unknown,
}

/// Normalized event from Backend / reports for replay integration.
@immutable
class ReplayExternalEvent {
  const ReplayExternalEvent({
    required this.id,
    required this.source,
    required this.category,
    required this.rawType,
    required this.title,
    required this.description,
    required this.eventTime,
    this.latitude,
    this.longitude,
    this.speedKmh,
    this.severity,
  });

  final String id;
  final ReplayExternalEventSource source;
  final ReplayExternalEventCategory category;
  final String rawType;
  final String title;
  final String description;
  final DateTime eventTime;
  final double? latitude;
  final double? longitude;
  final double? speedKmh;
  final String? severity;

  bool get hasCoordinates =>
      latitude != null &&
      longitude != null &&
      (latitude!.abs() > 1e-6 || longitude!.abs() > 1e-6);
}
