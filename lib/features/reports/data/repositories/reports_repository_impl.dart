import '../../../trips/domain/entities/trip.dart';
import '../../../map/data/datasources/route_datasource.dart';
import '../../domain/entities/summary_report.dart';
import '../../domain/entities/stop_report.dart';
import '../../domain/entities/event_report.dart';
import '../../domain/repositories/reports_repository.dart';
import '../datasources/reports_remote_datasource.dart';

class ReportsRepositoryImpl implements ReportsRepository {
  const ReportsRepositoryImpl(this._ds);

  final ReportsRemoteDataSource _ds;

  @override
  Future<SummaryReport?> getSummary({
    required String deviceId,
    required DateTime from,
    required DateTime to,
  }) async {
    final model = await _ds.getSummary(deviceId: deviceId, from: from, to: to);
    return model != null ? SummaryReport.fromModel(model) : null;
  }

  @override
  Future<List<StopReport>> getStops({
    required String deviceId,
    required DateTime from,
    required DateTime to,
  }) async {
    final models = await _ds.getStops(deviceId: deviceId, from: from, to: to);
    return models.map(StopReport.fromModel).toList();
  }

  @override
  Future<List<EventReport>> getEvents({
    required String deviceId,
    required DateTime from,
    required DateTime to,
    List<String>? types,
  }) async {
    final models = await _ds.getEvents(
      deviceId: deviceId,
      from: from,
      to: to,
      types: types,
    );
    return models.map(EventReport.fromModel).toList();
  }

  @override
  Future<List<TripEntity>> getTrips({
    required String deviceId,
    required DateTime from,
    required DateTime to,
  }) async {
    final models = await _ds.getTrips(deviceId: deviceId, from: from, to: to);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<RoutePoint>> getRoute({
    required String deviceId,
    required DateTime from,
    required DateTime to,
  }) async {
    return _ds.getRoute(deviceId: deviceId, from: from, to: to);
  }
}
