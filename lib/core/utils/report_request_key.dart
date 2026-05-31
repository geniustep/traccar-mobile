/// Builds stable deduplication keys for Traccar `/reports/*` requests.
///
/// Keys intentionally exclude [trigger] so the same logical report is shared
/// across dashboard, fleet snapshot, and reports UI.
abstract final class ReportRequestKey {
  ReportRequestKey._();

  /// UTC timestamp rounded to the minute — collapses millisecond drift.
  static DateTime normalizeUtc(DateTime dt) {
    final u = dt.toUtc();
    return DateTime.utc(
      u.year,
      u.month,
      u.day,
      u.hour,
      u.minute,
    );
  }

  static String normalizeIso(DateTime dt) =>
      normalizeUtc(dt).toIso8601String();

  /// Fleet or single-device report key:
  /// `reports_{type}|{sortedDeviceIds}|{from}|{to}`
  static String build({
    required String reportType,
    required List<int> deviceIds,
    required DateTime from,
    required DateTime to,
  }) {
    final sorted = [...deviceIds]..sort();
    final idsPart = sorted.isEmpty ? '_' : sorted.join(',');
    final fromIso = normalizeIso(from);
    final toIso = normalizeIso(to);
    return 'reports_$reportType|$idsPart|$fromIso|$toIso';
  }

  static String singleDevice({
    required String reportType,
    required String deviceId,
    required DateTime from,
    required DateTime to,
  }) {
    final id = int.tryParse(deviceId);
    return build(
      reportType: reportType,
      deviceIds: id != null ? [id] : [],
      from: from,
      to: to,
    );
  }

  /// Normalizes an existing key (legacy 3-part or current 4-part).
  static String normalizeKey(String key) {
    if (!key.startsWith('reports_')) return key;

    final parts = key.split('|');
    if (parts.length == 3) {
      final from = DateTime.tryParse(parts[1]);
      final to = DateTime.tryParse(parts[2]);
      if (from == null || to == null) return key;
      return '${parts[0]}|${normalizeIso(from)}|${normalizeIso(to)}';
    }
    if (parts.length >= 4) {
      final from = DateTime.tryParse(parts[parts.length - 2]);
      final to = DateTime.tryParse(parts[parts.length - 1]);
      if (from == null || to == null) return key;
      final prefix = parts.sublist(0, parts.length - 2).join('|');
      return '$prefix|${normalizeIso(from)}|${normalizeIso(to)}';
    }
    return key;
  }
}
