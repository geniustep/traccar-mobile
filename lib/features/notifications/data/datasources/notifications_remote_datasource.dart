import 'package:flutter/foundation.dart';
import '../../../../core/api/traccar_endpoints.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/network/traccar_client.dart';
import '../../../../core/response/result.dart';
import '../models/notification_model.dart';

/// Notification history is derived from recent Traccar events.
/// (Traccar's `GET /notifications` returns alert *rules/configuration*, not history.)
class NotificationsRemoteDataSource {
  const NotificationsRemoteDataSource(this._client);

  final TraccarClient _client;

  /// Fetches the last 7 days of events as notification feed.
  Future<List<NotificationModel>> getNotifications() async {
    // 1. Get devices for name lookup
    final devicesResult = await _client.get<List<Map<String, dynamic>>>(
      TraccarEndpoints.devices,
      fromJson: _parseMapList,
    );
    final devices = _unwrap(devicesResult);

    if (devices.isEmpty) return [];

    final nameMap = <int, String>{
      for (final d in devices)
        if (d['id'] is int) (d['id'] as int): d['name'] as String? ?? '',
    };

    // 2. Fetch events for past 7 days
    final now = DateTime.now().toUtc();
    final from = now.subtract(const Duration(days: 7));

    final eventsResult = await _client.get<List<Map<String, dynamic>>>(
      TraccarEndpoints.reportEvents,
      query: {
        'from': from.toIso8601String(),
        'to': now.toIso8601String(),
        'deviceId': nameMap.keys.toList(),
      },
      fromJson: _parseMapList,
    );
    final events = _unwrap(eventsResult);

    return events.map((e) {
      final dId = e['deviceId'] as int?;
      return NotificationModel.fromTraccarEvent(
        e,
        deviceName: dId != null ? (nameMap[dId] ?? '') : '',
      );
    }).toList();
  }

  static List<Map<String, dynamic>> _parseMapList(dynamic json) =>
      parseMapListForTest(json);

  /// Exposed for unit tests only.
  @visibleForTesting
  static List<Map<String, dynamic>> parseMapListForTest(dynamic json) {
    if (json == null) return [];
    if (json is! List) {
      throw const ParseException(
        message: 'Expected a JSON array in response.',
      );
    }
    return json.whereType<Map<String, dynamic>>().toList();
  }

  /// Unwraps [Result] — propagates [AuthException] on 401 without JSON decode.
  static T _unwrap<T>(Result<T, AppException> result) => result.when(
        success: (value) => value,
        failure: (error) => throw error,
      );

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
