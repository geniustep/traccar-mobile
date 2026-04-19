import 'package:intl/intl.dart';

class FormatUtils {
  FormatUtils._();

  static String distance(double meters) {
    if (meters < 1000) return '${meters.toStringAsFixed(0)} m';
    final km = meters / 1000;
    return '${km.toStringAsFixed(1)} km';
  }

  static String speed(double kmh) => '${kmh.toStringAsFixed(0)} km/h';

  static String number(num value) =>
      NumberFormat.compact().format(value);

  static String percentage(double value) => '${value.toStringAsFixed(1)}%';

  static String fuelLevel(double? liters) =>
      liters == null ? '--' : '${liters.toStringAsFixed(1)} L';

  static String voltage(double? v) =>
      v == null ? '--' : '${v.toStringAsFixed(1)} V';

  static String capitalize(String s) =>
      s.isEmpty ? s : '${s[0].toUpperCase()}${s.substring(1).toLowerCase()}';
}
