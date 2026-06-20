import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../theme/app_colors.dart';
import 'task_provider.dart';

class ProjectProvider with ChangeNotifier {
  final List<Project> _projects = [];
  TaskProvider? _taskProvider;
  
  String _activeFilter = 'All'; // 'All', 'In Progress', 'Completed'
  String _searchQuery = '';
  String _viewMode = 'list'; // 'list' or 'grid'
  ProjectProvider() {
    _initializeMockProjects();
  }

  void update(TaskProvider taskProvider) {
    _taskProvider = taskProvider;
    _checkAndUpdateProjectStatuses();
  }

  void _checkAndUpdateProjectStatuses() {
    if (_taskProvider == null) return;
    
    bool hasChanged = false;
    for (int i = 0; i < _projects.length; i++) {
      final project = _projects[i];
      final projectTasks = _taskProvider!.tasks
          .where((t) => t.project == project.name)
          .toList();
      
      String newStatus;
      if (projectTasks.isEmpty) {
        newStatus = 'In Progress';
      } else {
        final allCompleted = projectTasks.every((t) => t.isCompleted);
        newStatus = allCompleted ? 'Completed' : 'In Progress';
      }
      
      if (project.status != newStatus) {
        _projects[i] = project.copyWith(status: newStatus);
        hasChanged = true;
      }
    }
    
    if (hasChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  void _initializeMockProjects() {
    _projects.addAll([
      Project(
        id: 'p1',
        name: 'PRM392 Mobile App',
        description: 'Final project prototype and user testing',
        colorValue: AppColors.primary.value, 
        status: 'In Progress',
      ),
      Project(
        id: 'p2',
        name: 'Apartment Hunt',
        description: 'Researching neighborhoods and setting up viewings',
        colorValue: AppColors.accentYellow.value,
        status: 'In Progress',
      ),
      Project(
        id: 'p3',
        name: 'Design Portfolio',
        description: 'Update case studies with recent freelance work',
        colorValue: AppColors.accentPeach.value,
        status: 'Completed',
      ),
      Project(
        id: 'p4',
        name: 'Reading List 2024',
        description: 'Track books read and write short summaries',
        colorValue: AppColors.accentPink.value,
        status: 'In Progress',
      ),
      Project(
        id: 'p5',
        name: 'Learn Flutter',
        description: 'Watch tutorials and build sample apps',
        colorValue: AppColors.primary.value,
        status: 'In Progress',
      ),
      Project(
        id: 'p6',
        name: 'Personal Goals',
        description: 'Habits and health tracking',
        colorValue: AppColors.accentYellow.value, 
        status: 'In Progress',
      ),
      Project(
        id: 'p7',
        name: 'Work',
        description: 'Company tasks and assignments',
        colorValue: AppColors.accentPeach.value, 
        status: 'In Progress',
      ),
    ]);
  }

  List<Project> get projects => _projects;
  String get activeFilter => _activeFilter;
  String get searchQuery => _searchQuery;

  List<Project> get filteredProjects {
    Iterable<Project> result = _projects;

    // Filter by Status
    if (_activeFilter != 'All') {
      result = result.where((p) => p.status == _activeFilter);
    }

    // Search Query
    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      result = result.where((p) =>
          p.name.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query));
    }

    return result.toList();
  }

  int get inProgressProjectCount {
    return _projects.where((p) => p.status == 'In Progress').length;
  }

  void setActiveFilter(String filter) {
    _activeFilter = filter;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  String get viewMode => _viewMode;

  void toggleViewMode() {
    _viewMode = _viewMode == 'list' ? 'grid' : 'list';
    notifyListeners();
  }

  void addProject(Project project) {
    _projects.add(project);
    notifyListeners();
  }

  void updateProject(Project updated) {
    final index = _projects.indexWhere((p) => p.id == updated.id);
    if (index != -1) {
      _projects[index] = updated;
      notifyListeners();
    }
  }

  void deleteProject(String id) {
    _projects.removeWhere((p) => p.id == id);
    notifyListeners();
  }
}
