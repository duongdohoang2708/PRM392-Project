import 'package:flutter/material.dart';
import '../formatters/app_date_time_format.dart';

/// Preset and custom reminder label helpers for task create/edit flows.
class TaskReminder {
  TaskReminder._();

  static const String none = 'None';
  static const String custom = 'Custom';

  static const List<String> timedPresets = [
    none,
    '10 mins before',
    '15 mins before',
    '30 mins before',
    '1 hour before',
    '1 day before',
    custom,
  ];

  static const List<String> allDayPresets = [
    none,
    '1 day before',
    '1 week before',
    custom,
  ];

  static const List<String> timedUnits = [
    'minutes',
    'hours',
    'days',
    'weeks',
  ];

  static const List<String> allDayUnits = ['days', 'weeks'];

  static List<String> presetsFor(bool isAllDay) =>
      isAllDay ? allDayPresets : timedPresets;

  static bool isPreset(String reminder, bool isAllDay) =>
      presetsFor(isAllDay).contains(reminder);

  static bool isCustomValue(String reminder, bool isAllDay) =>
      reminder != none && !isPreset(reminder, isAllDay);

  static String dropdownValue(String reminder, bool isAllDay) {
    if (isPreset(reminder, isAllDay)) return reminder;
    return custom;
  }

  static String coerceForMode(String reminder, bool isAllDay) {
    if (isPreset(reminder, isAllDay)) return reminder;
    if (isAllDay) {
      return parseAllDayCustom(reminder) != null ? reminder : none;
    }
    return parseTimedCustom(reminder) != null ? reminder : none;
  }

  static String formatTimedCustom(int value, String unit) {
    return '$value ${_unitLabel(value, unit)} before';
  }

  static String formatAllDayCustom(int value, String unit, TimeOfDay time) {
    final timeLabel = AppDateTimeFormat.timeOfDay(time);
    return '$value ${_unitLabel(value, unit)} before at $timeLabel';
  }

  static String _unitLabel(int value, String unit) {
    final singular = value == 1;
    switch (unit) {
      case 'minutes':
        return singular ? 'min' : 'mins';
      case 'hours':
        return singular ? 'hour' : 'hours';
      case 'days':
        return singular ? 'day' : 'days';
      case 'weeks':
        return singular ? 'week' : 'weeks';
      default:
        return unit;
    }
  }

  static String unitPickerLabel(String unit, int value) {
    switch (unit) {
      case 'minutes':
        return value == 1 ? 'minute' : 'minutes';
      case 'hours':
        return value == 1 ? 'hour' : 'hours';
      case 'days':
        return value == 1 ? 'day' : 'days';
      case 'weeks':
        return value == 1 ? 'week' : 'weeks';
      default:
        return unit;
    }
  }

  static TimedCustomReminder? parseTimedCustom(String reminder) {
    final match = RegExp(
      r'^(\d+)\s+(min|mins|minute|minutes|hour|hours|day|days|week|weeks)\s+before$',
      caseSensitive: false,
    ).firstMatch(reminder.trim());
    if (match == null) return null;

    final value = int.tryParse(match.group(1)!);
    if (value == null || value < 1 || value > 360) return null;

    final unitToken = match.group(2)!.toLowerCase();
    final unit = switch (unitToken) {
      'min' || 'mins' || 'minute' || 'minutes' => 'minutes',
      'hour' || 'hours' => 'hours',
      'day' || 'days' => 'days',
      'week' || 'weeks' => 'weeks',
      _ => null,
    };
    if (unit == null) return null;

    return TimedCustomReminder(value: value, unit: unit);
  }

  static AllDayCustomReminder? parseAllDayCustom(String reminder) {
    final match = RegExp(
      r'^(\d+)\s+(day|days|week|weeks)\s+before\s+at\s+(.+)$',
      caseSensitive: false,
    ).firstMatch(reminder.trim());
    if (match == null) return null;

    final value = int.tryParse(match.group(1)!);
    if (value == null || value < 1 || value > 365) return null;

    final unitToken = match.group(2)!.toLowerCase();
    final unit = switch (unitToken) {
      'day' || 'days' => 'days',
      'week' || 'weeks' => 'weeks',
      _ => null,
    };
    if (unit == null) return null;

    final time = _parseTimeLabel(match.group(3)!.trim());
    if (time == null) return null;

    return AllDayCustomReminder(value: value, unit: unit, time: time);
  }
}

class TimedCustomReminder {
  final int value;
  final String unit;

  const TimedCustomReminder({required this.value, required this.unit});
}

class AllDayCustomReminder {
  final int value;
  final String unit;
  final TimeOfDay time;

  const AllDayCustomReminder({
    required this.value,
    required this.unit,
    required this.time,
  });
}

TimeOfDay? _parseTimeLabel(String label) {
  final match = RegExp(
    r'^(\d{1,2}):(\d{2})\s*(am|pm)?$',
    caseSensitive: false,
  ).firstMatch(label.replaceAll(RegExp(r'\s+'), ' '));
  if (match == null) return null;

  var hour = int.tryParse(match.group(1)!);
  final minute = int.tryParse(match.group(2)!);
  if (hour == null || minute == null) return null;

  final meridiem = match.group(3)?.toLowerCase();
  if (meridiem != null) {
    if (hour == 12) {
      hour = meridiem == 'am' ? 0 : 12;
    } else if (meridiem == 'pm') {
      hour += 12;
    }
  }

  if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
  return TimeOfDay(hour: hour, minute: minute);
}
