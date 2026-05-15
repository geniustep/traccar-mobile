import 'package:flutter/material.dart';

/// سريع المرشّح الزمني — لوحة ذكاء الأسطول (**Phase 10D**).
///
/// **`last7Days`**: من **00:00** قبل **6 أيام محلية** حتى **`DateTime.now()`** المحلي —
/// أي **7 أيام تقويمية** مع اليوم الحالي (مثل **Phase 10B**).
enum FleetDashboardDatePreset {
  today,
  yesterday,
  last7Days,

  /// يتطلّب **[FleetDashboardFilterState.customRange]**؛ إن نقص يُحمَل كـ **[today]**.
  custom,
}

/// يحوّل نطاق **`DateTimeRange`** من منتصف الليل المحلي لبداية اليوم الأوّل،
/// ونهاية اليوم الأخير **23:59:59** محليًا إن لم يكن اليوم الحالي؛ وإن كان اليوم
/// الحالي فالنهاية **`DateTime.now()`** حتى لا تُفقد بيانات الجلسة.
(DateTime fromLocal, DateTime toLocal) fleetDashboardLocalBounds({
  required FleetDashboardDatePreset preset,
  required DateTime now,
  DateTimeRange? customRange,
}) {
  switch (preset) {
    case FleetDashboardDatePreset.today:
      return (
        DateTime(now.year, now.month, now.day),
        now,
      );
    case FleetDashboardDatePreset.yesterday:
      final y = now.subtract(const Duration(days: 1));
      return (
        DateTime(y.year, y.month, y.day),
        DateTime(y.year, y.month, y.day, 23, 59, 59),
      );
    case FleetDashboardDatePreset.last7Days:
      final start = DateTime(now.year, now.month, now.day)
          .subtract(const Duration(days: 6));
      return (start, now);
    case FleetDashboardDatePreset.custom:
      final r = customRange;
      if (r == null) {
        return (
          DateTime(now.year, now.month, now.day),
          now,
        );
      }
      final start = DateTime(r.start.year, r.start.month, r.start.day);
      final endDay = DateTime(r.end.year, r.end.month, r.end.day);
      final endIsToday = endDay.year == now.year &&
          endDay.month == now.month &&
          endDay.day == now.day;
      final to = endIsToday
          ? now
          : DateTime(endDay.year, endDay.month, endDay.day, 23, 59, 59);
      if (to.isBefore(start)) {
        return (start, start);
      }
      return (start, to);
  }
}
