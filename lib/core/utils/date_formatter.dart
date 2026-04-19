import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  static String format(DateTime dt, String pattern) =>
      DateFormat(pattern).format(dt);

  static String toDate(DateTime dt) => DateFormat('dd MMM yyyy').format(dt);

  static String toTime(DateTime dt) => DateFormat('HH:mm').format(dt);

  static String toDateTime(DateTime dt) =>
      DateFormat('dd MMM yyyy, HH:mm').format(dt);

  static String toApiDate(DateTime dt) => DateFormat('yyyy-MM-dd').format(dt);

  static String toRelative(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return toDate(dt);
  }

  static String duration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }

  static DateTime? tryParse(String? s) =>
      s == null ? null : DateTime.tryParse(s)?.toLocal();
}
