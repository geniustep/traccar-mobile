import '../../../reports/data/fleet_reports_request_gate.dart';
import '../../../trips/data/models/trip_model.dart';

/// جلب رحلات وأحداث مدمجة لعدة أجهزة دفعة واحدة (نفس نمط لوحة التحكم الحالية).
class FleetIntelligenceRemoteDataSource {
  const FleetIntelligenceRemoteDataSource(this._fleetReports);

  final FleetReportsRequestGate _fleetReports;

  Future<({List<TripModel> trips, List<Map<String, dynamic>> events})>
      fetchTripsAndEvents({
    required List<int> deviceIds,
    required DateTime fromUtc,
    required DateTime toUtc,
    required String trigger,
  }) {
    return _fleetReports.fetchTripsAndEvents(
      deviceIds: deviceIds,
      fromUtc: fromUtc,
      toUtc: toUtc,
      trigger: trigger,
    );
  }
}
