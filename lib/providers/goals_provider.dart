import 'dart:async';

import 'package:flutter/foundation.dart';

import '../services/user_settings_sync.dart';
import '../models/focus_session_model.dart';
import '../models/task_model.dart';
import '../utils/calendar_week_config.dart';
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
  bool get isCompleted => goal == 0 || current >= goal;
  double get progress =>
      goal == 0 ? 1 : (current / goal).clamp(0, 1).toDouble();
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
  double get progress =>
      target == 0 ? 0 : (current / target).clamp(0, 1).toDouble();
}

enum ManualRestResult {
  success,
  alreadyManualRest,
  scheduledRestDay,
  noCreditsRemaining,
  streakAlreadyMet,
}

class GoalDayData {
  final DateTime date;
  final int tasksCompleted;
  final int focusMinutes;
  final int taskGoal;
  final int focusGoal;
  final bool isToday;
  final bool isRestDay;
  final bool isScheduledRestDay;
  final bool isManualRestDay;

  const GoalDayData({
    required this.date,
    required this.tasksCompleted,
    required this.focusMinutes,
    required this.taskGoal,
    required this.focusGoal,
    required this.isToday,
    this.isRestDay = false,
    this.isScheduledRestDay = false,
    this.isManualRestDay = false,
  });

  bool get taskGoalMet => taskGoal == 0 || tasksCompleted >= taskGoal;
  bool get focusGoalMet => focusMinutes >= focusGoal;

  bool get isFuture {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isAfter(today);
  }

  /// Counts toward streak (today or past only). Freeze days never count.
  bool get isStreakDay {
    if (isFuture) return false;
    if (isRestDay) return false;
    return taskGoalMet && focusGoalMet;
  }

  /// Regular streak day — shows flame on calendar.
  bool get isComplete => isStreakDay && !isRestDay;

  bool get isPartial {
    if (isFuture || isRestDay || isStreakDay) return false;
    return taskGoalMet || focusGoalMet;
  }

  bool get isMissed {
    if (isFuture) return false;
    if (isRestDay) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return date.isBefore(today) && !isStreakDay;
  }
}

class GoalsProvider with ChangeNotifier {
  static const int defaultFocusGoalMinutes = 60;
  static const int manualRestCreditsPerMonth = 3;

  /// Dart [DateTime.weekday]: 1 = Mon … 7 = Sun. Empty = no weekly freeze day.
  static const Set<int> defaultRestWeekdays = <int>{};

  TaskProvider? _taskProvider;
  FocusProvider? _focusProvider;
  Timer? _sourceNotifyDebounce;
  final UserSettingsSync _settingsSync = UserSettingsSync();
  String? _uid;

  int _focusGoal = defaultFocusGoalMinutes;
  Set<int> _restWeekdays = Set<int>.from(defaultRestWeekdays);
  final Set<DateTime> _manualRestDays = {};

  int get focusGoal => _focusGoal;
  Set<int> get restWeekdays => Set<int>.unmodifiable(_restWeekdays);

  int get manualRestCreditsUsedThisMonth => _manualRestDaysUsedInMonth(
        DateTime.now(),
      );

  int get manualRestCreditsRemaining =>
      manualRestCreditsPerMonth - manualRestCreditsUsedThisMonth;

  void bindUser(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    if (uid == null) return;
    unawaited(_pullRemoteGoals());
  }

  Future<void> _pullRemoteGoals() async {
    final uid = _uid;
    if (uid == null) return;
    final remote = await _settingsSync.pull(uid);
    if (remote == null) {
      await _pushGoals();
      return;
    }
    final focusGoal = remote['focusGoal'];
    if (focusGoal is int) _focusGoal = focusGoal.clamp(15, 720);
    final weekdays = remote['restWeekdays'];
    if (weekdays is List) {
      _restWeekdays = weekdays.whereType<int>().where((d) => d >= 1 && d <= 7).toSet();
    }
    final manualDays = remote['manualRestDays'];
    if (manualDays is List) {
      _manualRestDays
        ..clear()
        ..addAll(
          manualDays
              .whereType<String>()
              .map(DateTime.tryParse)
              .whereType<DateTime>()
              .map(_normalizeDay),
        );
    }
    notifyListeners();
  }

  Future<void> _pushGoals() async {
    final uid = _uid;
    if (uid == null) return;
    await _settingsSync.merge(uid, {
      'focusGoal': _focusGoal,
      'restWeekdays': _restWeekdays.toList(),
      'manualRestDays':
          _manualRestDays.map((day) => day.toIso8601String()).toList(),
    });
  }

  void setFocusGoal(int focusGoal) {
    final nextFocusGoal = focusGoal.clamp(15, 720);
    if (_focusGoal == nextFocusGoal) return;
    _focusGoal = nextFocusGoal;
    notifyListeners();
    unawaited(_pushGoals());
  }

  void setRestWeekdays(Set<int> weekdays) {
    final next = weekdays.where((day) => day >= 1 && day <= 7).toSet();
    if (setEquals(_restWeekdays, next)) return;
    _restWeekdays = next;
    notifyListeners();
    unawaited(_pushGoals());
  }

  bool isScheduledRestDay(DateTime day) =>
      _restWeekdays.contains(_normalizeDay(day).weekday);

  bool isManualRestDay(DateTime day) =>
      _manualRestDays.contains(_normalizeDay(day));

  bool isRestDay(DateTime day) =>
      isScheduledRestDay(day) || isManualRestDay(day);

  bool get isTodayRestDay => isRestDay(DateTime.now());

  bool get isTodayScheduledRestDay => isScheduledRestDay(DateTime.now());

  bool get isTodayManualRestDay => isManualRestDay(DateTime.now());

  bool get canUseManualRestCreditToday {
    final today = _normalizeDay(DateTime.now());
    if (isScheduledRestDay(today)) return false;
    if (isManualRestDay(today)) return false;
    if (_isNaturalStreakValid(today)) return false;
    return manualRestCreditsRemaining > 0;
  }

  bool get shouldShowFreezeDaySection {
    final today = _normalizeDay(DateTime.now());
    return !isTodayRestDay && !_isNaturalStreakValid(today);
  }

  ManualRestResult markTodayAsManualRest() {
    final today = _normalizeDay(DateTime.now());
    if (isScheduledRestDay(today)) {
      return ManualRestResult.scheduledRestDay;
    }
    if (isManualRestDay(today)) {
      return ManualRestResult.alreadyManualRest;
    }
    if (_isNaturalStreakValid(today)) {
      return ManualRestResult.streakAlreadyMet;
    }
    if (manualRestCreditsRemaining <= 0) {
      return ManualRestResult.noCreditsRemaining;
    }
    _manualRestDays.add(today);
    notifyListeners();
    unawaited(_pushGoals());
    return ManualRestResult.success;
  }

  int _manualRestDaysUsedInMonth(DateTime monthAnchor) {
    return _manualRestDays
        .where(
          (day) =>
              day.year == monthAnchor.year && day.month == monthAnchor.month,
        )
        .length;
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
    final today = _normalizeDay(DateTime.now());
    return DailyGoalData(
      current: _tasksCompletedDueOn(today),
      goal: _taskGoalFor(today),
      unit: 'tasks',
    );
  }

  int taskGoalFor(DateTime day) => _taskGoalFor(_normalizeDay(day));

  int get tasksCompletedToday {
    return _tasksCompletedDueOn(_normalizeDay(DateTime.now()));
  }

  int get focusMinutesToday {
    return _focusMinutesOn(_normalizeDay(DateTime.now()));
  }

  bool get taskGoalMetToday {
    final today = _normalizeDay(DateTime.now());
    return _isTaskGoalMet(today, _tasksCompletedDueOn(today));
  }

  bool get focusGoalMetToday => focusMinutesToday >= _focusGoal;

  bool get isTodayComplete =>
      _isDayStreakValid(_normalizeDay(DateTime.now())) || isTodayRestDay;

  int get totalSessions => _focusProvider?.completedSessionsCount ?? 0;
  int get totalFocusMinutes => _focusProvider?.totalFocusMinutes ?? 0;
  int get completedTasksAllTime =>
      (_taskProvider?.tasks ?? const <Task>[])
          .where((task) => task.isCompleted)
          .length;

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
    final weekStart = CalendarWeekConfig.weekStartFor(anchorDay);

    return List.generate(7, (index) {
      final day = weekStart.add(Duration(days: index));
      return _buildGoalDay(day, today);
    });
  }

  List<GoalDayData> goalMonthDaysFor(DateTime anchorMonth) {
    final now = DateTime.now();
    final today = _normalizeDay(now);
    final firstDay = DateTime(anchorMonth.year, anchorMonth.month, 1);
    final startDate = firstDay.subtract(
      Duration(days: CalendarWeekConfig.leadingDaysBeforeMonth(firstDay)),
    );

    return List.generate(42, (index) {
      final day = startDate.add(Duration(days: index));
      return _buildGoalDay(day, today);
    });
  }

  /// Goal snapshots for each day in [startInclusive, endExclusive), excluding future days.
  List<GoalDayData> goalDaysInStatisticsRange(
    DateTime startInclusive,
    DateTime endExclusive,
  ) {
    final today = _normalizeDay(DateTime.now());
    final days = <GoalDayData>[];
    var cursor = _normalizeDay(startInclusive);
    final lastDay = _normalizeDay(endExclusive.subtract(const Duration(days: 1)));

    while (!cursor.isAfter(lastDay)) {
      if (!cursor.isAfter(today)) {
        days.add(_buildGoalDay(cursor, today));
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    return days;
  }

  int get completeDaysCount => _completeDaysSet().length;

  int get currentStreak {
    final today = _normalizeDay(DateTime.now());
    var cursor = today;
    var streak = 0;

    if (!_countsTowardStreak(cursor) && !_isStreakBridgeDay(cursor)) {
      cursor = today.subtract(const Duration(days: 1));
    }

    while (true) {
      if (_countsTowardStreak(cursor)) {
        streak++;
        cursor = cursor.subtract(const Duration(days: 1));
      } else if (_isStreakBridgeDay(cursor)) {
        cursor = cursor.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    return streak;
  }

  int get bestStreak {
    final bounds = _activityDateBounds();
    if (bounds.$1 == null) return 0;

    var cursor = bounds.$1!;
    final latest = bounds.$2;
    var best = 0;
    var current = 0;

    while (!cursor.isAfter(latest)) {
      if (_countsTowardStreak(cursor)) {
        current++;
        if (current > best) best = current;
      } else if (_isStreakBridgeDay(cursor)) {
        // Preserve the run without adding a day.
      } else {
        current = 0;
      }
      cursor = cursor.add(const Duration(days: 1));
    }

    return best;
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

  String get streakHeroTitle {
    final streak = currentStreak;
    if (isTodayRestDay) return 'Freeze day activated';
    if (streak == 0) return 'Light your first flame';
    return 'You are on a roll!';
  }

  String get streakHeroSubtitle {
    final streak = currentStreak;
    final todayTaskGoal = taskDailyGoal.goal;

    if (isTodayRestDay) {
      if (streak == 0) {
        return 'Everyone needs a reset sometimes. Recharge today — your comeback starts tomorrow.';
      }
      return 'Your $streak-day streak won\'t break, but today won\'t '
          'increase your streak number.';
    }
    if (todayTaskGoal == 0) {
      return streak == 0
          ? 'No tasks planned — focus goal only.'
          : 'No tasks planned — focus goal only to keep your streak.';
    }
    if (streak == 0) {
      return 'Complete today\'s tasks and your focus goal.';
    }
    return '$streak-day streak. Keep today\'s tasks and focus goal on track.';
  }

  String get streakMotivation => streakHeroSubtitle;

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
    final tasksCompleted = _tasksCompletedDueOn(normalizedDay);
    final taskGoal = _taskGoalFor(normalizedDay);
    final scheduled = isScheduledRestDay(normalizedDay);
    final manual = isManualRestDay(normalizedDay);
    return GoalDayData(
      date: normalizedDay,
      tasksCompleted: tasksCompleted,
      focusMinutes: _focusMinutesOn(normalizedDay),
      taskGoal: taskGoal,
      focusGoal: _focusGoal,
      isToday: normalizedDay == today,
      isScheduledRestDay: scheduled,
      isManualRestDay: manual,
      isRestDay: scheduled || manual,
    );
  }

  Set<DateTime> _completeDaysSet() {
    final bounds = _activityDateBounds();
    final candidateDays = <DateTime>{};

    if (bounds.$1 != null) {
      var cursor = bounds.$1!;
      final latest = bounds.$2;
      while (!cursor.isAfter(latest)) {
        candidateDays.add(cursor);
        cursor = cursor.add(const Duration(days: 1));
      }
    }

    return candidateDays.where(_isDayStreakValidFromMaps).toSet();
  }

  (DateTime?, DateTime) _activityDateBounds() {
    final today = _normalizeDay(DateTime.now());
    DateTime? earliest;

    void consider(DateTime day) {
      final normalized = _normalizeDay(day);
      if (earliest == null || normalized.isBefore(earliest!)) {
        earliest = normalized;
      }
    }

    final tasks = _taskProvider?.tasks ?? const <Task>[];
    for (final task in tasks) {
      if (task.dueDate != null) consider(task.dueDate!);
      if (task.completedAt != null) consider(task.completedAt!);
    }

    final sessions = _focusProvider?.focusHistory ?? const <FocusSessionLog>[];
    for (final log in sessions) {
      consider(log.time);
    }

    for (final manualRestDay in _manualRestDays) {
      consider(manualRestDay);
    }

    consider(today);

    return (earliest, today);
  }

  bool _countsTowardStreak(DateTime day) => _isDayStreakValidFromMaps(day);

  bool _isStreakBridgeDay(DateTime day) {
    final normalizedDay = _normalizeDay(day);
    final today = _normalizeDay(DateTime.now());
    if (normalizedDay.isAfter(today)) return false;
    return isRestDay(normalizedDay);
  }

  bool _isDayStreakValidFromMaps(DateTime day) {
    final normalizedDay = _normalizeDay(day);
    final today = _normalizeDay(DateTime.now());
    if (normalizedDay.isAfter(today)) return false;
    if (isRestDay(normalizedDay)) return false;

    final taskGoal = _taskGoalFor(normalizedDay);
    final tasksCompleted = _tasksCompletedDueOn(normalizedDay);
    final focusMinutes = _focusMinutesOn(normalizedDay);
    final taskMet =
        _isTaskGoalMet(normalizedDay, tasksCompleted, taskGoal: taskGoal);

    return taskMet && _focusGoalMet(focusMinutes);
  }

  bool _isNaturalStreakValid(DateTime day) {
    final normalizedDay = _normalizeDay(day);
    if (isRestDay(normalizedDay)) return false;

    final taskGoal = _taskGoalFor(normalizedDay);
    final tasksCompleted = _tasksCompletedDueOn(normalizedDay);
    final focusMinutes = _focusMinutesOn(normalizedDay);
    final taskMet =
        _isTaskGoalMet(normalizedDay, tasksCompleted, taskGoal: taskGoal);

    return taskMet && _focusGoalMet(focusMinutes);
  }

  bool _isDayStreakValid(DateTime day) =>
      _isDayStreakValidFromMaps(_normalizeDay(day));

  bool _isTaskGoalMet(
    DateTime day,
    int tasksCompleted, {
    int? taskGoal,
  }) {
    final goal = taskGoal ?? _taskGoalFor(day);
    return goal == 0 || tasksCompleted >= goal;
  }

  bool _focusGoalMet(int focusMinutes) => focusMinutes >= _focusGoal;

  int _taskGoalFor(DateTime day) {
    return _taskProvider?.totalTasksDueOn(day) ?? 0;
  }

  int _tasksCompletedDueOn(DateTime day) {
    final tasks = _taskProvider?.tasks ?? const <Task>[];
    return tasks.where((task) {
      if (task.dueDate == null || task.completedAt == null) return false;
      final dueDay = _normalizeDay(task.dueDate!);
      final completedDay = _normalizeDay(task.completedAt!);
      return dueDay == day && completedDay == day;
    }).length;
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

  bool _isInRange(
    DateTime value,
    DateTime startInclusive,
    DateTime endExclusive,
  ) {
    return (value.isAtSameMomentAs(startInclusive) ||
            value.isAfter(startInclusive)) &&
        value.isBefore(endExclusive);
  }

  void _onSourceUpdated() {
    _sourceNotifyDebounce?.cancel();
    _sourceNotifyDebounce = Timer(const Duration(milliseconds: 250), () {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sourceNotifyDebounce?.cancel();
    _taskProvider?.removeListener(_onSourceUpdated);
    _focusProvider?.removeListener(_onSourceUpdated);
    super.dispose();
  }
}
