import '../models/project_model.dart';
import '../models/task_model.dart';

String? projectIdForName(List<Project> projects, String projectName) {
  if (projectName == 'All Projects' || projectName == 'None') return null;
  for (final project in projects) {
    if (project.name == projectName) return project.id;
  }
  return null;
}

String projectNameForTask(Task task, List<Project> projects) {
  if (!task.hasProject) return 'None';
  for (final project in projects) {
    if (project.id == task.projectId) return project.name;
  }
  return 'None';
}

Project? projectForTask(Task task, List<Project> projects) {
  if (!task.hasProject) return null;
  for (final project in projects) {
    if (project.id == task.projectId) return project;
  }
  return null;
}

String? normalizeProjectId(String? value) {
  if (value == null || value.isEmpty || value == 'None') return null;
  return value;
}
