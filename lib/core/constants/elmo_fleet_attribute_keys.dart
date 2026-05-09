/// مفاتيح خصائص Traccar (attributes) المملوكة لتطبيق ELMOGPS لميزات الأسطول.
/// لا تعتمد المزايا الأساسية لـ Traccar على هذه المفاتيح؛ تُستخدم فقط كامتداد.
abstract final class ElmoFleetAttributeKeys {
  // ── السائق (على مستوى Driver.attributes) ─────────────────────────────────
  static const String driverPhone = 'elmoPhone';
  static const String driverEmail = 'elmoEmail';
  static const String driverLicenseNumber = 'elmoLicenseNumber';
  static const String driverLicenseExpiryIso = 'elmoLicenseExpiryDate';
  static const String driverNotes = 'elmoNotes';
  static const String driverDeviceIds = 'elmoDeviceIds';

  // ── الصيانة (على مستوى Maintenance.attributes + ربط الجهاز) ─────────────
  static const String maintDeviceId = 'elmoDeviceId';
  static const String maintType = 'elmoMaintenanceType';
  static const String maintDueDateIso = 'elmoDueDate';
  static const String maintDueOdometer = 'elmoDueOdometer';
  static const String maintNotes = 'elmoNotesMaint';
  static const String maintCompletedIso = 'elmoCompletedAt';
  static const String maintStatus = 'elmoStatus'; // queued | completed ...

  // ── وثائق المركبة (على مستوى Device.attributes) ─────────────────────────
  static const String vehicleInsuranceExpiryIso = 'elmoInsuranceExpiryDate';
  static const String vehicleTechnicalExpiryIso =
      'elmoTechnicalInspectionExpiryDate';
}
