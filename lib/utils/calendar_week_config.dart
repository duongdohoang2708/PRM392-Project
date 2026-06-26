/// Week-start configuration shared by calendar, goals streak, and statistics.
class CalendarWeekConfig {
  CalendarWeekConfig._();

  static bool weekStartsOnMonday = true;

  static const _mondayFirstLabels = [
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
    'Sun',
  ];

  static const _sundayFirstLabels = [
    'Sun',
    'Mon',
    'Tue',
    'Wed',
    'Thu',
    'Fri',
    'Sat',
  ];

  static List<String> get weekdayLabels =>
      weekStartsOnMonday ? _mondayFirstLabels : _sundayFirstLabels;

  /// Days to subtract from the 1st of a month to align the grid start column.
  static int leadingDaysBeforeMonth(DateTime firstOfMonth) {
    final weekday = firstOfMonth.weekday;
    if (weekStartsOnMonday) return weekday - 1;
    return weekday % 7;
  }

  /// First day of the week that contains [day] (normalized to date only).
  static DateTime weekStartFor(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    if (weekStartsOnMonday) {
      return normalized.subtract(Duration(days: normalized.weekday - 1));
    }
    return normalized.subtract(Duration(days: normalized.weekday % 7));
  }

  /// Label for a date based on the configured week column order.
  static String labelForDateInWeek(DateTime date, DateTime weekStart) {
    final index = date.difference(weekStart).inDays.clamp(0, 6);
    return weekdayLabels[index];
  }
}
