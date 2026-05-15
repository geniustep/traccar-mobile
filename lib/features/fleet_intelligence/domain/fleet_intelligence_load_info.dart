import 'package:flutter/foundation.dart';

/// بيانات وصفية عن حدود التحميل — **Phase 10C**.
@immutable
class FleetIntelligenceLoadInfo {
  const FleetIntelligenceLoadInfo({
    required this.fleetRegisteredCount,
    required this.candidatesConsidered,
    required this.routesAnalyzed,
    required this.routesFailedPartial,
    required this.skippedBeyondCap,
    required this.maxVehicles,
    required this.fromLocal,
    required this.toLocal,
    required this.usedOnlineFirstOrdering,
  });

  /// عدد المركبات المستلمة من قائمة الأسطول بعد التصفية الأولية (قبل السقف).
  final int fleetRegisteredCount;

  /// عدد المرشّحين بعد فلاتر المجموعة / المعرفات / النشاط.
  final int candidatesConsidered;

  /// عدد استدعاءات **`getRoute`** في هذه التحميلة.
  final int routesAnalyzed;

  /// مركبات رُفع استثناء المسار لها واستُكملت بمدخلات فارغة.
  final int routesFailedPartial;

  /// مركبات لم تُحمّل لأنها خارج العيّينة بسبب **`maxVehicles`**.
  final int skippedBeyondCap;

  final int maxVehicles;
  final DateTime fromLocal;
  final DateTime toLocal;
  final bool usedOnlineFirstOrdering;

  bool get isLimitedSample => skippedBeyondCap > 0;

  bool get hasOperationalFailures =>
      routesFailedPartial > 0 && routesAnalyzed > 0;
}
