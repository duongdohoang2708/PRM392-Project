import 'package:flutter/material.dart';

/// Shared deadline validation for task create/edit flows.
class TaskDeadlineRules {
  static const String createDeadlineError =
      'Task deadline cannot be earlier than current time';

  /// Earliest date selectable when creating a new task.
  static DateTime minSelectableDateForCreate([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    return now.subtract(const Duration(minutes: 1));
  }

  /// Returns true when [date] is strictly before the start of today.
  static bool isPastCalendarDay(DateTime date, [DateTime? reference]) {
    final now = reference ?? DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final day = DateTime(date.year, date.month, date.day);
    return day.isBefore(today);
  }

  /// New tasks may omit a deadline, but any set deadline must be >= [reference].
  static bool isValidForCreate(DateTime? dueDate, [DateTime? reference]) {
    if (dueDate == null) return true;
    final now = reference ?? DateTime.now();
    return !dueDate.isBefore(now);
  }

  /// Default time when the user picks a date: one hour after [reference], rounded to the hour.
  /// e.g. 10:27 → 11:00
  static TimeOfDay defaultTimeOnDatePick([DateTime? reference]) {
    final now = reference ?? DateTime.now();
    final hour = (now.hour + 1).clamp(0, 23);
    return TimeOfDay(hour: hour, minute: 0);
  }
}
