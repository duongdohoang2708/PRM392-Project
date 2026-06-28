import 'package:flutter/material.dart';

enum ActivityModeId { defaultMode, work, study, chill, sleep }

class ActivityModeSchedule {
  final bool enabled;
  final TimeOfDay start;
  final TimeOfDay end;

  const ActivityModeSchedule({
    required this.enabled,
    required this.start,
    required this.end,
  });

  ActivityModeSchedule copyWith({
    bool? enabled,
    TimeOfDay? start,
    TimeOfDay? end,
  }) {
    return ActivityModeSchedule(
      enabled: enabled ?? this.enabled,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  bool containsTime(DateTime at) {
    if (!enabled) return false;
    final nowMinutes = at.hour * 60 + at.minute;
    final startMinutes = start.hour * 60 + start.minute;
    final endMinutes = end.hour * 60 + end.minute;

    if (startMinutes == endMinutes) return false;

    if (startMinutes < endMinutes) {
      return nowMinutes >= startMinutes && nowMinutes < endMinutes;
    }
    // Overnight window (e.g. 23:00 – 07:00)
    return nowMinutes >= startMinutes || nowMinutes < endMinutes;
  }
}

class ActivityModeDefinition {
  final ActivityModeId id;
  final String name;
  final IconData icon;
  final String description;
  final ActivityModeSchedule defaultSchedule;

  const ActivityModeDefinition({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.defaultSchedule,
  });
}

class ActivityModes {
  ActivityModes._();

  static const List<ActivityModeId> schedulePriority = [
    ActivityModeId.sleep,
    ActivityModeId.chill,
    ActivityModeId.study,
    ActivityModeId.work,
  ];

  static const List<ActivityModeDefinition> presets = [
    ActivityModeDefinition(
      id: ActivityModeId.defaultMode,
      name: 'Default',
      icon: Icons.spa_outlined,
      description: 'Matcha pastel — your everyday theme.',
      defaultSchedule: ActivityModeSchedule(
        enabled: false,
        start: TimeOfDay(hour: 0, minute: 0),
        end: TimeOfDay(hour: 0, minute: 0),
      ),
    ),
    ActivityModeDefinition(
      id: ActivityModeId.work,
      name: 'Work Mode',
      icon: Icons.work_outline,
      description: 'Cool, focused palette for deep work.',
      defaultSchedule: ActivityModeSchedule(
        enabled: true,
        start: TimeOfDay(hour: 9, minute: 0),
        end: TimeOfDay(hour: 17, minute: 0),
      ),
    ),
    ActivityModeDefinition(
      id: ActivityModeId.study,
      name: 'Study Mode',
      icon: Icons.menu_book_outlined,
      description: 'Warm tones to keep you learning.',
      defaultSchedule: ActivityModeSchedule(
        enabled: true,
        start: TimeOfDay(hour: 17, minute: 30),
        end: TimeOfDay(hour: 21, minute: 0),
      ),
    ),
    ActivityModeDefinition(
      id: ActivityModeId.chill,
      name: 'Chill Mode',
      icon: Icons.self_improvement_outlined,
      description: 'Soft lavender for relaxed evenings.',
      defaultSchedule: ActivityModeSchedule(
        enabled: true,
        start: TimeOfDay(hour: 21, minute: 0),
        end: TimeOfDay(hour: 23, minute: 0),
      ),
    ),
    ActivityModeDefinition(
      id: ActivityModeId.sleep,
      name: 'Sleep Mode',
      icon: Icons.bedtime_outlined,
      description: 'Dim, calming colors for winding down.',
      defaultSchedule: ActivityModeSchedule(
        enabled: true,
        start: TimeOfDay(hour: 23, minute: 0),
        end: TimeOfDay(hour: 7, minute: 0),
      ),
    ),
  ];

  static ActivityModeDefinition definitionFor(ActivityModeId id) {
    return presets.firstWhere((mode) => mode.id == id);
  }

  static String storageKeyFor(ActivityModeId id) {
    return switch (id) {
      ActivityModeId.defaultMode => 'default',
      ActivityModeId.work => 'work',
      ActivityModeId.study => 'study',
      ActivityModeId.chill => 'chill',
      ActivityModeId.sleep => 'sleep',
    };
  }

  static ActivityModeId idFromStorage(String value) {
    return switch (value) {
      'work' => ActivityModeId.work,
      'study' => ActivityModeId.study,
      'chill' => ActivityModeId.chill,
      'sleep' => ActivityModeId.sleep,
      _ => ActivityModeId.defaultMode,
    };
  }

  static ActivityModeId idFromRoute(String value) {
    return ActivityModeId.values.firstWhere(
      (id) => id.name == value,
      orElse: () => ActivityModeId.defaultMode,
    );
  }
}
