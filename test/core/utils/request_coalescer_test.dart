import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:elmogps/core/utils/request_coalescer.dart';

void main() {
  group('RequestCoalescer', () {
    late RequestCoalescer coalescer;

    setUp(() {
      coalescer = RequestCoalescer(cacheTtl: const Duration(seconds: 2));
    });

    test('first call executes the fetcher and returns result', () async {
      var callCount = 0;
      final result = await coalescer.coalesce('key1', () async {
        callCount++;
        return 42;
      });

      expect(result, 42);
      expect(callCount, 1);
    });

    test('concurrent calls with same key return same result without re-fetching', () async {
      var callCount = 0;
      final completer = Completer<int>();

      final future1 = coalescer.coalesce('key1', () {
        callCount++;
        return completer.future;
      });
      final future2 = coalescer.coalesce('key1', () {
        callCount++;
        return completer.future;
      });
      final future3 = coalescer.coalesce('key1', () {
        callCount++;
        return completer.future;
      });

      completer.complete(99);

      final results = await Future.wait([future1, future2, future3]);

      expect(results, [99, 99, 99]);
      expect(callCount, 1, reason: 'Only one HTTP call should be made');
    });

    test('different keys execute separate fetchers', () async {
      var callCount = 0;

      final r1 = await coalescer.coalesce('key_a', () async {
        callCount++;
        return 'a';
      });
      final r2 = await coalescer.coalesce('key_b', () async {
        callCount++;
        return 'b';
      });

      expect(r1, 'a');
      expect(r2, 'b');
      expect(callCount, 2);
    });

    test('cached result is returned within TTL without re-fetching', () async {
      var callCount = 0;

      await coalescer.coalesce('key1', () async {
        callCount++;
        return 'first';
      });

      final result = await coalescer.coalesce('key1', () async {
        callCount++;
        return 'second';
      });

      expect(result, 'first', reason: 'Should return cached result');
      expect(callCount, 1, reason: 'Should not re-fetch within TTL');
    });

    test('invalidateAll clears cache, next call re-fetches', () async {
      var callCount = 0;

      await coalescer.coalesce('key1', () async {
        callCount++;
        return 'first';
      });

      coalescer.invalidateAll();

      final result = await coalescer.coalesce('key1', () async {
        callCount++;
        return 'second';
      });

      expect(result, 'second');
      expect(callCount, 2);
    });

    test('invalidate(key) clears specific key only', () async {
      var callCountA = 0;
      var callCountB = 0;

      await coalescer.coalesce('a', () async {
        callCountA++;
        return 'a1';
      });
      await coalescer.coalesce('b', () async {
        callCountB++;
        return 'b1';
      });

      coalescer.invalidate('a');

      final ra = await coalescer.coalesce('a', () async {
        callCountA++;
        return 'a2';
      });
      final rb = await coalescer.coalesce('b', () async {
        callCountB++;
        return 'b2';
      });

      expect(ra, 'a2', reason: 'Key a should be re-fetched');
      expect(rb, 'b1', reason: 'Key b should be cached');
      expect(callCountA, 2);
      expect(callCountB, 1);
    });

    test('error in fetcher propagates and does not cache', () async {
      var callCount = 0;

      await expectLater(
        coalescer.coalesce('err', () async {
          callCount++;
          throw Exception('network error');
        }),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'toString',
            contains('network error'),
          ),
        ),
      );

      // Next call should re-attempt, not return cached error
      final result = await coalescer.coalesce('err', () async {
        callCount++;
        return 'recovered';
      });

      expect(result, 'recovered');
      expect(callCount, 2);
    });

    test('concurrent calls where fetcher errors: all callers receive the error', () async {
      var callCount = 0;
      final completer = Completer<int>();

      final f1 = coalescer.coalesce('fail', () {
        callCount++;
        return completer.future;
      });
      final f2 = coalescer.coalesce('fail', () {
        callCount++;
        return completer.future;
      });

      completer.completeError(Exception('boom'));

      expect(f1, throwsA(isA<Exception>()));
      expect(f2, throwsA(isA<Exception>()));
      expect(callCount, 1);
    });

    test('reports/events with same from/to key are coalesced', () async {
      var callCount = 0;
      final from = '2026-05-13T00:00:00.000Z';
      final to = '2026-05-13T12:00:00.000Z';
      final key = 'reports_events|1,2|$from|$to';

      final completer = Completer<List<String>>();

      final f1 = coalescer.coalesce(key, () {
        callCount++;
        return completer.future;
      });
      final f2 = coalescer.coalesce(key, () {
        callCount++;
        return completer.future;
      });

      completer.complete(['event1', 'event2']);

      final r1 = await f1;
      final r2 = await f2;

      expect(r1, ['event1', 'event2']);
      expect(r2, ['event1', 'event2']);
      expect(callCount, 1, reason: 'Same reports key should fire only once');
    });

    test('reports key with different sub-second to still coalesces', () async {
      var callCount = 0;
      final keyA =
          'reports_events|9,11|2026-05-16T00:00:00.000Z|2026-05-16T12:35:43.951400Z';
      final keyB =
          'reports_events|9,11|2026-05-16T00:00:00.000Z|2026-05-16T12:35:44.771480Z';

      final completer = Completer<List<String>>();

      final f1 = coalescer.coalesce(keyA, () {
        callCount++;
        return completer.future;
      });
      final f2 = coalescer.coalesce(keyB, () {
        callCount++;
        return completer.future;
      });

      completer.complete(['e1']);

      await Future.wait([f1, f2]);
      expect(callCount, 1);
    });
  });
}
