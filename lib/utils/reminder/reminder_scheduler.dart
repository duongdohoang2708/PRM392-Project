import '../../models/task_model.dart';
import '../formatters/app_date_time_format.dart';
import 'task_reminder.dart';

/// Computes scheduled fire times for task reminders and due-deadline alerts.
class ReminderScheduler {
  ReminderScheduler._();

  static const int _reminderIdOffset = 10000;
  static const int _dueIdOffset = 60000;
  static const int _idBucketSize = 50000;
  static const int _allDayDueHour = 9;

  static int notificationIdForTask(String taskId) {
    return _reminderIdOffset +
        (taskId.hashCode & 0x7fffffff) % _idBucketSize;
  }

  static int notificationIdForTaskDue(String taskId) {
    return _dueIdOffset + (taskId.hashCode & 0x7fffffff) % _idBucketSize;
  }

  // --- Advance reminders (optional user setting) ---

  static DateTime? computeFireTime({
    required DateTime? dueDate,
    required bool isAllDay,
    required String reminder,
  }) {
    final fireAt = computeRawFireTime(
      dueDate: dueDate,
      isAllDay: isAllDay,
      reminder: reminder,
    );
    if (fireAt == null) return null;
    if (!fireAt.isAfter(DateTime.now())) return null;
    return fireAt;
  }

  static DateTime? computeRawFireTime({
    required DateTime? dueDate,
    required bool isAllDay,
    required String reminder,
  }) {
    if (dueDate == null || reminder == TaskReminder.none) return null;
    return _subtractReminderOffset(dueDate, isAllDay, reminder);
  }

  static DateTime? computeFireTimeForTask(Task task) {
    if (task.isCompleted || !shouldRemindForTask(task)) return null;
    return computeFireTime(
      dueDate: task.dueDate,
      isAllDay: task.isAllDay,
      reminder: task.reminder,
    );
  }

  /// Whether a task is still eligible for advance (pre-due) reminders.
  static bool shouldRemindForTask(Task task) {
    if (task.isCompleted ||
        task.dueDate == null ||
        task.reminder == TaskReminder.none) {
      return false;
    }
    return !isTaskDeadlinePassed(task);
  }

  // --- Due-deadline alerts (always when task has a due date) ---

  static DateTime? computeRawDueFireTime(Task task) {
    final dueDate = task.dueDate;
    if (dueDate == null) return null;
    if (task.isAllDay) {
      return DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        _allDayDueHour,
      );
    }
    return dueDate;
  }

  static DateTime? computeDueFireTimeForTask(Task task) {
    if (task.isCompleted || !shouldNotifyAtDue(task)) return null;
    final dueAt = computeRawDueFireTime(task);
    if (dueAt == null || !dueAt.isAfter(DateTime.now())) return null;
    return dueAt;
  }

  /// Any incomplete task with a due date gets a notification at due time.
  static bool shouldNotifyAtDue(Task task) {
    if (task.isCompleted || task.dueDate == null) return false;
    return !isTaskDeadlinePassed(task);
  }

  /// Deadline has passed — no new notifications should be scheduled or delivered.
  static bool isTaskDeadlinePassed(Task task) {
    final dueDate = task.dueDate;
    if (dueDate == null) return false;

    final now = DateTime.now();
    final dueMoment = computeRawDueFireTime(task);
    if (dueMoment == null) return false;
    return !dueMoment.isAfter(now);
  }

  /// Watchdog may deliver a missed advance reminder before the deadline.
  static bool shouldDeliverReminderNow(Task task, DateTime fireAt) {
    if (!shouldRemindForTask(task)) return false;
    final now = DateTime.now();
    if (fireAt.isAfter(now)) return false;
    if (now.difference(fireAt) > const Duration(minutes: 30)) return false;
    final dueAt = computeRawDueFireTime(task);
    if (dueAt != null && !now.isBefore(dueAt)) return false;
    return true;
  }

  /// Watchdog delivers the due-deadline alert when due time is reached.
  static bool shouldDeliverDueNow(Task task, DateTime dueAt) {
    if (task.isCompleted || task.dueDate == null) return false;
    final now = DateTime.now();
    if (dueAt.isAfter(now)) return false;
    if (now.difference(dueAt) > const Duration(minutes: 30)) return false;
    return true;
  }

  /// In-app history backfill when the app reopens after a missed delivery window.
  static bool shouldBackfillReminderHistory(Task task, DateTime fireAt) {
    if (!shouldRemindForTask(task)) return false;
    final now = DateTime.now();
    if (fireAt.isAfter(now)) return false;
    if (now.difference(fireAt) > const Duration(hours: 6)) return false;
    final dueAt = computeRawDueFireTime(task);
    if (dueAt != null && !now.isBefore(dueAt)) return false;
    return true;
  }

  static bool shouldBackfillDueHistory(Task task, DateTime dueAt) {
    if (task.isCompleted || task.dueDate == null) return false;
    final now = DateTime.now();
    if (dueAt.isAfter(now)) return false;
    if (now.difference(dueAt) > const Duration(hours: 6)) return false;
    return true;
  }

  static DateTime? _subtractReminderOffset(
    DateTime dueDate,
    bool isAllDay,
    String reminder,
  ) {
    if (isAllDay) {
      final dueDayAtReminderHour = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        _allDayDueHour,
      );
      if (reminder == '1 day before') {
        return dueDayAtReminderHour.subtract(const Duration(days: 1));
      }
      if (reminder == '1 week before') {
        return dueDayAtReminderHour.subtract(const Duration(days: 7));
      }
      final custom = TaskReminder.parseAllDayCustom(reminder);
      if (custom == null) return null;
      final days = custom.unit == 'weeks' ? custom.value * 7 : custom.value;
      return DateTime(
        dueDayAtReminderHour.year,
        dueDayAtReminderHour.month,
        dueDayAtReminderHour.day - days,
        custom.time.hour,
        custom.time.minute,
      );
    }

    switch (reminder) {
      case '10 mins before':
        return dueDate.subtract(const Duration(minutes: 10));
      case '15 mins before':
        return dueDate.subtract(const Duration(minutes: 15));
      case '30 mins before':
        return dueDate.subtract(const Duration(minutes: 30));
      case '1 hour before':
        return dueDate.subtract(const Duration(hours: 1));
      case '1 day before':
        return dueDate.subtract(const Duration(days: 1));
    }

    final custom = TaskReminder.parseTimedCustom(reminder);
    if (custom == null) return null;
    return switch (custom.unit) {
      'minutes' => dueDate.subtract(Duration(minutes: custom.value)),
      'hours' => dueDate.subtract(Duration(hours: custom.value)),
      'days' => dueDate.subtract(Duration(days: custom.value)),
      'weeks' => dueDate.subtract(Duration(days: custom.value * 7)),
      _ => null,
    };
  }

  static String buildNotificationBody(Task task, DateTime fireAt) {
    final dueDate = task.dueDate;
    if (dueDate == null) return 'Task due soon';
    if (task.isAllDay) {
      final dueAt = DateTime(
        dueDate.year,
        dueDate.month,
        dueDate.day,
        _allDayDueHour,
      );
      return 'Due at ${_formatTime(dueAt)}';
    }
    return 'Due at ${_formatTime(dueDate)}';
  }

  static String buildDueNotificationBody(Task task) {
    if (task.isAllDay) {
      return 'This all-day task is due today';
    }
    return 'This task is due now';
  }

  static String _formatTime(DateTime dateTime) =>
      AppDateTimeFormat.time(dateTime);
}
