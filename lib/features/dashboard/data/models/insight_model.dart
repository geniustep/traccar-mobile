import '../../domain/entities/insight.dart';

class InsightModel {
  const InsightModel({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.severity,
    required this.icon,
    required this.createdAt,
    this.vehicleId,
  });

  final String id;
  final String type;
  final String title;
  final String description;
  final String severity;
  final String icon;
  final DateTime createdAt;
  final String? vehicleId;

  factory InsightModel.fromJson(Map<String, dynamic> json) {
    return InsightModel(
      id: json['id'] as String,
      type: json['type'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      severity: json['severity'] as String? ?? 'info',
      icon: json['icon'] as String? ?? 'info',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      vehicleId: json['vehicleId'] as String?,
    );
  }

  InsightEntity toEntity() => InsightEntity(
        id: id,
        type: type,
        title: title,
        description: description,
        severity: severity,
        icon: icon,
        createdAt: createdAt,
        vehicleId: vehicleId,
      );
}
