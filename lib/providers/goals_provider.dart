import 'package:flutter/material.dart';

import '../models/task_model.dart';
import 'focus_provider.dart';
import 'task_provider.dart';

enum AchievementCategory {
  sessions,
  focusMinutes,
  streak,
  perfectDays,
  tasksCompleted,
}

class DailyGoalData {
  final int current;
  final int goal;
  final String unit;

  const DailyGoalData({
    required this.current,
    required this.goal,
    required this.unit,
  });

  int get remaining => (goal - current) <= 0 ? 0 : goal - current;
  bool get isCompleted => current >= goal;
  double get progress => goal == 0 ? 0 : (current / goal).clamp(0, 1).toDouble();
}

class Achievement {
  final String title;
  final AchievementCategory category;
  final int target;
  final int current;

  const Achievement({
    required this.title,
    required this.category,
    required this.target,
    required this.current,
  });

  bool get isUnlocked => current >= target;
  double get progress => target == 0 ? 0 : (current / target).clamp(0, 1).toDouble();
}

class GoalDayData {
  final DateTime date;
  final int tasksCompleted;
  final int focusMinutes;
  final int taskGoal;
  final int focusGoal;
  final bool isToday;

  const GoalDayData({
    required this.date,
    required this.tasksCompleted,
    required this.focusMinutes,
    required this.taskGoal,
    required this.focusGoal,
    required this.isToday,
  });

  bool get taskGoalMet => tasksCompleted >= taskGoal;
  bool get focusGoalMet => focusMinutes >= focusGoal;
  bool get isComplete => taskGoalMet && focusGoalMet;
  bool get isPartial => taskGoalMet || focusGoalMet;

  bool get isMissed {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isBefore(today) && !isComplete;
  }
}

class GoalsProvider with ChangeNotifier {
  static const int defaultFocusGoalMinutes = 60;
  static const int defaultTaskGoalCount = 2;

  TaskProvider? _taskProvider;
  FocusProvider? _focusProvider;

  int _taskGoal = defaultTaskGoalCount;
  int _focusGoal = defaultFocusGoalMinutes;

  int get taskGoal => _taskGoal;
  int get focusGoal => _focusGoal;

  void setGoals({
    required int taskGoal,
    required int focusGoal,
  }) {
    final nextTaskGoal = taskGoal.clamp(1, 50);
    final nextFocusGoal = focusGoal.clamp(15, 720);
    if (_taskGoal == nextTaskGoal && _focusGoal == nextFocusGoal) return;

    _taskGoal = nextTaskGoal;
    _focusGoal = nextFocusGoal;
    notifyListeners();
  }

  void updateSources(TaskProvider taskProvider, FocusProvider focusProvider) {
    var didUpdateSource = false;

    if (_taskProvider != taskProvider) {
      _taskProvider?.removeListener(_onSourceUpdated);
      _taskProvider = taskProvider;
      _taskProvider?.addListener(_onSourceUpdated);
      didUpdateSource = true;
    }

    if (_focusProvider != focusProvider) {
      _focusProvider?.removeListener(_onSourceUpdated);
      _focusProvider = focusProvider;
      _focusProvider?.addListener(_onSourceUpdated);
      didUpdateSource = true;
    }

    if (didUpdateSource) {
      notifyListeners();
    }
  }

  DailyGoalData get focusDailyGoal {
    return DailyGoalData(
      current: focusMinutesToday,
      goal: _focusGoal,
      unit: 'min',
    );
  }

  DailyGoalData get taskDailyGoal {
    return DailyGoalData(
      current: tasksCompletedToday,
      goal: _taskGoal,
      unit: 'tasks',
    );
  }

  int get tasksCompletedToday {
    return _tasksCompletedOn(_normalizeDay(DateTime.now()));
  }

  int get focusMinutesToday {
    return _focusMinutesOn(_normalizeDay(DateTime.now()));
  }

  bool get taskGoalMetToday => tasksCompletedToday >= _taskGoal;
  bool get focusGoalMetToday => focusMinutesToday >= _focusGoal;
  bool get isTodayComplete => taskGoalMetToday && focusGoalMetToday;

  int get totalSessions => _focusProvider?.completedSessionsCount ?? 0;
  int get totalFocusMinutes => _focusProvider?.totalFocusMinutes ?? 0;
  int get completedTasksAllTime =>
      (_taskProvider?.tasks ?? const <Task>[]).where((task) => task.isCompleted).length;

  List<GoalDayData> get currentWeekGoalDays {
    final now = DateTime.now();
    return goalWeekDaysFor(now);
  }

  List<GoalDayData> get currentMonthGoalDays {
    final now = DateTime.now();
    return goalMonthDaysFor(now);
  }

  List<GoalDayData> goalWeekDaysFor(DateTime anchorDate) {
    final now = DateTime.now();
    final today = _normalizeDay(now);
    final anchorDay = _normalizeDay(anchorDate);
    final monday = anchorDay.subtract(Duration(days: anchorDay.weekday - 1));

    return List.generate(7, (index) {
      final day = monday.add(Duration(days: index));
      return _buildGoalDay(day, today);
    });
  }

  List<GoalDayData> goalMonthDaysFor(DateTime anchorMonth) {
    final now = DateTime.now();
    final today = _normalizeDay(now);
    final firstDay = DateTime(anchorMonth.year, anchorMonth.month, 1);
    
    final firstWeekday = firstDay.weekday;
    final startDate = firstDay.subtract(Duration(days: firstWeekday - 1));

    return List.generate(42, (index) {
      final day = startDate.add(Duration(days: index));
      return _buildGoalDay(day, today);
    });
  }

  int get completeDaysCount => _completeDaysSet().length;

  int get currentStreak {
    final completeDays = _completeDaysSet();
    if (completeDays.isEmpty) return 0;

    final today = _normalizeDay(DateTime.now());
    var cursor = today;
    var streak = 0;

    if (!completeDays.contains(today)) {
      cursor = today.subtract(const Duration(days: 1));
    }

    while (completeDays.contains(cursor)) {
      streak++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return streak;
  }

  int get bestStreak {
    final completeDays = _completeDaysSet().toList()..sort();
    if (completeDays.isEmpty) return 0;

    var best = 1;
    var current = 1;

    for (var index = 1; index < completeDays.length; index++) {
      final previous = completeDays[index - 1];
      final currentDay = completeDays[index];
      if (currentDay.difference(previous).inDays == 1) {
        current++;
      } else {
        best = current > best ? current : best;
        current = 1;
      }
    }

    return current > best ? current : best;
  }

  Achievement? get nextStreakAchievement {
    final streakAchievements = achievements
        .where((achievement) => achievement.category == AchievementCategory.streak)
        .toList();

    for (final achievement in streakAchievements) {
      if (!achievement.isUnlocked) return achievement;
    }

    return streakAchievements.isEmpty ? null : streakAchievements.last;
  }

  String get streakMotivation {
    final streak = currentStreak;
    if (streak == 0) {
      return 'Set your pace today. Complete both goals to start your streak.';
    }
    if (streak < 3) {
      return 'Great start. Keep completing both goals to build momentum.';
    }
    if (streak < 7) {
      return 'Consistency is forming. Protect your streak again today.';
    }
    if (streak < 14) {
      return 'Strong rhythm. Your daily discipline is paying off.';
    }
    return 'Excellent consistency. Keep both goals green and stay unstoppable.';
  }

  List<Achievement> get achievements {
    final sessionCount = totalSessions;
    final minutes = totalFocusMinutes;
    final streak = currentStreak;
    final perfectDays = completeDaysCount;
    final completedTasks = completedTasksAllTime;

    const sessionTargets = [1, 5, 10, 25, 50, 100, 200, 500];
    const minuteTargets = [60, 150, 300, 600, 1500, 3000, 6000];
    const streakTargets = [2, 5, 10, 20, 30, 50];
    const perfectDayTargets = [1, 3, 7, 14, 30, 60];
    const taskTargets = [10, 25, 50, 100, 200, 500];

    return [
      for (final target in sessionTargets)
        Achievement(
          title: target == 1 ? '1 session' : '$target sessions',
          category: AchievementCategory.sessions,
          target: target,
          current: sessionCount,
        ),
      for (final target in minuteTargets)
        Achievement(
          title: '$target focus minutes',
          category: AchievementCategory.focusMinutes,
          target: target,
          current: minutes,
        ),
      for (final target in streakTargets)
        Achievement(
          title: '$target-day streak',
          category: AchievementCategory.streak,
          target: target,
          current: streak,
        ),
      for (final target in perfectDayTargets)
        Achievement(
          title: '$target perfect days',
          category: AchievementCategory.perfectDays,
          target: target,
          current: perfectDays,
        ),
      for (final target in taskTargets)
        Achievement(
          title: '$target tasks done',
          category: AchievementCategory.tasksCompleted,
          target: target,
          current: completedTasks,
        ),
    ];
  }

  int get unlockedAchievementsCount =>
      achievements.where((achievement) => achievement.isUnlocked).length;

  int get totalAchievementsCount => achievements.length;

  GoalDayData _buildGoalDay(DateTime day, DateTime today) {
    final normalizedDay = _normalizeDay(day);
    return GoalDayData(
      date: normalizedDay,
      tasksCompleted: _tasksCompletedOn(normalizedDay),
      focusMinutes: _focusMinutesOn(normalizedDay),
      taskGoal: _taskGoal,
      focusGoal: _focusGoal,
      isToday: normalizedDay == today,
    );
  }

  Set<DateTime> _completeDaysSet() {
    final taskDays = <DateTime, int>{};
    final focusDays = <DateTime, int>{};

    final tasks = _taskProvider?.tasks ?? const <Task>[];
    for (final task in tasks) {
      final completedAt = task.completedAt;
      if (completedAt == null) continue;
      final day = _normalizeDay(completedAt);
      taskDays.update(day, (value) => value + 1, ifAbsent: () => 1);
    }

    final sessions = _focusProvider?.focusHistory ?? const <FocusSessionLog>[];
    for (final log in sessions) {
      final day = _normalizeDay(log.time);
      focusDays.update(day, (value) => value + log.durationMinutes,
          ifAbsent: () => log.durationMinutes);
    }

    final candidateDays = {...taskDays.keys, ...focusDays.keys};
    return candidateDays.where((day) {
      final tasksMet = (taskDays[day] ?? 0) >= _taskGoal;
      final focusMet = (focusDays[day] ?? 0) >= _focusGoal;
      return tasksMet && focusMet;
    }).toSet();
  }

  int _tasksCompletedOn(DateTime day) {
    final nextDay = day.add(const Duration(days: 1));
    final tasks = _taskProvider?.tasks ?? const <Task>[];
    return tasks
        .where(
          (task) => task.completedAt != null && _isInRange(task.completedAt!, day, nextDay),
        )
        .length;
  }

  int _focusMinutesOn(DateTime day) {
    final nextDay = day.add(const Duration(days: 1));
    final history = _focusProvider?.focusHistory ?? const <FocusSessionLog>[];
    return history
        .where((log) => _isInRange(log.time, day, nextDay))
        .fold(0, (sum, log) => sum + log.durationMinutes);
  }

  DateTime _normalizeDay(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool _isInRange(DateTime value, DateTime startInclusive, DateTime endExclusive) {
    return (value.isAtSameMomentAs(startInclusive) || value.isAfter(startInclusive)) &&
        value.isBefore(endExclusive);
  }

  void _onSourceUpdated() {
    notifyListeners();
  }

  @override
  void dispose() {
    _taskProvider?.removeListener(_onSourceUpdated);
    _focusProvider?.removeListener(_onSourceUpdated);
    super.dispose();
  }
}
