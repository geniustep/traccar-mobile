import 'package:flutter_test/flutter_test.dart';

import 'package:elmogps/features/map/presentation/utils/route_intel_local_threshold_form_parse.dart';

void main() {
  group('parseRouteIntelLocalFormInputs', () {
    test('reject empty or invalid numeric fields', () {
      expect(
        parseRouteIntelLocalFormInputs(
          stopSpeedEnterRaw: '',
          stopSpeedExitRaw: '5',
          minStopMinutesRaw: '4',
          overspeedRaw: '80',
          detectStops: true,
          detectOverspeed: true,
          detectIgnition: true,
        ).invalidNumeric,
        isTrue,
      );
      expect(
        parseRouteIntelLocalFormInputs(
          stopSpeedEnterRaw: '3',
          stopSpeedExitRaw: '5',
          minStopMinutesRaw: '0',
          overspeedRaw: '80',
          detectStops: true,
          detectOverspeed: true,
          detectIgnition: true,
        ).invalidNumeric,
        isTrue,
      );
      expect(
        parseRouteIntelLocalFormInputs(
          stopSpeedEnterRaw: '3',
          stopSpeedExitRaw: '5',
          minStopMinutesRaw: '4',
          overspeedRaw: '0',
          detectStops: true,
          detectOverspeed: true,
          detectIgnition: true,
        ).invalidNumeric,
        isTrue,
      );
    });

    test('exit below enter is corrected by normalized', () {
      final o = parseRouteIntelLocalFormInputs(
        stopSpeedEnterRaw: '10',
        stopSpeedExitRaw: '2',
        minStopMinutesRaw: '4',
        overspeedRaw: '80',
        detectStops: true,
        detectOverspeed: true,
        detectIgnition: true,
      );
      expect(o.invalidNumeric, isFalse);
      expect(o.thresholds!.stopSpeedEnterKmh, 10);
      expect(o.thresholds!.stopSpeedExitKmh, 10);
    });

    test('comma decimal separator parses', () {
      final o = parseRouteIntelLocalFormInputs(
        stopSpeedEnterRaw: '3,5',
        stopSpeedExitRaw: '5',
        minStopMinutesRaw: '4',
        overspeedRaw: '80',
        detectStops: false,
        detectOverspeed: false,
        detectIgnition: false,
      );
      expect(o.invalidNumeric, isFalse);
      expect(o.thresholds!.stopSpeedEnterKmh, 3.5);
      expect(o.thresholds!.detectStops, isFalse);
    });
  });

  group('routeIntelParseNonNegativeFiniteDouble', () {
    test('rejects negatives', () {
      expect(routeIntelParseNonNegativeFiniteDouble('-1'), isNull);
    });
  });
}
