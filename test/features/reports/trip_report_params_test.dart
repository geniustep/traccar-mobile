import 'package:elmogps/features/map/core/trip_segment_models.dart';
import 'package:elmogps/features/map/core/trip_segment_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('reportFilterParamsForTrip', () {
    test('from/to هي UTC وفق نقاط الرحلة المحلية + buffer', () {
      // Local equivalent of fixed offset (DST-free) for deterministic tests.
      final start = DateTime(2026, 3, 10, 8, 12);
      final end = DateTime(2026, 3, 10, 9, 45);

      final p = reportFilterParamsForTrip(
        vehicleId: '99',
        startTime: start,
        endTime: end,
        config: TripSegmentationConfig.defaults,
      );

      expect(p.from.isUtc, isTrue);
      expect(p.to.isUtc, isTrue);
      expect(p.vehicleId, '99');

      final buf = TripSegmentationConfig.defaults.bufferForReportParams;
      expect(
        p.from,
        start.toUtc().subtract(buf),
      );
      expect(
        p.to,
        end.toUtc().add(buf),
      );
    });
  });

  group('format helpers', () {
    test('formatTripDurationCompact', () {
      expect(formatTripDurationCompact(const Duration(hours: 1, minutes: 33)), '1h 33m');
      expect(formatTripDurationCompact(const Duration(minutes: 50)), '50m');
    });

    test('formatTripDistanceKmValue', () {
      expect(formatTripDistanceKmValue(23.456), '23.5');
    });
  });
}
