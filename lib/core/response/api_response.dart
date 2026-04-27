/// Generic wrapper for any API response.
///
/// Handles both list-based and single-object responses from Traccar,
/// along with optional metadata (total count, page info).
class ApiResponse<T> {
  const ApiResponse({
    required this.data,
    this.statusCode,
    this.message,
    this.total,
    this.page,
    this.pageSize,
  });

  final T data;
  final int? statusCode;
  final String? message;

  /// Total records on the server (from X-Total-Count or response body)
  final int? total;
  final int? page;
  final int? pageSize;

  bool get hasMore => total != null && page != null && pageSize != null
      ? (page! * pageSize!) < total!
      : false;

  bool get isOk => (statusCode ?? 200) < 400;

  /// Build from a raw JSON map where the list is under a `data` key.
  factory ApiResponse.fromJson(
    dynamic raw,
    T Function(dynamic) fromJson, {
    int? statusCode,
  }) {
    if (raw is Map<String, dynamic>) {
      final dataNode = raw.containsKey('data') ? raw['data'] : raw;
      return ApiResponse<T>(
        data: fromJson(dataNode),
        statusCode: statusCode,
        message: raw['message'] as String?,
        total: raw['total'] as int?,
        page: raw['page'] as int?,
        pageSize: raw['pageSize'] as int?,
      );
    }

    // Traccar returns bare arrays for most list endpoints
    return ApiResponse<T>(
      data: fromJson(raw),
      statusCode: statusCode,
    );
  }

  ApiResponse<U> mapData<U>(U Function(T) transform) => ApiResponse<U>(
        data: transform(data),
        statusCode: statusCode,
        message: message,
        total: total,
        page: page,
        pageSize: pageSize,
      );

  @override
  String toString() =>
      'ApiResponse(status: $statusCode, total: $total, data: $data)';
}
