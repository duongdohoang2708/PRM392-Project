import 'dart:async';

import 'package:flutter/material.dart';

import '../models/project_model.dart';
import '../repositories/project_repository.dart';
import '../repositories/task_repository.dart';
import 'task_provider.dart';

class ProjectProvider with ChangeNotifier {
  final List<Project> _projects = [];
  final Set<String> _optimisticallyDeletedIds = {};
  final ProjectRepository _projectRepository = ProjectRepository();
  final TaskRepository _taskRepository = TaskRepository();
  TaskProvider? _taskProvider;
  StreamSubscription<List<Project>>? _projectsSubscription;
  String? _uid;

  String _activeFilter = 'All';
  String _searchQuery = '';
  String _viewMode = 'list';

  ProjectProvider();

  void bindUser(String? uid) {
    if (_uid == uid) return;
    _uid = uid;
    _projectsSubscription?.cancel();
    _projects.clear();
    if (uid == null) {
      notifyListeners();
      return;
    }
    _projectsSubscription = _projectRepository.watchProjects(uid).listen((projects) {
      final filteredProjects = projects.where((p) => !_optimisticallyDeletedIds.contains(p.id)).toList();
      if (_hasSameProjectSnapshot(_projects, filteredProjects)) return;
      _projects
        ..clear()
        ..addAll(filteredProjects);
      _checkAndUpdateProjectStatuses();
      notifyListeners();
    });
  }

  bool _hasSameProjectSnapshot(List<Project> current, List<Project> incoming) {
    if (current.length != incoming.length) return false;

    final incomingById = {for (final project in incoming) project.id: project};
    for (final project in current) {
      final updated = incomingById[project.id];
      if (updated == null) return false;
      if (project.name != updated.name ||
          project.description != updated.description ||
          project.colorValue != updated.colorValue ||
          project.icon.codePoint != updated.icon.codePoint ||
          project.status != updated.status) {
        return false;
      }
    }
    return true;
  }

  void update(TaskProvider taskProvider) {
    _taskProvider = taskProvider;
    _checkAndUpdateProjectStatuses();
  }

  void _checkAndUpdateProjectStatuses() {
    if (_taskProvider == null || _uid == null) return;

    bool hasChanged = false;
    for (int i = 0; i < _projects.length; i++) {
      final project = _projects[i];
      final projectTasks = _taskProvider!.tasks
          .where((t) => t.projectId == project.id)
          .toList();

      String newStatus;
      if (projectTasks.isEmpty) {
        newStatus = 'In Progress';
      } else {
        final allCompleted = projectTasks.every((t) => t.isCompleted);
        newStatus = allCompleted ? 'Completed' : 'In Progress';
      }

      if (project.status != newStatus) {
        final updated = project.copyWith(status: newStatus);
        _projects[i] = updated;
        hasChanged = true;
        unawaited(_projectRepository.updateProject(_uid!, updated));
      }
    }

    if (hasChanged) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  List<Project> get projects => _projects;
  String get activeFilter => _activeFilter;
  String get searchQuery => _searchQuery;

  List<Project> get filteredProjects {
    Iterable<Project> result = _projects;

    if (_activeFilter != 'All') {
      result = result.where((p) => p.status == _activeFilter);
    }

    if (_searchQuery.trim().isNotEmpty) {
      final query = _searchQuery.trim().toLowerCase();
      result = result.where(
        (p) =>
            p.name.toLowerCase().contains(query) ||
            p.description.toLowerCase().contains(query),
      );
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

  Future<void> addProject(Project project) async {
    final uid = _uid;
    if (uid == null) return;
    unawaited(_projectRepository.createProject(uid, project));
  }

  Future<void> updateProject(Project updated) async {
    final uid = _uid;
    if (uid == null) return;

    final index = _projects.indexWhere((project) => project.id == updated.id);
    if (index != -1) {
      _projects[index] = updated;
      _projects.sort((a, b) => a.name.compareTo(b.name));
      notifyListeners();
    }

    unawaited(_projectRepository.updateProject(uid, updated));
  }

  Future<void> deleteProject(String id) async {
    final uid = _uid;
    if (uid == null) return;

    _optimisticallyDeletedIds.add(id);

    final removedIndex = _projects.indexWhere((project) => project.id == id);
    if (removedIndex != -1) {
      _projects.removeAt(removedIndex);
      notifyListeners();
    }

    unawaited(_taskRepository.deleteTasksByProjectId(uid, id));
    unawaited(_projectRepository.deleteProject(uid, id));
  }

  Project? findById(String id) {
    for (final project in _projects) {
      if (project.id == id) return project;
    }
    return null;
  }

  @override
  void dispose() {
    _projectsSubscription?.cancel();
    super.dispose();
  }
}
