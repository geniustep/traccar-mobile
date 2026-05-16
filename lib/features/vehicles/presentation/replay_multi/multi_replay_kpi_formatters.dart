import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/format_utils.dart';
/// Display formatting for multi-replay KPI values (Phase R8).
abstract final class MultiReplayKpiFormatters {
  MultiReplayKpiFormatters._();

  static String distanceKm(double? km) {
    if (km == null || km <= 0) return '—';
    return FormatUtils.distance(km * 1000);
  }

  static String speedKmh(double? kmh) {
    if (kmh == null) return '—';
    return '${kmh.round()} km/h';
  }

  static String duration(Duration d) {
    if (d <= Duration.zero) return '—';
    return DateFormatter.duration(d.inSeconds);
  }

  static String count(int? n) {
    if (n == null) return '—';
    return '$n';
  }

  static String time(DateTime? t) {
    if (t == null) return '—';
    return DateFormatter.toTime(t);
  }
}
