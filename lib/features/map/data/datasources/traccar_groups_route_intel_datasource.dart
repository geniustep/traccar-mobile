import '../../../../core/api/traccar_endpoints.dart';
import '../../../../core/network/traccar_client.dart';

/// Minimal `GET /groups` reader for Route Intelligence only (no group UI).
///
/// Parses Traccar `group.attributes` keyed by numeric group id (Traccar `groupId`).
class TraccarGroupsRouteIntelDataSource {
  const TraccarGroupsRouteIntelDataSource(this._client);

  final TraccarClient _client;

  /// Returns `group id → attributes`. Empty map on HTTP / parse failure (never throws).
  Future<Map<int, Map<String, dynamic>>> fetchGroupAttributesById() async {
    final result = await _client.get<List<Map<String, dynamic>>>(
      TraccarEndpoints.groups,
      fromJson: (j) =>
          (j as List).whereType<Map<String, dynamic>>().toList(),
    );
    return result.when(
      success: (list) {
        final out = <int, Map<String, dynamic>>{};
        for (final g in list) {
          final rawId = g['id'];
          if (rawId is! int) continue;
          out[rawId] =
              Map<String, dynamic>.from(g['attributes'] as Map? ?? {});
        }
        return out;
      },
      failure: (_) => <int, Map<String, dynamic>>{},
    );
  }
}
