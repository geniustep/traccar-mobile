class AlertEntity {
  const AlertEntity({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.description,
    required this.vehicleId,
    required this.vehicleName,
    required this.createdAt,
    required this.isRead,
    required this.latitude,
    required this.longitude,
    required this.attributes,
  });

  final String id;
  final String type;
  final String severity; // critical | high | medium | low | info
  final String title;
  final String description;
  final String vehicleId;
  final String vehicleName;
  final DateTime createdAt;
  final bool isRead;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic> attributes;

  bool get isCritical => severity == 'critical';
  bool get hasLocation => latitude != null && longitude != null;

  AlertEntity copyWith({bool? isRead}) {
    return AlertEntity(
      id: id,
      type: type,
      severity: severity,
      title: title,
      description: description,
      vehicleId: vehicleId,
      vehicleName: vehicleName,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      latitude: latitude,
      longitude: longitude,
      attributes: attributes,
    );
  }
}
