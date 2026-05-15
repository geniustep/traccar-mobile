import 'package:flutter/foundation.dart';

import '../domain/fleet_intelligence_dashboard_state.dart';
import '../domain/fleet_intelligence_query.dart';

/// مدة صلاحية التخزين المؤقت لنتيجة لوحة ذكاء الأسطول — **Phase 10F**.
///
/// النطاق الموصى به في الوثائق: **2–5 دقائق**؛ القيمة الافتراضية **3 دقائق**.
const kFleetIntelligenceDashboardCacheTtl = Duration(minutes: 3);

@immutable
class FleetIntelligenceDashboardCacheEntry {
  const FleetIntelligenceDashboardCacheEntry({
    required this.state,
    required this.fetchedAtUtc,
    required this.refreshNonceSnapshot,
  });

  final FleetIntelligenceDashboardState state;
  final DateTime fetchedAtUtc;

  /// قيمة **`FleetIntelligenceQuery.refreshNonce`** وقت التخزين — يجب أن تطابق الاستعلام الحالي ليُقبل الـ hit.
  final int refreshNonceSnapshot;
}

/// تخزين داخلي في الذاكرة لـ **[FleetIntelligenceDashboardState]** — لا يغيّر الحسابات (**Phase 10F**).
///
/// - **مفتاح التخزين:** **`FleetIntelligenceQuery.cacheStableKey`** (بدون **`refreshNonce`**).
/// - **تجاوز عند التحديث اليدوي:** أي تغيير في **`refreshNonce`** يمنع إعادة استخدام إدخال قديم حتى بعد إعادة الجلب وتحديث الإدخال.
/// - **انتهاء TTL:** يُزال الإدخال ويُعاد التحميل عند الطلب التالي.
class FleetIntelligenceDashboardCache {
  FleetIntelligenceDashboardCache({Duration? ttl})
      : ttl = ttl ?? kFleetIntelligenceDashboardCacheTtl;

  final Duration ttl;

  final Map<String, FleetIntelligenceDashboardCacheEntry> _entries = {};

  /// يعيد نسخة الحالة إن وُجدت إدخال صالح لنفس **`cacheStableKey`** و**`refreshNonce`** ولم ينتهِ **`ttl`**.
  FleetIntelligenceDashboardState? peekIfFresh({
    required FleetIntelligenceQuery query,
    required DateTime nowUtc,
  }) {
    final key = query.cacheStableKey;
    final e = _entries[key];
    if (e == null) return null;
    if (e.refreshNonceSnapshot != query.refreshNonce) return null;
    if (nowUtc.difference(e.fetchedAtUtc) > ttl) {
      _entries.remove(key);
      return null;
    }
    return e.state;
  }

  /// يكتب أو يحدِّث الإدخال بعد **`FleetIntelligenceMetricsLoader.load`**.
  void record({
    required FleetIntelligenceQuery query,
    required FleetIntelligenceDashboardState state,
    required DateTime nowUtc,
  }) {
    final key = query.cacheStableKey;
    _entries[key] = FleetIntelligenceDashboardCacheEntry(
      state: state,
      fetchedAtUtc: nowUtc,
      refreshNonceSnapshot: query.refreshNonce,
    );
  }

  /// للاختبار أو مسح جميع اللقطات بعد تسجيل الخروج (اختياري).
  void clear() => _entries.clear();
}
