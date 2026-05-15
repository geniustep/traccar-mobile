import '../../../../core/utils/date_formatter.dart';
import '../../../../core/utils/format_utils.dart';
import 'multi_vehicle_replay_timeline.dart';

/// Display helpers and validation for multi-vehicle replay.
abstract final class MultiVehicleReplayFormatters {
  MultiVehicleReplayFormatters._();

  static bool canReplay(int vehicleCount) =>
      MultiVehicleReplayTimelineBuilder.isValidCount(vehicleCount);

  static String formatReplayTime(DateTime? time) {
    if (time == null) return '—';
    return DateFormatter.toTime(time);
  }

  static String formatTimeRange(DateTime? start, DateTime? end) {
    if (start == null || end == null) return '—';
    return '${formatReplayTime(start)} – ${formatReplayTime(end)}';
  }

  static String formatDistance(double? meters) {
    if (meters == null) return '—';
    return FormatUtils.distance(meters);
  }

  static String formatDayLabel(DateTime date, {required bool isToday}) {
    if (isToday) return 'today'; // caller replaces with l10n.replayToday
    return DateFormatter.toDate(date);
  }

  static bool isSameCalendarDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static DateTime startOfDay(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime endOfDayForReplay(DateTime date) {
    final now = DateTime.now();
    if (isSameCalendarDay(date, now)) return now;
    return DateTime(date.year, date.month, date.day, 23, 59, 59);
  }
}
