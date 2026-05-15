/// فترة تجميع لوحة ذكاء الأسطول (تُستخدم مع Riverpod family).
enum FleetDashboardPeriod {
  today,
  week,
  month,
}

extension FleetDashboardPeriodX on FleetDashboardPeriod {
  /// نطاق UTC لطلبات التقارير ([من]، [إلى]).
  (DateTime, DateTime) get utcRange => utcRangeAt(DateTime.now().toUtc());

  /// نطاق UTC باستخدام [now] محدد — يُستعمل لتوحيد الـ timestamp
  /// داخل نفس refresh cycle ومنع اختلاف milliseconds بين providers.
  (DateTime, DateTime) utcRangeAt(DateTime now) {
    switch (this) {
      case FleetDashboardPeriod.today:
        final start = DateTime.utc(now.year, now.month, now.day);
        return (start, now);
      case FleetDashboardPeriod.week:
        final start = now.subtract(const Duration(days: 7));
        return (start, now);
      case FleetDashboardPeriod.month:
        final start = DateTime.utc(now.year, now.month, 1);
        return (start, now);
    }
  }
}
