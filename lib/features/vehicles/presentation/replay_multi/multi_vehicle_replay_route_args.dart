/// Route arguments for [/vehicles/replay-multi].
class MultiVehicleReplayRouteArgs {
  const MultiVehicleReplayRouteArgs({
    required this.vehicleIds,
    this.date,
  });

  final List<String> vehicleIds;
  final DateTime? date;
}
