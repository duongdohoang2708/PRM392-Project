import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Central date/time display configuration for the app.
class AppDateTimeFormat {
  AppDateTimeFormat._();

  /// When `false`, the app uses 24-hour display (`HH:mm`).
  static bool use12HourClock = true;

  static String get _timePattern => use12HourClock ? 'h:mm a' : 'HH:mm';

  static String time(DateTime value) =>
      DateFormat(_timePattern).format(value);

  static String date(DateTime value) =>
      DateFormat('MMM d, yyyy').format(value);

  static String shortDate(DateTime value) =>
      DateFormat('MMM d').format(value);

  static String monthYear(DateTime value) =>
      DateFormat('MMMM yyyy').format(value);

  static String weekdayMonthDay(DateTime value) =>
      DateFormat('EEEE, MMM d').format(value);

  static String dateAndTime(DateTime value) =>
      DateFormat('MMM d, $_timePattern').format(value);

  static String slashDate(DateTime value) =>
      DateFormat('dd/MM/yyyy').format(value);

  static String slashDateShort(DateTime value) =>
      DateFormat('dd/MM').format(value);

  static String timeOfDay(TimeOfDay value) {
    final now = DateTime.now();
    return time(
      DateTime(now.year, now.month, now.day, value.hour, value.minute),
    );
  }

  /// Hour number for statistics charts (e.g. "12", "5").
  static String chartHourNumber(int hour) {
    if (use12HourClock) {
      final display = hour % 12;
      return '${display == 0 ? 12 : display}';
    }
    return hour.toString().padLeft(2, '0');
  }

  /// AM/PM suffix for statistics charts; null in 24-hour mode.
  static String? chartHourPeriod(int hour) {
    if (!use12HourClock) return null;
    return hour < 12 ? 'AM' : 'PM';
  }

  /// Hour bucket label for statistics charts (e.g. "12 AM", "5 PM").
  static String chartHour(int hour) {
    final period = chartHourPeriod(hour);
    if (period == null) return chartHourNumber(hour);
    return '${chartHourNumber(hour)} $period';
  }

  static String sessionTimestamp(DateTime value) =>
      '${date(value)} - ${time(value)}';

  static String logTimestamp(DateTime value) =>
      '${slashDate(value)} - ${time(value)}';

  /// Label for task due date in list rows (Today/Tomorrow/Overdue variants).
  static String taskDueLabel(DateTime date, {required bool isOverdue, bool isAllDay = false}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final tDate = DateTime(date.year, date.month, date.day);

    if (isOverdue) {
      return 'Overdue, ${shortDate(date)}';
    }
    if (tDate.isAtSameMomentAs(today)) {
      return isAllDay ? 'Today, All Day' : 'Today, ${time(date)}';
    }
    if (tDate.isAtSameMomentAs(tomorrow)) {
      return isAllDay ? 'Tomorrow, All Day' : 'Tomorrow, ${time(date)}';
    }
    return isAllDay ? '${shortDate(date)}, All Day' : dateAndTime(date);
  }

  /// Countdown / duration display (`mm:ss`). Not affected by [use12HourClock].
  static String durationMinutesSeconds(int minutes, int seconds) =>
      '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

  /// Pomodoro preset duration (`25:00`). Not affected by [use12HourClock].
  static String durationMinutes(int minutes) =>
      '${minutes.toString().padLeft(2, '0')}:00';
}
