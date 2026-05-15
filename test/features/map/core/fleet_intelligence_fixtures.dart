import 'package:elmogps/features/map/core/fleet_intelligence_metrics_models.dart';
import 'package:elmogps/features/map/core/trip_segment_models.dart';

/// Sample vehicle row for Fleet Intelligence tests (**Phase 10A**).
FleetVehicleTripInput fleetVehicleInput({
  required String id,
  String? name,
  List<TripSegment> trips = const [],
}) =>
    FleetVehicleTripInput(
      vehicleId: id,
      vehicleName: name,
      trips: trips,
    );
