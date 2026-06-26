import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Shared icon tokens for consistent UI across screens.
abstract final class AppIcons {
  /// Streak freeze day — weekly schedule or manual mark (preserves streak, not counted).
  static const IconData freezeDay = Icons.ac_unit;

  static const Color freezeDayColor = AppColors.freezeBlue;
}
