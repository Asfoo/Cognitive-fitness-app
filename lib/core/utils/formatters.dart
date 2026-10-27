const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

extension DateTimeX on DateTime {
  DateTime get startOfDay => DateTime(year, month, day);

  /// Calendar-safe day arithmetic (immune to DST shifts).
  DateTime addDays(int days) => DateTime(year, month, day + days);

  bool isSameDay(DateTime other) => year == other.year && month == other.month && day == other.day;

  String get weekdayShort => _weekdays[weekday - 1];

  String get monthShort => _months[month - 1];

  /// e.g. "Tue, 27 Oct"
  String get dayLabel => '$weekdayShort, $day $monthShort';

  /// e.g. "09:05"
  String get timeLabel => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  /// "Today 09:05", "Yesterday 18:20" or "27 Oct 09:05" relative to [now].
  String relativeLabel(DateTime now) {
    if (isSameDay(now)) return 'Today $timeLabel';
    if (isSameDay(now.addDays(-1))) return 'Yesterday $timeLabel';
    return '$day $monthShort $timeLabel';
  }
}

abstract final class Format {
  static String ms(num? value) => value == null ? '–' : value.round().toString();

  static String percent(double? fraction) => fraction == null ? '–' : (fraction * 100).round().toString();

  /// Signed whole percentage, e.g. "+12%" / "−8%".
  static String signedPercent(double fraction) {
    final value = (fraction * 100).round();
    return '${value > 0 ? '+' : value < 0 ? '−' : ''}${value.abs()}%';
  }

  static String duration(Duration d) {
    if (d.inMinutes >= 1) return '${d.inMinutes}m ${d.inSeconds % 60}s';
    return '${d.inSeconds}s';
  }
}
