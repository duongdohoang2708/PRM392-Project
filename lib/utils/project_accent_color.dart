import 'package:flutter/material.dart';
import '../../providers/project_provider.dart';
import '../../theme/app_colors.dart';

/// Resolves accent color from a project name; falls back to app green.
class ProjectAccentColor {
  ProjectAccentColor._();

  static const Color defaultColor = AppColors.primaryDark;

  static Color resolve(ProjectProvider provider, String projectName) {
    if (projectName.isEmpty || projectName == 'None') {
      return defaultColor;
    }

    for (final project in provider.projects) {
      if (project.name == projectName) {
        return Color(project.colorValue);
      }
    }

    return defaultColor;
  }
}
