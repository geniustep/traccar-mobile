class InsightEntity {
  const InsightEntity({
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
}
