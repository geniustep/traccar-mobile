class AnalyticsData {
  const AnalyticsData({
    required this.weeklyDistanceMeters,
    required this.totalIdleSeconds,
    required this.overspeedCount,
    required this.hardBrakingCount,
    required this.mostActiveVehicle,
    required this.leastEfficientVehicle,
    required this.topAlertCategory,
    required this.weeklyTripCount,
    required this.fleetEfficiencyScore,
    required this.dailyDistances,
    required this.dailyLabels,
  });

  final double weeklyDistanceMeters;
  final int totalIdleSeconds;
  final int overspeedCount;
  final int hardBrakingCount;
  final String mostActiveVehicle;
  final String leastEfficientVehicle;
  final String topAlertCategory;
  final int weeklyTripCount;
  final double fleetEfficiencyScore;
  final List<double> dailyDistances;
  final List<String> dailyLabels;
}
