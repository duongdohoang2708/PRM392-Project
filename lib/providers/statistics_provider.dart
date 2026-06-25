import 'package:flutter/material.dart';

import '../models/task_model.dart';
import 'focus_provider.dart';
import 'task_provider.dart';

enum StatisticsTab { focus, task }
enum StatisticsRange { today, week, month }

class StatisticsBarPoint {
  final String label;
  final int value;
  final bool isHighlighted;

  const StatisticsBarPoint({
    required this.label,
    required this.value,
    this.isHighlighted = false,
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

  const TaskStatisticsData({
    required this.total,
    required this.completed,
    required this.pending,
    required this.overdue,
    required this.completionRate,
    required this.priorityBreakdown,
    required this.completionBars,
  });
}

class FocusStatisticsData {
  final int totalMinutes;
  final int sessions;
  final int averageMinutes;
  final List<StatisticsBarPoint> minutesBars;

  const FocusStatisticsData({
    required this.totalMinutes,
    required this.sessions,
    required this.averageMinutes,
    required this.minutesBars,
  });
}

class StatisticsProvider with ChangeNotifier {
  TaskProvider? _taskProvider;
  FocusProvider? _focusProvider;

  StatisticsRange _activeRange = StatisticsRange.week;
  StatisticsTab _activeTab = StatisticsTab.focus;

  StatisticsRange get activeRange => _activeRange;
  StatisticsTab get activeTab => _activeTab;

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
    final inRangeTasks = taskProvider.tasks
        .where((task) => _isInRange(task.createdAt, bounds.$1, bounds.$2))
        .toList();

    final completedInRange = taskProvider.tasks
        .where(
          (task) =>
              task.completedAt != null &&
              _isInRange(task.completedAt!, bounds.$1, bounds.$2),
        )
        .toList();

    final pendingCount = inRangeTasks.where((task) => !task.isCompleted).length;

    final now = DateTime.now();
    final startOfToday = DateTime(now.year, now.month, now.day);
    final overdueCount = taskProvider.tasks.where((task) {
      if (task.dueDate == null || task.isCompleted) return false;
      return task.dueDate!.isBefore(startOfToday) &&
          _isInRange(task.dueDate!, bounds.$1, bounds.$2);
    }).length;

    final denominator = inRangeTasks.isEmpty ? 1 : inRangeTasks.length;
    final completionRate = ((completedInRange.length / denominator) * 100)
        .clamp(0, 100)
        .round();

    final prioritySource = inRangeTasks.isEmpty ? taskProvider.tasks : inRangeTasks;
    final priorityBreakdown = <String, int>{
      'High': prioritySource.where((task) => task.priority == 'High').length,
      'Medium': prioritySource.where((task) => task.priority == 'Medium').length,
      'Low': prioritySource.where((task) => task.priority == 'Low').length,
    };

    return TaskStatisticsData(
      total: inRangeTasks.length,
      completed: completedInRange.length,
      pending: pendingCount,
      overdue: overdueCount,
      completionRate: completionRate,
      priorityBreakdown: priorityBreakdown,
      completionBars: _buildDailyTaskCompletionBars(completedInRange),
    );
  }

  FocusStatisticsData get focusStats {
    final focusProvider = _focusProvider;
    if (focusProvider == null) {
      return const FocusStatisticsData(
        totalMinutes: 0,
        sessions: 0,
        averageMinutes: 0,
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
    final averageMinutes = sessions == 0 ? 0 : (totalMinutes / sessions).round();

    return FocusStatisticsData(
      totalMinutes: totalMinutes,
      sessions: sessions,
      averageMinutes: averageMinutes,
      minutesBars: _buildDailyFocusBars(logsInRange),
    );
  }

  // ----- Range independent data (sessions/history only) -----

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

  List<StatisticsBarPoint> _buildDailyTaskCompletionBars(List<Task> completedTasks) {
    final labels = _buildRangeDays();
    final counts = <DateTime, int>{};

    for (final task in completedTasks) {
      final completedAt = task.completedAt;
      if (completedAt == null) continue;

      final day = DateTime(completedAt.year, completedAt.month, completedAt.day);
      counts.update(day, (value) => value + 1, ifAbsent: () => 1);
    }

    return List.generate(labels.length, (index) {
      final day = labels[index];
      final dayCount = counts[day] ?? 0;
      return StatisticsBarPoint(
        label: _formatBarLabel(day),
        value: dayCount,
        isHighlighted: index == labels.length - 1,
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
        isHighlighted: index == labels.length - 1,
      );
    });
  }

  List<DateTime> _buildRangeDays() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_activeRange) {
      case StatisticsRange.today:
        return [today];
      case StatisticsRange.week:
        return List.generate(7, (index) => today.subtract(Duration(days: 6 - index)));
      case StatisticsRange.month:
        return List.generate(30, (index) => today.subtract(Duration(days: 29 - index)));
    }
  }

  String _formatBarLabel(DateTime day) {
    switch (_activeRange) {
      case StatisticsRange.today:
        return 'Today';
      case StatisticsRange.week:
        const weekdays = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
        return weekdays[day.weekday - 1];
      case StatisticsRange.month:
        return day.day.toString();
    }
  }

  bool _isInRange(DateTime value, DateTime startInclusive, DateTime endExclusive) {
    return (value.isAtSameMomentAs(startInclusive) || value.isAfter(startInclusive)) &&
        value.isBefore(endExclusive);
  }

  (DateTime, DateTime) _currentRangeBounds() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_activeRange) {
      case StatisticsRange.today:
        return (today, today.add(const Duration(days: 1)));
      case StatisticsRange.week:
        return (today.subtract(const Duration(days: 6)), today.add(const Duration(days: 1)));
      case StatisticsRange.month:
        return (today.subtract(const Duration(days: 29)), today.add(const Duration(days: 1)));
    }
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
