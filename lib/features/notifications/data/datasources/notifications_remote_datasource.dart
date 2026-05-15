import 'package:flutter/foundation.dart';
import '../../../../core/network/traccar_client.dart';
import '../../../../core/api/traccar_endpoints.dart';
import '../models/notification_model.dart';

/// Notification history is derived from recent Traccar events.
/// (Traccar's `GET /notifications` returns alert *rules/configuration*, not history.)
class NotificationsRemoteDataSource {
  const NotificationsRemoteDataSource(this._client);

  final TraccarClient _client;

  /// Fetches the last 7 days of events as notification feed.
  Future<List<NotificationModel>> getNotifications() async {
    // 1. Get devices for name lookup
    final devices = (await _client.get<List<Map<String, dynamic>>>(
      TraccarEndpoints.devices,
      fromJson: (j) =>
          (j as List).whereType<Map<String, dynamic>>().toList(),
    )).getOrThrow();

    if (devices.isEmpty) return [];

    final nameMap = <int, String>{
      for (final d in devices)
        if (d['id'] is int) (d['id'] as int): d['name'] as String? ?? '',
    };

    // 2. Fetch events for past 7 days
    final now = DateTime.now().toUtc();
    final from = now.subtract(const Duration(days: 7));

    final events = (await _client.get<List<Map<String, dynamic>>>(
      TraccarEndpoints.reportEvents,
      query: {
        'from': from.toIso8601String(),
        'to': now.toIso8601String(),
        'deviceId': nameMap.keys.toList(),
      },
      fromJson: (j) =>
          (j as List).whereType<Map<String, dynamic>>().toList(),
    )).getOrThrow();

    return events.map((e) {
      final dId = e['deviceId'] as int?;
      return NotificationModel.fromTraccarEvent(
        e,
        deviceName: dId != null ? (nameMap[dId] ?? '') : '',
      );
    }).toList();
  }

  /// Traccar has no "mark as read" API for events.
  /// Read state is managed locally (shared_preferences or in-memory).
  Future<void> markAsRead(String id) async {}

  /// No-op for Traccar.
  Future<void> markAllAsRead() async {}

  /// Registers the FCM push token with the custom backend endpoint.
  ///
  /// Endpoint:  POST /fcm/register-token
  /// Payload:
  ///   { "token": "...", "platform": "android", "appVersion": "1.0.0" }
  ///
  /// Returns normally on success (2xx).
  /// Logs the error and returns normally on failure so the caller is never
  /// interrupted — push token registration is best-effort.
  Future<void> registerFcmToken(String token) async {
    debugPrint('[FCM] POST /fcm/register-token → sending token to backend…');

    final result = await _client.post<dynamic>(
      '/fcm/register-token',
      data: {
        'token': token,
        'platform': 'android',
        'appVersion': '1.0.0',
      },
    );

    result.when(
      success: (_) {
        debugPrint('[FCM] POST /fcm/register-token ✓ token registered successfully.');
      },
      failure: (ex) {
        debugPrint('[FCM] POST /fcm/register-token ✗ failed: ${ex.message}');
      },
    );
  }
}
