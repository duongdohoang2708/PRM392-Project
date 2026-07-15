import 'package:flutter/material.dart';
import '../../providers/project_provider.dart';
import '../../theme/app_colors.dart';

/// Resolves accent color from a project name; falls back to app green.
class ProjectAccentColor {
  ProjectAccentColor._();

  static const Color defaultColor = AppColors.primaryDark;

  static Color fromValue(BuildContext context, int colorValue) =>
      AppColors.vibrantProjectAccentOf(context, Color(colorValue));

  static Color resolve(
    BuildContext context,
    ProjectProvider provider,
    String projectName,
  ) {
    if (projectName.isEmpty || projectName == 'None') {
      return AppColors.vibrantProjectAccentOf(context, defaultColor);
    }

    for (final project in provider.projects) {
      if (project.name == projectName) {
        return fromValue(context, project.colorValue);
      }
    }

    return AppColors.vibrantProjectAccentOf(context, defaultColor);
  }
}
