import 'package:flutter/material.dart';
import '../models/project_model.dart';
import '../theme/app_colors.dart';

class ProjectProvider with ChangeNotifier {
  final List<Project> _projects = [];
  
  String _activeFilter = 'All'; // 'All', 'Active', 'Completed', 'Archived'
  String _searchQuery = '';
  String _viewMode = 'list'; // 'list' or 'grid'
  ProjectProvider() {
    _initializeMockProjects();
  }

  void _initializeMockProjects() {
    _projects.addAll([
      Project(
        id: 'p1',
        name: 'PRM392 Mobile App',
        description: 'Final project prototype and user testing',
        colorValue: AppColors.primary.value, 
        status: 'Active',
      ),
      Project(
        id: 'p2',
        name: 'Apartment Hunt',
        description: 'Researching neighborhoods and setting up viewings',
        colorValue: 0xFFFDE68A, // Butter Yellow
        status: 'Active',
      ),
      Project(
        id: 'p3',
        name: 'Design Portfolio',
        description: 'Update case studies with recent freelance work',
        colorValue: 0xFFFFDAB9, // Soft Peach
        status: 'Completed',
      ),
      Project(
        id: 'p4',
        name: 'Reading List 2024',
        description: 'Track books read and write short summaries',
        colorValue: 0xFFF4C8D3, // Blush Pink
        status: 'Active',
      ),
      Project(
        id: 'p5',
        name: 'Learn Flutter',
        description: 'Watch tutorials and build sample apps',
        colorValue: AppColors.primary.value,
        status: 'Active',
      ),
      Project(
        id: 'p6',
        name: 'Personal Goals',
        description: 'Habits and health tracking',
        colorValue: 0xFFFDE68A, 
        status: 'Active',
      ),
      Project(
        id: 'p7',
        name: 'Work',
        description: 'Company tasks and assignments',
        colorValue: 0xFFFFDAB9, 
        status: 'Active',
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

  int get activeProjectCount {
    return _projects.where((p) => p.status == 'Active').length;
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
