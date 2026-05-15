import 'package:elmogps/core/l10n/app_localizations.dart';
import 'package:elmogps/features/map/core/trip_segment_models.dart';
import 'package:elmogps/features/map/presentation/utils/trip_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  test(
      'TripUiFormatters titre / plage horaire / sous-ligne sans fournisseur technique',
      () {
    final l10nEn = AppLocalizations(const Locale('en'));
    final l10nFr = AppLocalizations(const Locale('fr'));

    final start = DateTime(2026, 7, 1, 9, 5);
    final end = DateTime(2026, 7, 1, 10, 42);
    final segment = TripSegment(
      selectionKey: 'trip_test_k',
      vehicleId: '1',
      index: 3,
      startTime: start,
      endTime: end,
      duration: end.difference(start),
      startPosition: const LatLng(36.8, 10.1),
      endPosition: const LatLng(36.9, 10.15),
      distanceKm: 8.812,
      maxSpeedKmh: 107,
      avgSpeedKmh: 61,
      stopCount: 2,
      totalStopDuration: const Duration(minutes: 14),
      overspeedCount: 0,
      ignitionOnCount: 0,
      ignitionOffCount: 0,
      hasIgnitionData: false,
    );

    expect(TripUiFormatters.tripTitle(l10nFr, 3), contains('3'));
    expect(TripUiFormatters.tripTitle(l10nEn, 3), contains('3'));

    final range = TripUiFormatters.tripTimeRangeHm(l10nFr, segment);
    expect(range, contains('→'));

    final subtitle = TripUiFormatters.tripSubtitleLine(l10nEn, segment);
    expect(subtitle.toLowerCase(), isNot(contains('traccar')));
    expect(subtitle, contains('8.8'));
    expect(subtitle.contains('GPS'), isFalse);

    expect(
      TripUiFormatters.tripsNone(l10nFr),
      isNotEmpty,
    );
  });
}
