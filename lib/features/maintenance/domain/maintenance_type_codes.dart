/// رموز مخزنة في [ElmoFleetAttributeKeys.maintType] ومُعرَّفة مستقلة عن واجهات Traccar.
abstract final class ElmoMaintenanceTypeCode {
  static const oilChange = 'oil_change';
  static const oilFilter = 'oil_filter';
  static const airFilter = 'air_filter';
  static const tires = 'tires';
  static const brakes = 'brakes';
  static const battery = 'battery';
  static const draining = 'draining';
  static const generalRevision = 'general_revision';
  static const insurance = 'insurance';
  static const technicalInspection = 'technical_inspection';
  static const vignette = 'vignette';
  static const other = 'other';

  static const List<String> allOrdered = [
    oilChange,
    oilFilter,
    airFilter,
    tires,
    brakes,
    battery,
    draining,
    generalRevision,
    insurance,
    technicalInspection,
    vignette,
    other,
  ];
}
