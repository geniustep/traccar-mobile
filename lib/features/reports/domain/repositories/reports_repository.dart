import '../../../trips/domain/entities/trip.dart';
import '../../../map/data/datasources/route_datasource.dart';
import '../entities/summary_report.dart';
import '../entities/stop_report.dart';
import '../entities/event_report.dart';

abstract class ReportsRepository {
  Future<SummaryReport?> getSummary({
    required String deviceId,
    required DateTime from,
    required DateTime to,
  });

  Future<List<StopReport>> getStops({
    required String deviceId,
    required DateTime from,
    required DateTime to,
  });

  Future<List<EventReport>> getEvents({
    required String deviceId,
    required DateTime from,
    required DateTime to,
    List<String>? types,
  });

  Future<List<TripEntity>> getTrips({
    required String deviceId,
    required DateTime from,
    required DateTime to,
  });

  Future<List<RoutePoint>> getRoute({
    required String deviceId,
    required DateTime from,
    required DateTime to,
  });
}
