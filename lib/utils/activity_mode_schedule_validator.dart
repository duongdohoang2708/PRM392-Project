import '../models/activity_mode.dart';

class ActivityModeScheduleValidator {
  ActivityModeScheduleValidator._();

  /// Returns an error message when [schedule] is invalid, otherwise `null`.
  static String? validate({
    required ActivityModeId modeId,
    required ActivityModeSchedule schedule,
    required Map<ActivityModeId, ActivityModeSchedule> schedules,
  }) {
    if (!schedule.enabled) return null;

    if (schedule.start.hour == schedule.end.hour &&
        schedule.start.minute == schedule.end.minute) {
      return 'Start and end time must be different.';
    }

    for (final entry in schedules.entries) {
      final otherId = entry.key;
      if (otherId == modeId || otherId == ActivityModeId.defaultMode) {
        continue;
      }

      final other = entry.value;
      if (!other.enabled) continue;

      if (schedule.hasSameWindowAs(other)) {
        final otherName = ActivityModes.definitionFor(otherId).name;
        return '$otherName already uses this exact schedule (same start and end). '
            'Change one of the times slightly — e.g. 1:01 PM–4 PM instead of 1 PM–4 PM.';
      }
    }

    return null;
  }
}
