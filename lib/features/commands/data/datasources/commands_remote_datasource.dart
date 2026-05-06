import '../../../../core/api/traccar_endpoints.dart';
import '../../../../core/error/app_exception.dart';
import '../../../../core/network/traccar_client.dart';
import '../../../../core/response/result.dart';

/// Remote data source — wraps all Traccar commands-related REST calls.
class CommandsRemoteDatasource {
  const CommandsRemoteDatasource(this._client);

  final TraccarClient _client;

  /// `GET /commands/types?deviceId=X`
  ///
  /// Returns a list of maps like:
  /// `[{ "type": "engineStop" }, { "type": "positionSingle" }, …]`
  Future<Result<List<String>, AppException>> fetchSupportedTypes(
    int deviceId,
  ) =>
      _client.get<List<String>>(
        TraccarEndpoints.commandTypes,
        query: {'deviceId': deviceId},
        fromJson: (data) {
          if (data is! List) return [];
          return data
              .whereType<Map<String, dynamic>>()
              .map((m) => m['type'] as String? ?? '')
              .where((t) => t.isNotEmpty)
              .toList();
        },
      );

  /// `POST /commands/send`
  ///
  /// Body: `{ deviceId, type, attributes: {} }`
  /// Traccar returns 200 or 202 on success.
  Future<Result<void, AppException>> sendCommand({
    required int deviceId,
    required String commandType,
    Map<String, dynamic>? attributes,
  }) async {
    final result = await _client.post<void>(
      TraccarEndpoints.commandSend,
      data: {
        'deviceId': deviceId,
        'type': commandType,
        'attributes': attributes ?? {},
      },
    );
    return result;
  }

  /// `GET /commands?deviceId=X` — fetch saved (queued) commands.
  Future<Result<List<Map<String, dynamic>>, AppException>> fetchSavedCommands(
    int deviceId,
  ) =>
      _client.get<List<Map<String, dynamic>>>(
        TraccarEndpoints.commands,
        query: {'deviceId': deviceId},
        fromJson: (data) {
          if (data is! List) return [];
          return data.whereType<Map<String, dynamic>>().toList();
        },
      );
}
