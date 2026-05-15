import 'package:flutter/foundation.dart';

/// سقف افتراضي لعدد المركبات التي تُجلب لها **مسار** في تحميلة واحدة (**Phase 10C**).
const kFleetIntelligenceDefaultMaxVehicles = 25;

/// استعلام موحّد لذكاء الأسطول — قابل للمقارنة ولمفتاح تخزيم مؤقت (**Phase 10C**).
@immutable
class FleetIntelligenceQuery {
  FleetIntelligenceQuery({
    required this.fromLocal,
    required this.toLocal,
    List<String>? vehicleIds,
    this.maxVehicles = kFleetIntelligenceDefaultMaxVehicles,
    this.includeInactive = false,
    this.groupId,
    this.refreshNonce = 0,
  }) : vehicleIds =
            vehicleIds == null ? null : List<String>.unmodifiable(vehicleIds);

  final DateTime fromLocal;
  final DateTime toLocal;
  final List<String>? vehicleIds;
  final int maxVehicles;
  final bool includeInactive;
  final String? groupId;
  final int refreshNonce;

  /// بصمة تشمل **`refreshNonce`** — تستخدم عند ضرورة تمييز جلسات التحديث بالكامل.
  String get cacheKey => [
        fromLocal.toIso8601String(),
        toLocal.toIso8601String(),
        vehicleIds?.join(',') ?? '*',
        '$maxVehicles',
        includeInactive ? '1' : '0',
        groupId ?? '*',
        '$refreshNonce',
      ].join('|');

  /// بصمة **بدون **`refreshNonce`** — مفتاح تخزيم مؤقت قصير (**Phase 10F**): نفس الفترة والحدود تشترك في دلو واحد؛ تغيير **`refreshNonce`** يفرض تجاوز الـ cache.
  String get cacheStableKey => [
        fromLocal.toIso8601String(),
        toLocal.toIso8601String(),
        vehicleIds?.join(',') ?? '*',
        '$maxVehicles',
        includeInactive ? '1' : '0',
        groupId ?? '*',
      ].join('|');
  FleetIntelligenceQuery copyWith({
    DateTime? fromLocal,
    DateTime? toLocal,
    List<String>? vehicleIds,
    int? maxVehicles,
    bool? includeInactive,
    String? groupId,
    int? refreshNonce,
  }) {
    return FleetIntelligenceQuery(
      fromLocal: fromLocal ?? this.fromLocal,
      toLocal: toLocal ?? this.toLocal,
      vehicleIds: vehicleIds ?? this.vehicleIds,
      maxVehicles: maxVehicles ?? this.maxVehicles,
      includeInactive: includeInactive ?? this.includeInactive,
      groupId: groupId ?? this.groupId,
      refreshNonce: refreshNonce ?? this.refreshNonce,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FleetIntelligenceQuery &&
        other.fromLocal == fromLocal &&
        other.toLocal == toLocal &&
        listEquals(other.vehicleIds, vehicleIds) &&
        other.maxVehicles == maxVehicles &&
        other.includeInactive == includeInactive &&
        other.groupId == groupId &&
        other.refreshNonce == refreshNonce;
  }

  @override
  int get hashCode => Object.hash(
        fromLocal,
        toLocal,
        vehicleIds == null ? null : Object.hashAll(vehicleIds!),
        maxVehicles,
        includeInactive,
        groupId,
        refreshNonce,
      );
}
