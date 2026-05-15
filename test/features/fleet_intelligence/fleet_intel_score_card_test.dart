import 'package:elmogps/core/l10n/app_localizations.dart';
import 'package:elmogps/features/fleet_intelligence/presentation/screens/fleet_intelligence_dashboard_screen.dart';
import 'package:elmogps/features/map/core/fleet_intelligence_metrics_models.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FleetIntelScoreCard — unscorable shows not rated not 0',
      (tester) async {
    final m = FleetIntelligenceMetrics(
      totalVehicles: 1,
      activeVehicles: 0,
      inactiveVehicles: 1,
      vehiclesWithTrips: 0,
      totalTrips: 0,
      totalDistanceKm: 0,
      totalDrivingDuration: Duration.zero,
      totalStopDuration: Duration.zero,
      totalStops: 0,
      totalOverspeedEvents: 0,
      averageScore: 0,
      isScorable: false,
      riskDistribution: const FleetRiskDistribution(
        excellentCount: 0,
        goodCount: 0,
        moderateCount: 0,
        highRiskCount: 0,
        unknownCount: 1,
      ),
      bestVehicleSummary: null,
      worstVehicleSummary: null,
      mostActiveVehicleSummary: null,
      mostOverspeedVehicleSummary: null,
      mostStoppedVehicleSummary: null,
      vehiclesNeedingAttention: [],
      vehicleSummaries: [],
      weightedAverageRaw: null,
    );

    late AppLocalizations l10n;

    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: const [
          AppLocalizations.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('en'),
          Locale('ar'),
          Locale('fr'),
          Locale('es'),
        ],
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return Scaffold(
              body: FleetIntelScoreCard(l10n: l10n, metrics: m),
            );
          },
        ),
      ),
    );

    await tester.pumpAndSettle();
    expect(find.textContaining(l10n.driverScoreLabel), findsNothing);
    expect(find.text(l10n.driverScoreNotScorable), findsOneWidget);
  });
}
