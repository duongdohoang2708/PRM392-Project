import 'package:flutter/material.dart';
import '../models/task_model.dart';

class TaskProvider with ChangeNotifier {
  final List<Task> _tasks = [];

  TaskProvider() {
    _initializeMockTasks();
  }

  void _initializeMockTasks() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _tasks.addAll([
      Task(
        id: '1',
        title: 'Finish Flutter Assignment',
        project: 'PRM392 Mobile App',
        priority: 'High',
        dueDate: today.add(const Duration(hours: 10)),
        notes:
            'Read chapters 4 and 5 in the Flutter Cookbook. Implement API service and write unit tests.',
        subTasks: [
          SubTask(id: '1_1', title: 'Read chapters 4 and 5', isCompleted: true),
          SubTask(
            id: '1_2',
            title: 'Implement API service',
            isCompleted: false,
          ),
          SubTask(id: '1_3', title: 'Write unit tests', isCompleted: false),
        ],
      ),
      Task(
        id: '2',
        title: 'UI Design Home Screen',
        project: 'PRM392 Mobile App',
        priority: 'Medium',
        dueDate: today.add(const Duration(hours: 14)),
        isCompleted: true,
      ),
      Task(
        id: '3',
        title: 'Go to the Gym',
        project: 'Personal Goals',
        priority: 'Low',
      ),
      Task(
        id: '4',
        title: 'Learn Provider State Management',
        project: 'Learn Flutter',
        priority: 'Medium',
        dueDate: today.add(const Duration(days: 1, hours: 10)),
        isImportant: true,
      ),
      Task(
        id: '5',
        title: 'Read Chapter 6 - Flutter Cookbook',
        project: 'Learn Flutter',
        priority: 'Low',
        dueDate: today.add(const Duration(days: 1, hours: 15)),
      ),
      Task(
        id: '6',
        title: 'Write project report',
        project: 'PRM392 Mobile App',
        priority: 'High',
        dueDate: today.add(const Duration(days: 3, hours: 9)),
      ),
      Task(
        id: '7',
        title: 'Setup Firebase Authentication',
        project: 'PRM392 Mobile App',
        priority: 'Medium',
        dueDate: today.subtract(const Duration(days: 2, hours: -10)),
      ),
      Task(
        id: '8',
        title: 'Buy groceries',
        project: 'Personal Goals',
        priority: 'Low',
      ),
      Task(
        id: '9',
        title: 'Call mom',
        project: 'Personal Goals',
        priority: 'Medium',
      ),
      Task(
        id: '10',
        title: 'Review PRs',
        project: 'PRM392 Mobile App',
        priority: 'High',
        dueDate: today.add(const Duration(hours: 11)),
      ),
      Task(
        id: '11',
        title: 'Plan next week sprint',
        project: 'PRM392 Mobile App',
        priority: 'Medium',
        dueDate: today.add(const Duration(days: 1, hours: 14)),
      ),
      Task(
        id: '12',
        title: 'Meditate for 10 minutes',
        project: 'Personal Goals',
        priority: 'Low',
        dueDate: today.add(const Duration(hours: 22)),
      ),
      Task(
        id: '13',
        title: 'Watch Flutter Animation Tutorial',
        project: 'Learn Flutter',
        priority: 'Medium',
        dueDate: today.add(const Duration(days: 2, hours: 14)),
        isImportant: true,
      ),
      Task(
        id: '14',
        title: 'Submit Expense Report',
        project: 'Work',
        priority: 'High',
        dueDate: today.subtract(const Duration(days: 3, hours: -10)),
      ),
      Task(
        id: '15',
        title: 'Prepare slides for presentation',
        project: 'Work',
        priority: 'High',
        dueDate: today.add(const Duration(days: 1, hours: 16)),
      ),
      Task(
        id: '16',
        title: 'Read 20 pages of new book',
        project: 'Personal Goals',
        priority: 'Low',
        dueDate: today.add(const Duration(days: 1, hours: 21)),
        isCompleted: true,
      ),
    ]);
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
    final projects = _tasks.map((t) => t.project).toSet().toList();
    projects.sort();
    return ['All Projects', ...projects];
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
      result = result.where((t) => t.project == _filterProject);
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
        return a.dueDate!.compareTo(b.dueDate!);
      } else if (_sortBy == 'Priority') {
        final Map<String, int> priorityMap = {'High': 0, 'Medium': 1, 'Low': 2};
        final pA = priorityMap[a.priority] ?? 3;
        final pB = priorityMap[b.priority] ?? 3;
        if (pA != pB) return pA.compareTo(pB);
        if (a.dueDate == null && b.dueDate == null) return 0;
        if (a.dueDate == null) return 1;
        if (b.dueDate == null) return -1;
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
  double getProjectProgress(String projectName) {
    final projectTasks = _tasks.where((t) => t.project == projectName).toList();
    if (projectTasks.isEmpty) return 0.0;

    final completed = projectTasks.where((t) => t.isCompleted).length;
    return completed / projectTasks.length;
  }

  int getProjectTaskCount(String projectName) {
    return _tasks.where((t) => t.project == projectName).length;
  }

  // Setters
  void setActiveFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
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
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        isCompleted: !_tasks[index].isCompleted,
      );
      notifyListeners();
    }
  }

  void toggleTaskImportance(String id) {
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        isImportant: !_tasks[index].isImportant,
      );
      notifyListeners();
    }
  }

  void addTask(Task task) {
    _tasks.add(task);
    notifyListeners();
  }

  void updateTask(Task updatedTask) {
    final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
    if (index != -1) {
      _tasks[index] = updatedTask;
      notifyListeners();
    }
  }

  void deleteTask(String id) {
    _tasks.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  // Dashboard Metrics
  int get tasksTodayCount {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _tasks.where((t) {
      if (t.dueDate == null) return false;
      final tDate = DateTime(t.dueDate!.year, t.dueDate!.month, t.dueDate!.day);
      return tDate.isAtSameMomentAs(today) && !t.isCompleted;
    }).length;
  }

  int get completedCount => _tasks.where((t) => t.isCompleted).length;

  int get productivityScore {
    if (_tasks.isEmpty) return 0;
    return ((completedCount / _tasks.length) * 100).round();
  }
}
