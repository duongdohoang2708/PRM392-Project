import 'dart:async';

import 'package:flutter/material.dart';

import '../models/task_model.dart';
import '../utils/formatters/app_date_time_format.dart';
import 'focus_provider.dart';
import 'goals_provider.dart';
import 'task_provider.dart';

enum StatisticsTab { focus, task }
enum StatisticsRange { today, week, month }

class StatisticsBarPoint {
  final String label;
  final String? subLabel;
  final int value;
  final bool isHighlighted;

  const StatisticsBarPoint({
    required this.label,
    this.subLabel,
    required this.value,
    this.isHighlighted = false,
  });
}

class TaskDueSummaryData {
  final int dueCount;
  final int completedCount;
  final int pendingCount;
  final int onTimeCount;
  final int lateCount;
  final int missedCount;
  final int onTimeRate;
  final int dueCompletionRate;

  const TaskDueSummaryData({
    this.dueCount = 0,
    this.completedCount = 0,
    this.pendingCount = 0,
    this.onTimeCount = 0,
    this.lateCount = 0,
    this.missedCount = 0,
    this.onTimeRate = 0,
    this.dueCompletionRate = 0,
  });
}

class TaskStatisticsData {
  final int total;
  final int completed;
  final int pending;
  final int overdue;
  final int completionRate;
  final Map<String, int> priorityBreakdown;
  final List<StatisticsBarPoint> completionBars;
  final TaskDueSummaryData dueSummary;

  const TaskStatisticsData({
    required this.total,
    required this.completed,
    required this.pending,
    required this.overdue,
    required this.completionRate,
    required this.priorityBreakdown,
    required this.completionBars,
    this.dueSummary = const TaskDueSummaryData(),
  });
}

class FocusGoalPeriodData {
  final int focusGoalMinutes;
  final int daysMet;
  final int eligibleDays;
  final int restDays;
  final int periodMinutes;
  final bool isSingleDay;
  final bool isRestDay;

  const FocusGoalPeriodData({
    this.focusGoalMinutes = 0,
    this.daysMet = 0,
    this.eligibleDays = 0,
    this.restDays = 0,
    this.periodMinutes = 0,
    this.isSingleDay = false,
    this.isRestDay = false,
  });

  double get progress => isSingleDay
      ? (focusGoalMinutes == 0
          ? 1
          : (periodMinutes / focusGoalMinutes).clamp(0, 1).toDouble())
      : (eligibleDays == 0 ? 0 : (daysMet / eligibleDays).clamp(0, 1).toDouble());
}

class FocusStatisticsData {
  final int totalMinutes;
  final int sessions;
  final int averageMinutes;
  final int longestMinutes;
  final List<StatisticsBarPoint> minutesBars;
  final FocusGoalPeriodData goalProgress;

  const FocusStatisticsData({
    required this.totalMinutes,
    required this.sessions,
    required this.averageMinutes,
    required this.longestMinutes,
    required this.minutesBars,
    this.goalProgress = const FocusGoalPeriodData(),
  });
}

class StatisticsProvider with ChangeNotifier {
  TaskProvider? _taskProvider;
  FocusProvider? _focusProvider;
  GoalsProvider? _goalsProvider;
  Timer? _sourceNotifyDebounce;

  StatisticsRange _activeRange = StatisticsRange.week;
  StatisticsTab _activeTab = StatisticsTab.focus;
  late DateTime _anchorDate;

  StatisticsProvider() {
    _anchorDate = _todayDate();
  }

  StatisticsRange get activeRange => _activeRange;
  StatisticsTab get activeTab => _activeTab;
  DateTime get anchorDate => _anchorDate;

  /// Stable key for resetting chart scroll when the viewed period changes.
  String get chartPeriodKey =>
      '${_activeRange.name}_${_anchorDate.year}_${_anchorDate.month}_${_anchorDate.day}';

  /// Label suffix for chart titles, e.g. "Focus Minutes by Hour".
  String get chartGranularityLabel {
    switch (_activeRange) {
      case StatisticsRange.today:
        return 'Hour';
      case StatisticsRange.week:
      case StatisticsRange.month:
        return 'Day';
    }
  }

  String get periodLabel {
    switch (_activeRange) {
      case StatisticsRange.today:
        return AppDateTimeFormat.weekdayMonthDay(_anchorDate);
      case StatisticsRange.week:
        final monday = _mondayOfWeek(_anchorDate);
        final sunday = monday.add(const Duration(days: 6));
        return '${AppDateTimeFormat.shortDate(monday)} – ${AppDateTimeFormat.shortDate(sunday)}';
      case StatisticsRange.month:
        return AppDateTimeFormat.monthYear(_anchorDate);
    }
  }

  bool get canShiftForward {
    final today = _todayDate();
    switch (_activeRange) {
      case StatisticsRange.today:
        return _anchorDate.isBefore(today);
      case StatisticsRange.week:
        return _mondayOfWeek(_anchorDate).isBefore(_mondayOfWeek(today));
      case StatisticsRange.month:
        final anchorMonth = DateTime(_anchorDate.year, _anchorDate.month, 1);
        final currentMonth = DateTime(today.year, today.month, 1);
        return anchorMonth.isBefore(currentMonth);
    }
  }

  void updateSources(
    TaskProvider taskProvider,
    FocusProvider focusProvider,
    GoalsProvider goalsProvider,
  ) {
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

    if (_goalsProvider != goalsProvider) {
      _goalsProvider?.removeListener(_onSourceUpdated);
      _goalsProvider = goalsProvider;
      _goalsProvider?.addListener(_onSourceUpdated);
      didUpdateSource = true;
    }

    if (didUpdateSource) {
      notifyListeners();
    }
  }

  void setActiveRange(StatisticsRange range) {
    if (_activeRange == range) return;
    _activeRange = range;
    notifyListeners();
  }

  void setActiveTab(StatisticsTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    notifyListeners();
  }

  void setAnchorDate(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    if (_isSameDay(_anchorDate, normalized)) return;
    _anchorDate = normalized;
    notifyListeners();
  }

  void shiftPeriod(int direction) {
    if (direction > 0 && !canShiftForward) return;
    if (direction == 0) return;

    switch (_activeRange) {
      case StatisticsRange.today:
        setAnchorDate(_anchorDate.add(Duration(days: direction)));
      case StatisticsRange.week:
        setAnchorDate(_anchorDate.add(Duration(days: 7 * direction)));
      case StatisticsRange.month:
        final shifted = DateTime(
          _anchorDate.year,
          _anchorDate.month + direction,
          1,
        );
        setAnchorDate(shifted);
    }
  }

  void resetToCurrentPeriod() {
    setAnchorDate(_todayDate());
  }

  // ----- Range dependent analytics (overview + charts) -----

  TaskStatisticsData get taskStats {
    final taskProvider = _taskProvider;
    if (taskProvider == null) {
      return const TaskStatisticsData(
        total: 0,
        completed: 0,
        pending: 0,
        overdue: 0,
        completionRate: 0,
        priorityBreakdown: {'High': 0, 'Medium': 0, 'Low': 0},
        completionBars: [],
      );
    }

    final bounds = _currentRangeBounds();
    final start = bounds.$1;
    final end = bounds.$2;

    final cohortTasks = taskProvider.tasks
        .where((task) => _isTaskRelevantInRange(task, start, end))
        .toList();

    final completedInRange = cohortTasks
        .where(
          (task) =>
              task.completedAt != null &&
              _isInRange(task.completedAt!, start, end),
        )
        .toList();

    final pendingCount =
        cohortTasks.where((task) => !task.isCompleted).length;

    final overdueCount = _countOverdueTasks(taskProvider.tasks, start);

    final denominator = cohortTasks.isEmpty ? 1 : cohortTasks.length;
    final completionRate = ((completedInRange.length / denominator) * 100)
        .clamp(0, 100)
        .round();

    final priorityBreakdown = <String, int>{
      'High': cohortTasks.where((task) => task.priority == 'High').length,
      'Medium': cohortTasks.where((task) => task.priority == 'Medium').length,
      'Low': cohortTasks.where((task) => task.priority == 'Low').length,
    };

    return TaskStatisticsData(
      total: cohortTasks.length,
      completed: completedInRange.length,
      pending: pendingCount,
      overdue: overdueCount,
      completionRate: completionRate,
      priorityBreakdown: priorityBreakdown,
      completionBars: _buildTaskCompletionBars(completedInRange),
      dueSummary: _computeTaskDueSummary(start, end),
    );
  }

  FocusStatisticsData get focusStats {
    final focusProvider = _focusProvider;
    if (focusProvider == null) {
      return const FocusStatisticsData(
        totalMinutes: 0,
        sessions: 0,
        averageMinutes: 0,
        longestMinutes: 0,
        minutesBars: [],
      );
    }

    final bounds = _currentRangeBounds();
    final logsInRange = focusProvider.focusHistory
        .where((log) => _isInRange(log.time, bounds.$1, bounds.$2))
        .toList();

    final totalMinutes = logsInRange.fold(
      0,
      (sum, log) => sum + log.durationMinutes,
    );
    final sessions = logsInRange.length;
    final averageMinutes =
        sessions == 0 ? 0 : (totalMinutes / sessions).round();
    final longestMinutes = sessions == 0
        ? 0
        : logsInRange
            .map((log) => log.durationMinutes)
            .reduce((a, b) => a > b ? a : b);

    return FocusStatisticsData(
      totalMinutes: totalMinutes,
      sessions: sessions,
      averageMinutes: averageMinutes,
      longestMinutes: longestMinutes,
      minutesBars: _buildFocusBars(logsInRange),
      goalProgress: _computeFocusGoalPeriod(bounds.$1, bounds.$2),
    );
  }

  // ----- Range filtered session helpers (overview cluster) -----

  int get totalSessionsInRange => focusStats.sessions;
  int get averageSessionMinutesInRange => focusStats.averageMinutes;

  List<FocusSessionLog> recentSessionsInRange({int limit = 5}) {
    final bounds = _currentRangeBounds();
    final history = _focusProvider?.focusHistory ?? const <FocusSessionLog>[];
    return history
        .where((log) => _isInRange(log.time, bounds.$1, bounds.$2))
        .take(limit)
        .toList();
  }

  // ----- Range independent data (focus history screen) -----

  int get totalSessions => _focusProvider?.completedSessionsCount ?? 0;
  int get totalFocusMinutesAllTime => _focusProvider?.totalFocusMinutes ?? 0;
  int get averageSessionMinutes => _focusProvider?.averageSessionMinutes ?? 0;
  int get longestSessionMinutes {
    final history = _focusProvider?.focusHistory ?? const <FocusSessionLog>[];
    if (history.isEmpty) return 0;
    return history
        .map((session) => session.durationMinutes)
        .reduce((a, b) => a > b ? a : b);
  }

  List<FocusSessionLog> get allSessions =>
      List<FocusSessionLog>.from(_focusProvider?.focusHistory ?? const []);

  List<FocusSessionLog> recentSessions({int limit = 5}) {
    final history = _focusProvider?.focusHistory ?? const <FocusSessionLog>[];
    return history.take(limit).toList();
  }

  // ----- Internal helpers -----

  DateTime _todayDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  DateTime _mondayOfWeek(DateTime date) {
    final normalized = DateTime(date.year, date.month, date.day);
    return normalized.subtract(Duration(days: normalized.weekday - 1));
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _isAnchorToday() => _isSameDay(_anchorDate, _todayDate());

  bool _shouldHighlightDay(DateTime day) {
    final today = _todayDate();
    if (!_isSameDay(day, today)) return false;
    final bounds = _currentRangeBounds();
    return _isInRange(today, bounds.$1, bounds.$2);
  }

  DateTime _overdueReferenceDate() {
    final today = _todayDate();
    final bounds = _currentRangeBounds();
    final periodEnd = bounds.$2.subtract(const Duration(days: 1));
    final periodEndDay =
        DateTime(periodEnd.year, periodEnd.month, periodEnd.day);
    if (periodEndDay.isAfter(today)) return today;
    return periodEndDay;
  }

  DateTime _normalizeDay(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  FocusGoalPeriodData _computeFocusGoalPeriod(
    DateTime start,
    DateTime end,
  ) {
    final goals = _goalsProvider;
    if (goals == null) return const FocusGoalPeriodData();

    final days = goals.goalDaysInStatisticsRange(start, end);
    if (days.isEmpty) return const FocusGoalPeriodData();

    final isSingleDay = _activeRange == StatisticsRange.today;
    final eligibleDays = days.length;
    final restDays = days.where((day) => day.isRestDay).length;
    final daysMet = days
        .where((day) => day.focusGoalMet || day.isRestDay)
        .length;

    if (isSingleDay) {
      final day = days.first;
      return FocusGoalPeriodData(
        focusGoalMinutes: day.focusGoal,
        daysMet: day.focusGoalMet || day.isRestDay ? 1 : 0,
        eligibleDays: 1,
        restDays: day.isRestDay ? 1 : 0,
        periodMinutes: day.focusMinutes,
        isSingleDay: true,
        isRestDay: day.isRestDay,
      );
    }

    return FocusGoalPeriodData(
      focusGoalMinutes: days.first.focusGoal,
      daysMet: daysMet,
      eligibleDays: eligibleDays,
      restDays: restDays,
      periodMinutes: days.fold(0, (sum, day) => sum + day.focusMinutes),
      isSingleDay: false,
      isRestDay: false,
    );
  }

  TaskDueSummaryData _computeTaskDueSummary(
    DateTime start,
    DateTime end,
  ) {
    final tasks = _taskProvider?.tasks ?? const <Task>[];
    final today = _todayDate();

    final dueTasks = tasks
        .where(
          (task) =>
              task.dueDate != null && _isDueDayInRange(task.dueDate!, start, end),
        )
        .toList();

    final dueCount = dueTasks.length;
    final completedDue =
        dueTasks.where((task) => task.isCompleted).toList();
    final completedCount = completedDue.length;
    final pendingCount = dueTasks.where((task) => !task.isCompleted).length;

    var onTimeCount = 0;
    var lateCount = 0;
    for (final task in completedDue) {
      if (_isCompletedOnTime(task)) {
        onTimeCount++;
      } else {
        lateCount++;
      }
    }

    final missedCount = dueTasks.where((task) {
      if (task.isCompleted || task.dueDate == null) return false;
      return _normalizeDay(task.dueDate!).isBefore(today);
    }).length;

    final finishedCount = onTimeCount + lateCount;
    final onTimeRate = finishedCount == 0
        ? 0
        : ((onTimeCount / finishedCount) * 100).round().clamp(0, 100);
    final dueCompletionRate = dueCount == 0
        ? 0
        : ((completedCount / dueCount) * 100).round().clamp(0, 100);

    return TaskDueSummaryData(
      dueCount: dueCount,
      completedCount: completedCount,
      pendingCount: pendingCount,
      onTimeCount: onTimeCount,
      lateCount: lateCount,
      missedCount: missedCount,
      onTimeRate: onTimeRate,
      dueCompletionRate: dueCompletionRate,
    );
  }

  bool _isDueDayInRange(
    DateTime dueDate,
    DateTime startInclusive,
    DateTime endExclusive,
  ) {
    final dueDay = _normalizeDay(dueDate);
    return (dueDay.isAtSameMomentAs(startInclusive) ||
            dueDay.isAfter(startInclusive)) &&
        dueDay.isBefore(endExclusive);
  }

  bool _isCompletedOnTime(Task task) {
    if (!task.isCompleted || task.dueDate == null || task.completedAt == null) {
      return false;
    }

    final due = task.dueDate!;
    final completed = task.completedAt!;

    if (task.isAllDay) {
      final dueDay = _normalizeDay(due);
      final completedDay = _normalizeDay(completed);
      return !completedDay.isAfter(dueDay);
    }

    return completed.isBefore(due) || completed.isAtSameMomentAs(due);
  }

  bool _isTaskRelevantInRange(
    Task task,
    DateTime startInclusive,
    DateTime endExclusive,
  ) {
    if (_isInRange(task.createdAt, startInclusive, endExclusive)) {
      return true;
    }
    if (task.completedAt != null &&
        _isInRange(task.completedAt!, startInclusive, endExclusive)) {
      return true;
    }
    if (task.dueDate != null &&
        _isInRange(task.dueDate!, startInclusive, endExclusive)) {
      return true;
    }
    return false;
  }

  int _countOverdueTasks(List<Task> tasks, DateTime rangeStart) {
    final referenceDay = _overdueReferenceDate();
    final referenceExclusive = referenceDay.add(const Duration(days: 1));

    return tasks.where((task) {
      if (task.isCompleted || task.dueDate == null) return false;
      if (!task.dueDate!.isBefore(referenceExclusive)) return false;

      switch (_activeRange) {
        case StatisticsRange.today:
          return true;
        case StatisticsRange.week:
        case StatisticsRange.month:
          return !task.dueDate!.isBefore(rangeStart);
      }
    }).length;
  }

  List<StatisticsBarPoint> _buildTaskCompletionBars(List<Task> completedTasks) {
    if (_activeRange == StatisticsRange.today) {
      return _buildHourlyTaskCompletionBars(completedTasks);
    }
    return _buildDailyTaskCompletionBars(completedTasks);
  }

  List<StatisticsBarPoint> _buildFocusBars(List<FocusSessionLog> logs) {
    if (_activeRange == StatisticsRange.today) {
      return _buildHourlyFocusBars(logs);
    }
    return _buildDailyFocusBars(logs);
  }

  List<StatisticsBarPoint> _buildDailyTaskCompletionBars(
      List<Task> completedTasks) {
    final labels = _buildRangeDays();
    final counts = <DateTime, int>{};

    for (final task in completedTasks) {
      final completedAt = task.completedAt;
      if (completedAt == null) continue;

      final day =
          DateTime(completedAt.year, completedAt.month, completedAt.day);
      counts.update(day, (value) => value + 1, ifAbsent: () => 1);
    }

    return List.generate(labels.length, (index) {
      final day = labels[index];
      final dayCount = counts[day] ?? 0;
      return StatisticsBarPoint(
        label: _formatBarLabel(day),
        value: dayCount,
        isHighlighted: _shouldHighlightDay(day),
      );
    });
  }

  List<StatisticsBarPoint> _buildDailyFocusBars(List<FocusSessionLog> logs) {
    final labels = _buildRangeDays();
    final minutesByDay = <DateTime, int>{};

    for (final log in logs) {
      final day = DateTime(log.time.year, log.time.month, log.time.day);
      minutesByDay.update(day, (value) => value + log.durationMinutes,
          ifAbsent: () => log.durationMinutes);
    }

    return List.generate(labels.length, (index) {
      final day = labels[index];
      final minutes = minutesByDay[day] ?? 0;
      return StatisticsBarPoint(
        label: _formatBarLabel(day),
        value: minutes,
        isHighlighted: _shouldHighlightDay(day),
      );
    });
  }

  List<StatisticsBarPoint> _buildHourlyTaskCompletionBars(
      List<Task> completedTasks) {
    final currentHour = DateTime.now().hour;
    final counts = List<int>.filled(24, 0);

    for (final task in completedTasks) {
      final completedAt = task.completedAt;
      if (completedAt == null) continue;
      counts[completedAt.hour]++;
    }

    return List.generate(24, (hour) {
      return StatisticsBarPoint(
        label: AppDateTimeFormat.chartHourNumber(hour),
        subLabel: AppDateTimeFormat.chartHourPeriod(hour),
        value: counts[hour],
        isHighlighted: _isAnchorToday() && hour == currentHour,
      );
    });
  }

  List<StatisticsBarPoint> _buildHourlyFocusBars(List<FocusSessionLog> logs) {
    final currentHour = DateTime.now().hour;
    final minutesByHour = List<int>.filled(24, 0);

    for (final log in logs) {
      minutesByHour[log.time.hour] += log.durationMinutes;
    }

    return List.generate(24, (hour) {
      return StatisticsBarPoint(
        label: AppDateTimeFormat.chartHourNumber(hour),
        subLabel: AppDateTimeFormat.chartHourPeriod(hour),
        value: minutesByHour[hour],
        isHighlighted: _isAnchorToday() && hour == currentHour,
      );
    });
  }

  List<DateTime> _buildRangeDays() {
    switch (_activeRange) {
      case StatisticsRange.today:
        return [
          DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day),
        ];
      case StatisticsRange.week:
        final monday = _mondayOfWeek(_anchorDate);
        return List.generate(
          7,
          (index) => monday.add(Duration(days: index)),
        );
      case StatisticsRange.month:
        final first = DateTime(_anchorDate.year, _anchorDate.month, 1);
        final lastDay =
            DateTime(_anchorDate.year, _anchorDate.month + 1, 0).day;
        return List.generate(
          lastDay,
          (index) => first.add(Duration(days: index)),
        );
    }
  }

  String _formatBarLabel(DateTime day) {
    switch (_activeRange) {
      case StatisticsRange.today:
        return AppDateTimeFormat.shortDate(day);
      case StatisticsRange.week:
        const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
        return weekdays[day.weekday - 1];
      case StatisticsRange.month:
        return day.day.toString();
    }
  }

  bool _isInRange(
      DateTime value, DateTime startInclusive, DateTime endExclusive) {
    return (value.isAtSameMomentAs(startInclusive) ||
            value.isAfter(startInclusive)) &&
        value.isBefore(endExclusive);
  }

  (DateTime, DateTime) _currentRangeBounds() {
    final anchor =
        DateTime(_anchorDate.year, _anchorDate.month, _anchorDate.day);

    switch (_activeRange) {
      case StatisticsRange.today:
        return (anchor, anchor.add(const Duration(days: 1)));
      case StatisticsRange.week:
        final monday = _mondayOfWeek(anchor);
        return (monday, monday.add(const Duration(days: 7)));
      case StatisticsRange.month:
        final first = DateTime(anchor.year, anchor.month, 1);
        final next = DateTime(anchor.year, anchor.month + 1, 1);
        return (first, next);
    }
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
    _goalsProvider?.removeListener(_onSourceUpdated);
    super.dispose();
  }
}
