/// Represents a paginated list of items with navigation helpers.
class Paginated<T> {
  const Paginated({
    required this.items,
    required this.page,
    required this.pageSize,
    required this.total,
  });

  final List<T> items;
  final int page;
  final int pageSize;
  final int total;

  int get totalPages => (total / pageSize).ceil();
  bool get hasNextPage => page < totalPages;
  bool get hasPreviousPage => page > 1;
  bool get isEmpty => items.isEmpty;
  bool get isFirstPage => page == 1;
  bool get isLastPage => page >= totalPages;

  /// Build from Traccar-style flat list (no server-side pagination metadata).
  /// Slices the full list locally.
  factory Paginated.fromList(
    List<T> all, {
    int page = 1,
    int pageSize = 20,
  }) {
    final start = ((page - 1) * pageSize).clamp(0, all.length);
    final end = (start + pageSize).clamp(0, all.length);
    return Paginated<T>(
      items: all.sublist(start, end),
      page: page,
      pageSize: pageSize,
      total: all.length,
    );
  }

  /// Build from a server response that carries total/page metadata.
  factory Paginated.fromJson(
    dynamic raw,
    T Function(Map<String, dynamic>) fromJson,
    int page,
    int pageSize,
  ) {
    List<dynamic> list;
    int total = 0;

    if (raw is Map<String, dynamic>) {
      list = raw['data'] as List<dynamic>? ?? [];
      total = raw['total'] as int? ?? list.length;
    } else if (raw is List) {
      list = raw;
      total = raw.length;
    } else {
      list = [];
    }

    return Paginated<T>(
      items: list
          .whereType<Map<String, dynamic>>()
          .map(fromJson)
          .toList(),
      page: page,
      pageSize: pageSize,
      total: total,
    );
  }

  Paginated<U> mapItems<U>(U Function(T) transform) => Paginated<U>(
        items: items.map(transform).toList(),
        page: page,
        pageSize: pageSize,
        total: total,
      );

  @override
  String toString() =>
      'Paginated(page: $page/$totalPages, items: ${items.length}/$total)';
}
