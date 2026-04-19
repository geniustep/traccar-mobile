import '../../domain/entities/alert.dart';

class AlertModel {
  const AlertModel({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.vehicleId,
    required this.vehicleName,
    required this.createdAt,
    required this.isRead,
    this.latitude,
    this.longitude,
    required this.attributes,
  });

  final String id;
  final String type;
  final String severity;
  final String title;
  final String description;
  final String vehicleId;
  final String vehicleName;
  final DateTime createdAt;
  final bool isRead;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic> attributes;

  factory AlertModel.fromJson(Map<String, dynamic> json) {
    return AlertModel(
      id: json['id']?.toString() ?? '',
      type: json['type'] as String? ?? '',
      severity: json['severity'] as String? ?? 'info',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ??
          json['message'] as String? ?? '',
      vehicleId: json['vehicleId']?.toString() ?? '',
      vehicleName: json['vehicleName'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '')?.toLocal() ??
          DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      attributes: json['attributes'] as Map<String, dynamic>? ?? {},
    );
  }

  AlertEntity toEntity() => AlertEntity(
        id: id,
        type: type,
        severity: severity,
        title: title,
        description: description,
        vehicleId: vehicleId,
        vehicleName: vehicleName,
        createdAt: createdAt,
        isRead: isRead,
        latitude: latitude,
        longitude: longitude,
        attributes: attributes,
      );
}
