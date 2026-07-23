import 'package:intl/intl.dart';

/// Centralized date/time formatting so the whole app displays dates
/// consistently (e.g. event schedules, deadlines, meeting times).
abstract final class DateFormatter {
  static final _dayMonthYear = DateFormat('MMM d, yyyy');
  static final _time = DateFormat('h:mm a');
  static final _dayMonthYearTime = DateFormat('MMM d, yyyy • h:mm a');
  static final _weekdayDayMonth = DateFormat('EEE, MMM d');

  static String date(DateTime dt) => _dayMonthYear.format(dt.toLocal());
  static String time(DateTime dt) => _time.format(dt.toLocal());
  static String dateTime(DateTime dt) => _dayMonthYearTime.format(dt.toLocal());
  static String weekdayDate(DateTime dt) => _weekdayDayMonth.format(dt.toLocal());

  /// Human-friendly countdown, e.g. "in 3 days", "in 2 hours", "Ended".
  static String relativeToNow(DateTime dt) {
    final now = DateTime.now();
    final diff = dt.difference(now);
    if (diff.isNegative) return 'Ended';
    if (diff.inDays >= 1) return 'in ${diff.inDays} day${diff.inDays == 1 ? '' : 's'}';
    if (diff.inHours >= 1) return 'in ${diff.inHours} hour${diff.inHours == 1 ? '' : 's'}';
    if (diff.inMinutes >= 1) return 'in ${diff.inMinutes} min';
    return 'Starting now';
  }

  /// Formats a date range for event cards, collapsing same-day ranges.
  static String range(DateTime start, DateTime end) {
    final sameDay = start.year == end.year && start.month == end.month && start.day == end.day;
    if (sameDay) {
      return '${date(start)} • ${time(start)} - ${time(end)}';
    }
    return '${dateTime(start)} - ${dateTime(end)}';
  }
}
