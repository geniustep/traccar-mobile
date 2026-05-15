import 'package:elmogps/core/l10n/app_localizations.dart';
import 'package:elmogps/features/map/core/daily_behavior_score_models.dart';
import 'package:elmogps/features/map/core/driver_behavior_score_models.dart';
import 'package:elmogps/features/map/core/trip_segment_models.dart';
import 'package:elmogps/features/map/presentation/utils/daily_behavior_score_formatters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  final l10nEn = AppLocalizations(const Locale('en'));
  final l10nFr = AppLocalizations(const Locale('fr'));

  TripSegment fakeTrip(int index) => TripSegment(
        selectionKey: 'k$index',
        vehicleId: '1',
        index: index,
        startTime: DateTime.utc(2025, 1, 1, 8),
        endTime: DateTime.utc(2025, 1, 1, 9),
        duration: const Duration(hours: 1),
        startPosition: const LatLng(36.8, 10.1),
        endPosition: const LatLng(36.81, 10.11),
        distanceKm: 10,
        maxSpeedKmh: 50,
        avgSpeedKmh: 35,
        stopCount: 1,
        totalStopDuration: Duration.zero,
        overspeedCount: 0,
        ignitionOnCount: 0,
        ignitionOffCount: 0,
        hasIgnitionData: false,
      );

  group('DailyBehaviorScoreUi.periodScoreSummaryLine', () {
    test('scorable shows score and risk label (EN)', () {
      const daily = DailyVehicleBehaviorScore(
        score: 82,
        riskLevel: DriverRiskLevel.good,
        isScorable: true,
        totalTrips: 2,
        scorableTrips: 2,
        unscorableTrips: 0,
        totalDistanceKm: 40,
        totalDuration: Duration(hours: 1),
        totalOverspeedEvents: 1,
        totalStops: 2,
        totalStopDuration: Duration.zero,
        tripScoreEntries: [],
        weightedAverageRaw: 82,
        arithmeticAverageScore: 82,
      );
      final line = DailyBehaviorScoreUi.periodScoreSummaryLine(l10nEn, daily);
      expect(DailyBehaviorScoreUi.periodSummaryLooksScorable(l10nEn, line, 82), isTrue);
      expect(line, contains(l10nEn.driverScoreGood));
      expect(line, isNot(contains('${l10nEn.driverScoreLabel} 0')));
    });

    test('not scorable returns empty line (no score 0 surface)', () {
      const daily = DailyVehicleBehaviorScore(
        score: 0,
        riskLevel: DriverRiskLevel.unknown,
        isScorable: false,
        totalTrips: 3,
        scorableTrips: 0,
        unscorableTrips: 3,
        totalDistanceKm: 5,
        totalDuration: Duration(minutes: 10),
        totalOverspeedEvents: 0,
        totalStops: 0,
        totalStopDuration: Duration.zero,
        tripScoreEntries: [],
      );
      final line = DailyBehaviorScoreUi.periodScoreSummaryLine(l10nEn, daily);
      expect(line, isEmpty);
      expect(line, isNot(contains('0')));
    });
  });

  group('DailyBehaviorScoreUi.periodStatsMidLine', () {
    test('joins trip count distance overspeed stops', () {
      const daily = DailyVehicleBehaviorScore(
        score: 0,
        riskLevel: DriverRiskLevel.unknown,
        isScorable: false,
        totalTrips: 5,
        scorableTrips: 0,
        unscorableTrips: 5,
        totalDistanceKm: 123.4,
        totalDuration: Duration.zero,
        totalOverspeedEvents: 3,
        totalStops: 4,
        totalStopDuration: Duration.zero,
        tripScoreEntries: [],
      );
      final line = DailyBehaviorScoreUi.periodStatsMidLine(l10nEn, daily);
      expect(line, contains('5'));
      expect(line, contains('123.4'));
      expect(line, contains('3'));
      expect(line, contains('4'));
      expect(line, contains('·'));
    });
  });

  group('DailyBehaviorScoreUi best/worst trip lines', () {
    test('null trips yield null lines', () {
      expect(DailyBehaviorScoreUi.bestTripLine(l10nEn, null), isNull);
      expect(DailyBehaviorScoreUi.worstTripLine(l10nEn, null), isNull);
    });

    test('uses Trip title with index', () {
      final t = fakeTrip(2);
      final b = DailyBehaviorScoreUi.bestTripLine(l10nEn, t);
      expect(b, isNotNull);
      expect(b, contains(l10nEn.tripTitle(2)));
    });
  });

  test('FR not-scorable wording matches request style', () {
    expect(l10nFr.dailyScoreNotScorable, contains('éval'));
    expect(l10nFr.dailyScoreInsufficientData.toLowerCase(), contains('données'));
    expect(l10nFr.dailyScoreInsufficientData.toLowerCase(), contains('insuffis'));
  });

  group('DailyBehaviorScoreUi.shouldShowUnscoredExcludedHint', () {
    test('true when scored period still has unscorable legs', () {
      const daily = DailyVehicleBehaviorScore(
        score: 90,
        riskLevel: DriverRiskLevel.excellent,
        isScorable: true,
        totalTrips: 4,
        scorableTrips: 3,
        unscorableTrips: 1,
        totalDistanceKm: 20,
        totalDuration: Duration(hours: 1),
        totalOverspeedEvents: 0,
        totalStops: 0,
        totalStopDuration: Duration.zero,
        tripScoreEntries: [],
        weightedAverageRaw: 90,
        arithmeticAverageScore: 90,
      );
      expect(DailyBehaviorScoreUi.shouldShowUnscoredExcludedHint(daily), isTrue);
    });

    test('false when none unscorable or not scorable', () {
      const allScored = DailyVehicleBehaviorScore(
        score: 90,
        riskLevel: DriverRiskLevel.excellent,
        isScorable: true,
        totalTrips: 3,
        scorableTrips: 3,
        unscorableTrips: 0,
        totalDistanceKm: 20,
        totalDuration: Duration.zero,
        totalOverspeedEvents: 0,
        totalStops: 0,
        totalStopDuration: Duration.zero,
        tripScoreEntries: [],
      );
      expect(DailyBehaviorScoreUi.shouldShowUnscoredExcludedHint(allScored), isFalse);
      expect(
        DailyBehaviorScoreUi.shouldShowUnscoredExcludedHint(
          const DailyVehicleBehaviorScore(
            score: 0,
            riskLevel: DriverRiskLevel.unknown,
            isScorable: false,
            totalTrips: 2,
            scorableTrips: 0,
            unscorableTrips: 2,
            totalDistanceKm: 1,
            totalDuration: Duration.zero,
            totalOverspeedEvents: 0,
            totalStops: 0,
            totalStopDuration: Duration.zero,
            tripScoreEntries: [],
          ),
        ),
        isFalse,
      );
    });
  });

  group('DailyBehaviorScoreUi.sheetAvoidsNumericZeroScoreLine', () {
    test('non-scorable copy does not show Score 0 headline', () {
      const daily = DailyVehicleBehaviorScore(
        score: 0,
        riskLevel: DriverRiskLevel.unknown,
        isScorable: false,
        totalTrips: 2,
        scorableTrips: 0,
        unscorableTrips: 2,
        totalDistanceKm: 3,
        totalDuration: Duration(minutes: 20),
        totalOverspeedEvents: 1,
        totalStops: 2,
        totalStopDuration: Duration(minutes: 5),
        tripScoreEntries: [],
      );
      final simulated = [
        l10nEn.dailyScoreNotScorable,
        l10nEn.dailyScoreInsufficientData,
        l10nEn.tripsTitle,
        '${daily.totalTrips}',
        l10nEn.dailyScoreNoEvaluatedTrips,
        l10nEn.tripDistance,
        l10nEn.dailyScoreTotalDuration,
      ].join('\n');
      expect(DailyBehaviorScoreUi.sheetAvoidsNumericZeroScoreLine(l10nEn, simulated), isTrue);
      expect(DailyBehaviorScoreUi.periodScoreSummaryLine(l10nEn, daily), isEmpty);
    });
  });

  group('evaluated/unscored count labels accessible', () {
    test('EN labels non-empty', () {
      expect(l10nEn.dailyScoreEvaluatedTrips, isNotEmpty);
      expect(l10nEn.dailyScoreUnscoredTrips, isNotEmpty);
      expect(l10nEn.dailyScoreUnscoredExcludedHint, isNotEmpty);
    });
  });
}
