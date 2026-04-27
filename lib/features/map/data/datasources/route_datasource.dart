import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../core/network/traccar_client.dart';
import '../../../../core/api/traccar_endpoints.dart';

/// A single position point from Traccar's route report.
class RoutePoint {
  const RoutePoint({
    required this.position,
    required this.speed,
    required this.course,
    required this.fixTime,
    required this.ignition,
  });

  final LatLng position;
  final double speed;   // km/h (converted from knots)
  final double course;  // degrees 0–360
  final DateTime fixTime;
  final bool ignition;

  factory RoutePoint.fromJson(Map<String, dynamic> json) {
    final attrs =
        Map<String, dynamic>.from(json['attributes'] as Map? ?? {});
    return RoutePoint(
      position: LatLng(
        (json['latitude'] as num?)?.toDouble() ?? 0,
        (json['longitude'] as num?)?.toDouble() ?? 0,
      ),
      speed: ((json['speed'] as num?)?.toDouble() ?? 0) * 1.852,
      course: (json['course'] as num?)?.toDouble() ?? 0,
      fixTime: DateTime.tryParse(
                  json['fixTime'] as String? ?? '')?.toLocal() ??
              DateTime.now(),
      ignition: attrs['ignition'] as bool? ?? false,
    );
  }
}

class RouteDataSource {
  const RouteDataSource(this._client);

  final TraccarClient _client;

  /// Fetches route points for [deviceId] between [from] and [to].
  ///
  /// Defaults to today (midnight → now) when dates are omitted.
  Future<List<RoutePoint>> getRoute(
    String deviceId, {
    DateTime? from,
    DateTime? to,
  }) async {
    final now = DateTime.now().toUtc();
    final start = from ??
        DateTime.utc(now.year, now.month, now.day);
    final end = to ?? now;

    final raw = (await _client.get<List<Map<String, dynamic>>>(
      TraccarEndpoints.reportRoute,
      query: {
        'deviceId': int.tryParse(deviceId) ?? deviceId,
        'from': start.toIso8601String(),
        'to': end.toIso8601String(),
      },
      fromJson: (j) =>
          (j as List).whereType<Map<String, dynamic>>().toList(),
    )).getOrThrow();

    return raw.map(RoutePoint.fromJson).toList();
  }

  /// Fetches the latest position for [deviceId].
  Future<Map<String, dynamic>?> getCurrentPosition(String deviceId) async {
    final list = (await _client.get<List<Map<String, dynamic>>>(
      TraccarEndpoints.positions,
      query: {'deviceId': int.tryParse(deviceId) ?? deviceId},
      fromJson: (j) =>
          (j as List).whereType<Map<String, dynamic>>().toList(),
    )).getOrThrow();
    return list.isNotEmpty ? list.first : null;
  }
}
