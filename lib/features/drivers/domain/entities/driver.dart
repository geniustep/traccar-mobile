import '../../../fleet_domain/fleet_condition_logic.dart';

class DriverEntity {
  const DriverEntity({
    required this.id,
    required this.name,
    required this.uniqueId,
    required this.linkedDeviceIds,
    required this.rawAttributes,
    this.phone,
    this.email,
    this.licenseNumber,
    this.licenseExpiry,
    this.notes,
  });

  final int id;
  final String name;

  /// المعرِّف المنطقي للسائق في Traccar (أو كود شركة خاص بالعميل)
  final String uniqueId;

  /// أرقام هواتف التواصل المرئية؛ القيم فارغ من دون تأكيد طرفية.
  final String? phone;
  final String? email;

  /// رقم الرخصة إن وَفَّر جهاز الجانب الأمامي بيانًا كذلك؛ يُكمَّل عبر الخصائص.
  final String? licenseNumber;
  final DateTime? licenseExpiry;
  final String? notes;

  /// معرِّف الأجهزة المستخدمة لتضييق نافذة المركبات.
  final List<int> linkedDeviceIds;

  /// أصل خريطة الخصائص كما هي من الخادوم (لقراءات متخصصة).
  final Map<String, dynamic> rawAttributes;

  DriverLicenseStatus licenseStatus(DateTime reference) =>
      DriverLicenseStatus.fromExpiry(licenseExpiry, reference);

  DriverEntity copyWith({
    int? id,
    String? name,
    String? uniqueId,
    String? phone,
    String? email,
    String? licenseNumber,
    DateTime? licenseExpiry,
    String? notes,
    List<int>? linkedDeviceIds,
    Map<String, dynamic>? rawAttributes,
  }) =>
      DriverEntity(
        id: id ?? this.id,
        name: name ?? this.name,
        uniqueId: uniqueId ?? this.uniqueId,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        licenseNumber: licenseNumber ?? this.licenseNumber,
        licenseExpiry: licenseExpiry ?? this.licenseExpiry,
        notes: notes ?? this.notes,
        linkedDeviceIds: linkedDeviceIds ?? this.linkedDeviceIds,
        rawAttributes: rawAttributes ?? this.rawAttributes,
      );
}
