import 'dart:async';

import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../models/task_model.dart';
import '../repositories/task_repository.dart';
import '../utils/project_task_utils.dart';
import '../utils/reminder/task_reminder.dart';
import '../utils/validation/task_deadline_rules.dart';
import 'project_provider.dart';
import 'settings_provider.dart';

class TaskProvider with ChangeNotifier {
  final List<Task> _tasks = [];
  final TaskRepository _taskRepository = TaskRepository();
  Timer? _searchNotifyDebounce;
  SettingsProvider? _settingsProvider;
  ProjectProvider? _projectProvider;
  StreamSubscription<List<Task>>? _tasksSubscription;
  String? _uid;

  TaskProvider();

  void bindUser(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    _tasksSubscription?.cancel();
    _tasks.clear();
    if (uid == null) {
      notifyListeners();
      return;
    }
    _tasksSubscription = _taskRepository.watchTasks(uid).listen((tasks) {
      _tasks
        ..clear()
        ..addAll(tasks);
      notifyListeners();
    });
  }

  void bindSettings(SettingsProvider settingsProvider) {
    if (_settingsProvider == settingsProvider) return;
    _settingsProvider?.removeListener(_onSettingsChanged);
    _settingsProvider = settingsProvider;
    _settingsProvider?.addListener(_onSettingsChanged);
  }

  void _onSettingsChanged() {
    notifyListeners();
  }

  void bindProjects(ProjectProvider projectProvider) {
    _projectProvider = projectProvider;
  }

  @override
  void dispose() {
    _searchNotifyDebounce?.cancel();
    _tasksSubscription?.cancel();
    super.dispose();
  }

  String _defaultReminderFor(Task task) {
    if (task.dueDate == null) return TaskReminder.none;
    if (task.isAllDay) {
      return _settingsProvider?.defaultAllDayReminder ?? '1 day before';
    }
    return _settingsProvider?.defaultTimedReminder ?? '30 mins before';
  }

  String _activeFilter = '';
  String _searchQuery = '';
  String _sortBy = 'Due Date';
  String _filterProject = 'All Projects';
  String _filterPriority = 'All Priorities';
  String _filterStatus = 'All Status';

  List<Task> get tasks => _tasks;
  String get activeFilter => _activeFilter;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;
  String get filterProject => _filterProject;
  String get filterPriority => _filterPriority;
  String get filterStatus => _filterStatus;

  // Available dropdown options (derived from current tasks)
  List<String> get availableProjects {
    final projects = _projectProvider?.projects ?? const <Project>[];
    final names = projects.map((p) => p.name).toList()..sort();
    return ['All Projects', ...names];
  }

  List<String> get availablePriorities => [
    'All Priorities',
    'High',
    'Medium',
    'Low',
  ];
  List<String> get availableStatuses => [
    'All Status',
    'Pending',
    'Completed',
    'Overdue',
  ];
  List<String> get sortOptions => ['Due Date', 'Priority', 'Name'];

  // Filter tasks based on all active filters and search query
  List<Task> get filteredTasks {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeek = today.add(const Duration(days: 7));

    // 1. Basic Chip Filters
    Iterable<Task> result;
    switch (_activeFilter) {
      case 'Today':
        result = _tasks.where((t) {
          if (t.dueDate == null) return false;
          final tDate = DateTime(
            t.dueDate!.year,
            t.dueDate!.month,
            t.dueDate!.day,
          );
          return tDate.isAtSameMomentAs(today);
        });
        break;
      case 'Tomorrow':
        result = _tasks.where((t) {
          if (t.dueDate == null) return false;
          final tDate = DateTime(
            t.dueDate!.year,
            t.dueDate!.month,
            t.dueDate!.day,
          );
          return tDate.isAtSameMomentAs(today.add(const Duration(days: 1)));
        });
        break;
      case 'This Week':
        result = _tasks.where((t) {
          if (t.dueDate == null) return false;
          final tDate = DateTime(
            t.dueDate!.year,
            t.dueDate!.month,
            t.dueDate!.day,
          );
          return tDate.isAfter(today.add(const Duration(days: 1))) &&
              tDate.isBefore(nextWeek);
        });
        break;
      case 'Important':
        result = _tasks.where((t) => t.isImportant);
        break;
      case 'Scheduled':
        result = _tasks.where((t) => t.dueDate != null);
        break;
      case 'Unscheduled':
        result = _tasks.where((t) => t.dueDate == null);
        break;
      case 'Completed':
        result = _tasks.where((t) => t.isCompleted);
        break;
      case 'Overdue':
        result = _tasks.where((t) {
          if (t.dueDate == null) return false;
          final tDate = DateTime(
            t.dueDate!.year,
            t.dueDate!.month,
            t.dueDate!.day,
          );
          return tDate.isBefore(today) && !t.isCompleted;
        });
        break;
      case '':
      case 'All':
      default:
        result = _tasks;
        break;
    }

    // 2. Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      result = result.where((t) => t.title.toLowerCase().contains(query));
    }

    // 3. Dropdown Filters
    if (_filterProject != 'All Projects') {
      final projectId = projectIdForName(
        _projectProvider?.projects ?? const [],
        _filterProject,
      );
      result = result.where(
        (t) => projectId != null && t.projectId == projectId,
      );
    }
    if (_filterPriority != 'All Priorities') {
      result = result.where((t) => t.priority == _filterPriority);
    }
    if (_filterStatus != 'All Status') {
      if (_filterStatus == 'Completed') {
        result = result.where((t) => t.isCompleted);
      } else if (_filterStatus == 'Pending') {
        result = result.where((t) {
          if (t.isCompleted) return false;
          if (t.dueDate == null) return true;
          final tDate = DateTime(
            t.dueDate!.year,
            t.dueDate!.month,
            t.dueDate!.day,
          );
          return !tDate.isBefore(today); // Exclude overdue tasks
        });
      } else if (_filterStatus == 'Overdue') {
        result = result.where((t) {
          if (t.dueDate == null) return false;
          final tDate = DateTime(
            t.dueDate!.year,
            t.dueDate!.month,
            t.dueDate!.day,
          );
          return tDate.isBefore(today) && !t.isCompleted;
        });
      }
    }

    // 4. Sorting
    var listResult = result.toList();
    listResult.sort((a, b) {
      if (_sortBy == 'Due Date') {
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;

        final aDate = DateTime(a.dueDate!.year, a.dueDate!.month, a.dueDate!.day);
        final bDate = DateTime(b.dueDate!.year, b.dueDate!.month, b.dueDate!.day);
        
        if (aDate.isAtSameMomentAs(bDate)) {
          if (a.isAllDay && !b.isAllDay) return -1;
          if (!a.isAllDay && b.isAllDay) return 1;
        }

        return a.dueDate!.compareTo(b.dueDate!);
      } else if (_sortBy == 'Priority') {
        final Map<String, int> priorityMap = {'High': 0, 'Medium': 1, 'Low': 2};
        final pA = priorityMap[a.priority] ?? 3;
        final pB = priorityMap[b.priority] ?? 3;
        if (pA != pB) return pA.compareTo(pB);

        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;

        final aDate = DateTime(a.dueDate!.year, a.dueDate!.month, a.dueDate!.day);
        final bDate = DateTime(b.dueDate!.year, b.dueDate!.month, b.dueDate!.day);
        
        if (aDate.isAtSameMomentAs(bDate)) {
          if (a.isAllDay && !b.isAllDay) return -1;
          if (!a.isAllDay && b.isAllDay) return 1;
        }

        return a.dueDate!.compareTo(b.dueDate!); // secondary sort
      } else if (_sortBy == 'Name') {
        return a.title.compareTo(b.title);
      }
      return 0;
    });

    return listResult;
  }

  // Get tasks by specific grouping for the List screen
  List<Task> getTasksForGroup(String group) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final nextWeek = today.add(const Duration(days: 7));

    final tasksToFilter = filteredTasks;

    switch (group) {
      case 'Today':
        return tasksToFilter.where((t) {
          if (t.dueDate == null) return false;
          final tDate = DateTime(
            t.dueDate!.year,
            t.dueDate!.month,
            t.dueDate!.day,
          );
          return tDate.isAtSameMomentAs(today) && !t.isCompleted;
        }).toList();
      case 'Tomorrow':
        return tasksToFilter.where((t) {
          if (t.dueDate == null) return false;
          final tDate = DateTime(
            t.dueDate!.year,
            t.dueDate!.month,
            t.dueDate!.day,
          );
          return tDate.isAtSameMomentAs(tomorrow) && !t.isCompleted;
        }).toList();
      case 'This Week':
        return tasksToFilter.where((t) {
          if (t.dueDate == null) return false;
          final tDate = DateTime(
            t.dueDate!.year,
            t.dueDate!.month,
            t.dueDate!.day,
          );
          return tDate.isAfter(tomorrow) &&
              tDate.isBefore(nextWeek) &&
              !t.isCompleted;
        }).toList();
      case 'Later':
        return tasksToFilter.where((t) {
          if (t.dueDate == null) return true;
          final tDate = DateTime(
            t.dueDate!.year,
            t.dueDate!.month,
            t.dueDate!.day,
          );
          return tDate.isAtSameMomentAs(nextWeek) || tDate.isAfter(nextWeek);
        }).toList();
      case 'Overdue':
        return tasksToFilter.where((t) {
          if (t.dueDate == null) return false;
          final tDate = DateTime(
            t.dueDate!.year,
            t.dueDate!.month,
            t.dueDate!.day,
          );
          return tDate.isBefore(today) && !t.isCompleted;
        }).toList();
      case 'Completed':
        return tasksToFilter.where((t) => t.isCompleted).toList();
      default:
        return [];
    }
  }

  // Count getter for smart lists
  int getCountForFilter(String filter) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final nextWeek = today.add(const Duration(days: 7));

    switch (filter) {
      case 'Today':
        return _tasks.where((t) {
          if (t.dueDate == null) return false;
          final tDate = DateTime(
            t.dueDate!.year,
            t.dueDate!.month,
            t.dueDate!.day,
          );
          return tDate.isAtSameMomentAs(today) && !t.isCompleted;
        }).length;
      case 'Tomorrow':
        return _tasks.where((t) {
          if (t.dueDate == null) return false;
          final tDate = DateTime(
            t.dueDate!.year,
            t.dueDate!.month,
            t.dueDate!.day,
          );
          return tDate.isAtSameMomentAs(today.add(const Duration(days: 1))) &&
              !t.isCompleted;
        }).length;
      case 'This Week':
        return _tasks.where((t) {
          if (t.dueDate == null) return false;
          final tDate = DateTime(
            t.dueDate!.year,
            t.dueDate!.month,
            t.dueDate!.day,
          );
          return tDate.isAfter(today.add(const Duration(days: 1))) &&
              tDate.isBefore(nextWeek) &&
              !t.isCompleted;
        }).length;
      case 'Important':
        return _tasks.where((t) => t.isImportant && !t.isCompleted).length;
      case 'Scheduled':
        return _tasks.where((t) => t.dueDate != null && !t.isCompleted).length;
      case 'Unscheduled':
        return _tasks.where((t) => t.dueDate == null && !t.isCompleted).length;
      case 'Completed':
        return _tasks.where((t) => t.isCompleted).length;
      case 'Overdue':
        return _tasks.where((t) {
          if (t.dueDate == null) return false;
          final tDate = DateTime(
            t.dueDate!.year,
            t.dueDate!.month,
            t.dueDate!.day,
          );
          return tDate.isBefore(today) && !t.isCompleted;
        }).length;
      case 'All':
      default:
        return _tasks.length;
    }
  }

  // Project Progress
  double getProjectProgress(String projectId) {
    final projectTasks =
        _tasks.where((t) => t.projectId == projectId).toList();
    if (projectTasks.isEmpty) return 0.0;

    final completed = projectTasks.where((t) => t.isCompleted).length;
    return completed / projectTasks.length;
  }

  int getProjectTaskCount(String projectId) {
    return _tasks.where((t) => t.projectId == projectId).length;
  }

  Future<void> _persistTask(Task task) async {
    final uid = _uid;
    if (uid == null) return;
    await _taskRepository.updateTask(uid, task);
  }

  // Setters
  void setActiveFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    if (_searchQuery == query) return;
    _searchQuery = query;
    _searchNotifyDebounce?.cancel();
    _searchNotifyDebounce = Timer(const Duration(milliseconds: 200), () {
      notifyListeners();
    });
  }

  void setFilterProject(String project) {
    _filterProject = project;
    notifyListeners();
  }

  void setFilterPriority(String priority) {
    _filterPriority = priority;
    notifyListeners();
  }

  void setFilterStatus(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  void toggleTaskCompletion(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index == -1) return;

    final willBeCompleted = !_tasks[index].isCompleted;
    final updatedSubTasks = _tasks[index].subTasks
        .map((st) => st.copyWith(isCompleted: willBeCompleted))
        .toList();

    final updated = _tasks[index].copyWith(
      isCompleted: willBeCompleted,
      completedAt: willBeCompleted ? DateTime.now() : null,
      subTasks: updatedSubTasks,
    );
    _tasks[index] = updated;
    notifyListeners();
    unawaited(_persistTask(updated));
  }

  void addSubTask(String taskId, {String? subTaskId}) {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = _tasks[taskIndex];
    final newId = subTaskId ?? '${taskId}_sub_${DateTime.now().millisecondsSinceEpoch}';
    final subTasks = [...task.subTasks, SubTask(id: newId, title: '')];
    _tasks[taskIndex] = task.copyWith(subTasks: subTasks);
    notifyListeners();
    unawaited(_persistTask(_tasks[taskIndex]));
  }

  void updateSubTaskTitle(String taskId, String subTaskId, String title) {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = _tasks[taskIndex];
    final subTaskIndex = task.subTasks.indexWhere((st) => st.id == subTaskId);
    if (subTaskIndex == -1) return;

    final subTasks = List<SubTask>.from(task.subTasks);
    final trimmed = title.trim();
    if (trimmed.isEmpty) {
      subTasks.removeAt(subTaskIndex);
    } else {
      subTasks[subTaskIndex] = subTasks[subTaskIndex].copyWith(title: trimmed);
    }

    final allCompleted = subTasks.isNotEmpty && subTasks.every((st) => st.isCompleted);
    _tasks[taskIndex] = task.copyWith(
      subTasks: subTasks,
      isCompleted: subTasks.isEmpty ? task.isCompleted : allCompleted,
      completedAt: subTasks.isEmpty
          ? task.completedAt
          : (allCompleted ? (task.completedAt ?? DateTime.now()) : null),
    );
    notifyListeners();
    unawaited(_persistTask(_tasks[taskIndex]));
  }

  void removeSubTask(String taskId, String subTaskId) {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex == -1) return;

    final task = _tasks[taskIndex];
    final subTasks = task.subTasks.where((st) => st.id != subTaskId).toList();
    final allCompleted = subTasks.isNotEmpty && subTasks.every((st) => st.isCompleted);
    _tasks[taskIndex] = task.copyWith(
      subTasks: subTasks,
      isCompleted: subTasks.isEmpty ? task.isCompleted : allCompleted,
      completedAt: subTasks.isEmpty
          ? task.completedAt
          : (allCompleted ? (task.completedAt ?? DateTime.now()) : null),
    );
    notifyListeners();
    unawaited(_persistTask(_tasks[taskIndex]));
  }

  void toggleSubTaskCompletion(String taskId, String subTaskId, {bool autoCompleteParent = true}) {
    final taskIndex = _tasks.indexWhere((t) => t.id == taskId);
    if (taskIndex != -1) {
      final task = _tasks[taskIndex];
      final subTaskIndex = task.subTasks.indexWhere((st) => st.id == subTaskId);
      if (subTaskIndex != -1) {
        final subTasks = List<SubTask>.from(task.subTasks);
        final willBeCompleted = !subTasks[subTaskIndex].isCompleted;
        subTasks[subTaskIndex] = subTasks[subTaskIndex].copyWith(isCompleted: willBeCompleted);
        
        final allCompleted = subTasks.isNotEmpty && subTasks.every((st) => st.isCompleted);
        
        _tasks[taskIndex] = task.copyWith(
          subTasks: subTasks,
          isCompleted: autoCompleteParent ? allCompleted : task.isCompleted,
          completedAt: (autoCompleteParent && allCompleted && !task.isCompleted) ? DateTime.now() : (allCompleted ? task.completedAt : null),
        );
        notifyListeners();
        unawaited(_persistTask(_tasks[taskIndex]));
      }
    }
  }

  void toggleTaskImportance(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        isImportant: !_tasks[index].isImportant,
      );
      notifyListeners();
      unawaited(_persistTask(_tasks[index]));
    }
  }

  Future<bool> addTask(Task task) async {
    if (!TaskDeadlineRules.isValidForCreate(task.dueDate)) {
      return false;
    }
    final uid = _uid;
    if (uid == null) return false;

    final normalizedTask = task.isCompleted && task.completedAt == null
        ? task.copyWith(completedAt: DateTime.now())
        : task;
    unawaited(_taskRepository.createTask(uid, normalizedTask));
    return true;
  }

  Future<void> updateTask(Task updatedTask) async {
    final uid = _uid;
    if (uid == null) return;

    final normalizedTask = updatedTask.isCompleted && updatedTask.completedAt == null
        ? updatedTask.copyWith(completedAt: DateTime.now())
        : updatedTask;

    final index = _tasks.indexWhere((task) => task.id == normalizedTask.id);
    if (index != -1) {
      _tasks[index] = normalizedTask;
      notifyListeners();
    }

    unawaited(_taskRepository.updateTask(uid, normalizedTask));
  }

  Future<void> deleteTask(String id) async {
    final uid = _uid;
    if (uid == null) return;
    unawaited(_taskRepository.deleteTask(uid, id));
  }

  // Dashboard Metrics
  int get tasksTodayCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Count ALL tasks with a due date of today (both completed and pending)
    return _tasks.where((t) {
      if (t.dueDate == null) return false;
      final tDate = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return tDate.isAtSameMomentAs(today);
    }).length;
  }

  int get completedTodayCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Tasks due today that are completed
    return _tasks.where((t) {
      if (t.dueDate == null || !t.isCompleted) return false;
      final tDate = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return tDate.isAtSameMomentAs(today);
    }).length;
  }

  int get remainingTodayCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    // Tasks due today that are NOT yet completed
    return _tasks.where((t) {
      if (t.dueDate == null || t.isCompleted) return false;
      final tDate = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return tDate.isAtSameMomentAs(today);
    }).length;
  }

  int totalTasksDueOn(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return _tasks.where((task) => _isTaskDueOn(task, normalized)).length;
  }

  int tasksDueOnCompletedCount(DateTime day) {
    final normalized = DateTime(day.year, day.month, day.day);
    return _tasks.where((task) {
      if (task.completedAt == null || task.dueDate == null) return false;
      final dueDay = DateTime(
        task.dueDate!.year,
        task.dueDate!.month,
        task.dueDate!.day,
      );
      final completedDay = DateTime(
        task.completedAt!.year,
        task.completedAt!.month,
        task.completedAt!.day,
      );
      return dueDay.isAtSameMomentAs(normalized) &&
          completedDay.isAtSameMomentAs(normalized);
    }).length;
  }

  bool _isTaskDueOn(Task task, DateTime day) {
    if (task.dueDate == null) return false;
    final dueDay = DateTime(
      task.dueDate!.year,
      task.dueDate!.month,
      task.dueDate!.day,
    );
    return dueDay.isAtSameMomentAs(day);
  }

  int get overdueCount => getCountForFilter('Overdue');

  int get completedCount => _tasks.where((t) => t.isCompleted).length;

  int get productivityScore {
    if (_tasks.isEmpty) return 0;
    return ((completedCount / _tasks.length) * 100).round();
  }
}
