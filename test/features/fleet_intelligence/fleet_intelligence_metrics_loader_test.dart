import 'package:elmogps/features/fleet_intelligence/application/fleet_intelligence_metrics_loader.dart';
import 'package:elmogps/features/fleet_intelligence/domain/fleet_intelligence_query.dart';
import 'package:elmogps/features/map/core/route_intelligence_thresholds.dart';
import 'package:elmogps/features/map/data/datasources/route_datasource.dart';
import 'package:elmogps/features/vehicles/domain/entities/vehicle.dart';
import 'package:flutter_test/flutter_test.dart';

VehicleEntity _v(
  String id, {
  String name = 'N',
  bool online = true,
  String groupId = 'g',
}) {
  return VehicleEntity(
    id: id,
    name: name,
    plateNumber: '',
    type: 'car',
    status: online ? 'moving' : 'offline',
    speed: 0,
    latitude: 0,
    longitude: 0,
    address: null,
    lastUpdate: DateTime.now(),
    ignition: false,
    batteryVoltage: 0,
    fuelLevel: 0,
    driverName: '',
    groupId: groupId,
  );
}

void main() {
  final th = RouteIntelligenceThresholds.defaults;
  final t0 = DateTime(2026, 5, 10);
  final t1 = DateTime(2026, 5, 10, 23, 59);

  test('respects maxVehicles and reports skippedBeyondCap', () async {
    final vehicles =
        List.generate(5, (i) => _v('$i', online: true));
    final q = FleetIntelligenceQuery(
      fromLocal: t0,
      toLocal: t1,
      maxVehicles: 2,
      includeInactive: false,
    );

    var calls = 0;
    final dash = await FleetIntelligenceMetricsLoader.load(
      query: q,
      allVehicles: vehicles,
      thresholds: th,
      fetchRoute: (id, {from, to}) async {
        calls++;
        return const <RoutePoint>[];
      },
    );

    expect(dash.loadInfo.routesAnalyzed, 2);
    expect(dash.loadInfo.skippedBeyondCap, 3);
    expect(calls, 2);
  });

  test('single route failure does not fail whole load', () async {
    final vehicles = [_v('ok'), _v('fail')];
    final q = FleetIntelligenceQuery(fromLocal: t0, toLocal: t1, maxVehicles: 10);

    final dash = await FleetIntelligenceMetricsLoader.load(
      query: q,
      allVehicles: vehicles,
      thresholds: th,
      fetchRoute: (id, {from, to}) async {
        if (id == 'fail') throw Exception('net');
        return const <RoutePoint>[];
      },
    );

    expect(dash.loadInfo.routesFailedPartial, 1);
    expect(dash.partialErrorsCount, 1);
    expect(dash.metrics.totalVehicles, 2);
  });

  test('vehicles without trips are inactive in summaries', () async {
    final vehicles = [_v('a')];
    final q = FleetIntelligenceQuery(fromLocal: t0, toLocal: t1);
    final dash = await FleetIntelligenceMetricsLoader.load(
      query: q,
      allVehicles: vehicles,
      thresholds: th,
      fetchRoute: (_, {from, to}) async => const <RoutePoint>[],
    );
    final row = dash.metrics.vehicleSummaries.single;
    expect(row.totalTrips, 0);
    expect(row.isActive, isFalse);
  });
}
