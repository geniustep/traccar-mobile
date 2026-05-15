import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/format_utils.dart';
import 'vehicle_comparison_model.dart';

/// Display helpers and comparison rules (unit-tested).
abstract final class VehicleComparisonFormatters {
  VehicleComparisonFormatters._();

  static const String emptyValue = '—';

  static bool canCompare(int vehicleCount) => vehicleCount >= 2;

  static List<String> removeVehicle(List<String> ids, String vehicleId) =>
      ids.where((id) => id != vehicleId).toList();

  static String formatDistanceKm(double? km) {
    if (km == null) return emptyValue;
    return FormatUtils.distance(km * 1000);
  }

  static String formatSpeedKmh(double? kmh) {
    if (kmh == null) return emptyValue;
    return FormatUtils.speed(kmh);
  }

  static String formatCount(int? count) {
    if (count == null) return emptyValue;
    return '$count';
  }

  static String formatDurationSeconds(int? seconds) {
    if (seconds == null) return emptyValue;
    return DateFormatter.duration(seconds);
  }

  static String formatLastUpdate(DateTime? dt) {
    if (dt == null) return emptyValue;
    return DateFormatter.toRelative(dt);
  }

  static String? vehicleNameForId(
    List<VehicleComparisonItem> items,
    String? vehicleId,
  ) {
    if (vehicleId == null) return null;
    for (final item in items) {
      if (item.vehicleId == vehicleId) return item.name;
    }
    return null;
  }
}
