/// Query for [vehicleTripsProvider] — optional date range (UTC recommended).
class VehicleTripsQuery {
  const VehicleTripsQuery({
    required this.vehicleId,
    this.from,
    this.to,
  });

  final String vehicleId;
  final DateTime? from;
  final DateTime? to;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VehicleTripsQuery &&
          vehicleId == other.vehicleId &&
          from == other.from &&
          to == other.to;

  @override
  int get hashCode => Object.hash(vehicleId, from, to);
}
