import 'package:flutter/material.dart';

import '../models/activity_mode.dart';
import 'app_colors.dart';

/// Color tokens for an activity mode, applied via [ThemeExtension].
class ActivityModePalette extends ThemeExtension<ActivityModePalette> {
  final ActivityModeId modeId;
  final Color primary;
  final Color primaryDark;
  final Color primaryLight;
  final Color background;
  final Color surface;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color card;
  final Color drawerHeader;
  final Color insetSurface;
  final Color accentYellow;
  final Color accentPeach;
  final Color accentPink;

  const ActivityModePalette({
    required this.modeId,
    required this.primary,
    required this.primaryDark,
    required this.primaryLight,
    required this.background,
    required this.surface,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.card,
    required this.drawerHeader,
    required this.insetSurface,
    required this.accentYellow,
    required this.accentPeach,
    required this.accentPink,
  });

  static ActivityModePalette forMode(
    ActivityModeId id, {
    required Brightness brightness,
  }) {
    final dark = brightness == Brightness.dark;
    return switch (id) {
      ActivityModeId.defaultMode => dark ? _defaultDark : _defaultLight,
      ActivityModeId.work => dark ? _workDark : _workLight,
      ActivityModeId.study => dark ? _studyDark : _studyLight,
      ActivityModeId.chill => dark ? _chillDark : _chillLight,
      ActivityModeId.sleep => dark ? _sleepDark : _sleepLight,
    };
  }

  static const ActivityModePalette _defaultLight = ActivityModePalette(
    modeId: ActivityModeId.defaultMode,
    primary: AppColors.primary,
    primaryDark: AppColors.primaryDark,
    primaryLight: AppColors.primaryLight,
    background: AppColors.background,
    surface: AppColors.surface,
    border: AppColors.border,
    textPrimary: AppColors.textPrimary,
    textSecondary: AppColors.textSecondary,
    card: AppColors.surface,
    drawerHeader: AppColors.primaryLight,
    insetSurface: AppColors.background,
    accentYellow: AppColors.accentYellow,
    accentPeach: AppColors.accentPeach,
    accentPink: AppColors.accentPink,
  );

  static const ActivityModePalette _defaultDark = ActivityModePalette(
    modeId: ActivityModeId.defaultMode,
    primary: AppColors.primary,
    primaryDark: AppColors.primaryDark,
    primaryLight: AppColors.primaryLight,
    background: AppColors.darkBackground,
    surface: AppColors.darkSurface,
    border: AppColors.darkBorder,
    textPrimary: AppColors.darkTextPrimary,
    textSecondary: AppColors.darkTextSecondary,
    card: Color(0xFF2D3530),
    drawerHeader: Color(0xFF2A332E),
    insetSurface: Color(0xFF232A26),
    accentYellow: AppColors.accentYellow,
    accentPeach: AppColors.accentPeach,
    accentPink: AppColors.accentPink,
  );

  static const ActivityModePalette _workLight = ActivityModePalette(
    modeId: ActivityModeId.work,
    primary: Color(0xFF6B9BD1),
    primaryDark: Color(0xFF3D6FA3),
    primaryLight: Color(0xFFC5D9EE),
    background: Color(0xFFF4F7FB),
    surface: Color(0xFFFAFCFE),
    border: Color(0xFFC8D6E5),
    textPrimary: Color(0xFF2C3E50),
    textSecondary: Color(0xFF5A6F82),
    card: Color(0xFFFAFCFE),
    drawerHeader: Color(0xFFC5D9EE),
    insetSurface: Color(0xFFEEF3F8),
    accentYellow: Color(0xFFE3B82B),
    accentPeach: Color(0xFF5A8FC4),
    accentPink: Color(0xFF7BA3CC),
  );

  static const ActivityModePalette _workDark = ActivityModePalette(
    modeId: ActivityModeId.work,
    primary: Color(0xFF7EB3E8),
    primaryDark: Color(0xFF5A9AD4),
    primaryLight: Color(0xFF3D5A73),
    background: Color(0xFF141C26),
    surface: Color(0xFF1C2733),
    border: Color(0xFF2E3F52),
    textPrimary: Color(0xFFE4ECF4),
    textSecondary: Color(0xFF8FA3B8),
    card: Color(0xFF222E3C),
    drawerHeader: Color(0xFF243040),
    insetSurface: Color(0xFF1A2430),
    accentYellow: Color(0xFFE3B82B),
    accentPeach: Color(0xFF6BA8D8),
    accentPink: Color(0xFF8BB8E0),
  );

  static const ActivityModePalette _studyLight = ActivityModePalette(
    modeId: ActivityModeId.study,
    primary: Color(0xFFD4A84B),
    primaryDark: Color(0xFFA67C1A),
    primaryLight: Color(0xFFF0DFA8),
    background: Color(0xFFFBF6ED),
    surface: Color(0xFFFFFDF8),
    border: Color(0xFFE8D9B8),
    textPrimary: Color(0xFF3D3428),
    textSecondary: Color(0xFF7A6E5C),
    card: Color(0xFFFFFDF8),
    drawerHeader: Color(0xFFF0DFA8),
    insetSurface: Color(0xFFF5EDE0),
    accentYellow: Color(0xFFE3B82B),
    accentPeach: Color(0xFFDF7E52),
    accentPink: Color(0xFFD4A84B),
  );

  static const ActivityModePalette _studyDark = ActivityModePalette(
    modeId: ActivityModeId.study,
    primary: Color(0xFFE8C060),
    primaryDark: Color(0xFFD4A84B),
    primaryLight: Color(0xFF5C4A28),
    background: Color(0xFF1E1A14),
    surface: Color(0xFF2A241C),
    border: Color(0xFF4A4030),
    textPrimary: Color(0xFFF0E8DC),
    textSecondary: Color(0xFFB0A090),
    card: Color(0xFF322C22),
    drawerHeader: Color(0xFF3A3228),
    insetSurface: Color(0xFF252018),
    accentYellow: Color(0xFFE8C060),
    accentPeach: Color(0xFFE09060),
    accentPink: Color(0xFFD4A84B),
  );

  static const ActivityModePalette _chillLight = ActivityModePalette(
    modeId: ActivityModeId.chill,
    primary: Color(0xFFB39DDB),
    primaryDark: Color(0xFF7E57C2),
    primaryLight: Color(0xFFE8DFF5),
    background: Color(0xFFF8F4FC),
    surface: Color(0xFFFFFCFF),
    border: Color(0xFFD9CCE8),
    textPrimary: Color(0xFF3A3048),
    textSecondary: Color(0xFF7A6E8C),
    card: Color(0xFFFFFCFF),
    drawerHeader: Color(0xFFE8DFF5),
    insetSurface: Color(0xFFF0EAF8),
    accentYellow: Color(0xFFE3B82B),
    accentPeach: Color(0xFFCE93D8),
    accentPink: Color(0xFFD65D7F),
  );

  static const ActivityModePalette _chillDark = ActivityModePalette(
    modeId: ActivityModeId.chill,
    primary: Color(0xFFCE93D8),
    primaryDark: Color(0xFFB39DDB),
    primaryLight: Color(0xFF4A3A5C),
    background: Color(0xFF1A1520),
    surface: Color(0xFF241E2C),
    border: Color(0xFF3E3450),
    textPrimary: Color(0xFFEDE8F4),
    textSecondary: Color(0xFFA898B8),
    card: Color(0xFF2C2438),
    drawerHeader: Color(0xFF342A42),
    insetSurface: Color(0xFF201A28),
    accentYellow: Color(0xFFE3B82B),
    accentPeach: Color(0xFFCE93D8),
    accentPink: Color(0xFFD65D7F),
  );

  static const ActivityModePalette _sleepLight = ActivityModePalette(
    modeId: ActivityModeId.sleep,
    primary: Color(0xFF7986CB),
    primaryDark: Color(0xFF3F51B5),
    primaryLight: Color(0xFFC5CAE9),
    background: Color(0xFFECEEF5),
    surface: Color(0xFFF5F6FA),
    border: Color(0xFFB8BFD4),
    textPrimary: Color(0xFF2C3048),
    textSecondary: Color(0xFF5C6080),
    card: Color(0xFFF5F6FA),
    drawerHeader: Color(0xFFC5CAE9),
    insetSurface: Color(0xFFE4E6F0),
    accentYellow: Color(0xFF9FA8DA),
    accentPeach: Color(0xFF7986CB),
    accentPink: Color(0xFF7986CB),
  );

  static const ActivityModePalette _sleepDark = ActivityModePalette(
    modeId: ActivityModeId.sleep,
    primary: Color(0xFF9FA8DA),
    primaryDark: Color(0xFF7986CB),
    primaryLight: Color(0xFF2C3458),
    background: Color(0xFF0E1018),
    surface: Color(0xFF161A24),
    border: Color(0xFF2A3040),
    textPrimary: Color(0xFFD8DCE8),
    textSecondary: Color(0xFF8890A8),
    card: Color(0xFF1C2030),
    drawerHeader: Color(0xFF222838),
    insetSurface: Color(0xFF121620),
    accentYellow: Color(0xFF9FA8DA),
    accentPeach: Color(0xFF7986CB),
    accentPink: Color(0xFF7986CB),
  );

  @override
  ActivityModePalette copyWith({
    ActivityModeId? modeId,
    Color? primary,
    Color? primaryDark,
    Color? primaryLight,
    Color? background,
    Color? surface,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? card,
    Color? drawerHeader,
    Color? insetSurface,
    Color? accentYellow,
    Color? accentPeach,
    Color? accentPink,
  }) {
    return ActivityModePalette(
      modeId: modeId ?? this.modeId,
      primary: primary ?? this.primary,
      primaryDark: primaryDark ?? this.primaryDark,
      primaryLight: primaryLight ?? this.primaryLight,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      card: card ?? this.card,
      drawerHeader: drawerHeader ?? this.drawerHeader,
      insetSurface: insetSurface ?? this.insetSurface,
      accentYellow: accentYellow ?? this.accentYellow,
      accentPeach: accentPeach ?? this.accentPeach,
      accentPink: accentPink ?? this.accentPink,
    );
  }

  @override
  ActivityModePalette lerp(ThemeExtension<ActivityModePalette>? other, double t) {
    if (other is! ActivityModePalette) return this;
    return ActivityModePalette(
      modeId: t < 0.5 ? modeId : other.modeId,
      primary: Color.lerp(primary, other.primary, t)!,
      primaryDark: Color.lerp(primaryDark, other.primaryDark, t)!,
      primaryLight: Color.lerp(primaryLight, other.primaryLight, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      card: Color.lerp(card, other.card, t)!,
      drawerHeader: Color.lerp(drawerHeader, other.drawerHeader, t)!,
      insetSurface: Color.lerp(insetSurface, other.insetSurface, t)!,
      accentYellow: Color.lerp(accentYellow, other.accentYellow, t)!,
      accentPeach: Color.lerp(accentPeach, other.accentPeach, t)!,
      accentPink: Color.lerp(accentPink, other.accentPink, t)!,
    );
  }
}
