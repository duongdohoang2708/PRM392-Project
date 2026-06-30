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
    primary: Color(0xFF4A9BB0),
    primaryDark: Color(0xFF2D7A8F),
    primaryLight: Color(0xFFB8DDE6),
    background: Color(0xFFF0F7F8),
    surface: Color(0xFFF8FCFD),
    border: Color(0xFFB8D4DC),
    textPrimary: Color(0xFF1E3A42),
    textSecondary: Color(0xFF4A6B75),
    card: Color(0xFFF8FCFD),
    drawerHeader: Color(0xFFB8DDE6),
    insetSurface: Color(0xFFE4F0F2),
    accentYellow: Color(0xFFE3B82B),
    accentPeach: Color(0xFF3D8A9E),
    accentPink: Color(0xFF5AA8BC),
  );

  static const ActivityModePalette _workDark = ActivityModePalette(
    modeId: ActivityModeId.work,
    primary: Color(0xFF5EB8CC),
    primaryDark: Color(0xFF4A9BB0),
    primaryLight: Color(0xFF2A4F58),
    background: Color(0xFF0F1A1E),
    surface: Color(0xFF162428),
    border: Color(0xFF2A4550),
    textPrimary: Color(0xFFE0F0F4),
    textSecondary: Color(0xFF8AABB4),
    card: Color(0xFF1C3038),
    drawerHeader: Color(0xFF223840),
    insetSurface: Color(0xFF141E22),
    accentYellow: Color(0xFFE3B82B),
    accentPeach: Color(0xFF5EB8CC),
    accentPink: Color(0xFF7EC8D8),
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
    primary: Color(0xFFE8A0B0),
    primaryDark: Color(0xFFC76B82),
    primaryLight: Color(0xFFF5D4DC),
    background: Color(0xFFFDF5F6),
    surface: Color(0xFFFFFAFB),
    border: Color(0xFFE8C8D0),
    textPrimary: Color(0xFF3D2830),
    textSecondary: Color(0xFF7A5A64),
    card: Color(0xFFFFFAFB),
    drawerHeader: Color(0xFFF5D4DC),
    insetSurface: Color(0xFFF8EAED),
    accentYellow: Color(0xFFE3B82B),
    accentPeach: Color(0xFFE09098),
    accentPink: Color(0xFFD65D7F),
  );

  static const ActivityModePalette _chillDark = ActivityModePalette(
    modeId: ActivityModeId.chill,
    primary: Color(0xFFF0B0C0),
    primaryDark: Color(0xFFE8A0B0),
    primaryLight: Color(0xFF5C3848),
    background: Color(0xFF1A1014),
    surface: Color(0xFF261820),
    border: Color(0xFF4A3040),
    textPrimary: Color(0xFFF4E8EC),
    textSecondary: Color(0xFFB898A4),
    card: Color(0xFF2E2030),
    drawerHeader: Color(0xFF382830),
    insetSurface: Color(0xFF201418),
    accentYellow: Color(0xFFE3B82B),
    accentPeach: Color(0xFFE09098),
    accentPink: Color(0xFFD65D7F),
  );

  static const ActivityModePalette _sleepLight = ActivityModePalette(
    modeId: ActivityModeId.sleep,
    primary: Color(0xFF9AA8B8),
    primaryDark: Color(0xFF6E7F92),
    primaryLight: Color(0xFFD0D8E0),
    background: Color(0xFFE8EAEE),
    surface: Color(0xFFF2F4F7),
    border: Color(0xFFC0C8D4),
    textPrimary: Color(0xFF2A3040),
    textSecondary: Color(0xFF5A6478),
    card: Color(0xFFF2F4F7),
    drawerHeader: Color(0xFFD0D8E0),
    insetSurface: Color(0xFFDCE0E8),
    accentYellow: Color(0xFFB0BCC8),
    accentPeach: Color(0xFF8A98A8),
    accentPink: Color(0xFF9AA8B8),
  );

  static const ActivityModePalette _sleepDark = ActivityModePalette(
    modeId: ActivityModeId.sleep,
    primary: Color(0xFFB0BCC8),
    primaryDark: Color(0xFF9AA8B8),
    primaryLight: Color(0xFF3A4450),
    background: Color(0xFF0A0C10),
    surface: Color(0xFF12151A),
    border: Color(0xFF2A3040),
    textPrimary: Color(0xFFD8DCE4),
    textSecondary: Color(0xFF8890A0),
    card: Color(0xFF181C24),
    drawerHeader: Color(0xFF1E2228),
    insetSurface: Color(0xFF0E1014),
    accentYellow: Color(0xFFB0BCC8),
    accentPeach: Color(0xFF8A98A8),
    accentPink: Color(0xFF9AA8B8),
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
