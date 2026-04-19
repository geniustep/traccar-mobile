import '../../domain/entities/analytics_data.dart';

class AnalyticsModel {
  const AnalyticsModel({
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

  factory AnalyticsModel.fromJson(Map<String, dynamic> json) {
    final daily = json['dailyDistances'] as List<dynamic>? ?? [];
    final labels = json['dailyLabels'] as List<dynamic>? ?? [];

    return AnalyticsModel(
      weeklyDistanceMeters: (json['weeklyDistance'] as num?)?.toDouble() ?? 0,
      totalIdleSeconds: json['totalIdleTime'] as int? ?? 0,
      overspeedCount: json['overspeedCount'] as int? ?? 0,
      hardBrakingCount: json['hardBrakingCount'] as int? ?? 0,
      mostActiveVehicle: json['mostActiveVehicle'] as String? ?? '--',
      leastEfficientVehicle: json['leastEfficientVehicle'] as String? ?? '--',
      topAlertCategory: json['topAlertCategory'] as String? ?? '--',
      weeklyTripCount: json['weeklyTripCount'] as int? ?? 0,
      fleetEfficiencyScore: (json['efficiencyScore'] as num?)?.toDouble() ?? 0,
      dailyDistances: daily.map((e) => (e as num).toDouble()).toList(),
      dailyLabels: labels.map((e) => e as String).toList(),
    );
  }

  AnalyticsData toEntity() => AnalyticsData(
        weeklyDistanceMeters: weeklyDistanceMeters,
        totalIdleSeconds: totalIdleSeconds,
        overspeedCount: overspeedCount,
        hardBrakingCount: hardBrakingCount,
        mostActiveVehicle: mostActiveVehicle,
        leastEfficientVehicle: leastEfficientVehicle,
        topAlertCategory: topAlertCategory,
        weeklyTripCount: weeklyTripCount,
        fleetEfficiencyScore: fleetEfficiencyScore,
        dailyDistances: dailyDistances,
        dailyLabels: dailyLabels,
      );
}
