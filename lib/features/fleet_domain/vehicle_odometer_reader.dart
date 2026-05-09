/// يستخرج قيمة عداد المسافة بـ **كيلومتر** من سجلات Traccar الفعلية أو من بيانات
/// الموضع المركَّبة، بدون افتراض وحدات خاطئة.
abstract final class VehicleOdometerReader {
  static double? odometerKmFromPositionAttrs(Map<String, dynamic> attrs) {
    final totalDist = attrs['totalDistance'];
    final dist = attrs['distance'];
    final odom = attrs['odometer'];

    double? meters;
    if (totalDist != null || dist != null) {
      meters = ((totalDist ?? dist) as num).toDouble();
      if (meters >= 0) return meters / 1000;
    }

    // بعض البروتوكولات تقرأ odom بالكيلومترات مباشرة (قيم أكبر بدون عدادات آلاف KM)
    if (odom != null && odom is num) {
      final v = odom.toDouble();
      if (v <= 0) return null;
      if (v < 25000) return v;
      if (v > 250000) return v / 1000;
      return v;
    }
    return null;
  }

  /// دمج حقول الموضع الاختيارية من المركبة.
  static Map<String, dynamic>? mergePositionAttrs(
    Map<String, dynamic>? rawPosition,
  ) {
    if (rawPosition == null) return null;
    return Map<String, dynamic>.from(
      rawPosition['attributes'] as Map? ?? {},
    );
  }
}
