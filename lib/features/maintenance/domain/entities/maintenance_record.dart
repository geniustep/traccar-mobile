/// سجل صيانة ممتدَّ بخصائص جانبية حسب احتياجات العميل.

import '../../../../core/constants/elmo_fleet_attribute_keys.dart';
import '../../../fleet_domain/fleet_condition_logic.dart';

class MaintenanceRecordEntity {
  const MaintenanceRecordEntity({
    required this.id,
    required this.deviceId,
    required this.name,
    required this.rawAttributes,
    required this.traccarType,
    required this.traccarStart,
    required this.traccarPeriod,
    this.maintenanceTypeCode,
    this.dueDate,
    this.dueOdometerKm,
    this.notes,
    this.completedAt,
  });

  final int id;
  final int deviceId;
  final String name;
  final Map<String, dynamic> rawAttributes;
  final String traccarType;
  final double traccarStart;
  final double traccarPeriod;

  final String? maintenanceTypeCode;
  final DateTime? dueDate;
  final double? dueOdometerKm;
  final String? notes;
  final DateTime? completedAt;

  bool get isCompleted =>
      completedAt != null ||
      '${rawAttributes[ElmoFleetAttributeKeys.maintStatus]}'.toLowerCase() ==
          'completed';

  ElmoMaintenanceSeverity resolveSeverity({
    required DateTime reference,
    double? currentOdometerKm,
  }) {
    if (isCompleted) return ElmoMaintenanceSeverity.completed;

    final byDate = ElmoMaintenanceSeverity.fromDueDateOnly(
      reference: reference,
      dueDate: dueDate,
    );

    final byOd = ElmoMaintenanceSeverity.fromDueOdometerOnlyKm(
      dueKm: dueOdometerKm,
      currentKm: currentOdometerKm,
    );

    return ElmoMaintenanceSeverity.worstOfDateAndOdometer(
      byDate: byDate,
      byOdometer: byOd,
      hasDate: dueDate != null,
      hasOdometer: dueOdometerKm != null && currentOdometerKm != null,
    );
  }

  MaintenanceRecordEntity copyWith({
    int? id,
    int? deviceId,
    String? name,
    Map<String, dynamic>? rawAttributes,
    String? traccarType,
    double? traccarStart,
    double? traccarPeriod,
    String? maintenanceTypeCode,
    DateTime? dueDate,
    double? dueOdometerKm,
    String? notes,
    DateTime? completedAt,
  }) =>
      MaintenanceRecordEntity(
        id: id ?? this.id,
        deviceId: deviceId ?? this.deviceId,
        name: name ?? this.name,
        rawAttributes: rawAttributes ?? this.rawAttributes,
        traccarType: traccarType ?? this.traccarType,
        traccarStart: traccarStart ?? this.traccarStart,
        traccarPeriod: traccarPeriod ?? this.traccarPeriod,
        maintenanceTypeCode: maintenanceTypeCode ?? this.maintenanceTypeCode,
        dueDate: dueDate ?? this.dueDate,
        dueOdometerKm: dueOdometerKm ?? this.dueOdometerKm,
        notes: notes ?? this.notes,
        completedAt: completedAt ?? this.completedAt,
      );
}
