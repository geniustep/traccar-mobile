class DashboardSummary {
  const DashboardSummary({
    required this.totalVehicles,
    required this.movingVehicles,
    required this.stoppedVehicles,
    required this.idleVehicles,
    required this.offlineVehicles,
    required this.alertsToday,
    required this.criticalAlerts,
    required this.tripsToday,
    required this.totalDistanceToday,
    required this.lastUpdated,
  });

  final int totalVehicles;
  final int movingVehicles;
  final int stoppedVehicles;
  final int idleVehicles;
  final int offlineVehicles;
  final int alertsToday;
  final int criticalAlerts;
  final int tripsToday;
  final double totalDistanceToday;
  final DateTime lastUpdated;
}
