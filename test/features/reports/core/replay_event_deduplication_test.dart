import 'package:elmogps/features/map/core/route_event_timeline_models.dart';
import 'package:elmogps/features/reports/core/replay_event_deduplication.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  RouteEventTimelineItem item({
    required RouteTimelineEntryKind kind,
    required DateTime time,
    String key = 'k',
  }) =>
      RouteEventTimelineItem(
        selectionKey: key,
        kind: kind,
        sortTime: time,
        position: const LatLng(1, 2),
        title: key,
        primaryTimeLabel: '',
        detailLine: '',
      );

  test('external overspeed replaces local within 30s', () {
    final t = DateTime.utc(2024, 6, 1, 12);
    final merged = mergeTimelineWithExternalEvents(
      localAndSupplemental: [
        item(kind: RouteTimelineEntryKind.overspeed, time: t, key: 'local'),
      ],
      external: [
        item(
          kind: RouteTimelineEntryKind.overspeed,
          time: t.add(const Duration(seconds: 20)),
          key: 'ext',
        ),
      ],
    );
    expect(merged, hasLength(1));
    expect(merged.single.selectionKey, 'ext');
  });

  test('external alert does not dedupe local stop', () {
    final t = DateTime.utc(2024, 6, 1, 12);
    final merged = mergeTimelineWithExternalEvents(
      localAndSupplemental: [
        item(kind: RouteTimelineEntryKind.stop, time: t, key: 'stop'),
      ],
      external: [
        item(
          kind: RouteTimelineEntryKind.externalEvent,
          time: t.add(const Duration(seconds: 5)),
          key: 'alert',
        ),
      ],
    );
    expect(merged, hasLength(2));
  });

  test('overspeed events 31s apart are both kept', () {
    final t = DateTime.utc(2024, 6, 1, 12);
    final merged = mergeTimelineWithExternalEvents(
      localAndSupplemental: [
        item(kind: RouteTimelineEntryKind.overspeed, time: t, key: 'a'),
      ],
      external: [
        item(
          kind: RouteTimelineEntryKind.overspeed,
          time: t.add(const Duration(seconds: 31)),
          key: 'b',
        ),
      ],
    );
    expect(merged, hasLength(2));
  });
}
