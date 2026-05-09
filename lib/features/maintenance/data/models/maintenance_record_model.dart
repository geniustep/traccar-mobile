import '../../../../core/constants/elmo_fleet_attribute_keys.dart';
import '../../domain/entities/maintenance_record.dart';
import '../../domain/maintenance_type_codes.dart';

/// طبقة وسيطة بين خادوم Traccar ومنطق النطاق المحلي.
class MaintenanceRecordModel {
  const MaintenanceRecordModel({
    required this.id,
    required this.name,
    required this.type,
    required this.start,
    required this.period,
    required this.attributes,
  });

  factory MaintenanceRecordModel.fromJson(Map<String, dynamic> json) {
    final attrs = Map<String, dynamic>.from(json['attributes'] as Map? ?? {});

    return MaintenanceRecordModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'mileage',
      start: (json['start'] as num?)?.toDouble() ?? 0,
      period: (json['period'] as num?)?.toDouble() ?? 999999,
      attributes: attrs,
    );
  }

  final int id;
  final String name;
  final String type;
  final double start;
  final double period;
  final Map<String, dynamic> attributes;

  int get deviceIdField =>
      _parsePositiveInt(attributes[ElmoFleetAttributeKeys.maintDeviceId]);

  String? get notes =>
      attributes[ElmoFleetAttributeKeys.maintNotes] as String?;

  String get maintenanceTypeStored =>
      '${attributes[ElmoFleetAttributeKeys.maintType] ?? ElmoMaintenanceTypeCode.other}';

  DateTime? get dueDate =>
      _parseFlexibleDate(attributes[ElmoFleetAttributeKeys.maintDueDateIso]);

  double? get dueOdometerKm =>
      _parseKm(attributes[ElmoFleetAttributeKeys.maintDueOdometer]);

  DateTime? get completedAt =>
      _parseFlexibleDate(attributes[ElmoFleetAttributeKeys.maintCompletedIso]);

  MaintenanceRecordEntity toEntity() => MaintenanceRecordEntity(
        id: id,
        deviceId: deviceIdField,
        name: name,
        rawAttributes: Map<String, dynamic>.from(attributes),
        traccarType: type,
        traccarStart: start,
        traccarPeriod: period,
        maintenanceTypeCode: maintenanceTypeStored,
        dueDate: dueDate,
        dueOdometerKm: dueOdometerKm,
        notes: notes,
        completedAt: completedAt,
      );

  Map<String, dynamic> toCreatePayload() => <String, dynamic>{
        'name': name,
        'type': type,
        'start': start,
        'period': period,
        'attributes': Map<String, dynamic>.from(attributes),
      };

  Map<String, dynamic> toUpdatePayload() => <String, dynamic>{
        'id': id,
        'name': name,
        'type': type,
        'start': start,
        'period': period,
        'attributes': Map<String, dynamic>.from(attributes),
      };

  /// يبني جسمًا آمنًا من منطق النطاق مع إسقاط الحقول الفارغة غير الضرورية.
  MaintenanceRecordModel copyFromEntity(MaintenanceRecordEntity e) {
    final attrs = Map<String, dynamic>.from(e.rawAttributes);

    attrs[ElmoFleetAttributeKeys.maintDeviceId] = e.deviceId;

    if (e.maintenanceTypeCode != null &&
        e.maintenanceTypeCode!.trim().isNotEmpty) {
      attrs[ElmoFleetAttributeKeys.maintType] = e.maintenanceTypeCode!.trim();
    }

    if (e.dueDate != null) {
      attrs[ElmoFleetAttributeKeys.maintDueDateIso] =
          e.dueDate!.toIso8601String().split('T').first;
    } else {
      attrs.remove(ElmoFleetAttributeKeys.maintDueDateIso);
    }

    if (e.dueOdometerKm != null) {
      attrs[ElmoFleetAttributeKeys.maintDueOdometer] = e.dueOdometerKm!;
    } else {
      attrs.remove(ElmoFleetAttributeKeys.maintDueOdometer);
    }

    if (e.notes != null && e.notes!.trim().isNotEmpty) {
      attrs[ElmoFleetAttributeKeys.maintNotes] = e.notes!.trim();
    } else {
      attrs.remove(ElmoFleetAttributeKeys.maintNotes);
    }

    if (e.completedAt != null) {
      attrs[ElmoFleetAttributeKeys.maintCompletedIso] =
          e.completedAt!.toIso8601String();
      attrs[ElmoFleetAttributeKeys.maintStatus] = 'completed';
    } else {
      attrs.remove(ElmoFleetAttributeKeys.maintCompletedIso);
      attrs.remove(ElmoFleetAttributeKeys.maintStatus);
    }

    return MaintenanceRecordModel(
      id: e.id,
      name: e.name,
      type: e.traccarType.isEmpty ? 'mileage' : e.traccarType,
      start: e.traccarStart,
      period: e.traccarPeriod,
      attributes: attrs,
    );
  }

  static int _parsePositiveInt(dynamic v) {
    if (v is int && v > 0) return v;
    if (v is num && v.toInt() > 0) return v.toInt();
    final p = int.tryParse('$v');
    return (p != null && p > 0) ? p : 0;
  }

  static double? _parseKm(dynamic raw) {
    if (raw == null) return null;
    if (raw is num) return raw.toDouble();
    return double.tryParse('$raw');
  }

  static DateTime? _parseFlexibleDate(dynamic raw) {
    if (raw == null) return null;
    final s = '$raw'.trim();
    if (s.isEmpty) return null;
    if (s.contains('T')) return DateTime.tryParse(s);
    return DateTime.tryParse('${s}T00:00:00Z');
  }
}
