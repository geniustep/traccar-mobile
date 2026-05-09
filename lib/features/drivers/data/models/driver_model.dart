import 'dart:convert';

import '../../../../core/constants/elmo_fleet_attribute_keys.dart';
import '../../domain/entities/driver.dart';

class DriverModel {
  const DriverModel({
    required this.id,
    required this.name,
    required this.uniqueId,
    required this.attributes,
    this.linkedDeviceIds = const [],
  });

  factory DriverModel.fromJson(Map<String, dynamic> json) {
    final attrs = Map<String, dynamic>.from(json['attributes'] as Map? ?? {});

    return DriverModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      uniqueId: json['uniqueId'] as String? ?? '',
      attributes: attrs,
      linkedDeviceIds: _decodeDeviceIds(attrs[ElmoFleetAttributeKeys.driverDeviceIds]),
    );
  }

  final int id;
  final String name;
  final String uniqueId;

  /// خصائص Traccar الأصلية مضافًا إليها الحقول الموسَّعة لمشروعنا.
  final Map<String, dynamic> attributes;

  /// أرشفة المركبات المرتبطة بصغير أعداد صحيحة من خصائص JSON.
  final List<int> linkedDeviceIds;

  String? get phone =>
      attributes[ElmoFleetAttributeKeys.driverPhone] as String?;

  String? get email =>
      attributes[ElmoFleetAttributeKeys.driverEmail] as String?;

  String? get licenseNumber =>
      attributes[ElmoFleetAttributeKeys.driverLicenseNumber] as String?;

  DateTime? get licenseExpiry =>
      _parseDateOnly(attributes[ElmoFleetAttributeKeys.driverLicenseExpiryIso]);

  String? get notes => attributes[ElmoFleetAttributeKeys.driverNotes] as String?;

  DriverEntity toEntity() => DriverEntity(
        id: id,
        name: name,
        uniqueId: uniqueId,
        phone: phone,
        email: email,
        licenseNumber: licenseNumber,
        licenseExpiry: licenseExpiry,
        notes: notes,
        linkedDeviceIds: List<int>.from(linkedDeviceIds),
        rawAttributes: Map<String, dynamic>.from(attributes),
      );

  Map<String, dynamic> toUpdatePayload() => <String, dynamic>{
        'id': id,
        'name': name,
        'uniqueId': uniqueId,
        'attributes': Map<String, dynamic>.from(attributes),
      };

  Map<String, dynamic> toCreatePayload() => <String, dynamic>{
        'name': name,
        'uniqueId': uniqueId,
        'attributes': Map<String, dynamic>.from(attributes),
      };

  static DateTime? _parseDateOnly(dynamic raw) {
    if (raw == null) return null;
    final s = '$raw'.trim();
    if (s.isEmpty) return null;
    if (s.contains('T')) {
      return DateTime.tryParse(s);
    }

    /// يوم صافٍ بتوقيت وسط؛ يعتمد المنطقي على قارن يوم وسط الموعد.
    return DateTime.tryParse('${s}T00:00:00Z');
  }

  DriverModel copyFromEntity(DriverEntity e) {
    final attrs = Map<String, dynamic>.from(e.rawAttributes);
    attrs[ElmoFleetAttributeKeys.driverPhone] = e.phone;
    attrs[ElmoFleetAttributeKeys.driverEmail] = e.email;
    attrs[ElmoFleetAttributeKeys.driverLicenseNumber] = e.licenseNumber;
    if (e.licenseExpiry != null) {
      attrs[ElmoFleetAttributeKeys.driverLicenseExpiryIso] =
          e.licenseExpiry!.toIso8601String().split('T').first;
    } else {
      attrs.remove(ElmoFleetAttributeKeys.driverLicenseExpiryIso);
    }

    attrs[ElmoFleetAttributeKeys.driverNotes] = e.notes;

    attrs[ElmoFleetAttributeKeys.driverDeviceIds] = jsonEncode(e.linkedDeviceIds);

    const allowedNullKeys = [
      ElmoFleetAttributeKeys.driverEmail,
      ElmoFleetAttributeKeys.driverPhone,
      ElmoFleetAttributeKeys.driverNotes,
      ElmoFleetAttributeKeys.driverLicenseNumber,
    ];

    for (final k in allowedNullKeys) {
      if (attrs[k] == null || (attrs[k] is String && (attrs[k] as String).isEmpty)) {
        attrs.remove(k);
      }
    }

    return DriverModel(
      id: e.id,
      name: e.name,
      uniqueId: e.uniqueId,
      attributes: attrs,
      linkedDeviceIds: List<int>.from(e.linkedDeviceIds),
    );
  }

  static List<int> _decodeDeviceIds(dynamic encoded) {
    if (encoded == null) return const [];
    if (encoded is List) return encoded.whereType<num>().map((e) => e.toInt()).toList();
    if (encoded is String && encoded.trim().startsWith('[')) {
      try {
        final list = jsonDecode(encoded) as List<dynamic>? ?? [];
        return list.whereType<num>().map((e) => e.toInt()).toList();
      } catch (_) {}
    }

    /// شكل مختصر مفصول بشريط عمود إن وفرت سجلات قديمة.
    final s = '$encoded'.trim();
    if (s.isEmpty) return const [];
    final parts =
        s.split(RegExp(r'[\s,|;]+')).where((part) => part.isNotEmpty);
    final out = <int>[];
    for (final chunk in parts) {
      final n = int.tryParse(chunk.trim());
      if (n != null) out.add(n);
    }

    return out;
  }
}
