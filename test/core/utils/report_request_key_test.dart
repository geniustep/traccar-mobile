import 'package:flutter_test/flutter_test.dart';
import 'package:elmogps/core/utils/report_request_key.dart';

void main() {
  group('ReportRequestKey', () {
    test('normalizes to UTC minute boundary', () {
      final raw = DateTime.utc(2026, 5, 16, 12, 35, 44, 771, 480);
      final n = ReportRequestKey.normalizeUtc(raw);
      expect(n, DateTime.utc(2026, 5, 16, 12, 35));
    });

    test('build sorts device ids and excludes trigger', () {
      final key = ReportRequestKey.build(
        reportType: 'events',
        deviceIds: [11, 1, 9],
        from: DateTime.utc(2026, 5, 16, 0),
        to: DateTime.utc(2026, 5, 16, 12, 35, 44),
      );
      expect(key, contains('1,9,11'));
      expect(key, 'reports_events|1,9,11|2026-05-16T00:00:00.000Z|2026-05-16T12:35:00.000Z');
    });

    test('normalizeKey collapses millisecond drift on 4-part keys', () {
      final a = ReportRequestKey.build(
        reportType: 'trips',
        deviceIds: [2],
        from: DateTime.utc(2026, 5, 16, 0),
        to: DateTime.utc(2026, 5, 16, 12, 35, 43, 951),
      );
      final b = ReportRequestKey.build(
        reportType: 'trips',
        deviceIds: [2],
        from: DateTime.utc(2026, 5, 16, 0),
        to: DateTime.utc(2026, 5, 16, 12, 35, 44, 771),
      );
      expect(ReportRequestKey.normalizeKey(a), ReportRequestKey.normalizeKey(b));
    });
  });
}
