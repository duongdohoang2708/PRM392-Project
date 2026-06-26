import '../../models/task_model.dart';
import '../../providers/focus_provider.dart';
import '../../providers/goals_provider.dart';

/// Builds copy and schedule times for goals, focus, achievement, and digest alerts.
class InsightNotificationBuilder {
  InsightNotificationBuilder._();

  static const int morningHour = 8;
  static const int morningMinute = 0;
  static const int overdueDigestMinute = 15;
  static const int importantEodHour = 20;
  static const int importantEodMinute = 0;
  static const int goalsEodHour = 21;
  static const int goalsEodMinute = 0;
  static const int weeklySummaryHour = 20;
  static const int weeklySummaryMinute = 0;
  static const int freezeDayHour = 9;
  static const int focusNearMinutes = 10;

  static String achievementKey(Achievement achievement) =>
      '${achievement.category.name}_${achievement.target}';

  static DateTime? nextDailyTime({
    required int hour,
    required int minute,
  }) {
    final now = DateTime.now();
    var candidate = DateTime(now.year, now.month, now.day, hour, minute);
    if (!candidate.isAfter(now)) {
      candidate = candidate.add(const Duration(days: 1));
    }
    return candidate;
  }

  static DateTime? nextWeeklySundayTime({
    required int hour,
    required int minute,
  }) {
    final now = DateTime.now();
    var cursor = DateTime(now.year, now.month, now.day, hour, minute);
    for (var i = 0; i < 14; i++) {
      if (cursor.weekday == DateTime.sunday && cursor.isAfter(now)) {
        return cursor;
      }
      cursor = DateTime(
        cursor.year,
        cursor.month,
        cursor.day + 1,
        hour,
        minute,
      );
    }
    return null;
  }

  static int tasksDueTodayCount(List<Task> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return tasks.where((task) {
      if (task.isCompleted || task.dueDate == null) return false;
      final dueDay = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );
      return dueDay.isAtSameMomentAs(today);
    }).length;
  }

  static int overdueCount(List<Task> tasks) {
    final now = DateTime.now();
    return tasks.where((task) {
      if (task.isCompleted || task.dueDate == null) return false;
      return task.dueDate!.isBefore(now);
    }).length;
  }

  static int importantIncompleteDueToday(List<Task> tasks) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return tasks.where((task) {
      if (!task.isImportant || task.isCompleted || task.dueDate == null) {
        return false;
      }
      final dueDay = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );
      return dueDay.isAtSameMomentAs(today);
    }).length;
  }

  static int tasksCompletedInLastDays(List<Task> tasks, int days) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));
    return tasks.where((task) {
      final completedAt = task.completedAt;
      if (!task.isCompleted || completedAt == null) return false;
      final completedDay = DateTime(
        completedAt.year,
        completedAt.month,
        completedAt.day,
      );
      final today = DateTime(now.year, now.month, now.day);
      return !completedDay.isBefore(start) && !completedDay.isAfter(today);
    }).length;
  }

  static ({String title, String body}) morningDigest(List<Task> tasks) {
    final todayCount = tasksDueTodayCount(tasks);
    final overdue = overdueCount(tasks);
    if (todayCount == 0 && overdue == 0) {
      return (
        title: 'Good morning',
        body: 'No tasks scheduled for today. Plan something or enjoy the calm.',
      );
    }
    final parts = <String>[];
    if (todayCount > 0) {
      parts.add(
        todayCount == 1 ? '1 task due today' : '$todayCount tasks due today',
      );
    }
    if (overdue > 0) {
      parts.add(overdue == 1 ? '1 overdue' : '$overdue overdue');
    }
    return (
      title: 'Today in TaskFlow',
      body: parts.join(' • '),
    );
  }

  static ({String title, String body})? overdueDigest(List<Task> tasks) {
    final overdue = overdueCount(tasks);
    if (overdue == 0) return null;
    return (
      title: 'Overdue tasks',
      body: overdue == 1
          ? 'You have 1 overdue task waiting for attention.'
          : 'You have $overdue overdue tasks waiting for attention.',
    );
  }

  static ({String title, String body})? importantEod(List<Task> tasks) {
    final count = importantIncompleteDueToday(tasks);
    if (count == 0) return null;
    return (
      title: 'Important tasks tonight',
      body: count == 1
          ? '1 important task is still due today.'
          : '$count important tasks are still due today.',
    );
  }

  static ({String title, String body})? goalsEndOfDay(GoalsProvider goals) {
    if (goals.isTodayRestDay || goals.isTodayComplete) return null;

    final taskRemaining = goals.taskDailyGoal.remaining;
    final focusRemaining = goals.focusDailyGoal.remaining;
    final parts = <String>[];

    if (taskRemaining > 0) {
      parts.add(
        taskRemaining == 1
            ? '1 task goal left'
            : '$taskRemaining task goals left',
      );
    }
    if (focusRemaining > 0) {
      parts.add(
        focusRemaining == 1
            ? '1 min of focus left'
            : '$focusRemaining min of focus left',
      );
    }
    if (parts.isEmpty) return null;

    var body = 'Keep your streak alive: ${parts.join(' • ')}.';
    if (goals.manualRestCreditsRemaining > 0) {
      body +=
          ' (${goals.manualRestCreditsRemaining} freeze credit${goals.manualRestCreditsRemaining == 1 ? '' : 's'} left this month)';
    }
    return (title: 'Streak check-in', body: body);
  }

  static ({String title, String body}) freezeDayMorning(GoalsProvider goals) {
    if (goals.isTodayManualRestDay) {
      return (
        title: 'Manual freeze day',
        body:
            'Goals are waived today. Your streak is preserved without adding a day.',
      );
    }
    return (
      title: 'Weekly freeze day',
      body:
          'Rest day — task and focus goals are waived. Your streak is preserved.',
    );
  }

  static ({String title, String body}) weeklySummary({
    required List<Task> tasks,
    required GoalsProvider goals,
    required int focusMinutesThisWeek,
  }) {
    final completed = tasksCompletedInLastDays(tasks, 7);
    return (
      title: 'Your week in TaskFlow',
      body:
          '$completed tasks completed • $focusMinutesThisWeek min focused • ${goals.currentStreak}-day streak',
    );
  }

  static int focusMinutesInLastDays(FocusProvider focus, int days) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));
    return focus.focusHistory.where((log) {
      final day = DateTime(log.time.year, log.time.month, log.time.day);
      return !day.isBefore(start) && !day.isAfter(now);
    }).fold<int>(0, (sum, log) => sum + log.durationMinutes);
  }

  static ({String title, String body}) streakSecured(GoalsProvider goals) {
    return (
      title: 'Streak secured!',
      body:
          '${goals.currentStreak}-day streak — today\'s tasks and focus goals are complete.',
    );
  }

  static ({String title, String body}) focusGoalMet(GoalsProvider goals) {
    return (
      title: 'Focus goal reached',
      body:
          'You hit ${goals.focusGoal} minutes of focus today. Great concentration!',
    );
  }

  static ({String title, String body}) focusGoalNear(GoalsProvider goals) {
    final remaining = goals.focusDailyGoal.remaining;
    return (
      title: 'Almost at your focus goal',
      body:
          'Only $remaining min left to reach ${goals.focusGoal} minutes today.',
    );
  }

  static ({String title, String body}) achievementUnlocked(
    Achievement achievement,
  ) {
    return (title: 'Achievement unlocked', body: achievement.title);
  }

  static ({String title, String body})? achievementNearUnlock(
    Achievement achievement,
  ) {
    final remaining = achievement.target - achievement.current;
    if (remaining != 1) return null;
    return (
      title: 'Almost there',
      body: 'Just 1 more step to unlock "${achievement.title}".',
    );
  }

  static ({String title, String body})? statisticsMilestone({
    required int completedTasksAllTime,
  }) {
    const milestones = [10, 25, 50, 100, 200, 500];
    for (final milestone in milestones) {
      if (completedTasksAllTime == milestone) {
        return (
          title: 'Milestone reached',
          body: 'You have completed $milestone tasks in TaskFlow!',
        );
      }
    }
    return null;
  }
}
