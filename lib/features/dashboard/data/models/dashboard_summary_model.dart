import '../../domain/entities/dashboard_summary.dart';

class DashboardSummaryModel {
  const DashboardSummaryModel({
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

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    return DashboardSummaryModel(
      totalVehicles: json['totalVehicles'] as int? ?? 0,
      movingVehicles: json['movingVehicles'] as int? ?? 0,
      stoppedVehicles: json['stoppedVehicles'] as int? ?? 0,
      idleVehicles: json['idleVehicles'] as int? ?? 0,
      offlineVehicles: json['offlineVehicles'] as int? ?? 0,
      alertsToday: json['alertsToday'] as int? ?? 0,
      criticalAlerts: json['criticalAlerts'] as int? ?? 0,
      tripsToday: json['tripsToday'] as int? ?? 0,
      totalDistanceToday: (json['totalDistanceToday'] as num?)?.toDouble() ?? 0,
      lastUpdated: DateTime.tryParse(json['lastUpdated'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  DashboardSummary toEntity() => DashboardSummary(
        totalVehicles: totalVehicles,
        movingVehicles: movingVehicles,
        stoppedVehicles: stoppedVehicles,
        idleVehicles: idleVehicles,
        offlineVehicles: offlineVehicles,
        alertsToday: alertsToday,
        criticalAlerts: criticalAlerts,
        tripsToday: tripsToday,
        totalDistanceToday: totalDistanceToday,
        lastUpdated: lastUpdated,
      );
}
