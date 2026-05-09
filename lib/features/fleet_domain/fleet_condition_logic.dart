/// حالة امتثال الرخصة حسب الموعد المخزَّن وتاريخ المرجع.
enum DriverLicenseStatus {
  unknown,
  valid,
  expiringSoon,
  expired;

  static DriverLicenseStatus fromExpiry(
    DateTime? expiry,
    DateTime reference,
  ) {
    if (expiry == null) return unknown;

    final d = DateTime.utc(expiry.year, expiry.month, expiry.day);
    final r = DateTime.utc(reference.year, reference.month, reference.day);

    if (d.isBefore(r)) return expired;
    final delta = d.difference(r).inDays;
    if (delta <= 30) return expiringSoon;
    return valid;
  }
}

/// منطق حالة الصيانة (تاريخ + عداد؛ يُدمج وفق الأولويات).
enum ElmoMaintenanceSeverity {
  unknown,
  completed,
  upcoming,
  soon,
  overdue;

  static DateTime utcDateOnly(DateTime d) =>
      DateTime.utc(d.year, d.month, d.day);

  static int _priority(ElmoMaintenanceSeverity s) {
    switch (s) {
      case ElmoMaintenanceSeverity.unknown:
        return -1;
      case ElmoMaintenanceSeverity.completed:
        return -2;
      case ElmoMaintenanceSeverity.upcoming:
        return 1;
      case ElmoMaintenanceSeverity.soon:
        return 2;
      case ElmoMaintenanceSeverity.overdue:
        return 3;
    }
  }

  static ElmoMaintenanceSeverity fromDueDateOnly({
    required DateTime reference,
    required DateTime? dueDate,
  }) {
    if (dueDate == null) return unknown;

    final due = utcDateOnly(dueDate);
    final ref = utcDateOnly(reference);
    if (due.isBefore(ref)) return overdue;
    final delta = due.difference(ref).inDays;
    if (delta <= 30) return soon;
    return upcoming;
  }

  static ElmoMaintenanceSeverity fromDueOdometerOnlyKm({
    required double? dueKm,
    required double? currentKm,
  }) {
    if (dueKm == null || currentKm == null) return unknown;
    if (dueKm < 0 || currentKm < 0) return unknown;

    final diff = dueKm - currentKm;
    if (diff < 0) return overdue;
    if (diff <= 1000) return soon;
    return upcoming;
  }

  static ElmoMaintenanceSeverity worstOfDateAndOdometer({
    required ElmoMaintenanceSeverity byDate,
    required ElmoMaintenanceSeverity byOdometer,
    required bool hasDate,
    required bool hasOdometer,
  }) {
    if (!hasDate && !hasOdometer) return unknown;

    final d = hasDate ? byDate : unknown;
    final o = hasOdometer ? byOdometer : unknown;

    final pd = _priority(d);
    final po = _priority(o);

    if (pd < 0 && po < 0) return unknown;
    if (pd < 0) return o;
    if (po < 0) return d;
    return pd >= po ? d : o;
  }
}
